import os
from dotenv import load_dotenv
from google.cloud import firestore
from elevenlabs.client import ElevenLabs
from google import genai

load_dotenv()

# ===== FIRESTORE =====
try:
    db = firestore.Client()
    print("✓ Firestore initialized")
except Exception as e:
    print(f"⚠️ Firestore error: {e}")
    db = None

# ===== ELEVENLABS (Unified for 1 Agent) =====
try:
    el_client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
    # Use the single ID provided in your .env for both variables
    ONBOARDING_AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    SERVICE_AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    print("✓ ElevenLabs initialized")
except Exception as e:
    print(f"⚠️ ElevenLabs error: {e}")
    el_client = None

# ===== GEMINI 2.0 =====
try:
    gemini_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    print("✓ Gemini 2.0 client initialized")
except Exception as e:
    print(f"⚠️ Gemini error: {e}")
    gemini_client = None

def get_gemini_client():
    return gemini_client

def get_health_status():
    return {
        "status": "healthy",
        "firestore": "connected" if db else "disconnected",
        "elevenlabs": "connected" if el_client else "disconnected",
        "gemini": "connected" if gemini_client else "disconnected"
    }