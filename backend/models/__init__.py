"""
models - VoiceCare AI Call Data Models
Organized by call type: Onboarding, Reminder, Emergency, and Casual
"""

from .common import TranscriptEntry, CallLog
from .onboarding import SeniorProfile, OnboardingCall
from .reminder import ReminderDetails, ReminderCall
from .emergency import EmergencyCall
from .casual import CasualTalkCall

__all__ = [
    "TranscriptEntry",
    "CallLog",
    "SeniorProfile",
    "OnboardingCall",
    "ReminderDetails",
    "ReminderCall",
    "EmergencyCall",
    "CasualTalkCall",
]
