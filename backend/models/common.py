from pydantic import BaseModel, Field
from typing import List, Optional, Literal

# --- GLOBAL LITERALS ---
CallCategory = Literal["onboarding", "reminder", "emergency", "casual"]
CallStatus = Literal["ringing", "in_progress", "completed", "missed", "failed", "rescheduled"]

class TranscriptEntry(BaseModel):
    """Enhanced Transcript Entry with Sentiment Analysis"""
    role: Literal["user", "assistant"] = Field(...)
    text: str = Field(...)
    # AI will populate this during post-processing
    sentiment_score: Optional[float] = Field(
        None, description="Range -1.0 to 1.0 (Negative to Positive)"
    )
    timestamp: str = Field(..., description="ISO format timestamp")

class CallLog(BaseModel):
    """The Universal Base Model for every VoiceCare interaction"""
    call_id: str = Field(...)
    user_id: str = Field(...)
    category: CallCategory = Field(...)
    status: CallStatus = Field(default="completed")
    
    # Timing & Performance
    created_at: str = Field(...)
    completed_at: Optional[str] = None
    duration_seconds: Optional[int] = None
    
    # Intelligence Highlights
    ai_summary: Optional[str] = Field(
        None, description="A 1-sentence summary of the interaction for the dashboard"
    )
    mood_at_end: Optional[str] = Field(
        None, description="Final detected mood: 'Happy', 'Agitated', 'Calm'"
    )
    
    # Technical Metadata
    transcript_count: int = Field(default=0)
    voice_id: str = Field(default="eleven_labs_default")
    error_message: Optional[str] = None

    # Flexibility for specific service data
    # (Stores IDs for ReminderDetails or EmergencyAssessments)
    linked_resource_id: Optional[str] = None