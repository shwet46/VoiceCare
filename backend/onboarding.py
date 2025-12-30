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
            You need to collect the following information in this specific order:
            1. Personal Basics: Name, Age, and Allergies.
            2. Medication Reminders: Name of medication, Time to take it, Frequency.
            3. Emergency Contact: Name, Relationship, Phone Number.
            4. Companion Calls: Preferred time for a chat, Preferred topic/mood.

            Conversation Flow & Rules:
            1. Warm Welcome & Name: Start by introducing yourself as VoiceCare. Immediately ask for their name so you can address them properly.
            2. Personal Details (One by one):
                 * Age: Once you have their name, use it. (e.g., "It's nice to meet you, [Name]. May I ask how old you are?")
                 * Allergies: Ask if they have any known allergies (food, medicine, or environmental).
            3. Medications: Transition to health. Ask if they have medications to track. If yes, ask for the name first. Wait for answer. Then ask for the time. Wait for answer. Then ask for the frequency.
            4. Emergency Contact: Transition gently. Ask for the name of a close contact. Then ask how they are related. Finally, ask for their phone number.
            5. Companion Calls: Explain that VoiceCare loves to chat. Ask what time of day they would prefer a check-in call. Then, ask what they would like to talk about (e.g., "Would you like to vent about troubles, discuss the news, or just have a friendly chat?").

            Critical Rules:
            * One Question Rule: NEVER stack questions. Do not say "How old are you and do you have allergies?" Ask for age. Wait. Then ask for allergies.
            * Patience: If the user is confused, reassure them. "Take your time, there is no rush."
            * Confirmation: Briefly confirm important details (e.g., "Okay, noted. You are allergic to Penicillin.").

            Output Format (Technical):
            * Keep responses conversational (Speech-to-Text friendly).
            * When a specific section of data is fully collected, append a JSON block at the end of your response for the app to process.

            {{"action": "save_data", "data_type": "personal_info" | "medication" | "contact" | "call_pref", "payload": {{ ... }}}}

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
