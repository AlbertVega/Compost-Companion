from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: str = Field(..., max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)  # max 72 for bcrypt
    country: Optional[str]
    location: Optional[str]


class UserResponse(BaseModel):
    username: str
    email: EmailStr
    country: Optional[str]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True  # Updated for Pydantic v2

class CompostPileCreate(BaseModel):
    username: str
    name: str = Field(..., max_length=100)
    volume_at_creation: Optional[float]
    location: Optional[str]


class CompostPileResponse(BaseModel):
    pile_id: int
    username: str
    name: str
    volume_at_creation: Optional[float]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class HealthRecordCreate(BaseModel):
    pile_ID: int
    temperature: Optional[float]
    moisture: Optional[float]
    nitrogen_content: Optional[float]
    carbon_content: Optional[float]


class HealthRecordResponse(BaseModel):
    record_ID: int
    pile_ID: int
    temperature: Optional[float]
    moisture: Optional[float]
    nitrogen_content: Optional[float]
    carbon_content: Optional[float]
    health_score: Optional[int]
    status: Optional[str]
    timestamp: datetime

    class Config:
        from_attributes = True


class NotificationResponse(BaseModel):
    notification_ID: int
    pile_ID: int
    title: str
    description: Optional[str]
    type: Optional[str]
    priority: int
    created_at: datetime
    read_on: Optional[datetime]

    class Config:
        from_attributes = True
