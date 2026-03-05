ROLES = {
    "operator": {"start", "stop", "restart", "submit", "approve", "view"},
    "admin": {"*"},
    "auditor": {"view", "logs", "verify_audit"},
}


def authorize(role: str, action: str) -> bool:
    perms = ROLES.get(role, set())
    return "*" in perms or action in perms
