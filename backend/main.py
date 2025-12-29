import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from google.cloud import firestore
from elevenlabs.client import ElevenLabs
from services.twilio_service import TwilioWhatsAppService

# 1. Setup
load_dotenv()
app = Flask(__name__)

CORS(app)

# Initialize Clients
try:
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    db = firestore.Client(project=project_id) if project_id else firestore.Client()
except Exception as e:
    print(f"Warning: Firestore not initialized - {e}")
    db = None

try:
    el_client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
    AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
except Exception as e:
    print(f"Warning: ElevenLabs not initialized - {e}")
    el_client = None
    AGENT_ID = None

# Initialize Twilio WhatsApp Service
try:
    twilio_service = TwilioWhatsAppService()
    print("✓ Twilio WhatsApp service initialized")
except ValueError as e:
    print(f"Warning: Twilio service not initialized - {e}")
    twilio_service = None

# --- ENDPOINTS FOR FLUTTER ---


@app.route("/api/voice-session", methods=["GET"])
def get_voice_session():
    """Provides a secure, temporary URL for the Flutter app to start the agent call."""
    try:
        # Generates a signed WebSocket URL valid for 15 minutes
        signed_url = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=AGENT_ID
        )
        return jsonify({"signed_url": signed_url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/profile/<user_id>", methods=["GET"])
def get_user_profile(user_id):
    """Fetches the profile extracted by Gemini for the Flutter UI."""
    try:
        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return jsonify(doc.to_dict())
        return jsonify({"error": "Profile not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/profile/<user_id>", methods=["POST"])
def update_user_profile(user_id):
    """Allows manual editing of the profile from the Flutter Profile page."""
    try:
        new_data = request.json
        db.collection("users").document(user_id).set(new_data, merge=True)
        return jsonify({"status": "success", "message": "Profile updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/save-profile", methods=["POST"])
def save_profile():
    data = request.json
    user_id = data.get("user_id")

    db.collection("seniors").document(user_id).set(data)

    return jsonify({"status": "success", "message": "Profile synced to Firestore"})


@app.route("/api/home/<user_id>", methods=["GET"])
def get_home_data(user_id):
    """Fetches personalized dashboard data for the senior citizen."""
    try:
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404

        data = user_doc.to_dict()
        profile = data.get("profile", {})

        home_config = {
            "welcome_message": f"Hello {profile.get('full_name', 'there')}, I am watching over you.",
            "reminders": profile.get("medications", []),
            "emergency_contact": profile.get("emergency_phone"),
            "features": {
                "show_allergy_warning": len(profile.get("allergies", [])) > 0,
                "sos_enabled": True,
            },
        }
        return jsonify(home_config)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- TWILIO WHATSAPP API ENDPOINTS ---


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
            return (
                jsonify(
                    {
                        "success": False,
                        "error": "Twilio service not configured. Please check your .env file.",
                    }
                ),
                503,
            )

        data = request.json
        phone_number = data.get("phone_number")
        message = data.get("message")

        # Validate required fields
        if not phone_number or not message:
            return (
                jsonify(
                    {
                        "success": False,
                        "error": "Missing required fields: phone_number and message",
                    }
                ),
                400,
            )

        # Send message
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
            return (
                jsonify(
                    {
                        "success": False,
                        "error": "Twilio service not configured. Please check your .env file.",
                    }
                ),
                503,
            )

        data = request.json
        phone_numbers = data.get("phone_numbers", [])
        message = data.get("message")

        # Validate required fields
        if not phone_numbers or not message:
            return (
                jsonify(
                    {
                        "success": False,
                        "error": "Missing required fields: phone_numbers and message",
                    }
                ),
                400,
            )

        if not isinstance(phone_numbers, list):
            return (
                jsonify(
                    {
                        "success": False,
                        "error": "phone_numbers must be a list of phone numbers",
                    }
                ),
                400,
            )

        # Send messages
        results = twilio_service.send_bulk_messages(phone_numbers, message)

        # Count successes and failures
        success_count = sum(1 for r in results if r["success"])
        failure_count = len(results) - success_count

        return (
            jsonify(
                {
                    "success": True,
                    "total": len(results),
                    "sent": success_count,
                    "failed": failure_count,
                    "results": results,
                }
            ),
            200,
        )

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


# --- SERVER START ---

if __name__ == "__main__":
    print("🚀 VoiceCare Backend starting on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=True)
