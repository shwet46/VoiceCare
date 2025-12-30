"""
onboarding.py - Onboarding Agent Logic
Processes onboarding transcripts and extracts medical profiles using Gemini 2.0
"""
import json
from datetime import datetime
from config import db, get_gemini_client
from models.onboarding import SeniorProfile
from google.cloud import firestore

def process_onboarding_transcript(transcript_log, user_id):
    """
    Parses transcript with Gemini 2.0 and saves both the structured 
    profile and the raw transcript to Firestore.
    """
    try:
        # 1. Setup Context
        full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])
        today_date = datetime.now().strftime("%Y-%m-%d")

        client = get_gemini_client()
        
        prompt = f"""
        Extract the senior's profile into JSON. Today's date is {today_date}.
        
        SCHEMA:
        {{
          "full_name": "string",
          "reminders": [
            {{
              "name": "string", "type": "medication"|"companion"|"appointment",
              "time": "HH:MM AM/PM", "date": "YYYY-MM-DD|null",
              "frequency": "Daily"|"Once", "is_one_time": bool, "about": "string"
            }}
          ],
          "emergency_contacts": [
            {{ "name": "string", "number": "string", "relation": "string", "is_primary": true }}
          ],
          "allergies": ["string"]
        }}

        RULES:
        - Normalize times (e.g. "08:00 PM").
        - If it's a 'Daily Chat', set type to 'companion' and frequency to 'Daily'.
        - ONLY output JSON.

        TRANSCRIPT:
        {full_text}
        """

        # 2. AI Extraction
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config={"response_mime_type": "application/json"},
        )

        # 3. Validation & Cleaning
        raw_json = json.loads(response.text)
        profile_model = SeniorProfile(**raw_json)
        structured_data = profile_model.model_dump()

        # 4. Save to Firestore
        if db:
            update_payload = {
                "profile": structured_data,
                "onboarding_complete": True,
                "onboarding_transcript": transcript_log, # <--- SAVING TRANSCRIPT HERE
                "updated_at": firestore.SERVER_TIMESTAMP,
            }

            db.collection("users").document(user_id).update(update_payload)
            print(f"✅ Profile and Transcript saved for user: {user_id}")

        return structured_data

    except Exception as e:
        print(f"❌ Error in onboarding extraction: {e}")
        raise