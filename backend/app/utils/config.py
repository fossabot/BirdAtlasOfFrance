import logging
from typing import Any, Dict, Optional

from pydantic import BaseSettings, PostgresDsn, validator

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """App settings from env.

    Args:
        POSTGRES_HOST (Optional, str): DB Host. Default to "localhost".
        POSTGRES_PORT (Optional, int): DB Port. Default to 5432.
        POSTGRES_USER (str): DB username.
        POSTGRES_PASSWORD (str): DB password.
        POSTGRES_DB (str): DB name.
        LOG_LEVEL (Optional, str) : Log level. Default to "INFO"

    Returns:
        [type]: [description]
    """

    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    POSTGRES_HOST: Optional[str] = "localhost"
    POSTGRES_PORT: Optional[str] = 5432
    LOG_LEVEL: Optional[str] = "INFO"
    APP_NAME: Optional[str] = "Bird atlas of France"
    APP_SYSNAME: Optional[str] = "odf_api"
    API_PREFIX: Optional[str] = "/api/v1"
    APP_URL: str

    SQLALCHEMY_DATABASE_URI: Optional[PostgresDsn] = None

    @validator("SQLALCHEMY_DATABASE_URI", pre=True)
    def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
        if isinstance(v, str):
            return v
        pg_uri = PostgresDsn.build(
            scheme="postgresql",
            user=values.get("POSTGRES_USER"),
            password=values.get("POSTGRES_PASSWORD"),
            host=values.get("POSTGRES_HOST"),
            port=values.get("POSTGRES_PORT"),
            # path=f"/{values.get('POSTGRES_DB') or  ''}?application_name=odf_api",
            path=f"/{values.get('POSTGRES_DB') or  ''}",
        )
        return pg_uri

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()

logger.debug
