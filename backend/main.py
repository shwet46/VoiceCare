import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs

load_dotenv()
app = Flask(__name__)
CORS(app)

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID")

@app.route('/api/voice-session', methods=['GET'])
def get_voice_session():
    """Provides a secure URL for the Flutter app to start the conversation."""
    try:
        response = client.conversational_ai.conversations.get_signed_url(agent_id=AGENT_ID)
        return jsonify({"signed_url": response})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/save-transcript', methods=['POST'])
def save_transcript():
    """Endpoint to receive the full conversation log for the LLM or UI."""
    data = request.json
    # Logic to save 'data' to your database goes here
    print(f"Transcript received: {data}")
    return jsonify({"status": "success", "message": "Onboarding recorded."})

if __name__ == "__main__":
    app.run(debug=True, port=5000)