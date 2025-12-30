from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from datetime import datetime

# --- SERVICE SUB-MODELS ---

class MedicationReminder(BaseModel):
    """Specific details for Service 1: Reminders"""
    medication_name: str = Field(..., description="Name of the medicine")
    dosage: Optional[str] = Field(None, description="e.g., '1 pill', '5ml'")
    total_duration_days: int = Field(..., description="How many days the medication is prescribed for")
    intervals_per_day: int = Field(..., description="How many times a day (e.g., 2 for morning and night)")
    specific_times: List[str] = Field(
        default_factory=list, 
        description="List of specific times mentioned, e.g., ['09:00 AM', '08:00 PM']"
    )

class EmergencyContact(BaseModel):
    """Specific details for Service 2: Emergency"""
    name: str = Field(..., description="Name of the emergency contact")
    relationship: str = Field(..., description="Relationship to the senior, e.g., 'Daughter', 'Neighbor'")
    phone_number: str = Field(..., description="Verified phone number")
    is_primary: bool = Field(default=True)

class NormalTalkConfig(BaseModel):
    """Specific details for Service 3: Normal Talks"""
    preferred_topics: List[str] = Field(
        default_factory=list, 
        description="Topics they enjoy: e.g., 'Cricket', 'Gardening', 'Old Bollywood Songs'"
    )
    call_duration_minutes: int = Field(
        default=10, 
        description="How long they usually want to chat for"
    )
    preferred_time_of_day: Optional[str] = Field(
        None, description="e.g., 'Evening after tea'"
    )

# --- THE MAIN PROFILE MODEL ---

class SeniorProfile(BaseModel):
    """The full structured profile saved in Firestore under /users/{user_id}"""
    full_name: Optional[str] = Field(None)
    onboarding_type: Literal["self", "caregiver"] = Field(
        default="self", 
        description="Whether the AI talked to the senior directly or a concerned person"
    )
    
    # Service 1: Reminders
    medication_reminders: List[MedicationReminder] = Field(default_factory=list)
    
    # Service 2: Emergency
    emergency_contacts: List[EmergencyContact] = Field(default_factory=list)
    
    # Service 3: Normal Talks
    companionship_config: Optional[NormalTalkConfig] = Field(default=None)

    # General Metadata
    allergies: List[str] = Field(default_factory=list)
    language_preference: str = Field(default="english")
    onboarding_status: Literal["not_started", "in_progress", "completed"] = Field(default="not_started")