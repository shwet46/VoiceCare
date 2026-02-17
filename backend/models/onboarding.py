from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Literal
from datetime import datetime, timezone
from .common import TranscriptEntry, CallStatus

# --- SERVICE SUB-MODELS ---

class MedicationReminder(BaseModel):
    """Specific details for Service 1: Reminders"""
    model_config = ConfigDict(extra="forbid")
    
    medication_name: str = Field(description="Name of the medicine")
    dosage: Optional[str] = Field(default=None, description="e.g., '1 pill', '5ml'")
    total_duration_days: int = Field(default=0, description="How many days the medication is prescribed for")
    intervals_per_day: int = Field(default=0, description="How many times a day")
    specific_times: List[str] = Field(default_factory=list, description="List of specific times mentioned, e.g., ['09:00 AM']")

class EmergencyContact(BaseModel):
    """Specific details for Service 2: Emergency"""
    model_config = ConfigDict(extra="forbid")
    
    name: str = Field(description="Name of the emergency contact")
    relationship: str = Field(description="Relationship to the senior, e.g., 'Daughter'")
    phone_number: str = Field(description="Verified phone number")
    is_primary: bool = Field(default=True, description="Whether this is the main contact")

class NormalTalkConfig(BaseModel):
    """Specific details for Service 3: Normal Talks"""
    model_config = ConfigDict(extra="forbid")
    
    preferred_topics: List[str] = Field(default_factory=list, description="Topics they enjoy: e.g., 'Cricket', 'Gardening'")
    call_duration_minutes: int = Field(default=10, description="How long they usually want to chat for")
    preferred_time_of_day: Optional[str] = Field(default=None, description="e.g., 'Evening after tea'")

# --- THE MAIN PROFILE MODEL ---

class Reminder(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str = Field(description="Name of the medication or task")
    type: str = Field(description="'medication', 'companion', or 'appointment'")
    time: str = Field(description="Time in HH:MM AM/PM format")
    date: Optional[str] = Field(default=None, description="YYYY-MM-DD for one-time events")
    frequency: str = Field(default="Daily", description="'Daily', 'Weekly', or 'Once'")
    is_one_time: bool = Field(default=False)
    about: Optional[str] = Field(default=None, description="Additional context or purpose")

class EmergencyContact(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str
    number: str
    relation: str
    is_primary: bool = True

class SeniorProfile(BaseModel):
    model_config = ConfigDict(extra="forbid")
    full_name: Optional[str] = None
    reminders: List[Reminder] = []
    emergency_contacts: List[EmergencyContact] = []
    allergies: List[str] = []

class OnboardingCall(BaseModel):
    """Structured record of an onboarding conversation for Firestore logs"""
    # Note: We don't need 'extra="forbid"' here as this isn't passed to Gemini, 
    # but it's good practice for consistency.
    model_config = ConfigDict(extra="forbid")
    
    call_id: str = Field(..., description="Unique session ID")
    user_id: str = Field(..., description="Firebase user ID")
    transcript: List[TranscriptEntry] = Field(default_factory=list)
    profile: Optional[SeniorProfile] = Field(None)
    status: CallStatus = Field(default="completed")
    started_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    ended_at: Optional[str] = None
    duration_seconds: Optional[int] = None