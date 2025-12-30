import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone
from pydantic import ValidationError
from google.cloud import firestore

from models.onboarding import OnboardingCall
from models.reminder import ReminderCall
from models.emergency import EmergencyCall
from models.casual import CasualTalkCall
from config import db, el_client, AGENT_ID, get_health_status
from onboarding import process_onboarding_transcript
from scheduler import check_and_trigger_calls, schedule_reminder, list_pending_reminders

app = Flask(__name__)
CORS(app)

def _normalize_transcript(entries):
    now_iso = datetime.now(timezone.utc).isoformat()
    return [{"role": i.get("role", "assistant"), "text": i.get("text", ""), "timestamp": i.get("timestamp") or now_iso} for i in entries or []]

@app.route("/api/voice-session/start", methods=["POST"])
def start_session():
    try:
        agent_id = AGENT_ID # Using unified ID
        response = el_client.conversational_ai.conversations.get_signed_url(agent_id=agent_id)
        signed = getattr(response, "signed_url", None) or getattr(response, "url", None) or str(response)
        return jsonify({"signed_url": signed, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/voice-session/save-transcript", methods=["POST"])
def save_transcript():
    try:
        data = request.json or {}
        if data.get("agent_type") == "onboarding":
            profile = process_onboarding_transcript(data.get('transcript', []), data.get('user_id'))
            return jsonify({"status": "success", "profile": profile})
        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/calls/log", methods=["POST"])
def log_call_event():
    try:
        payload = request.json
        agent_type, service_type, call_data = payload.get("agent_type"), payload.get("service_type", "casual"), payload.get("call", {})
        call_data["transcript"] = _normalize_transcript(call_data.get("transcript"))

        if agent_type == "onboarding": model_cls = OnboardingCall
        elif service_type == "reminder": model_cls = ReminderCall
        elif service_type == "emergency": model_cls = EmergencyCall
        else: model_cls = CasualTalkCall

        call_obj = model_cls(**call_data)
        db.collection("call_logs").document(call_obj.call_id).set(call_obj.model_dump())
        return jsonify({"success": True, "call_id": call_obj.call_id}), 201
    except ValidationError as ve:
        return jsonify({"error": "Validation failed", "details": ve.errors()}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/calls/<user_id>", methods=["GET"])
def list_calls(user_id):
    try:
        query = db.collection("call_logs").where(filter=firestore.FieldFilter("user_id", "==", user_id))
        calls = [d.to_dict() for d in query.stream()]
        calls.sort(key=lambda x: x.get("started_at") or "", reverse=True)
        return jsonify({"calls": calls, "success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/reminders/schedule", methods=["POST"])
def schedule_reminder_api():
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        medication_name = data.get("medication_name")
        scheduled_time_str = data.get("scheduled_time")
        if not user_id or not scheduled_time_str:
            return jsonify({"error": "Missing user_id or scheduled_time"}), 400
        scheduled_time = datetime.fromisoformat(scheduled_time_str.replace("Z", "+00:00"))
        result = schedule_reminder(user_id, "reminder", scheduled_time, medication_name=medication_name)
        return jsonify(result), 200 if result.get("success") else 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/reminders/<user_id>", methods=["GET"])
def get_reminders(user_id):
    return jsonify(list_pending_reminders(user_id))

@app.route("/api/scheduler/check-pending", methods=["POST"])
def trigger_scheduler():
    return jsonify(check_and_trigger_calls())

@app.route("/api/health")
def health():
    return jsonify(get_health_status())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)