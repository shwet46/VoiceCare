import os
import json
from datetime import datetime
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from elevenlabs.conversational_ai.conversation import Conversation
from elevenlabs.conversational_ai.default_audio_interface import DefaultAudioInterface

load_dotenv()

# Memory for current session
conversation_log = []

def handle_transcript(role, text):
    entry = {"role": role, "text": text, "timestamp": datetime.now().isoformat()}
    conversation_log.append(entry)
    print(f"{role.upper()}: {text}")

def start_onboarding_test():
    client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
    agent_id = os.getenv("ELEVENLABS_AGENT_ID")

    print("\n--- VoiceCare Onboarding Active (Press Ctrl+C to save & exit) ---")
    
    conversation = Conversation(
        client,
        agent_id,
        requires_auth=True,
        audio_interface=DefaultAudioInterface(),
        # CALLBACKS: This is where we record the text
        callback_agent_response=lambda text: handle_transcript("assistant", text),
        callback_user_transcript=lambda text: handle_transcript("user", text),
    )

    conversation.start_session()
    
    try:
        import time
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        conversation.end_session()
        # Save the transcript for your LLM or UI
        with open("last_onboarding.json", "w") as f:
            json.dump(conversation_log, f, indent=4)
        print(f"\nSaved {len(conversation_log)} turns to last_onboarding.json")

if __name__ == "__main__":
    start_onboarding_test()