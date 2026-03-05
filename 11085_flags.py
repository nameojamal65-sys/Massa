import os


def flag(name: str, default: str = "0") -> bool:
    return os.getenv(
        name,
        default).strip() in (
        "1",
        "true",
        "True",
        "yes",
        "YES")


SC_VERSION = os.getenv("SC_VERSION", "1").strip()
SC_FREEZE = flag("SC_FREEZE", "0")
SC_RATE_LIMIT = flag("SC_RATE_LIMIT", "0")
SC_NEW_UI = flag("SC_NEW_UI", "0")   # serve /dash when enabled
