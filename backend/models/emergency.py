from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from .common import TranscriptEntry

# --- TRIGGER TYPES ---
EmergencyTrigger = Literal[
    "user_sos",             # User shouted "Help" or pressed SOS
    "inactivity_timeout",   # No interaction for > 6 hours
    "compliance_failure",   # Missed multiple medication reminders
    "fall_detected"         # Sensor or Voice pattern detection
]

class EmergencyCall(BaseModel):
    """Reframed Emergency structure for proactive welfare monitoring"""
    user_id: str = Field(...)
    call_id: str = Field(...)
    
    # 1. The Trigger Logic
    trigger_type: EmergencyTrigger = Field(...)
    severity_level: Literal["critical", "high", "moderate", "low"] = Field(...)
    
    # 2. Situational Context
    # If trigger is inactivity, this might be null until the AI actually gets them on the phone
    transcript: List[TranscriptEntry] = Field(default_factory=list)
    emergency_description: str = Field(..., description="e.g. 'User unresponsive for 6hrs'")
    
    # 3. Notification Tracking
    emergency_contacts_notified: List[str] = Field(
        default_factory=list, description="Names/IDs of family messaged via WhatsApp"
    )
    last_known_location: Optional[str] = Field(None)
    
    # 4. Status Tracking
    resolved: bool = Field(default=False)
    resolution_note: Optional[str] = Field(None, description="e.g. 'Son checked in, user was sleeping'")
    
    # Timestamps
    created_at: str = Field(..., description="ISO timestamp")
    completed_at: Optional[str] = None