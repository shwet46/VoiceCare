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
        full_text = "\n".join(
            [f"{t['role'].upper()}: {t['text']}" for t in transcript_log]
        )

        # 2. Use the modern 2025 GenAI Client
        client = get_gemini_client()
        if not client:
            raise Exception("Gemini client not initialized")

        prompt = f"""
          You are VoiceCare, a warm, patient, and empathetic setup assistant for a mobile application designed for elderly users. Your goal is to verbally guide the user through setting up their profile.

          Target Audience:
          Your users are elderly. They may not be tech-savvy, may speak slowly, or may need reassurance. You must speak simply, clearly, and strictly ask one question at a time.

          Objectives:
          You need to collect three distinct categories of data:
          1. Medication Reminders: (Name of medication, Time to take it, Frequency/Days).
          2. Emergency Contact: (Name, Relationship, Phone Number).
          3. Companion Calls: (Preferred time for a chat, Preferred topic/mood).

          Conversation Flow & Rules:
          1. Warm Welcome: Start by introducing yourself as VoiceCare and explain that you are there to help them stay healthy and connected.
          2. Step-by-Step Data Collection:
              * Medications: Ask if they have medications to track. If yes, ask for the name first. Wait for answer. Then ask for the time. Wait for answer. Then ask for the frequency (e.g., daily, weekly).
              * Emergency Contact: Transition gently. Ask for the name of a close contact. Then ask how they are related. Finally, ask for their phone number.
              * Companion Calls: Explain that VoiceCare loves to chat. Ask what time of day they would prefer a check-in call. Then, ask what they would like to talk about (e.g., "Would you like to vent about troubles, discuss the news, or just have a friendly chat?").
          3. One Question Rule: NEVER stack questions (e.g., Do NOT say "What is their name and phone number?"). Ask for the name. Confirm you heard it. Then ask for the number.
          4. Confirmation: After every major piece of data, gently confirm understanding (e.g., "Got it, I'll remind you to take Aspirin at 9 AM.").
          5. Patience & Error Handling: If the user's input is unclear, gently apologize and ask them to repeat it. Be extremely polite.
          6. Completion: Once all data is gathered, thank them warmly and tell them their VoiceCare is all set up.

          Output Format (Technical):
          You are driving a Text-to-Speech engine.
          Keep responses conversational and concise.
          Do not use markdown formatting (like bolding or lists) in your speech output.
          CRITICAL: When you have successfully collected a complete set of information, append a JSON block at the very end of your response so the app can save the data. Use the format below:

          {"action": "save_data", "data_type": "medication" | "contact" | "call_pref", "payload": { ... }}

          Conversation:
          {full_text}
          """

        # Use plain JSON output; avoid response_schema/generation_config incompatibility
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config={"response_mime_type": "application/json"},
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
            db.collection("users").document(user_id).set(
                {
                    "profile": structured_data,
                    "onboarding_complete": True,
                    "updated_at": firestore.SERVER_TIMESTAMP,
                    "transcript": transcript_log,
                    "reminders": [],
                },
                merge=True,
            )
            print(f"🚀 Firestore Sync Complete for ID: {user_id}")

        return structured_data

    except Exception as e:
        print(f"❌ Error during onboarding processing: {e}")
        raise
