# config/settings.py
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Make credentials optional so importing the module doesn't fail during test
    # collection or in environments where Airtable isn't configured.
    airtable_pat: str | None = None
    airtable_base_id: str | None = None

    # Use pydantic v2 style model_config with SettingsConfigDict
    model_config: SettingsConfigDict = SettingsConfigDict(env_file=".env")


# Module-level settings kept for backward compatibility. Callers should be able
# to access `settings.airtable_pat` and get None if not configured.
settings = Settings()
