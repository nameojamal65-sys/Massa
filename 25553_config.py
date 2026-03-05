import os


class Settings:
    APP_HOST = os.getenv("SC_HOST", "0.0.0.0")
    APP_PORT = int(os.getenv("SC_PORT", "8080"))

    PLATFORM_MODE = os.getenv("SC_PLATFORM_MODE", "1") == "1"

    REQUIRE_HITL = os.getenv("SC_REQUIRE_HITL", "1") != "0"
    ALLOW_EXTERNAL = os.getenv("SC_ALLOW_EXTERNAL", "0") == "1"

    ROLE = os.getenv("SC_ROLE", "control")  # control|worker
    WORKER_DEFAULT = os.getenv("SC_WORKER_URL", "http://127.0.0.1:9000")

    MTLS = os.getenv("SC_MTLS", "0") == "1"
    CA_CERT = os.getenv("SC_CA_CERT", "security/mtls/ca.crt")
    CLIENT_CERT = os.getenv("SC_CLIENT_CERT", "security/mtls/node.crt")
    CLIENT_KEY = os.getenv("SC_CLIENT_KEY", "security/mtls/node.key")

    LOG_DIR = os.getenv("SC_LOG_DIR", "logs")
    DATA_DIR = os.getenv("SC_DATA_DIR", "data")
    ARTIFACT_DIR = os.getenv("SC_ARTIFACT_DIR", "logs/artifacts")
    TENANT_DIR = os.getenv("SC_TENANT_DIR", "data/tenants")
    IDENTITY_DB = os.getenv("SC_ID_DB", "data/identity.json")
    AUDIT_LOG = os.getenv("SC_AUDIT_LOG", "data/audit_chain.log")
    POLICY_FILE = os.getenv("SC_POLICY", "policy/policy.yaml")
    PLANS_FILE = os.getenv("SC_PLANS", "commercial/plans.yaml")
