# config/settings.py
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    supabase_url: str
    supabase_key: str
    airtable_pat: str
    airtable_base_id: str

    class Config:
        env_file = ".env"  # load values from .env by default


settings = Settings()
