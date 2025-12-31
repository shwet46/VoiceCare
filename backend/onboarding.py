"""
onboarding.py - Onboarding Agent Logic
Processes onboarding transcripts and extracts medical profiles using Gemini 2.0
"""

from datetime import datetime
from google.cloud import firestore
from config import db, get_gemini_client
import json

def process_onboarding_transcript(transcript_log, user_id):
    full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])
    client = get_gemini_client()

    prompt = f"""
    Extract the senior's profile into JSON.

    SCHEMA:
    {{
      "full_name": "string",
      "allergies": ["string"],
      "emergency_contacts": [
        {{ "name": "string", "number": "string", "relation": "string", "is_primary": true }}
      ],
      "reminders": [
        {{
          "name": "string",
          "time": "HH:MM AM/PM",
          "about": "string"
        }}
      ]
    }}

    ONLY output JSON.

    TRANSCRIPT:
    {full_text}
    """

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
        config={"response_mime_type": "application/json"},
    )

    data = json.loads(response.text)

    user_ref = db.collection("users").document(user_id)

    # Update core profile
    user_ref.set({
        "full_name": data.get("full_name"),
        "allergies": data.get("allergies", []),
        "emergency_contacts": data.get("emergency_contacts", []),
        "onboarding_complete": True,
        "updated_at": firestore.SERVER_TIMESTAMP
    }, merge=True)

    created_reminders = []

    for rem in data.get("reminders", []):
        # Convert time string to ISO format (you can adjust parsing if needed)
        time_str = rem.get("time")
        scheduled_time = None
        try:
            scheduled_time = datetime.strptime(time_str, "%I:%M %p").isoformat()
        except:
            scheduled_time = datetime.utcnow().isoformat()

        reminder_doc = {
            "user_id": user_id,
            "medication_name": rem.get("name"),
            "scheduled_time": scheduled_time,
            "status": "pending",
            "type": "reminder",
            "about": rem.get("about", "")
        }

        doc_ref = db.collection("reminders").add(reminder_doc)
        created_reminders.append(doc_ref[1].id)

    return {"profile_saved": True, "reminders_created": created_reminders}

