import os
import json
import google.generativeai as genai
from google.cloud import firestore

def process_transcript_and_sync(transcript_file="last_onboarding.json", user_id="test_senior_01"):
    # 1. Initialize Clients
    db = firestore.Client()
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    model = genai.GenerativeModel("gemini-1.5-flash")

    # 2. Read the local transcript
    with open(transcript_file, "r") as f:
        transcript_data = json.load(f)
    
    full_text = "\n".join([f"{t['role']}: {t['text']}" for t in transcript_data])

    # 3. Use Gemini to extract structured info
    prompt = f"""
    Extract a medical profile from this VoiceCare onboarding transcript.
    Return ONLY a JSON object with these keys: 
    "full_name", "emergency_contact", "emergency_phone", "allergies", "medications", "care_preferences".
    
    Transcript:
    {full_text}
    """
    
    response = model.generate_content(
        prompt, 
        generation_config={"response_mime_type": "application/json"}
    )
    
    profile_data = json.loads(response.text)

    # 4. Save to Firestore
    db.collection("users").document(user_id).set({
        "profile": profile_data,
        "onboarding_status": "complete",
        "last_updated": firestore.SERVER_TIMESTAMP
    }, merge=True)
    
    print(f"✅ Profile synced to Firestore for {user_id}")
    return profile_data