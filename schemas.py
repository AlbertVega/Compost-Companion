from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: str = Field(..., max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)  # max 72 for bcrypt
    country: Optional[str] = None
    location: Optional[str] = None


class UserResponse(BaseModel):
    username: str
    email: EmailStr
    country: Optional[str]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True  # Updated for Pydantic v2

class CompostPileCreate(BaseModel):
    name: str = Field(..., max_length=100)
    device_id: Optional[str] = Field(None, max_length=80)
    volume_at_creation: Optional[float] = None
    location: Optional[str] = None
    
 
class CompostPileUpdate(BaseModel): #For updating pile fields (linking/unlinking a device).
    name: Optional[str] = Field(None, max_length=100)
    device_id: Optional[str] = Field(None, max_length=80)
    volume_at_creation: Optional[float] = None
    location: Optional[str] = None
 


class CompostPileResponse(BaseModel):
    pile_id: int
    username: str
    name: str
    device_id: Optional[str]
    volume_at_creation: Optional[float]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class HealthRecordCreate(BaseModel):
    pile_id: int
    temperature: Optional[float] = None
    moisture: Optional[float] = None
    nitrogen_content: Optional[float] = None
    carbon_content: Optional[float] = None


class HealthRecordIngest(BaseModel):
    """Schema for creating health records via API (pile_id comes from URL)"""
    temperature: Optional[float] = None
    moisture: Optional[float] = None
    nitrogen_content: Optional[float] = None
    carbon_content: Optional[float] = None
    timestamp: Optional[datetime] = None


class HealthRecordResponse(BaseModel):
    record_id: int
    pile_id: int
    temperature: Optional[float]
    moisture: Optional[float]
    nitrogen_content: Optional[float]
    carbon_content: Optional[float]
    health_score: Optional[int]
    status: Optional[str]
    timestamp: datetime

    class Config:
        from_attributes = True


class IngredientCreate(BaseModel):
    name: str = Field(..., max_length=80)
    moisture_content: Optional[float] = None
    nitrogen_content: Optional[float] = None
    carbon_content: Optional[float] = None


class IngredientResponse(BaseModel):
    name: str
    moisture_content: Optional[float]
    nitrogen_content: Optional[float]
    carbon_content: Optional[float]

    class Config:
        from_attributes = True


class NotificationResponse(BaseModel):
    notification_id: int
    pile_id: int
    title: str
    description: Optional[str]
    type: Optional[str]
    priority: int
    created_at: datetime
    read_on: Optional[datetime]

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None
