from datetime import datetime
import json
from config import db, get_gemini_client

def process_reminder_call_log(transcript_log, user_id, call_id=None):
    """
    Analyzes a reminder call transcript to extract metadata and 
    saves it to the 'call_logs' collection.
    """
    full_text = "\n".join([f"{t['role'].upper()}: {t['text']}" for t in transcript_log])
    client = get_gemini_client()

    prompt = f"""
    Analyze this transcript between a medical AI assistant and a senior user.
    Extract the following information into a JSON object.

    SCHEMA:
    {{
      "engagement_level": "low" | "meaningful" | "high",
      "mood_detected": "string (e.g., happy, anxious, neutral)",
      "comfort_provided": boolean,
      "memory_anchors": ["string (e.g., personal facts, likes/dislikes)"],
      "topics_discussed": ["string"],
      "user_worries": ["string"],
      "red_flags_detected": boolean
    }}

    ONLY output valid JSON.

    TRANSCRIPT:
    {full_text}
    """

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
        config={"response_mime_type": "application/json"},
    )

    analysis = json.loads(response.text)

    # Prepare the Firestore document following your screenshot structure
    # Document ID format: cas-1767100091
    doc_id = call_id if call_id else f"cas-{int(datetime.utcnow().timestamp())}"
    
    call_log_data = {
        "call_id": doc_id,
        "user_id": user_id,
        "call_initiated_by": "user", # or "assistant" based on session type
        "started_at": transcript_log[0].get("timestamp") if transcript_log else datetime.utcnow().isoformat(),
        "ended_at": datetime.utcnow().isoformat(),
        "call_duration_seconds": None, # Optional: calculate if timestamps available
        "engagement_level": analysis.get("engagement_level"),
        "mood_detected": analysis.get("mood_detected"),
        "comfort_provided": analysis.get("comfort_provided"),
        "memory_anchors": analysis.get("memory_anchors", []),
        "topics_discussed": analysis.get("topics_discussed", []),
        "user_worries": analysis.get("user_worries", []),
        "red_flags_detected": analysis.get("red_flags_detected", False),
        "transcript": transcript_log # Stores the full conversation as shown in screenshot
    }

    # Save to the 'call_logs' collection
    db.collection("call_logs").document(doc_id).set(call_log_data)

    return {"log_saved": True, "call_id": doc_id}