import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
import json

# ===== IMPORT MODULAR COMPONENTS =====
from config import db, el_client, AGENT_ID, twilio_service
from onboarding import process_onboarding_transcript
from service_agent import get_service_context, handle_service_tool
from scheduler import check_and_trigger_calls, schedule_reminder, list_pending_reminders

# ===== FLASK APP SETUP =====
app = Flask(__name__)
CORS(app)

print("\n🚀 VoiceCare Backend initialized with modular architecture")
print("   ├─ Onboarding Agent (data collection)")
print("   ├─ Service Agent (reminders, emergency, casual)")
print("   └─ Scheduler (perfect timing)\n")
# ===== VOICE SESSION ENDPOINTS =====

@app.route("/api/voice-session/start", methods=["POST"])
def start_voice_session():
    """
    Initiates a voice session with either the Onboarding or Service Agent.
    Uses the same ElevenLabs agent with dynamic context injection.
    
    Request body:
    {
        "agent_type": "onboarding" or "service",
        "user_id": "user_123",
        "service_type": "reminder" | "emergency" | "casual" | "check_in" (only for service agent)
    }
    """
    try:
        data = request.json
        agent_type = data.get("agent_type")  # "onboarding" or "service"
        user_id = data.get("user_id")
        service_type = data.get("service_type", "casual")  # For service agent

        if not agent_type or not user_id:
            return jsonify({"error": "Missing agent_type or user_id"}), 400

        if not el_client:
            return jsonify({"error": "ElevenLabs not initialized"}), 503

        if not AGENT_ID:
            return jsonify({"error": "Agent ID not configured"}), 503

        # Build dynamic system prompt based on agent type
        dynamic_vars = {}
        
        if agent_type == "onboarding":
            dynamic_vars = {
                "agent_mode": "onboarding",
                "system_prompt": "You are a helpful medical assistant conducting a health onboarding interview. Ask about the senior's name, emergency contact, medications, allergies, and health concerns. Be warm and patient."
            }
        elif agent_type == "service":
            # Inject personalized context for service agent
            system_prompt = get_service_context(user_id, service_type)
            dynamic_vars = {
                "agent_mode": "service",
                "service_type": service_type,
                "system_prompt": system_prompt
            }
        else:
            return jsonify({"error": "Invalid agent_type. Must be 'onboarding' or 'service'"}), 400

        # Get signed URL with dynamic variables
        signed_url = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=AGENT_ID,
            **dynamic_vars
        )

        return jsonify({
            "status": "success",
            "signed_url": signed_url,
            "agent_type": agent_type,
            "user_id": user_id
        }), 200

    except Exception as e:
        print(f"❌ Error starting voice session: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/voice-session/save-transcript", methods=["POST"])
def save_voice_transcript():
    """
    Saves and processes the voice session transcript.
    For onboarding: extracts medical profile using Gemini and saves to Firestore.
    For service: can log call outcome and next scheduled reminder.
    
    Request body:
    {
        "user_id": "user_123",
        "agent_type": "onboarding" or "service",
        "transcript": [ {"role": "agent", "text": "..."}, {"role": "user", "text": "..."} ]
    }
    """
    try:
        data = request.json
        user_id = data.get("user_id")
        agent_type = data.get("agent_type")
        transcript = data.get("transcript", [])

        if not user_id or not transcript:
            return jsonify({"error": "Missing user_id or transcript"}), 400

        if agent_type == "onboarding":
            # Process onboarding transcript
            profile = process_onboarding_transcript(transcript, user_id)
            return jsonify({
                "status": "success",
                "message": "Onboarding transcript processed and profile saved",
                "profile": profile
            }), 200

        elif agent_type == "service":
            # For service agent, just save the transcript
            if db:
                db.collection("users").document(user_id).update({
                    "last_service_call": {
                        "transcript": transcript,
                        "timestamp": datetime.now().isoformat(),
                        "type": data.get("service_type", "unknown")
                    }
                })
            return jsonify({
                "status": "success",
                "message": "Service call transcript saved"
            }), 200

        else:
            return jsonify({"error": "Invalid agent_type"}), 400

    except Exception as e:
        print(f"❌ Error saving transcript: {e}")
        return jsonify({"error": str(e)}), 500


# ===== PROFILE MANAGEMENT ENDPOINTS =====

@app.route("/api/profile/<user_id>", methods=["GET"])
def get_user_profile(user_id):
    """Fetches the complete user profile from Firestore."""
    try:
        if not db:
            return jsonify({"error": "Firestore not initialized"}), 503

        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return jsonify(doc.to_dict()), 200
        return jsonify({"error": "Profile not found"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/profile/<user_id>", methods=["POST"])
def update_user_profile(user_id):
    """Updates the user profile in Firestore."""
    try:
        if not db:
            return jsonify({"error": "Firestore not initialized"}), 503

        new_data = request.json
        db.collection("users").document(user_id).set(new_data, merge=True)

        return jsonify({
            "status": "success",
            "message": "Profile updated successfully"
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/home/<user_id>", methods=["GET"])
def get_home_data(user_id):
    """Fetches personalized dashboard data for the home screen."""
    try:
        if not db:
            return jsonify({"error": "Firestore not initialized"}), 503

        user_doc = db.collection("users").document(user_id).get()

        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404

        data = user_doc.to_dict()
        profile = data.get("profile", {})

        # Fetch pending reminders
        reminder_response = list_pending_reminders(user_id)
        pending_reminders = reminder_response.get("reminders", [])

        home_config = {
            "welcome_message": f"Hello {profile.get('full_name', 'there')}, I am watching over you.",
            "medications": profile.get("medications", []),
            "pending_reminders": len(pending_reminders),
            "emergency_contact": profile.get("emergency_phone"),
            "features": {
                "show_allergy_warning": len(profile.get("allergies", [])) > 0,
                "sos_enabled": True,
                "reminder_enabled": True
            }
        }
        return jsonify(home_config), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===== REMINDER MANAGEMENT ENDPOINTS =====

@app.route("/api/reminders/<user_id>", methods=["GET"])
def get_user_reminders(user_id):
    """Lists all pending reminders for a user."""
    try:
        result = list_pending_reminders(user_id)
        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/reminders/schedule", methods=["POST"])
def schedule_medication_reminder():
    """
    Schedules a medication reminder.
    
    Request body:
    {
        "user_id": "user_123",
        "medication_name": "Aspirin",
        "scheduled_time": "2025-12-30T10:30:00Z"
    }
    """
    try:
        data = request.json
        user_id = data.get("user_id")
        medication_name = data.get("medication_name")
        scheduled_time_str = data.get("scheduled_time")

        if not user_id or not scheduled_time_str:
            return jsonify({"error": "Missing user_id or scheduled_time"}), 400

        # Parse ISO timestamp
        scheduled_time = datetime.fromisoformat(scheduled_time_str.replace('Z', '+00:00'))

        result = schedule_reminder(
            user_id,
            "reminder",
            scheduled_time,
            medication_name=medication_name
        )

        return jsonify(result), 200 if result["success"] else 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===== SCHEDULER ENDPOINTS =====

@app.route("/api/scheduler/check-pending", methods=["POST"])
def trigger_pending_calls():
    """
    Checks for pending reminders and triggers voice calls.
    This can be called by Google Cloud Scheduler every 5 minutes.
    """
    try:
        result = check_and_trigger_calls()
        return jsonify(result), 200 if result["success"] else 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===== TWILIO WHATSAPP ENDPOINTS =====

@app.route("/api/whatsapp/send", methods=["POST"])
def send_whatsapp_message():
    """
    Send a WhatsApp message via Twilio
    
    Request body:
    {
        "phone_number": "+919167586024",
        "message": "Your message content here"
    }
    """
    try:
        if not twilio_service:
            return jsonify({
                "success": False,
                "error": "Twilio service not configured. Please check your .env file."
            }), 503

        data = request.json
        phone_number = data.get("phone_number")
        message = data.get("message")

        if not phone_number or not message:
            return jsonify({
                "success": False,
                "error": "Missing required fields: phone_number and message"
            }), 400

        result = twilio_service.send_message(phone_number, message)

        if result["success"]:
            return jsonify(result), 200
        else:
            return jsonify(result), 500

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route("/api/whatsapp/send-bulk", methods=["POST"])
def send_bulk_whatsapp_messages():
    """
    Send the same WhatsApp message to multiple contacts
    
    Request body:
    {
        "phone_numbers": ["+919167586024", "+919876543210"],
        "message": "Your message content here"
    }
    """
    try:
        if not twilio_service:
            return jsonify({
                "success": False,
                "error": "Twilio service not configured. Please check your .env file."
            }), 503

        data = request.json
        phone_numbers = data.get("phone_numbers", [])
        message = data.get("message")

        if not phone_numbers or not message:
            return jsonify({
                "success": False,
                "error": "Missing required fields: phone_numbers and message"
            }), 400

        if not isinstance(phone_numbers, list):
            return jsonify({
                "success": False,
                "error": "phone_numbers must be a list of phone numbers"
            }), 400

        results = twilio_service.send_bulk_messages(phone_numbers, message)

        success_count = sum(1 for r in results if r["success"])
        failure_count = len(results) - success_count

        return jsonify({
            "success": True,
            "total": len(results),
            "sent": success_count,
            "failed": failure_count,
            "results": results
        }), 200

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


# ===== HEALTH CHECK =====

@app.route("/api/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "VoiceCare Backend",
        "firestore": "connected" if db else "disconnected",
        "elevenlabs": "connected" if el_client else "disconnected",
        "twilio": "connected" if twilio_service else "disconnected"
    }), 200


# ===== SERVER START =====

if __name__ == "__main__":
    print("🚀 VoiceCare Backend starting on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=True)