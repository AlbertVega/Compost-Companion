from sqlalchemy import Column, String, Integer, ForeignKey, Numeric, DateTime, SmallInteger, Text, Date, Time, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

# 1. User (Table name is quoted in SQL, so we use "User" here)
class User(Base):
    __tablename__ = "User"
    username = Column(String(50), primary_key=True)
    email = Column(String(120), nullable=False, unique=True)
    password = Column(String(255), nullable=False)
    country = Column(String(100))
    location = Column(String(255))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 2. CompostPile
class CompostPile(Base):
    __tablename__ = "compostpile" # PostgreSQL often lowercases names unless quoted
    pile_ID = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), ForeignKey("User.username", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    volume_at_creation = Column(Numeric(6, 2))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 3. HealthRecord
class HealthRecord(Base):
    __tablename__ = "healthrecord"
    record_ID = Column(Integer, primary_key=True, autoincrement=True)
    pile_ID = Column(Integer, ForeignKey("compostpile.pile_ID", ondelete="CASCADE"), nullable=False)
    temperature = Column(Numeric(4, 1))
    moisture = Column(Numeric(5, 2))
    nitrogen_content = Column(Numeric(5, 2))
    carbon_content = Column(Numeric(5, 2))
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    health_score = Column(SmallInteger)
    status = Column(String(30))

    __table_args__ = (CheckConstraint('health_score BETWEEN 0 AND 100'),)

# 4. CompostRecipe
class CompostRecipe(Base):
    __tablename__ = "compostrecipe"
    recipe_ID = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(120), nullable=False)
    target_moisture = Column(Numeric(5, 2))
    target_CN_ratio = Column(Numeric(5, 2))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 5. Ingredient
class Ingredient(Base):
    __tablename__ = "ingredient"
    name = Column(String(80), primary_key=True)
    moisture_content = Column(Numeric(5, 2))
    nitrogen_content = Column(Numeric(5, 2))
    carbon_content = Column(Numeric(5, 2))

# 6. Notification
class Notification(Base):
    __tablename__ = "notification"
    notification_ID = Column(Integer, primary_key=True, autoincrement=True)
    pile_ID = Column(Integer, ForeignKey("compostpile.pile_ID", ondelete="CASCADE"), nullable=False)
    title = Column(String(120), nullable=False)
    description = Column(Text)
    type = Column(String(40))
    priority = Column(SmallInteger, default=5)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_on = Column(DateTime(timezone=True))
