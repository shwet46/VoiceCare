"""
onboarding.py - Onboarding Agent Logic
Processes onboarding transcripts and extracts medical profiles using Gemini 2.0
"""

import json
from config import db, get_gemini_model
from models.onboarding import SeniorProfile, OnboardingCall
from google.cloud import firestore


def process_onboarding_transcript(transcript_log, user_id):
    """
    Uses Gemini 2.0 to extract structured medical profile from onboarding transcript.
    Saves extracted data to Firestore.
    
    Args:
        transcript_log (list): List of transcript entries with 'role' and 'text'
        user_id (str): Firebase user ID
        
    Returns:
        dict: Extracted structured profile data
    """
    try:
        # 1. Prepare transcript text
        full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])

        # 2. Get Gemini model for structured output
        model = get_gemini_model()

        prompt = f"""
        You are a medical assistant. Extract a structured senior citizen's profile from this onboarding conversation.
        If a field was not mentioned, leave it null or an empty list.
        Be accurate and careful with phone numbers and names.
        
        Conversation:
        {full_text}
        """

        # Generate structured response
        response = model.generate_content(
            prompt,
            generation_config={
                "response_mime_type": "application/json",
                "response_schema": SeniorProfile
            }
        )

        structured_data = json.loads(response.text)
        print(f"✅ Extracted Profile:\n{json.dumps(structured_data, indent=2)}")

        # 3. Save to Firestore
        if db:
            db.collection("users").document(user_id).set({
                "profile": structured_data,
                "onboarding_complete": True,
                "updated_at": firestore.SERVER_TIMESTAMP,
                "transcript": transcript_log,
                "reminders": []  # Initialize empty reminders list
            }, merge=True)
            print(f"🚀 Firestore Sync Complete for ID: {user_id}")
        else:
            print("⚠️ Firestore not initialized, skipping database sync")

        return structured_data
        
    except Exception as e:
        print(f"❌ Error during onboarding processing: {e}")
        raise
