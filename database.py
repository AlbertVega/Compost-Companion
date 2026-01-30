import os
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

url_object = URL.create(
    "postgresql",
    username="compostproject",
    password="AlbertAndMichael",  # Consider moving this to .env later
    host="database-compost.c0g1hasawu7w.ca-west-1.rds.amazonaws.com",
    port=5432,
    database="compost_db",
)

connect_args = {
    "sslmode": "verify-full",
    "sslrootcert": "global-bundle.pem"
}


engine = create_engine(url_object, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
