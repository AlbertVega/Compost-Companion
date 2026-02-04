from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext

from database import engine, get_db
import models
from models import User, CompostPile
from schemas import UserCreate, UserResponse, CompostPileCreate, CompostPileResponse
import bcrypt

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Compost Optimization API")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    # Encode password to UTF-8, truncate to 72 bytes for bcrypt
    safe_password = password.encode("utf-8")[:72]
    # Generate salt and hash
    hashed = bcrypt.hashpw(safe_password, bcrypt.gensalt())
    # Return decoded hash as string
    return hashed.decode("utf-8")



@app.get("/")
def read_root():
    return {"status": "Compost API is online"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    return {"message": "Successfully connected to AWS RDS!"}


@app.post("/users/register", response_model=UserResponse, status_code=201)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check if username or email already exists
    existing_user = db.query(User).filter(
        (User.username == user.username) | (User.email == user.email)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )

    # Hash the password
    hashed_password = hash_password(user.password)

    # Create new user
    db_user = User(
        username=user.username,
        email=user.email,
        password=hashed_password,
        country=user.country,
        location=user.location
    )

    # Add to DB
    db.add(db_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create user due to database constraint"
        )

    db.refresh(db_user)
    return db_user

@app.post("/compost-piles/create", response_model=CompostPileResponse, status_code=201)
def create_compost_pile(pile: CompostPileCreate, db: Session = Depends(get_db)):
    # Optional: verify user exists
    from models import User
    user = db.query(User).filter(User.username == pile.username).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail=f"User '{pile.username}' not found"
        )

    # Create compost pile
    db_pile = CompostPile(
        username=pile.username,
        name=pile.name,
        volume_at_creation=pile.volume_at_creation,
        location=pile.location  # Save the location
    )

    db.add(db_pile)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Could not create compost pile due to database constraint"
        )

    db.refresh(db_pile)
    return db_pile



