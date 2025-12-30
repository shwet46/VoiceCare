"""
CLI smoke tester that mirrors main.py endpoints using Flask's test client.
Run with uv/venv: `uv run python test.py run-all --user-id demo_user`
No need to start the server separately; this imports app from main.py and
invokes routes directly. Requires .env creds for Firestore/ElevenLabs/Twilio.
"""

import argparse
import json
import time
from datetime import datetime, timedelta, timezone

from main import app  # Imports the Flask app and config clients


client = app.test_client()


def _call_api(method: str, path: str, payload=None):
    resp = client.open(path, method=method, json=payload)
    try:
        body = resp.get_json()
    except Exception:
        body = resp.data.decode("utf-8")
    print(f"\n[{method}] {path} -> {resp.status_code}")
    print(json.dumps(body, indent=2) if isinstance(body, dict) else body)
    return resp, body


def _iso_now():
    return datetime.now(timezone.utc).isoformat()


def _make_transcript(sample: str):
    now = _iso_now()
    return [
        {"role": "assistant", "text": sample.split("|")[0].strip(), "timestamp": now},
        {"role": "user", "text": sample.split("|")[1].strip(), "timestamp": now},
    ]


def health_check():
    _call_api("GET", "/api/health")


def start_voice_session(agent: str, user_id: str, service_type: str = "casual"):
    payload = {
        "agent_type": agent,
        "user_id": user_id,
        "service_type": service_type,
    }
    _, body = _call_api("POST", "/api/voice-session/start", payload)
    if isinstance(body, dict) and body.get("signed_url"):
        print("\nSigned URL received. You can open it with a WebSocket client for a live call:")
        print("  wscat -c \"<signed_url_here>\"")


def onboarding_flow(user_id: str):
    print("\n-- Onboarding flow --")
    start_voice_session("onboarding", user_id)
    transcript = _make_transcript("Hello! I'm here to learn about your health.|Hi, I'm using aspirin and allergic to penicillin.")
    payload = {
        "user_id": user_id,
        "agent_type": "onboarding",
        "transcript": transcript,
    }
    _call_api("POST", "/api/voice-session/save-transcript", payload)

    call_id = f"onboard-{int(time.time())}"
    log_payload = {
        "agent_type": "onboarding",
        "call": {
            "call_id": call_id,
            "user_id": user_id,
            "transcript": transcript,
            "profile": {
                "full_name": "Demo Senior",
                "onboarding_type": "self",
                "medication_reminders": [],
                "emergency_contacts": [],
                "companionship_config": None,
                "allergies": ["penicillin"],
                "language_preference": "english",
                "onboarding_status": "completed",
            },
            "status": "completed",
            "started_at": _iso_now(),
            "ended_at": _iso_now(),
            "duration_seconds": 12,
        },
    }
    _call_api("POST", "/api/calls/log", log_payload)
    _call_api("GET", f"/api/profile/{user_id}")


def service_flow(user_id: str):
    print("\n-- Reminder service flow --")
    start_voice_session("service", user_id, service_type="reminder")
    transcript = _make_transcript("Time for your morning pill.|Okay I will take it now.")

    payload = {
        "user_id": user_id,
        "agent_type": "service",
        "service_type": "reminder",
        "transcript": transcript,
    }
    _call_api("POST", "/api/voice-session/save-transcript", payload)

    call_id = f"rem-{int(time.time())}"
    log_payload = {
        "agent_type": "service",
        "service_type": "reminder",
        "call": {
            "call_id": call_id,
            "user_id": user_id,
            "reminder_details": {
                "reminder_id": "demo-reminder",
                "category": "medication",
                "title": "Morning Pill",
                "medication_name": "Aspirin",
                "dosage": "1 pill",
                "activity_type": None,
                "scheduled_time": _iso_now(),
                "is_recurring": False,
            },
            "call_status": "answered",
            "action_status": "completed",
            "transcript": transcript,
            "started_at": _iso_now(),
            "ended_at": _iso_now(),
            "user_reasoning": "Took with breakfast",
        },
    }
    _call_api("POST", "/api/calls/log", log_payload)

    print("\n-- Emergency service flow --")
    emergency_call = {
        "agent_type": "service",
        "service_type": "emergency",
        "call": {
            "call_id": f"emg-{int(time.time())}",
            "user_id": user_id,
            "trigger_type": "user_sos",
            "severity_level": "high",
            "transcript": transcript,
            "emergency_description": "User reported dizziness",
            "emergency_contacts_notified": ["primary"],
            "last_known_location": "Home",
            "resolved": False,
            "created_at": _iso_now(),
        },
    }
    _call_api("POST", "/api/calls/log", emergency_call)

    print("\n-- Casual/companionship flow --")
    casual_call = {
        "agent_type": "service",
        "service_type": "casual",
        "call": {
            "call_id": f"cas-{int(time.time())}",
            "user_id": user_id,
            "topics_discussed": ["Gardening", "Family"],
            "mood_detected": "happy",
            "engagement_level": "meaningful",
            "user_worries": [],
            "comfort_provided": True,
            "memory_anchors": ["Loves roses"],
            "red_flags_detected": False,
            "transcript": transcript,
            "call_initiated_by": "user",
            "started_at": _iso_now(),
        },
    }
    _call_api("POST", "/api/calls/log", casual_call)


def reminder_flow(user_id: str):
    print("\n-- Reminder scheduling --")
    scheduled_time = (datetime.now(timezone.utc) + timedelta(minutes=1)).isoformat()
    payload = {
        "user_id": user_id,
        "medication_name": "Aspirin",
        "scheduled_time": scheduled_time,
    }
    _call_api("POST", "/api/reminders/schedule", payload)
    _call_api("GET", f"/api/reminders/{user_id}")
    _call_api("POST", "/api/scheduler/check-pending")


def list_calls(user_id: str):
    _call_api("GET", f"/api/calls/{user_id}")


def main():
    parser = argparse.ArgumentParser(description="VoiceCare backend smoke tester")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("health")

    p_voice = sub.add_parser("start-voice")
    p_voice.add_argument("--agent", required=True, choices=["onboarding", "service"])
    p_voice.add_argument("--user-id", required=True)
    p_voice.add_argument("--service-type", default="casual")

    p_onb = sub.add_parser("onboarding")
    p_onb.add_argument("--user-id", required=True)

    p_service = sub.add_parser("service")
    p_service.add_argument("--user-id", required=True)

    p_rem = sub.add_parser("reminders")
    p_rem.add_argument("--user-id", required=True)

    p_calls = sub.add_parser("calls")
    p_calls.add_argument("--user-id", required=True)

    p_all = sub.add_parser("run-all")
    p_all.add_argument("--user-id", required=True)

    args = parser.parse_args()

    if args.cmd == "health":
        health_check()
    elif args.cmd == "start-voice":
        start_voice_session(args.agent, args.user_id, args.service_type)
    elif args.cmd == "onboarding":
        onboarding_flow(args.user_id)
    elif args.cmd == "service":
        service_flow(args.user_id)
    elif args.cmd == "reminders":
        reminder_flow(args.user_id)
    elif args.cmd == "calls":
        list_calls(args.user_id)
    elif args.cmd == "run-all":
        health_check()
        onboarding_flow(args.user_id)
        service_flow(args.user_id)
        reminder_flow(args.user_id)
        list_calls(args.user_id)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
