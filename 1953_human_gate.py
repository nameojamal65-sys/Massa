from core.config import Settings
from security.rbac import authorize

def require_human_approval(task: dict, role: str="operator") -> bool:
    if not Settings.REQUIRE_HITL:
        return True

    if not authorize(role, "approve"):
        print("❌ RBAC: cannot approve")
        return False

    # In platform mode require dual approval for production tasks (simple: operator then auditor)
    approvals_needed = 2 if Settings.PLATFORM_MODE else 1
    approvals = 0

    roles = [role] + (["auditor"] if approvals_needed == 2 else [])
    for i in range(approvals_needed):
        r = roles[i] if i < len(roles) else role
        print("\n⚠️ HUMAN APPROVAL REQUIRED")
        print("Role:", r)
        print("Task:", task)
        ans = input(f"Approval {i+1}/{approvals_needed} (yes/no): ").strip().lower()
        if ans == "yes":
            approvals += 1
        else:
            break

    return approvals >= approvals_needed
