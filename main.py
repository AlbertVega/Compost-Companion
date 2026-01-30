from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import engine, get_db
import models

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Compost Optimization API")

@app.get("/")
def read_root():
    return {"status": "Compost API is online"}

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    # Simple query to prove the connection works
    return {"message": "Successfully connected to AWS RDS!"}
