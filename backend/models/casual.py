from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from .common import TranscriptEntry

# --- EMOTIONAL & ENGAGEMENT TYPES ---
UserMood = Literal["happy", "sad", "lonely", "anxious", "excited", "nostalgic", "neutral"]
EngagementDepth = Literal["surface_level", "meaningful", "deep_emotional"]

class CasualTalkCall(BaseModel):
    """Data model for companionship and consoling conversations"""
    user_id: str = Field(..., description="Firebase user ID")
    call_id: str = Field(..., description="Unique session ID")
    
    # 1. Initiation Context
    # Since user clicks the button:
    call_initiated_by: Literal["user", "assistant"] = Field(default="user")
    
    # 2. Conversation Intelligence
    topics_discussed: List[str] = Field(
        default_factory=list, description="e.g., 'Cricket', 'Family', 'Cooking'"
    )
    mood_detected: UserMood = Field(default="neutral")
    engagement_level: EngagementDepth = Field(default="surface_level")
    
    # 3. Consolations & Insights
    # This is key for the 'Consoling' part
    user_worries: List[str] = Field(
        default_factory=list, description="Specific things the user is worried about"
    )
    comfort_provided: bool = Field(
        default=False, description="Did the AI successfully console the user?"
    )
    memory_anchors: List[str] = Field(
        default_factory=list, description="Facts to remember for future 'Casual' calls"
    )

    # 4. Health/Safety Cross-Check
    # Even in casual talk, we look for red flags
    red_flags_detected: bool = Field(default=False)
    
    # 5. Metadata
    transcript: List[TranscriptEntry] = Field(default_factory=list)
    started_at: str = Field(...)
    ended_at: Optional[str] = None
    call_duration_seconds: Optional[int] = None