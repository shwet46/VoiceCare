"""
service_agent.py - Service Agent Logic
Handles Reminders, Emergency, and Casual Talk with personalized context injection.
"""

from config import db, get_gemini_client # Fixed Import
from google.cloud import firestore
from datetime import datetime, timedelta, timezone
import json

SERVICE_PERSONAS = {
    "reminder": (
        "You are a gentle medical assistant. Your goal is to ensure the senior takes their medications. "
        "Use 'log_success' if they take it, or 'reschedule' if they need more time."
    ),
    "emergency": (
        "CRITICAL: You are an emergency responder. Stay calm. Assess the situation. "
        "Use 'notify_family' immediately if the situation is serious."
    ),
    "casual": (
        "You are a warm, friendly companion. Talk about their memories and hobbies. "
        "Make them feel valued and heard."
    )
}

def get_service_context(user_id, service_type="casual"):
    """Enriches the system prompt with Firestore profile data."""
    try:
        if not db: return SERVICE_PERSONAS.get(service_type)

        user_doc = db.collection("users").document(user_id).get()
        if not user_doc.exists: return SERVICE_PERSONAS.get(service_type)

        profile = user_doc.to_dict().get("profile", {})
        base_prompt = SERVICE_PERSONAS.get(service_type, SERVICE_PERSONAS["casual"])
        
        context = f"{base_prompt}\n\n--- USER CONTEXT ---\n"
        context += f"Name: {profile.get('full_name', 'Friend')}\n"
        context += f"Meds: {', '.join(profile.get('medications', []))}\n"
        return context
    except Exception as e:
        print(f"❌ Context Error: {e}")
        return SERVICE_PERSONAS.get(service_type)

def handle_service_tool(tool_name, args, user_id):
    """Closed-loop logic for tool calls (Gemini -> Firestore)."""
    # ... (Your existing tool logic is good, just ensure it uses 'db' from config)
    pass