"""
config.py - Central Client Initialization
Initializes all external clients: Firestore, ElevenLabs, Gemini, Twilio
"""

import os
from dotenv import load_dotenv
from google.cloud import firestore
from elevenlabs.client import ElevenLabs
import google.generativeai as genai

load_dotenv()

# ===== FIRESTORE CLIENT =====
try:
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    db = firestore.Client(project=project_id) if project_id else firestore.Client()
    print("✓ Firestore initialized")
except Exception as e:
    print(f"⚠️ Warning: Firestore not initialized - {e}")
    db = None

# ===== ELEVENLABS CLIENT =====
try:
    el_client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
    AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")
    print("✓ ElevenLabs initialized")
except Exception as e:
    print(f"⚠️ Warning: ElevenLabs not initialized - {e}")
    el_client = None
    AGENT_ID = None

# ===== GEMINI API CONFIG =====
try:
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    print("✓ Gemini API configured")
except Exception as e:
    print(f"⚠️ Warning: Gemini API not configured - {e}")

# ===== TWILIO CLIENT =====
try:
    from services.twilio_service import TwilioWhatsAppService
    twilio_service = TwilioWhatsAppService()
    print("✓ Twilio WhatsApp service initialized")
except ValueError as e:
    print(f"⚠️ Warning: Twilio service not initialized - {e}")
    twilio_service = None
except Exception as e:
    print(f"⚠️ Warning: Twilio service error - {e}")
    twilio_service = None


def get_gemini_model(model_name="gemini-2.0-flash"):
    """Returns a Gemini model instance for structured generation."""
    return genai.GenerativeModel(model_name)
