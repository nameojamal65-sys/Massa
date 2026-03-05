from pydantic import BaseSettings

class Settings(BaseSettings):
    SECRET_KEY: str = "legendary_super_secret_key_v11_termux"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    MULTI_TENANT_DB_URL: str = "sqlite:///legendary_v11_termux.db"

settings = Settings()
