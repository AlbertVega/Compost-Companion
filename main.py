import os
from datetime import datetime, timedelta, timezone

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext
from jose import JWTError, jwt

from database import engine, get_db
import models
from models import User, CompostPile
from schemas import (
    UserCreate,
    UserResponse,
    CompostPileCreate,
    CompostPileResponse,
    Token,
    TokenData,
)
import bcrypt

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Compost Optimization API")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/users/login")

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET_KEY environment variable is required")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

def hash_password(password: str) -> str:
    # Encode password to UTF-8, truncate to 72 bytes for bcrypt
    safe_password = password.encode("utf-8")[:72]
    # Generate salt and hash
    hashed = bcrypt.hashpw(safe_password, bcrypt.gensalt())
    # Return decoded hash as string
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8")[:72], hashed_password.encode("utf-8"))


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
            expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str | None = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.username == token_data.username).first()
    if user is None:
        raise credentials_exception
    return user



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


@app.post("/users/login", response_model=Token)
def login_user(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/users/me", response_model=UserResponse)
def read_current_user(current_user: User = Depends(get_current_user)):
    return current_user



@app.get("/compost-piles/me", response_model=list[CompostPileResponse])
def list_my_compost_piles(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    return db.query(CompostPile).filter(CompostPile.username == current_user.username).all()

@app.post("/compost-piles/create", response_model=CompostPileResponse, status_code=201)
def create_compost_pile(
        pile: CompostPileCreate,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    # Create compost pile for authenticated user only
    db_pile = CompostPile(
        username=current_user.username,
        name=pile.name,
        volume_at_creation=pile.volume_at_creation,
        location=pile.location,
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
