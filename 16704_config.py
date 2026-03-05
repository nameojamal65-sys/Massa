from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Sovereign Core"
    SECRET_KEY: str = "CHANGE_ME_SECRET"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    OPENAI_API_KEY: str | None = None

settings = Settings()
