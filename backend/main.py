import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from google.cloud import firestore
from elevenlabs.client import ElevenLabs

# 1. Setup
load_dotenv()
app = Flask(__name__)

CORS(app) 

# Initialize Clients
db = firestore.Client()
el_client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")

# --- ENDPOINTS FOR FLUTTER ---

@app.route('/api/voice-session', methods=['GET'])
def get_voice_session():
    """Provides a secure, temporary URL for the Flutter app to start the agent call."""
    try:
        # Generates a signed WebSocket URL valid for 15 minutes
        signed_url = el_client.conversational_ai.conversations.get_signed_url(
            agent_id=AGENT_ID
        )
        return jsonify({"signed_url": signed_url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/profile/<user_id>', methods=['GET'])
def get_user_profile(user_id):
    """Fetches the profile extracted by Gemini for the Flutter UI."""
    try:
        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return jsonify(doc.to_dict())
        return jsonify({"error": "Profile not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/profile/<user_id>', methods=['POST'])
def update_user_profile(user_id):
    """Allows manual editing of the profile from the Flutter Profile page."""
    try:
        new_data = request.json
        db.collection("users").document(user_id).set(new_data, merge=True)
        return jsonify({"status": "success", "message": "Profile updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/save-profile', methods=['POST'])
def save_profile():
    data = request.json
    user_id = data.get('user_id')
    
    db.collection('seniors').document(user_id).set(data)
    
    return jsonify({"status": "success", "message": "Profile synced to Firestore"})

@app.route('/api/home/<user_id>', methods=['GET'])
def get_home_data(user_id):
    """Fetches personalized dashboard data for the senior citizen."""
    try:
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404
            
        data = user_doc.to_dict()
        profile = data.get('profile', {})
        
        home_config = {
            "welcome_message": f"Hello {profile.get('full_name', 'there')}, I am watching over you.",
            "reminders": profile.get('medications', []),
            "emergency_contact": profile.get('emergency_phone'),
            "features": {
                "show_allergy_warning": len(profile.get('allergies', [])) > 0,
                "sos_enabled": True
            }
        }
        return jsonify(home_config)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- SERVER START ---

if __name__ == "__main__":
    print("🚀 VoiceCare Backend starting on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=True)