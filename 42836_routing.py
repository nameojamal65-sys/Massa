import re
DIFFUSION_HINTS = [
  r"\bdiffusion\b", r"\bcinematic\b", r"\bsvd\b", r"\banimatediff\b",
  r"سينمائي", r"ديفيوجن", r"واقعي", r"مشهد", r"فيلم"
]
def wants_diffusion(prompt: str) -> bool:
    p = (prompt or "").lower()
    for pat in DIFFUSION_HINTS:
        if re.search(pat, p, flags=re.IGNORECASE):
            return True
    return False
