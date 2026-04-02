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
    CompostPileUpdate,
    CompostPileResponse,
    HealthRecordCreate,
    HealthRecordIngest,
    HealthRecordResponse,
    HealthRecordSimplifiedResponse,
    IngredientCreate,
    IngredientResponse,
    Token,
    TokenData,
    EvaluateRecipeRequest,
    RecipeEvaluation,
    TaskCreate,
    TaskResponse
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
    safe_password = password.encode("utf-8")[:72]
    hashed = bcrypt.hashpw(safe_password, bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8")[:72],
        hashed_password.encode("utf-8"),
    )


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> User:
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
# HELPERS
# ============================================================================

def _resolve_pile_by_device(device_id: str, db: Session) -> CompostPile:
    """Look up a compost pile by its linked device_id, or 404."""
    pile = db.query(CompostPile).filter(CompostPile.device_id == device_id).first()
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"No compost pile linked to device '{device_id}'",
        )
    return pile


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
    """Register a new user."""
    existing_user = (
        db.query(User)
        .filter((User.username == user.username) | (User.email == user.email))
        .first()
    )
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered",
        )

    hashed_password = hash_password(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        password=hashed_password,
        country=user.country,
        location=user.location,
    )

    db.add(db_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create user due to database constraint",
        )

    db.refresh(db_user)
    return db_user


@app.post("/users/login", response_model=Token)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    """Login and receive JWT token."""
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
    """Get current authenticated user."""
    return current_user


# ============================================================================
# COMPOST PILE ENDPOINTS
# ============================================================================

@app.get("/compost-piles/me", response_model=list[CompostPileResponse])
def list_my_compost_piles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all compost piles for the current user."""
    return (
        db.query(CompostPile)
        .filter(CompostPile.username == current_user.username)
        .all()
    )


@app.post("/compost-piles/create", response_model=CompostPileResponse, status_code=201)
def create_compost_pile(
    pile: CompostPileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new compost pile for the authenticated user."""
    # If a device_id is provided, make sure it isn't already linked
    if pile.device_id:
        existing = (
            db.query(CompostPile)
            .filter(CompostPile.device_id == pile.device_id)
            .first()
        )
        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Device '{pile.device_id}' is already linked to pile '{existing.name}' (id={existing.pile_id})",
            )

    db_pile = CompostPile(
        username=current_user.username,
        name=pile.name,
        device_id=pile.device_id,
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
            detail="Could not create compost pile due to database constraint",
        )

    db.refresh(db_pile)
    return db_pile


@app.patch("/compost-piles/{pile_id}", response_model=CompostPileResponse)
def update_compost_pile(
    pile_id: int,
    updates: CompostPileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a compost pile (e.g. link or unlink a device)."""
    pile = (
        db.query(CompostPile)
        .filter(
            CompostPile.pile_id == pile_id,
            CompostPile.username == current_user.username,
        )
        .first()
    )
    if not pile:
        raise HTTPException(status_code=404, detail=f"Compost pile {pile_id} not found")

    update_data = updates.model_dump(exclude_unset=True)

    # Validate uniqueness if device_id is being changed
    if "device_id" in update_data and update_data["device_id"] is not None:
        conflict = (
            db.query(CompostPile)
            .filter(
                CompostPile.device_id == update_data["device_id"],
                CompostPile.pile_id != pile_id,
            )
            .first()
        )
        if conflict:
            raise HTTPException(
                status_code=400,
                detail=f"Device '{update_data['device_id']}' is already linked to another pile",
            )

    for field, value in update_data.items():
        setattr(pile, field, value)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Update failed due to database constraint")

    db.refresh(pile)
    return pile


@app.get("/compost-piles/{pile_id}", response_model=CompostPileResponse)
def get_compost_pile(
    pile_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a specific compost pile by ID."""
    pile = (
        db.query(CompostPile)
        .filter(
            CompostPile.pile_id == pile_id,
            CompostPile.username == current_user.username,
        )
        .first()
    )
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )
    
    return pile

@app.delete("/compost-piles/{pile_id}", status_code=204)
def delete_compost_pile(
        pile_id: int,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
):
    """Delete a specific compost pile by ID"""
    pile = db.query(CompostPile).filter(
        CompostPile.pile_id == pile_id,
        CompostPile.username == current_user.username
    ).first()

    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )

    db.delete(pile)
    db.commit()
    return None



# ============================================================================
# HEALTH RECORD ENDPOINTS (authenticated, by pile_id)
# ============================================================================

@app.post(
    "/compost-piles/{pile_id}/health-records",
    response_model=HealthRecordResponse,
    status_code=201,
)
def create_health_record(
    pile_id: int,
    record: HealthRecordIngest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new health record for a compost pile."""
    pile = (
        db.query(CompostPile)
        .filter(
            CompostPile.pile_id == pile_id,
            CompostPile.username == current_user.username,
        )
        .first()
    )
    if not pile:
        raise HTTPException(
            status_code=404,
            detail=f"Compost pile {pile_id} not found"
        )

    db_record = HealthRecord(
        pile_id=pile_id,
        temperature=record.temperature,
        moisture=record.moisture,
        nitrogen_content=record.nitrogen_content,
        carbon_content=record.carbon_content,
        timestamp=record.timestamp or datetime.now(timezone.utc),
    )

    db.add(db_record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Could not create health record due to database constraint",
        )

    db.refresh(db_record)
    return db_record


@app.get(
    "/compost-piles/{pile_id}/health-records/latest",
    response_model=HealthRecordResponse,
)
def get_latest_health_record(
    pile_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the most recent health record for a compost pile."""
    pile = (
        db.query(CompostPile)
        .filter(
            CompostPile.pile_id == pile_id,
            CompostPile.username == current_user.username,
        )
        .first()
    )
    if not pile:
        raise HTTPException(
            status_code=404, detail=f"Compost pile {pile_id} not found"
        )

    latest_record = (
        db.query(HealthRecord)
        .filter(HealthRecord.pile_id == pile_id)
        .order_by(desc(HealthRecord.timestamp))
        .first()
    )
    if not latest_record:
        raise HTTPException(
            status_code=404,
            detail=f"No health records found for compost pile {pile_id}",
        )

    return latest_record


@app.get(
    "/compost-piles/{pile_id}/health-records",
    response_model=list[HealthRecordResponse],
)
def get_all_health_records(
    pile_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 100,
):
    """Get all health records for a compost pile (most recent first)."""
    pile = (
        db.query(CompostPile)
        .filter(
            CompostPile.pile_id == pile_id,
            CompostPile.username == current_user.username,
        )
        .first()
    )
    if not pile:
        raise HTTPException(
            status_code=404, detail=f"Compost pile {pile_id} not found"
        )

    records = (
        db.query(HealthRecord)
        .filter(HealthRecord.pile_id == pile_id)
        .order_by(desc(HealthRecord.timestamp))
        .limit(limit)
        .all()
    )

    return records


# ============================================================================
# DEVICE INGESTION ENDPOINT (no auth — used by ESP32 hardware)
# ============================================================================

@app.post(
    "/devices/{device_id}/health-records",
    response_model=HealthRecordResponse,
    status_code=201,
    tags=["devices"],
)
def ingest_health_record_by_device(
    device_id: str,
    record: HealthRecordIngest,
    db: Session = Depends(get_db),
):
    """
    Hardware ingestion endpoint.

    The ESP32 identifies itself by device_id (its MAC address or a
    user-assigned label). The server resolves which pile that device
    is linked to and stores the health record against it.

    No JWT required — the device authenticates via its unique device_id.
    """
    pile = _resolve_pile_by_device(device_id, db)

    db_record = HealthRecord(
        pile_id=pile.pile_id,
        temperature=record.temperature,
        moisture=record.moisture,
        nitrogen_content=record.nitrogen_content,
        carbon_content=record.carbon_content,
        timestamp=record.timestamp or datetime.now(timezone.utc),
    )

    db.add(db_record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Could not create health record due to database constraint",
        )

    db.refresh(db_record)
    return db_record


# ============================================================================
# INGREDIENT ENDPOINTS
# ============================================================================

@app.get("/ingredients", response_model=list[IngredientResponse])
def get_all_ingredients(db: Session = Depends(get_db)):
    """Get all ingredients (public endpoint, no auth required)."""
    return db.query(Ingredient).all()


@app.get("/ingredients/{ingredient_name}", response_model=IngredientResponse)
def get_ingredient(ingredient_name: str, db: Session = Depends(get_db)):
    """Get a specific ingredient by name."""
    ingredient = (
        db.query(Ingredient).filter(Ingredient.name == ingredient_name).first()
    )
    if not ingredient:
        raise HTTPException(
            status_code=404, detail=f"Ingredient '{ingredient_name}' not found"
        )
    return ingredient


@app.post("/ingredients", response_model=IngredientResponse, status_code=201)
def create_ingredient(
    ingredient: IngredientCreate,
    db: Session = Depends(get_db),
):
    """Create a new ingredient (public endpoint for now)."""
    existing = (
        db.query(Ingredient).filter(Ingredient.name == ingredient.name).first()
    )
    if existing:
        raise HTTPException(
            status_code=400, detail=f"Ingredient '{ingredient.name}' already exists"
        )

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
            detail="Could not create ingredient due to database constraint",
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
# ============================================================================
# LEGACY ESP32 TEST ENDPOINT
# ============================================================================
@app.post(
    "/test/compost-piles/{pile_id}/health-records",
    response_model=HealthRecordResponse,
    status_code=201,
    tags=["legacy-test"],
    deprecated=True,
)
def create_health_record_test(
    pile_id: int,
    record: HealthRecordIngest,
    db: Session = Depends(get_db),
):
    """Legacy test endpoint. Prefer /devices/{device_id}/health-records."""
    pile = db.query(CompostPile).filter(CompostPile.pile_id == pile_id).first()
    if not pile:
        raise HTTPException(
            status_code=404, detail=f"Compost pile {pile_id} not found"
        )
        
    # Calculate health_score and status
    t = float(record.temperature) if record.temperature is not None else 0.0
    mc = float(record.moisture) if record.moisture is not None else 0.0
    
    s_mc = max(0.0, 1.0 - abs(mc - 47.5) / 5.0)
    s_t = max(0.0, 1.0 - abs(t - 50.0) / 10.0)
    
    health_score = int(round(100.0 * (0.5 * s_mc + 0.5 * s_t)))
    
    if health_score > 70:
        status = 'good'
    elif 50 <= health_score <= 70:
        status = 'acceptable'
    else:
        status = 'bad'

    db_record = HealthRecord(
        pile_id=pile_id,
        temperature=record.temperature,
        moisture=record.moisture,
        nitrogen_content=record.nitrogen_content,
        carbon_content=record.carbon_content,
        timestamp=record.timestamp or datetime.now(timezone.utc),
        health_score=health_score,
        status=status
    )

    db.add(db_record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400, detail="Could not create test health record"
        )

    db.refresh(db_record)
    return db_record
    
# ============================================================================
# TASKS ENDPOINTS
# ============================================================================

@app.get("/compost-piles/{pile_id}/health-records/yesterday", response_model=list[HealthRecordSimplifiedResponse])
def get_yesterday_health_records(
    pile_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pile = db.query(CompostPile).filter(CompostPile.pile_id == pile_id, CompostPile.username == current_user.username).first()
    if not pile:
        raise HTTPException(status_code=404, detail="Pile not found")

    yesterday = datetime.now(timezone.utc) - timedelta(days=1)
    start_of_yesterday = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_yesterday = start_of_yesterday + timedelta(days=1)

    records = db.query(HealthRecord).filter(
        HealthRecord.pile_id == pile_id,
        HealthRecord.timestamp >= start_of_yesterday,
        HealthRecord.timestamp < end_of_yesterday
    ).all()
    return records

@app.post("/tasks", response_model=TaskResponse, status_code=201)
def create_task(
    task: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pile = db.query(CompostPile).filter(CompostPile.pile_id == task.pile_id, CompostPile.username == current_user.username).first()
    if not pile:
        raise HTTPException(status_code=404, detail="Pile not found")

    new_task = models.Task(**task.model_dump()) 
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@app.get("/tasks/date/{target_date}", response_model=list[TaskResponse])
def get_tasks_by_date(
    target_date: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        query_date = datetime.strptime(target_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

    user_piles = db.query(CompostPile.pile_id).filter(CompostPile.username == current_user.username)
    tasks = db.query(models.Task).filter(
        models.Task.pile_id.in_(user_piles),
        models.Task.date_scheduled == query_date
    ).all()
    return tasks

@app.patch("/tasks/{task_id}/complete", response_model=TaskResponse)
def complete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(models.Task).join(CompostPile).filter(
        models.Task.task_id == task_id,
        CompostPile.username == current_user.username
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.status = "Done"
    db.commit()
    db.refresh(task)
    return task
@app.get("/compost-piles/{pile_id}/tasks/active", response_model=list[TaskResponse])
def get_active_tasks_for_pile(
    pile_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pile = db.query(CompostPile).filter(CompostPile.pile_id == pile_id, CompostPile.username == current_user.username).first()
    if not pile:
        raise HTTPException(status_code=404, detail="Pile not found or not owned by user.")
    tasks = db.query(models.Task).filter(
        models.Task.pile_id == pile_id,
        models.Task.status == "Active"
    ).order_by(models.Task.date_scheduled.asc(), models.Task.time_scheduled.asc()).all()
    return tasks
