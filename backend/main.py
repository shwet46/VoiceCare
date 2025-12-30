import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone
from pydantic import ValidationError
from google.cloud import firestore

# Import your models
from models.onboarding import OnboardingCall, SeniorProfile
from models.reminder import ReminderCall, ReminderDetails
from models.emergency import EmergencyCall
from models.casual import CasualTalkCall
from models.common import CallLog

# Import config and helpers
from config import db, el_client, AGENT_ID, get_health_status
from onboarding import process_onboarding_transcript
from scheduler import (
    check_and_trigger_calls,
    schedule_reminder,
    list_pending_reminders,
)

app = Flask(__name__)
CORS(app)

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
        # You might want to pass dynamic agent_ids based on service type here
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


@app.route("/api/voice-session/save-transcript", methods=["POST"])
def save_transcript():
    """
    Called when a session ends.
    If it's onboarding, it extracts structured data and saves the User Profile.
    """
    try:
        data = request.json or {}
        user_id = data.get("user_id")

        if data.get("agent_type") == "onboarding":
            # 1. Process transcript to get Profile
            profile_data = process_onboarding_transcript(
                data.get("transcript", []), user_id
            )

            # --- FIX STARTS HERE ---
            final_payload = {}

            # Case A: It's a list (The current error source)
            if isinstance(profile_data, list):
                if len(profile_data) > 0:
                    # Check if the item inside is a Pydantic model
                    first_item = profile_data[0]
                    if hasattr(first_item, "model_dump"):
                        final_payload = first_item.model_dump()
                    elif isinstance(first_item, dict):
                        final_payload = first_item
                    else:
                        # Fallback: save the whole list as a raw field
                        final_payload = {"raw_data": profile_data}
                else:
                    final_payload = {}  # Empty list

            # Case B: It's already a Pydantic model (The expected goal)
            elif hasattr(profile_data, "model_dump"):
                final_payload = profile_data.model_dump()

            # Case C: It's a plain dictionary
            elif isinstance(profile_data, dict):
                final_payload = profile_data

            # 2. Save/Update Profile in Firestore 'users' collection
            if final_payload:
                db.collection("users").document(user_id).set(final_payload, merge=True)
                return jsonify({"status": "success", "profile": final_payload})
            else:
                return (
                    jsonify(
                        {"status": "warning", "message": "No profile data extracted"}
                    ),
                    200,
                )
            # --- FIX ENDS HERE ---

        return jsonify({"status": "success"})
    except Exception as e:
        # Added detailed logging to help debug
        print(f"ERROR in save_transcript: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/calls/log", methods=["POST"])
def log_call_event():
    """Logs the full call details (Onboarding, Reminder, Casual, or Emergency) to Firestore."""
    try:
        payload = request.json
        agent_type = payload.get("agent_type")
        service_type = payload.get("service_type", "casual")
        call_data = payload.get("call", {})

        # Normalize transcript
        call_data["transcript"] = _normalize_transcript(call_data.get("transcript"))

        # Select correct model
        if agent_type == "onboarding":
            model_cls = OnboardingCall
        elif service_type == "reminder":
            model_cls = ReminderCall
        elif service_type == "emergency":
            model_cls = EmergencyCall
        else:
            model_cls = CasualTalkCall

        # Validate and Save
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
    """Fetches the structured profile (meds, contacts) created during onboarding."""
    try:
        doc = db.collection("users").document(user_id).get()
        if not doc.exists:
            return jsonify({"error": "Profile not found"}), 404
        return jsonify(doc.to_dict()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/user/<user_id>/profile", methods=["PATCH"])
def update_user_profile(user_id):
    """Updates specific fields in the profile (e.g., adding a new allergy)."""
    try:
        data = request.json
        # Validate partial update using Pydantic if necessary, or direct update
        db.collection("users").document(user_id).update(data)
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 3. CALL HISTORY ENDPOINTS (Frontend: "History" & "Dashboard") ---


@app.route("/api/calls/<user_id>", methods=["GET"])
def list_calls(user_id):
    """Returns a list of all past calls for the timeline view."""
    try:
        # Filter by user_id and sort by start time
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
    """Returns full details (transcript, sentiment, analysis) for a single call."""
    try:
        doc = db.collection("call_logs").document(call_id).get()
        if not doc.exists:
            return jsonify({"error": "Call not found"}), 404
        return jsonify(doc.to_dict()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 4. REMINDER MANAGEMENT (Frontend: "Medication Schedule") ---


@app.route("/api/reminders/schedule", methods=["POST"])
def create_reminder():
    """Manually schedule a new reminder from the dashboard."""
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        medication_name = data.get("medication_name")
        scheduled_time_str = data.get("scheduled_time")  # Expects ISO string

        if not user_id or not scheduled_time_str:
            return jsonify({"error": "Missing user_id or scheduled_time"}), 400

        scheduled_time = datetime.fromisoformat(
            scheduled_time_str.replace("Z", "+00:00")
        )

        # Use scheduler logic
        result = schedule_reminder(
            user_id, "reminder", scheduled_time, medication_name=medication_name
        )
        return jsonify(result), 200 if result.get("success") else 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/reminders/<user_id>", methods=["GET"])
def get_reminders(user_id):
    """Get all pending/active reminders."""
    return jsonify(list_pending_reminders(user_id))


@app.route("/api/reminders/<reminder_id>", methods=["DELETE"])
def remove_reminder(reminder_id):
    """Cancel a scheduled reminder."""
    try:
        # Assuming you have a helper or direct DB deletion
        # delete_reminder is a hypothetical helper you should add to scheduler.py
        # Or direct DB call:
        db.collection("scheduled_tasks").document(reminder_id).delete()
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- 5. EMERGENCY & SYSTEM ENDPOINTS ---


@app.route("/api/emergency/trigger", methods=["POST"])
def trigger_manual_emergency():
    """Allows the frontend 'SOS' button to log an emergency and trigger alerts."""
    try:
        data = request.json
        user_id = data.get("user_id")

        # 1. Log the Emergency Call immediately
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

        # 2. (Optional) Here you would trigger the actual phone call via Twilio/ElevenLabs

        return jsonify({"success": True, "call_id": call_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/scheduler/check-pending", methods=["POST"])
def trigger_scheduler():
    """Cron job endpoint to check for due reminders."""
    return jsonify(check_and_trigger_calls())


@app.route("/api/health")
def health():
    return jsonify(get_health_status())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
