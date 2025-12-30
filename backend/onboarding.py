"""
onboarding.py - Onboarding Agent Logic
Processes onboarding transcripts and extracts medical profiles using Gemini 2.0
"""

import json
from config import db, get_gemini_client
from models.onboarding import SeniorProfile
from google.cloud import firestore

def process_onboarding_transcript(transcript_log, user_id):
    """
    Uses Gemini 2.0 to extract structured medical profile from onboarding transcript.
    """
    try:
        # 1. Prepare transcript text
        full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])

        # 2. Use the modern 2025 GenAI Client
        client = get_gemini_client()
        if not client:
            raise Exception("Gemini client not initialized")

        prompt = f"""
        You are a medical assistant. Extract a structured senior citizen's profile from this onboarding conversation.
        If a field was not mentioned, leave it null or an empty list.
        Be accurate and careful with phone numbers and names.
        
        Conversation:
        {full_text}
        """

        # Use plain JSON output; avoid response_schema/generation_config incompatibility
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config={"response_mime_type": "application/json"}
        )

        raw = response.text if hasattr(response, "text") else response
        structured_data = json.loads(raw)
        try:
            structured_data = SeniorProfile(**structured_data).model_dump()
        except Exception:
            pass

        print(f"✅ Extracted Profile for {user_id}")

        # 3. Save to Firestore
        if db:
            db.collection("users").document(user_id).set({
                "profile": structured_data,
                "onboarding_complete": True,
                "updated_at": firestore.SERVER_TIMESTAMP,
                "transcript": transcript_log,
                "reminders": [] 
            }, merge=True)
            print(f"🚀 Firestore Sync Complete for ID: {user_id}")
        
        return structured_data
        
    except Exception as e:
        print(f"❌ Error during onboarding processing: {e}")
        raise