import os
import json
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from elevenlabs.client import ElevenLabs
from google import genai

load_dotenv()

# ===== 1. FIRESTORE SETUP =====
# This logic handles both Vercel (Env Var) and Local (File) authentication
try:
    # Option A: Production (Vercel) - Load from Environment Variable String
    firebase_creds_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")

    if firebase_creds_json:
        print("Using Firebase Creds from Env Var")
        cred_dict = json.loads(firebase_creds_json)
        cred = credentials.Certificate(cred_dict)

    # Option B: Local Development - Load from File
    elif os.path.exists("serviceAccountKey.json"):
        print("Using Firebase Creds from Local File")
        cred = credentials.Certificate("serviceAccountKey.json")

    else:
        raise FileNotFoundError(
            "No Firebase credentials found (checked Env Var 'FIREBASE_SERVICE_ACCOUNT' and local 'serviceAccountKey.json')"
        )

    # Initialize Firebase App (if not already running)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    print("✓ Firestore initialized successfully")

except Exception as e:
    print(f"⚠️ Firestore error: {e}")
    db = None

# ===== 2. ELEVENLABS (Unified for 1 Agent) =====
try:
    el_client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))

    # Using the single ID provided in your .env for all agent types
    ONBOARDING_AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    SERVICE_AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")

    print("✓ ElevenLabs initialized")
except Exception as e:
    print(f"⚠️ ElevenLabs error: {e}")
    el_client = None

# ===== 3. GEMINI 2.0 =====
try:
    gemini_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    print("✓ Gemini 2.0 client initialized")
except Exception as e:
    print(f"⚠️ Gemini error: {e}")
    gemini_client = None


# ===== HELPERS =====
def get_gemini_client():
    return gemini_client


def get_health_status():
    return {
        "status": "healthy",
        "firestore": "connected" if db else "disconnected",
        "elevenlabs": "connected" if el_client else "disconnected",
        "gemini": "connected" if gemini_client else "disconnected",
    }
