import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(dotenv_path=BASE_DIR / ".env")


def _required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(
            f"Missing required database setting: {name}. "
            "Make sure your .env file is present and loaded."
        )
    return value


def _build_database_url() -> str | URL:
    # Support DB_URL for convenience in some deployment setups.
    explicit_url = os.getenv("DB_URL")
    if explicit_url:
        return explicit_url

    return URL.create(
        "postgresql",
        username=_required_env("DB_USERNAME"),
        password=_required_env("DB_PASSWORD"),
        host=_required_env("DB_HOST"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=_required_env("DB_NAME"),
    )


_db_url = _build_database_url()

# Only pass SSL/connect args for non-sqlite databases (e.g. Postgres). SQLite
# doesn't accept ssl/connect args in its DBAPI, so skip them for local testing.
if isinstance(_db_url, str) and _db_url.startswith("sqlite"):
    connect_args = {}
else:
    connect_args = {
        "sslmode": os.getenv("DB_SSLMODE", "verify-full"),
        "sslrootcert": os.getenv("DB_SSLROOTCERT", str(BASE_DIR / "global-bundle.pem")),
    }

engine = create_engine(_db_url, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
