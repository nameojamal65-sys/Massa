from dataclasses import dataclass, asdict, field
from typing import Any, Dict, List, Optional
import time, uuid

def now_ms() -> int:
    return int(time.time() * 1000)

@dataclass
class Job:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: int = field(default_factory=now_ms)
    updated_at: int = field(default_factory=now_ms)
    status: str = "queued"        # queued|running|done|failed
    title: str = ""
    request: Dict[str, Any] = field(default_factory=dict)
    result: Dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None
    correlation_id: Optional[str] = None

    def to_dict(self):
        return asdict(self)

@dataclass
class Approval:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: int = field(default_factory=now_ms)
    status: str = "pending"       # pending|approved|rejected
    job_id: Optional[str] = None
    reason: str = ""
    payload: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return asdict(self)

@dataclass
class AuditEvent:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    ts: int = field(default_factory=now_ms)
    kind: str = "event"
    actor: str = "system"
    job_id: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return asdict(self)
