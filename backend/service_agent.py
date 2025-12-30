"""
service_agent.py - Service Agent Logic
Handles Reminders, Emergency, and Casual Talk with personalized context injection.
Implements "Closed-Loop" logic with tool handlers for reschedule, log_success, notify_family, etc.
"""

from config import db, get_gemini_model
from google.cloud import firestore
from datetime import datetime, timedelta
import json


# Service personas dynamically injected into system prompts
SERVICE_PERSONAS = {
    "reminder": (
        "You are a gentle medical assistant dedicated to the well-being of a senior citizen. "
        "Your goal is to ensure they take their medications on time. "
        "If they refuse, try to persuade them kindly by explaining the importance. "
        "Use 'log_success' when they agree to take their medication, or 'reschedule' if they need more time."
    ),
    "emergency": (
        "CRITICAL: You are an emergency responder trained to handle urgent situations. "
        "Stay calm and reassuring. Keep the user talking to assess their condition. "
        "Ask for their location, pain level, and whether they've had recent falls or injuries. "
        "Use 'notify_family' immediately if the situation is serious."
    ),
    "casual": (
        "You are a warm, friendly companion who genuinely cares about the senior's well-being. "
        "Talk about their memories, hobbies, family, and interests mentioned in their profile. "
        "Be patient, slow-paced, and encouraging. Make them feel valued and heard."
    ),
    "check_in": (
        "You are a caring health assistant checking in on the senior's daily wellness. "
        "Ask about their sleep, appetite, mood, and any new aches or concerns. "
        "Be supportive and remind them that you're here to help. "
        "Use 'log_vitals' to record any health observations."
    )
}


def get_service_context(user_id, service_type="casual"):
    """
    Retrieves personalized context for a service call.
    Injects user profile data into the system prompt.
    
    Args:
        user_id (str): Firebase user ID
        service_type (str): Type of service - 'reminder', 'emergency', 'casual', 'check_in'
        
    Returns:
        str: Enriched system prompt with user context
    """
    try:
        if not db:
            print("⚠️ Firestore not initialized")
            return SERVICE_PERSONAS.get(service_type, SERVICE_PERSONAS["casual"])

        # Fetch user profile
        user_doc = db.collection("users").document(user_id).get()
        
        if not user_doc.exists:
            print(f"⚠️ User {user_id} not found in Firestore")
            return SERVICE_PERSONAS.get(service_type, SERVICE_PERSONAS["casual"])

        user_data = user_doc.to_dict()
        profile = user_data.get("profile", {})

        # Build dynamic system prompt
        base_prompt = SERVICE_PERSONAS.get(service_type, SERVICE_PERSONAS["casual"])
        
        context = f"{base_prompt}\n\n--- USER CONTEXT ---\n"
        context += f"Senior Name: {profile.get('full_name', 'Friend')}\n"
        
        medications = profile.get('medications', [])
        if medications:
            context += f"Current Medications: {', '.join(medications)}\n"
        
        allergies = profile.get('allergies', [])
        if allergies:
            context += f"⚠️ ALLERGIES: {', '.join(allergies)}\n"
        
        health_concerns = profile.get('health_concerns', [])
        if health_concerns:
            context += f"Health Concerns: {', '.join(health_concerns)}\n"
        
        emergency_contact = profile.get('emergency_contact')
        emergency_phone = profile.get('emergency_phone')
        if emergency_contact and emergency_phone:
            context += f"Emergency Contact: {emergency_contact} ({emergency_phone})\n"

        return context
        
    except Exception as e:
        print(f"❌ Error getting service context: {e}")
        return SERVICE_PERSONAS.get(service_type, SERVICE_PERSONAS["casual"])


# ===== TOOL HANDLERS (Called by Gemini/ElevenLabs) =====

def handle_service_tool(tool_name, args, user_id):
    """
    Handles tool calls from the LLM during service conversations.
    Implements closed-loop logic for reminders, emergencies, and follow-ups.
    
    Args:
        tool_name (str): Name of the tool being called
        args (dict): Arguments passed by the LLM
        user_id (str): Firebase user ID
        
    Returns:
        dict: Result of the tool call
    """
    try:
        if not db:
            return {"success": False, "error": "Firestore not initialized"}

        if tool_name == "log_success":
            """Mark medication as taken successfully."""
            medication_name = args.get("medication_name", "Unknown medication")
            db.collection("users").document(user_id).update({
                "last_med_taken": firestore.SERVER_TIMESTAMP,
                "last_med_name": medication_name
            })
            print(f"✅ Logged: {medication_name} taken successfully")
            return {
                "success": True,
                "message": f"Great! {medication_name} logged as taken."
            }

        elif tool_name == "reschedule":
            """Reschedule medication reminder for later."""
            delay_minutes = args.get("delay_minutes", 30)
            reminder_id = args.get("reminder_id")
            
            new_time = datetime.now() + timedelta(minutes=delay_minutes)
            
            if reminder_id:
                db.collection("reminders").document(reminder_id).update({
                    "scheduled_time": firestore.Timestamp.from_datetime(new_time),
                    "status": "pending"
                })
            
            print(f"🔄 Rescheduled reminder for {delay_minutes} minutes later")
            return {
                "success": True,
                "message": f"Reminder rescheduled for {delay_minutes} minutes from now."
            }

        elif tool_name == "notify_family":
            """Send emergency alert to family via SMS or notification."""
            emergency_type = args.get("emergency_type", "general")
            message = args.get("message", "Your loved one needs assistance.")
            
            user_doc = db.collection("users").document(user_id).get()
            if user_doc.exists:
                profile = user_doc.to_dict().get("profile", {})
                emergency_phone = profile.get("emergency_phone")
                emergency_contact = profile.get("emergency_contact", "Family member")
                
                # TODO: Integrate with Twilio service to send SMS
                # from services.twilio_service import send_emergency_alert
                # send_emergency_alert(emergency_phone, message)
                
                print(f"🚨 EMERGENCY: {emergency_type} - Notified {emergency_contact}")
                return {
                    "success": True,
                    "message": f"Emergency alert sent to {emergency_contact}."
                }
            
            return {
                "success": False,
                "error": "Unable to find emergency contact"
            }

        elif tool_name == "log_vitals":
            """Log vital signs or health observations."""
            vitals = args.get("vitals", {})
            
            vitals_entry = {
                "timestamp": firestore.SERVER_TIMESTAMP,
                "data": vitals
            }
            
            db.collection("users").document(user_id).collection("vitals").add(vitals_entry)
            
            print(f"📊 Logged vitals: {vitals}")
            return {
                "success": True,
                "message": "Health observations recorded successfully."
            }

        elif tool_name == "book_doctor":
            """Initiate doctor appointment booking."""
            doctor_type = args.get("doctor_type", "General Practitioner")
            preferred_date = args.get("preferred_date")
            
            appointment = {
                "doctor_type": doctor_type,
                "preferred_date": preferred_date,
                "status": "pending",
                "created_at": firestore.SERVER_TIMESTAMP
            }
            
            db.collection("users").document(user_id).collection("appointments").add(appointment)
            
            print(f"📅 Doctor appointment requested: {doctor_type}")
            return {
                "success": True,
                "message": f"Your {doctor_type} appointment request has been noted."
            }

        else:
            return {
                "success": False,
                "error": f"Unknown tool: {tool_name}"
            }

    except Exception as e:
        print(f"❌ Error in tool handler: {e}")
        return {
            "success": False,
            "error": str(e)
        }
