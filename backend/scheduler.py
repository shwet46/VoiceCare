"""
scheduler.py - Background Scheduler
"""
from config import db
from datetime import datetime, timezone
from google.cloud import firestore

def check_and_trigger_calls():
    try:
        if not db:
            return {"success": False, "error": "Firestore not available"}

        now = datetime.now(timezone.utc)
        pending = db.collection("reminders").where(filter=firestore.FieldFilter("status", "==", "pending")).stream()

        count = 0
        for doc in pending:
            data = doc.to_dict() or {}
            scheduled_time = data.get("scheduled_time")
            if scheduled_time and isinstance(scheduled_time, firestore.Timestamp):
                if scheduled_time.to_datetime() > now:
                    continue
            doc.reference.update({
                "status": "pinging",
                "triggered_at": firestore.SERVER_TIMESTAMP
            })
            count += 1

        return {"success": True, "triggered": count}
    except Exception as e:
        return {"success": False, "error": str(e)}

def schedule_reminder(user_id, reminder_type, scheduled_time, medication_name=None):
    """Schedules a new reminder."""
    try:
        reminder_data = {
            "user_id": user_id,
            "type": reminder_type,
            "medication_name": medication_name,
            "scheduled_time": scheduled_time if isinstance(scheduled_time, datetime) else datetime.fromisoformat(str(scheduled_time)),
            "status": "pending",
            "created_at": firestore.SERVER_TIMESTAMP
        }
        db.collection("reminders").add(reminder_data)
        return {"success": True, "message": "Scheduled"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def list_pending_reminders(user_id):
    reminders = db.collection("reminders") \
        .where(filter=firestore.FieldFilter("user_id", "==", user_id)) \
        .where(filter=firestore.FieldFilter("status", "==", "pending")) \
        .stream()
    return {"reminders": [r.to_dict() for r in reminders], "success": True}