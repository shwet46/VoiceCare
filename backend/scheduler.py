"""
scheduler.py - Background Scheduler for Automated Service Calls
Checks for pending reminders and triggers calls at the perfect timing.
Can be run as a background process or triggered by Google Cloud Scheduler.
"""

from config import db
from datetime import datetime, timezone
import json
from google.cloud import firestore


def check_and_trigger_calls():
    """
    Scans Firestore for pending reminders/check-ins and triggers voice calls.
    This function should be called periodically (every 5-10 minutes).
    """
    try:
        if not db:
            print("⚠️ Firestore not initialized")
            return {"success": False, "error": "Firestore not available"}

        now = datetime.now(timezone.utc)

        # Query all pending reminders that are due
        pending_reminders = db.collection("reminders") \
            .where("status", "==", "pending") \
            .where("scheduled_time", "<=", firestore.Timestamp.from_datetime(now)) \
            .stream()

        triggered_count = 0

        for reminder_doc in pending_reminders:
            reminder_data = reminder_doc.to_dict()
            user_id = reminder_data.get("user_id")
            reminder_type = reminder_data.get("type", "reminder")  # reminder, check_in, casual

            try:
                # Update status to "pinging" to indicate trigger attempt
                reminder_doc.reference.update({
                    "status": "pinging",
                    "triggered_at": firestore.SERVER_TIMESTAMP
                })

                # TODO: Send FCM notification to Flutter app to show incoming call UI
                # trigger_fcm_notification(user_id, reminder_type, reminder_doc.id)

                print(f"📞 Triggered {reminder_type} call for user {user_id}")
                triggered_count += 1

            except Exception as e:
                print(f"❌ Error triggering reminder {reminder_doc.id}: {e}")
                reminder_doc.reference.update({"status": "error", "error": str(e)})

        return {
            "success": True,
            "triggered": triggered_count,
            "timestamp": now.isoformat()
        }

    except Exception as e:
        print(f"❌ Error in scheduler: {e}")
        return {"success": False, "error": str(e)}


def schedule_reminder(user_id, reminder_type, scheduled_time, medication_name=None):
    """
    Schedules a new reminder in Firestore.
    
    Args:
        user_id (str): Firebase user ID
        reminder_type (str): Type of reminder ('reminder', 'check_in', 'casual', 'emergency')
        scheduled_time (datetime): When to trigger the reminder
        medication_name (str, optional): Name of medication (for reminder type)
        
    Returns:
        dict: Result with reminder document ID
    """
    try:
        if not db:
            return {"success": False, "error": "Firestore not initialized"}

        reminder_data = {
            "user_id": user_id,
            "type": reminder_type,
            "scheduled_time": firestore.Timestamp.from_datetime(scheduled_time),
            "status": "pending",
            "created_at": firestore.SERVER_TIMESTAMP,
            "medication_name": medication_name
        }

        doc_ref = db.collection("reminders").add(reminder_data)
        reminder_id = doc_ref[1].id

        print(f"✅ Scheduled {reminder_type} reminder for user {user_id} at {scheduled_time}")
        return {
            "success": True,
            "reminder_id": reminder_id,
            "scheduled_time": scheduled_time.isoformat()
        }

    except Exception as e:
        print(f"❌ Error scheduling reminder: {e}")
        return {"success": False, "error": str(e)}


def list_pending_reminders(user_id):
    """Lists all pending reminders for a user."""
    try:
        if not db:
            return {"success": False, "reminders": []}

        reminders = db.collection("reminders") \
            .where("user_id", "==", user_id) \
            .where("status", "==", "pending") \
            .stream()

        reminder_list = []
        for doc in reminders:
            data = doc.to_dict()
            data["id"] = doc.id
            reminder_list.append(data)

        return {"success": True, "reminders": reminder_list}

    except Exception as e:
        print(f"❌ Error listing reminders: {e}")
        return {"success": False, "reminders": [], "error": str(e)}


def complete_reminder(reminder_id):
    """Marks a reminder as completed."""
    try:
        if not db:
            return {"success": False, "error": "Firestore not initialized"}

        db.collection("reminders").document(reminder_id).update({
            "status": "completed",
            "completed_at": firestore.SERVER_TIMESTAMP
        })

        print(f"✅ Reminder {reminder_id} marked as completed")
        return {"success": True}

    except Exception as e:
        print(f"❌ Error completing reminder: {e}")
        return {"success": False, "error": str(e)}
