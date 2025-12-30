from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from .common import TranscriptEntry

# --- OUTCOME TYPES ---

# Represents the status of the VOICE CALL itself
CallStatus = Literal["answered", "missed", "voicemail", "busy", "failed"]

# Represents the status of the TASK (Medication/Activity)
ActionStatus = Literal[
    "completed",      # Took meds / Finished exercise
    "delayed",        # User said "Call me back in 10 mins"
    "refused",        # User explicitly said "I won't do it"
    "partially_done",  # Took 1 pill out of 2
    "ignored",        # Call was answered but user hung up or stayed silent
    "pending"         # Default state
]

class ReminderDetails(BaseModel):
    """Details about the specific task assigned to the AI"""
    reminder_id: str = Field(..., description="Unique ID from Firestore")
    category: Literal["medication", "activity", "appointment"] = Field(...)
    
    # Task specific details
    title: str = Field(..., description="e.g., 'Morning Yoga' or 'Blood Pressure Pill'")
    medication_name: Optional[str] = None
    dosage: Optional[str] = None
    activity_type: Optional[str] = Field(None, description="e.g., 'Walking', 'Stretching'")
    
    # Timing logic
    scheduled_time: str = Field(..., description="ISO timestamp for the cron job")
    is_recurring: bool = False

class ReminderCall(BaseModel):
    """The complete record of a single reminder interaction"""
    user_id: str = Field(...)
    call_id: str = Field(...)
    
    # The "What"
    reminder_details: ReminderDetails = Field(...)
    
    # The "Outcome" (The Intelligent Logic Part)
    call_status: CallStatus = Field(default="missed")
    action_status: ActionStatus = Field(default="pending")
    
    # Rescheduling logic
    is_rescheduled: bool = Field(default=False)
    new_scheduled_time: Optional[str] = Field(
        None, description="If status is 'delayed', when is the next attempt?"
    )
    
    # AI Analysis
    user_reasoning: Optional[str] = Field(
        None, description="Why did they delay? e.g., 'Not hungry yet', 'Feeling tired'"
    )
    transcript: List[TranscriptEntry] = Field(default_factory=list)
    
    # Timestamps
    started_at: str = Field(...)
    ended_at: Optional[str] = None