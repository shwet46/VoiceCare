import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone
from pydantic import ValidationError
from google.cloud import firestore
from twilio.rest import Client  # Added Twilio import

# Import your models
from models.onboarding import OnboardingCall, SeniorProfile
from models.reminder import ReminderCall, ReminderDetails
from models.emergency import EmergencyCall
from models.casual import CasualTalkCall
from models.common import CallLog

# Import config and helpers
from config import db, el_client, AGENT_ID, CANSUAL_AGENT_ID, SERVICE_AGENT_ID, get_health_status
from onboarding import process_onboarding_transcript
from calllogs import process_reminder_call_log
from scheduler import (
    check_and_trigger_calls,
    schedule_reminder,
    list_pending_reminders,
)

app = Flask(__name__)
CORS(app)

# --- SERVICE CLASSES ---


class TwilioWhatsAppService:
    def __init__(self):
        """Initialize Twilio client with credentials from environment variables"""
        self.account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        self.auth_token = os.getenv("TWILIO_AUTH_TOKEN")
        self.from_whatsapp_number = os.getenv("TWILIO_WHATSAPP_NUMBER")

        # We initialize lazily or log a warning if creds are missing to prevent app crash
        if not all([self.account_sid, self.auth_token, self.from_whatsapp_number]):
            print("⚠️ Twilio credentials missing. WhatsApp service will not work.")
            self.client = None
        else:
            self.client = Client(self.account_sid, self.auth_token)

    def send_message(self, to_number, message_body):
        """
        Send a WhatsApp message to a specific number
        Args:
            to_number (str): Recipient's phone number (e.g., +919167586024)
            message_body (str): The message content to send
        """
        if not self.client:
            return {"success": False, "error": "Twilio not configured"}

        try:
            # Twilio WhatsApp numbers must be prefixed with 'whatsapp:'
            # Handle cases where input might already have the prefix
            recipient = (
                to_number
                if to_number.startswith("whatsapp:")
                else f"whatsapp:{to_number}"
            )

            # Handle sender prefix similarly
            sender = (
                self.from_whatsapp_number
                if self.from_whatsapp_number.startswith("whatsapp:")
                else f"whatsapp:{self.from_whatsapp_number}"
            )

            message = self.client.messages.create(
                body=message_body, from_=sender, to=recipient
            )

            return {
                "success": True,
                "message_sid": message.sid,
                "status": message.status,
                "to": to_number,
                "message": "Message sent successfully",
            }

        except Exception as e:
            print(f"Twilio Error: {str(e)}")
            return {"success": False, "error": str(e), "to": to_number}


# Initialize the service
whatsapp_service = TwilioWhatsAppService()


# --- HELPER FUNCTIONS ---


def _normalize_transcript(entries):
    """Ensures transcript entries match the Pydantic model format."""
    now_iso = datetime.now(timezone.utc).isoformat()
    return [
        {
            "role": i.get("role", "assistant"),
            "text": i.get("text", ""),
            "timestamp": i.get("timestamp") or now_iso,
        }
        for i in entries or []
    ]


# --- 1. VOICE SESSION MANAGEMENT ---
@app.route("/api/voice-session/start", methods=["GET"])
def start_session():
    """Generates the signed URL to start the ElevenLabs conversation."""
    try:
        agent_id = AGENT_ID
        response = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=agent_id
        )
        signed = (
            getattr(response, "signed_url", None)
            or getattr(response, "url", None)
            or str(response)
        )
        return jsonify({"signed_url": signed, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/api/reminder-voice-session/start", methods=["GET"])
def start_reminder_session():
    """Generates the signed URL to start the ElevenLabs conversation."""
    try:
        # You might want to pass dynamic agent_ids based on service type here
        agent_id = SERVICE_AGENT_ID
        response = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=agent_id
        )
        signed = (
            getattr(response, "signed_url", None)
            or getattr(response, "url", None)
            or str(response)
        )
        return jsonify({"signed_url": signed, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/api/casual-voice-session/start", methods=["GET"])
def start_casual_session():
    """Generates the signed URL to start the ElevenLabs conversation."""
    try:
        # You might want to pass dynamic agent_ids based on service type here
        agent_id = CANSUAL_AGENT_ID
        response = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=agent_id
        )
        signed = (
            getattr(response, "signed_url", None)
            or getattr(response, "url", None)
            or str(response)
        )
        return jsonify({"signed_url": signed, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# voice session for reminder calls
# @app.route("/api/voice-session/reminder", methods=["POST"])
# def start_reminder_session():
#     try:
#         data = request.json
        
#         # 1. Align these keys with your system prompt tags!
#         # Your prompt uses: {{reminder_topic}}, {{specific_task}}, {{questions_to_ask}}
#         dynamic_vars = {
#             "reminder_topic": data.get("name", "your health check"),
#             "specific_task": data.get("about", "ensure you are feeling well"),
#             "questions_to_ask": data.get("questions", "How are you feeling today?")
#         }

#         # 2. Use the correct Override class
#         config_override = ConversationConfigOverride(
#             agent={
#                 "dynamic_variables": dynamic_vars
#             }
#         )

#         # 3. Use the correct keyword: conversation_config_override
#         response = el_client.conversational_ai.conversations.get_signed_url(
#             agent_id=SERVICE_AGENT_ID,
#             conversation_config_override=config_override
#         )
        
#         signed_url = getattr(response, "signed_url", str(response))
#         return jsonify({"signed_url": signed_url, "status": "success"})

#     except Exception as e:
#         print(f"DEBUG ERROR: {e}")
#         return jsonify({"error": str(e)}), 500
    
@app.route("/api/voice-session/save-transcript", methods=["POST"])
def save_transcript():
    """
    Called when a session ends.
    Handles 'onboarding' (profile creation) and 'reminder' (call log saving).
    """
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        agent_type = data.get("agent_type")
        transcript_log = data.get("transcript", [])
        call_id = data.get("call_id") # Expected from frontend

        if agent_type == "onboarding":
            # 1. Process transcript to get Profile and create initial reminders
            result = process_onboarding_transcript(transcript_log, user_id)
            return jsonify({"status": "success", "result": result})

        elif agent_type == "reminder":
            # 2. Process the conversation to extract sentiment and memory anchors
            result = process_reminder_call_log(transcript_log, user_id, call_id)
            return jsonify({"status": "success", "result": result})

        return jsonify({"status": "success"})
    except Exception as e:
        print(f"ERROR in save_transcript: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/calls/log", methods=["POST"])
def log_call_event():
    """Logs the full call details to Firestore."""
    try:
        payload = request.json
        agent_type = payload.get("agent_type")
        service_type = payload.get("service_type", "casual")
        call_data = payload.get("call", {})

        call_data["transcript"] = _normalize_transcript(call_data.get("transcript"))

        if agent_type == "onboarding":
            model_cls = OnboardingCall
        elif service_type == "reminder":
            model_cls = ReminderCall
        elif service_type == "emergency":
            model_cls = EmergencyCall
        else:
            model_cls = CasualTalkCall

        call_obj = model_cls(**call_data)
        db.collection("call_logs").document(call_obj.call_id).set(call_obj.model_dump())

        return jsonify({"success": True, "call_id": call_obj.call_id}), 201
    except ValidationError as ve:
        return jsonify({"error": "Validation failed", "details": ve.errors()}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 2. USER PROFILE ENDPOINTS (Frontend: "My Profile") ---
@app.route("/api/user/<user_id>/profile", methods=["GET"])
def get_user_profile(user_id):
    """Fetches the structured profile."""
    try:
        doc = db.collection("users").document(user_id).get()
        if not doc.exists:
            return jsonify({"error": "Profile not found"}), 404
        return jsonify(doc.to_dict()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/user/<user_id>/profile", methods=["PATCH"])
def update_user_profile(user_id):
    """Updates specific fields in the profile."""
    try:
        data = request.json
        db.collection("users").document(user_id).update(data)
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 3. CALL HISTORY ENDPOINTS ---


@app.route("/api/calls/<user_id>", methods=["GET"])
def list_calls(user_id):
    """Returns a list of all past calls."""
    try:
        query = (
            db.collection("call_logs")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .order_by("started_at", direction=firestore.Query.DESCENDING)
        )
        calls = [d.to_dict() for d in query.stream()]
        return jsonify({"calls": calls, "success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/call/<call_id>", methods=["GET"])
def get_call_details(call_id):
    """Returns full details for a single call."""
    try:
        doc = db.collection("call_logs").document(call_id).get()
        if not doc.exists:
            return jsonify({"error": "Call not found"}), 404
        return jsonify(doc.to_dict()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 4. REMINDER MANAGEMENT ---


@app.route("/api/reminders/schedule", methods=["POST"])
def create_reminder():
    """Manually schedule a new reminder."""
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        medication_name = data.get("medication_name")
        scheduled_time_str = data.get("scheduled_time")

        if not user_id or not scheduled_time_str:
            return jsonify({"error": "Missing user_id or scheduled_time"}), 400

        scheduled_time = datetime.fromisoformat(
            scheduled_time_str.replace("Z", "+00:00")
        )

        result = schedule_reminder(
            user_id, "reminder", scheduled_time, medication_name=medication_name
        )
        return jsonify(result), 200 if result.get("success") else 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/reminders/<user_id>", methods=["GET"])
def get_reminders(user_id):
    return jsonify(list_pending_reminders(user_id))


@app.route("/api/reminders/<reminder_id>", methods=["DELETE"])
def remove_reminder(reminder_id):
    """Cancel a scheduled reminder."""
    try:
        db.collection("scheduled_tasks").document(reminder_id).delete()
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 5. WHATSAPP & NOTIFICATIONS (NEW) ---


@app.route("/api/notifications/whatsapp", methods=["POST"])
def send_whatsapp():
    """
    Sends a WhatsApp message via Twilio.
    Expects JSON: { "to": "+919876543210", "message": "Hello!" }
    """
    try:
        data = request.json or {}
        to_number = data.get("to")
        message_body = data.get("message")

        if not to_number or not message_body:
            return jsonify({"error": "Missing 'to' or 'message' fields"}), 400

        result = whatsapp_service.send_message(to_number, message_body)

        if result.get("success"):
            return jsonify(result), 200
        else:
            return jsonify(result), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 6. EMERGENCY & SYSTEM ENDPOINTS ---


@app.route("/api/emergency/trigger", methods=["POST"])
def trigger_manual_emergency():
    """Allows the frontend 'SOS' button to log an emergency."""
    try:
        data = request.json
        user_id = data.get("user_id")

        call_id = f"sos_{int(datetime.now().timestamp())}"
        emergency_payload = EmergencyCall(
            user_id=user_id,
            call_id=call_id,
            trigger_type="user_sos",
            severity_level="critical",
            emergency_description="User pressed SOS button in app",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        db.collection("call_logs").document(call_id).set(emergency_payload.model_dump())

        # OPTIONAL: Send WhatsApp Alert immediately
        # whatsapp_service.send_message("+91YOUR_ADMIN_NUM", f"SOS Alert for User {user_id}")

        return jsonify({"success": True, "call_id": call_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/scheduler/check-pending", methods=["POST"])
def trigger_scheduler():
    return jsonify(check_and_trigger_calls())


@app.route("/api/health")
def health():
    return jsonify(get_health_status())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
