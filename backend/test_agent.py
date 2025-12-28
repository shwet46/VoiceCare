import os
import json
from datetime import datetime
from dotenv import load_dotenv

# ElevenLabs Imports
from elevenlabs.client import ElevenLabs
from elevenlabs.conversational_ai.conversation import Conversation
from elevenlabs.conversational_ai.default_audio_interface import DefaultAudioInterface

# AI & Database Imports
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from pydantic import BaseModel, Field
from typing import List, Optional

load_dotenv()

# --- 1. DATA SCHEMA FOR GEMINI ---
class SeniorProfile(BaseModel):
    full_name: Optional[str] = Field(description="The senior citizen's full name")
    emergency_contact: Optional[str] = Field(description="Name of the emergency contact person")
    emergency_phone: Optional[str] = Field(description="Phone number of the emergency contact")
    allergies: List[str] = Field(default_factory=list, description="List of any reported allergies")
    medications: List[str] = Field(default_factory=list, description="List of current medications mentioned")
    health_concerns: List[str] = Field(default_factory=list, description="Any specific health or safety concerns")

# --- 2. TRANSCRIPT PROCESSING & SYNC LOGIC ---
def process_and_sync_profile(transcript_log, user_id="test_user_senior"):
    """Uses Gemini 2.0 to extract data and saves it to Firestore."""
    print("\n--- Processing Conversation with Gemini 2.0 Flash ---")
    
    # 1. Prepare Text
    full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])

    # 2. Configure Gemini (Updated to stable 2.0-flash for late 2025)
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    model = genai.GenerativeModel("gemini-2.0-flash")

    prompt = f"""
    You are a medical assistant. Extract a structured profile from this onboarding chat.
    If a field was not mentioned, leave it null or an empty list.
    
    Transcript:
    {full_text}
    """

    try:
        # Structured Output Generation
        response = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json",
                response_schema=SeniorProfile
            )
        )
        
        structured_data = json.loads(response.text)
        print(f"✅ Extracted Data: {json.dumps(structured_data, indent=2)}")

        # 3. Initialize Firebase & Sync
        if not firebase_admin._apps:
            cred = credentials.Certificate("serviceAccountKey.json")
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        # Update user profile and set onboarding status
        db.collection("users").document(user_id).set({
            "profile": structured_data,
            "onboarding_complete": True,
            "updated_at": firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        print(f"🚀 Firestore Sync Complete for ID: {user_id}")
        
    except Exception as e:
        print(f"❌ Error during AI processing or DB sync: {e}")

# --- 3. MAIN CONVERSATION LOGIC ---
conversation_log = []

def handle_transcript(role, text):
    entry = {"role": role, "text": text, "timestamp": datetime.now().isoformat()}
    conversation_log.append(entry)
    print(f"{role.upper()}: {text}")

def start_onboarding_test():
    # Credentials Check
    if not os.getenv("GEMINI_API_KEY"):
        print("❌ Error: GEMINI_API_KEY not found in .env")
        return

    client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
    agent_id = os.getenv("ELEVENLABS_AGENT_ID")

    print(f"\n--- VoiceCare Onboarding Active (Agent ID: {agent_id}) ---")
    print("--- Speak now! Press Ctrl+C to end call and sync to Profile ---")
    
    conversation = Conversation(
        client,
        agent_id,
        requires_auth=True,
        audio_interface=DefaultAudioInterface(),
        callback_agent_response=lambda text: handle_transcript("assistant", text),
        callback_user_transcript=lambda text: handle_transcript("user", text),
    )

    conversation.start_session()
    
    try:
        import time
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n--- Call Ended by User ---")
        conversation.end_session()
        
        # Save local JSON backup
        with open("last_onboarding.json", "w") as f:
            json.dump(conversation_log, f, indent=4)
            
        # Run processing and database update
        process_and_sync_profile(conversation_log)

if __name__ == "__main__":
    start_onboarding_test()