import os
from datetime import datetime, timedelta, timezone

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import desc
from passlib.context import CryptContext
from jose import JWTError, jwt

from database import engine, get_db
import models
from models import User, CompostPile, HealthRecord, Ingredient
from AI_Agent.expert_system import CompostExpertSystem
from schemas import (
    UserCreate,
    UserResponse,
    CompostPileCreate,
    CompostPileResponse,
    HealthRecordCreate,
    HealthRecordIngest,
    HealthRecordResponse,
    IngredientCreate,
    IngredientResponse,
    Token,
    TokenData,
    EvaluateRecipeRequest,
    RecipeEvaluation
)
import bcrypt

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Compost Optimization API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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


# ============================================================================
# ROOT & TEST ENDPOINTS
# ============================================================================

@app.get("/")
def read_root():
    return {"status": "Compost API is online"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    return {"message": "Successfully connected to AWS RDS!"}


# ============================================================================
# USER ENDPOINTS
# ============================================================================

@app.post("/users/register", response_model=UserResponse, status_code=201)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
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
    """Login and receive JWT token"""
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
    """Get current authenticated user"""
    return current_user


# ============================================================================
# COMPOST PILE ENDPOINTS
# ============================================================================

@app.get("/compost-piles/me", response_model=list[CompostPileResponse])
def list_my_compost_piles(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Get all compost piles for the current user"""
    return db.query(CompostPile).filter(CompostPile.username == current_user.username).all()


@app.post("/compost-piles/create", response_model=CompostPileResponse, status_code=201)
def create_compost_pile(
        pile: CompostPileCreate,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Create a new compost pile for the authenticated user"""
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


@app.get("/compost-piles/{pile_id}", response_model=CompostPileResponse)
def get_compost_pile(
        pile_id: int,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Get a specific compost pile by ID"""
    pile = db.query(CompostPile).filter(
        CompostPile.pile_id == pile_id,
        CompostPile.username == current_user.username
    ).first()
    
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )
    
    return pile


# ============================================================================
# HEALTH RECORD ENDPOINTS
# ============================================================================

@app.post("/compost-piles/{pile_id}/health-records", response_model=HealthRecordResponse, status_code=201)
def create_health_record(
        pile_id: int,
        record: HealthRecordIngest,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Create a new health record for a compost pile"""
    # Verify pile belongs to user
    pile = db.query(CompostPile).filter(
        CompostPile.pile_id == pile_id,
        CompostPile.username == current_user.username
    ).first()
    
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )
    
    # Create health record
    db_record = HealthRecord(
        pile_id=pile_id,
        temperature=record.temperature,
        moisture=record.moisture,
        nitrogen_content=record.nitrogen_content,
        carbon_content=record.carbon_content,
        timestamp=record.timestamp or datetime.now(timezone.utc)
    )
    
    db.add(db_record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Could not create health record due to database constraint"
        )
    
    db.refresh(db_record)
    return db_record


@app.get("/compost-piles/{pile_id}/health-records/latest", response_model=HealthRecordResponse)
def get_latest_health_record(
        pile_id: int,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Get the most recent health record for a compost pile"""
    # Verify pile belongs to user
    pile = db.query(CompostPile).filter(
        CompostPile.pile_id == pile_id,
        CompostPile.username == current_user.username
    ).first()
    
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )
    
    # Get latest record
    latest_record = db.query(HealthRecord).filter(
        HealthRecord.pile_id == pile_id
    ).order_by(desc(HealthRecord.timestamp)).first()
    
    if not latest_record:
        raise HTTPException(
            status_code=404,
            detail=f"No health records found for compost pile {pile_id}"
        )
    # if record lacks computed fields (e.g. old rows), calculate and persist

    
    return latest_record


@app.get("/compost-piles/{pile_id}/health-records", response_model=list[HealthRecordResponse])
def get_all_health_records(
        pile_id: int,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
        limit: int = 100,
):
    """Get all health records for a compost pile (most recent first)"""
    # Verify pile belongs to user
    pile = db.query(CompostPile).filter(
        CompostPile.pile_id == pile_id,
        CompostPile.username == current_user.username
    ).first()
    
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )
    
    # Get all records, ordered by most recent first
    records = db.query(HealthRecord).filter(
        HealthRecord.pile_id == pile_id
    ).order_by(desc(HealthRecord.timestamp)).limit(limit).all()
    

    return records


# ============================================================================
# INGREDIENT ENDPOINTS
# ============================================================================

@app.get("/ingredients", response_model=list[IngredientResponse])
def get_all_ingredients(db: Session = Depends(get_db)):
    """Get all ingredients (public endpoint, no auth required)"""
    return db.query(Ingredient).all()


@app.get("/ingredients/{ingredient_name}", response_model=IngredientResponse)
def get_ingredient(ingredient_name: str, db: Session = Depends(get_db)):
    """Get a specific ingredient by name"""
    ingredient = db.query(Ingredient).filter(Ingredient.name == ingredient_name).first()
    
    if not ingredient:
        raise HTTPException(
            status_code=404,
            detail=f"Ingredient '{ingredient_name}' not found"
        )
    
    return ingredient


@app.post("/ingredients", response_model=IngredientResponse, status_code=201)
def create_ingredient(
        ingredient: IngredientCreate,
        db: Session = Depends(get_db),
):
    """Create a new ingredient (public endpoint for now)"""
    # Check if ingredient already exists
    existing = db.query(Ingredient).filter(Ingredient.name == ingredient.name).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Ingredient '{ingredient.name}' already exists"
        )
    
    # Create new ingredient
    db_ingredient = Ingredient(
        name=ingredient.name,
        moisture_content=ingredient.moisture_content,
        nitrogen_content=ingredient.nitrogen_content,
        carbon_content=ingredient.carbon_content,
    )
    
    db.add(db_ingredient)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Could not create ingredient due to database constraint"
        )
    
    db.refresh(db_ingredient)
    return db_ingredient

# ============================================================================
# EXPERT SYSTEM ENDPOINTS
# ============================================================================

@app.post("/evaluate-recipe", response_model=RecipeEvaluation)
def evaluate_recipe(request: EvaluateRecipeRequest):
    expert_system = CompostExpertSystem()
    return expert_system.evaluate_recipe(
        ingredients=request.selected_ingredients,
        available_ingredients=request.available_ingredients
    )