#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sentinel_super"
APPDIR="$ROOT/app"

echo "🚀 Project Sentinel — SUPER MASTER Installer"
echo "📁 Target: $ROOT"

mkdir -p "$APPDIR"
cd "$ROOT"

echo "📦 Installing dependencies..."
pip install --upgrade pip >/dev/null
pip install fastapi uvicorn sqlmodel python-multipart pydantic >/dev/null

touch "$APPDIR/__init__.py"

# Backup old main.py if exists
if [ -f "$APPDIR/main.py" ]; then
  TS=$(date +%Y%m%d_%H%M%S)
  cp "$APPDIR/main.py" "$APPDIR/main.py.bak_$TS"
  echo "🧾 Backup created: app/main.py.bak_$TS"
fi

echo "🧠 Writing app/main.py (full logic)..."
cat > "$APPDIR/main.py" <<'PY'
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Literal, Optional, Tuple

from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from pydantic import BaseModel, Field
from sqlmodel import SQLModel, Field as SQLField, Session, create_engine, select


# =============================================================================
# Project Sentinel — Termux SUPER (One-file)
# =============================================================================

# -----------------------------
# CONFIG (agreed baseline)
# -----------------------------
SLA_WORKING_DAYS = 15
EARLY_WARNING_DAYS = 3

PROJECT_VALUE = 600_000_000
MARGIN = 0.02
PROFIT_TOTAL = PROJECT_VALUE * MARGIN          # 12,000,000
PROJECT_DAYS_APPROX = 900                      # ~30 months
PROFIT_PER_DAY = int(PROFIT_TOTAL / PROJECT_DAYS_APPROX)  # ~13,333 SAR/day

RISK_CAP_PROJECT = 300.0
RISK_CAP_DEPT = 150.0

# Simulated today (optional): uncomment for testing 2026 regardless of phone date
# SIM_TODAY = date(2026, 3, 25)
# def today() -> date: return SIM_TODAY
def today() -> date:
    return date.today()

# Holidays (assumptions for 2026)
HOLIDAYS: Dict[date, str] = {date(2026, 9, 23): "National Day"}
eid_start = date(2026, 4, 10)
for i in range(5):
    HOLIDAYS[eid_start + timedelta(days=i)] = "Eid"

EventType = Literal["SHOP_DRAWING", "MATERIAL_SUBMITTAL", "RFI", "LONG_LEAD", "NCR"]
Dept = Literal["TECHNICAL", "PROCUREMENT", "QAQC"]

EVENT_WEIGHTS: Dict[str, float] = {
    "SHOP_DRAWING": 1.4,
    "MATERIAL_SUBMITTAL": 1.3,
    "RFI": 1.0,
    "LONG_LEAD": 2.0,
    "NCR": 1.5,
}

DEPT_MAP: Dict[str, str] = {
    "SHOP_DRAWING": "TECHNICAL",
    "MATERIAL_SUBMITTAL": "TECHNICAL",
    "RFI": "TECHNICAL",
    "LONG_LEAD": "PROCUREMENT",
    "NCR": "QAQC",
}

# -----------------------------
# DB (SQLite)
# -----------------------------
engine = create_engine("sqlite:///sentinel.db", echo=False)


class Event(SQLModel, table=True):
    id: Optional[int] = SQLField(default=None, primary_key=True)

    external_ref: str = SQLField(index=True)
    event_type: str = SQLField(index=True)
    department: str = SQLField(index=True)

    title: str = ""
    submission_date: date
    due_date: date

    weight: float = 1.0
    impact_factor: float = 1.0
    is_critical: bool = False
    notice_required: bool = False

    status: str = "OPEN"  # OPEN / CLOSED
    closed_at: Optional[datetime] = None

    override_due_date: Optional[date] = None
    override_reason: Optional[str] = None
    overridden_at: Optional[datetime] = None

    created_at: datetime = SQLField(default_factory=datetime.utcnow)
    updated_at: datetime = SQLField(default_factory=datetime.utcnow)


class Escalation(SQLModel, table=True):
    id: Optional[int] = SQLField(default=None, primary_key=True)

    event_id: int = SQLField(index=True)
    level: int  # 1 breach, 2 critical

    triggered_at: datetime = SQLField(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    status: str = "OPEN"  # OPEN / CLOSED

    duration_working_days: int = 0


class AuditLog(SQLModel, table=True):
    id: Optional[int] = SQLField(default=None, primary_key=True)
    timestamp: datetime = SQLField(default_factory=datetime.utcnow)

    action: str
    entity: str
    ref: str
    details: str = ""


def init_db():
    SQLModel.metadata.create_all(engine)


def audit(session: Session, action: str, entity: str, ref: str, details: str = ""):
    session.add(AuditLog(action=action, entity=entity, ref=ref, details=details))
    session.commit()


# -----------------------------
# Working Day Engine (6D; Friday off)
# -----------------------------
def is_friday(d: date) -> bool:
    return d.weekday() == 4

def is_working_day(d: date) -> bool:
    if is_friday(d):
        return False
    if d in HOLIDAYS:
        return False
    return True

def add_working_days_from_next_day(submit_date: date, n: int) -> date:
    current = submit_date
    added = 0
    while added < n:
        current = current + timedelta(days=1)
        if is_working_day(current):
            added += 1
    return current

def working_days_between(a: date, b: date) -> int:
    if a == b:
        return 0
    step = 1 if b > a else -1
    d = a
    count = 0
    while d != b:
        d = d + timedelta(days=step)
        if is_working_day(d):
            count += step
    return count


# -----------------------------
# SLA / Risk / Exposure
# -----------------------------
Stage = Literal["ON_TRACK", "PRE_WARNING", "WARNING", "BREACH", "CRITICAL_BREACH"]

def effective_due_date(ev: Event) -> date:
    return ev.override_due_date or ev.due_date

def compute_stage(now: date, due: date) -> Tuple[Stage, int, int]:
    remaining = working_days_between(now, due)
    delay = 0
    if remaining < 0:
        delay = working_days_between(due, now)
    if remaining > EARLY_WARNING_DAYS:
        stage: Stage = "ON_TRACK"
    elif remaining == EARLY_WARNING_DAYS:
        stage = "PRE_WARNING"
    elif 0 <= remaining <= 1:
        stage = "WARNING"
    else:
        stage = "BREACH"
        if delay > 5:
            stage = "CRITICAL_BREACH"
    return stage, remaining, delay

def risk_multiplier(delay_days: int) -> float:
    if delay_days <= 3:
        return 1.0
    if delay_days <= 7:
        return 1.3
    return 1.7

def cumulative_risk(delay_days: int, weight: float, impact: float) -> float:
    if delay_days <= 0:
        return 0.0
    total = 0.0
    for day_i in range(1, delay_days + 1):
        total += (weight * impact * risk_multiplier(day_i))
    return total

def contract_risk_factor(notice_required: bool) -> float:
    return 1.5 if notice_required else 1.0

def criticality_factor(is_critical: bool) -> float:
    return 1.0 if is_critical else 0.3

def exposure_sar(delay_days: int, is_critical: bool, notice_required: bool) -> float:
    if delay_days <= 0:
        return 0.0
    return delay_days * PROFIT_PER_DAY * criticality_factor(is_critical) * contract_risk_factor(notice_required)


# -----------------------------
# Escalations
# -----------------------------
def close_all_escalations_for_event(session: Session, ev: Event):
    escs = session.exec(
        select(Escalation).where(Escalation.event_id == ev.id, Escalation.status == "OPEN")
    ).all()
    for e in escs:
        e.status = "CLOSED"
        e.resolved_at = datetime.utcnow()
        session.add(e)
    session.commit()

def update_escalation_durations(session: Session, ev: Event):
    now = today()
    escs = session.exec(
        select(Escalation).where(Escalation.event_id == ev.id, Escalation.status == "OPEN")
    ).all()
    for e in escs:
        e.duration_working_days = abs(working_days_between(e.triggered_at.date(), now))
        session.add(e)
    session.commit()

def ensure_escalations(session: Session, ev: Event):
    if ev.status == "CLOSED":
        close_all_escalations_for_event(session, ev)
        return

    due = effective_due_date(ev)
    stage, _, delay = compute_stage(today(), due)

    open_escs = session.exec(
        select(Escalation).where(Escalation.event_id == ev.id, Escalation.status == "OPEN")
    ).all()
    open_levels = {e.level for e in open_escs}

    created_any = False
    if stage == "BREACH" and 1 not in open_levels:
        session.add(Escalation(event_id=ev.id, level=1))
        created_any = True
        audit(session, "ESCALATION_L1", "Event", f"{ev.event_type}:{ev.external_ref}", f"delay={delay}")

    if stage == "CRITICAL_BREACH" and 2 not in open_levels:
        session.add(Escalation(event_id=ev.id, level=2))
        created_any = True
        audit(session, "ESCALATION_L2", "Event", f"{ev.event_type}:{ev.external_ref}", f"delay={delay}")

    if created_any:
        session.commit()

    update_escalation_durations(session, ev)


# -----------------------------
# Health Engine
# -----------------------------
def normalize_score(value: float, cap: float) -> int:
    if cap <= 0:
        return 100
    pct = min(100.0, (value / cap) * 100.0)
    return max(0, 100 - int(pct))

def band(score: int) -> str:
    if score >= 80:
        return "GREEN"
    if score >= 60:
        return "YELLOW"
    if score >= 40:
        return "ORANGE"
    return "RED"

def compute_health_snapshot(events_out: List[Dict[str, Any]]) -> Dict[str, Any]:
    def penalty(stage: str) -> int:
        if stage == "PRE_WARNING": return 1
        if stage == "WARNING": return 3
        if stage == "BREACH": return 7
        if stage == "CRITICAL_BREACH": return 12
        return 0

    sla_penalty_project = 0
    critical_breach_count = 0
    total_risk = 0.0
    total_exposure = 0.0

    dept_penalty: Dict[str, int] = {"TECHNICAL": 0, "PROCUREMENT": 0, "QAQC": 0}
    dept_risk: Dict[str, float] = {"TECHNICAL": 0.0, "PROCUREMENT": 0.0, "QAQC": 0.0}
    dept_expo: Dict[str, float] = {"TECHNICAL": 0.0, "PROCUREMENT": 0.0, "QAQC": 0.0}

    sorted_by_risk = sorted(
        [e for e in events_out if e["status"] == "OPEN"],
        key=lambda x: (-x["cumulative_risk"], -x["exposure_sar"])
    )
    top3 = [f'{e["event_type"]} {e["external_ref"]} ({e["stage"]})' for e in sorted_by_risk[:3]]

    for e in events_out:
        if e["status"] != "OPEN":
            continue

        p = penalty(e["stage"])
        sla_penalty_project += p
        dept_penalty[e["department"]] = dept_penalty.get(e["department"], 0) + p

        total_risk += e["cumulative_risk"]
        total_exposure += e["exposure_sar"]

        dept_risk[e["department"]] = dept_risk.get(e["department"], 0.0) + e["cumulative_risk"]
        dept_expo[e["department"]] = dept_expo.get(e["department"], 0.0) + e["exposure_sar"]

        if e["stage"] == "CRITICAL_BREACH":
            critical_breach_count += 1

    sla_score = max(0, 100 - sla_penalty_project)
    risk_score = normalize_score(total_risk, RISK_CAP_PROJECT)

    expo_ratio = (total_exposure / PROFIT_TOTAL) if PROFIT_TOTAL > 0 else 0.0
    expo_pressure = min(1.0, expo_ratio) * 100.0 * 2.0  # K=2
    exposure_score = max(0, 100 - int(min(100.0, expo_pressure)))

    critical_score = max(0, 100 - min(100, critical_breach_count * 15))

    health = int(round(0.30 * sla_score + 0.25 * risk_score + 0.25 * exposure_score + 0.20 * critical_score))

    if critical_breach_count > 0:
        health = max(0, health - min(12, 4 * critical_breach_count))

    dept_scores: Dict[str, int] = {}
    for d in ["TECHNICAL", "PROCUREMENT", "QAQC"]:
        d_sla = max(0, 100 - dept_penalty.get(d, 0))
        d_risk_score = normalize_score(dept_risk.get(d, 0.0), RISK_CAP_DEPT)
        d_expo_ratio = (dept_expo.get(d, 0.0) / PROFIT_TOTAL) if PROFIT_TOTAL > 0 else 0.0
        d_expo_pressure = min(1.0, d_expo_ratio) * 100.0 * 2.0
        d_expo_score = max(0, 100 - int(min(100.0, d_expo_pressure)))
        dept_scores[d] = int(round(0.40 * d_sla + 0.30 * d_risk_score + 0.20 * d_expo_score + 0.10 * 100))

    return {
        "project_health_score": health,
        "band": band(health),
        "total_open_risk": round(total_risk, 2),
        "total_exposure_sar": round(total_exposure, 2),
        "top_issues": top3,
        "departments": dept_scores,
    }


# -----------------------------
# API Schemas
# -----------------------------
class EventCreate(BaseModel):
    external_ref: str
    event_type: EventType
    title: str = ""
    submission_date: date
    impact_factor: float = 1.0
    is_critical: bool = False
    notice_required: bool = False

class EventOut(BaseModel):
    external_ref: str
    event_type: str
    department: str
    title: str
    submission_date: date
    due_date: date
    stage: str
    remaining_days: int
    delay_days: int
    cumulative_risk: float
    exposure_sar: float
    status: str

class OverrideReq(BaseModel):
    new_due_date: date
    reason: str = Field(min_length=3)

class HealthOut(BaseModel):
    project_health_score: int
    band: str
    total_open_risk: float
    total_exposure_sar: float
    top_issues: List[str]
    departments: Dict[str, int]
    as_of: str

class ImportReport(BaseModel):
    event_type: str
    rows: int
    created: int
    updated: int
    closed: int
    skipped_no_change: int
    errors: List[Dict[str, Any]]


# -----------------------------
# SUPER CSV Validator + Import
# -----------------------------
CSV_HEADER = ["external_ref", "title", "submission_date", "impact_factor", "is_critical", "notice_required", "status"]

STATUS_MAP = {
    # Open-ish
    "OPEN": "OPEN",
    "RAISED": "OPEN",
    "SUBMITTED": "OPEN",
    "UNDER REVIEW": "OPEN",
    "IN REVIEW": "OPEN",
    "RFQ": "OPEN",
    "AWARDED": "OPEN",
    "IN PRODUCTION": "OPEN",
    "SHIPPED": "OPEN",
    "DELIVERED": "OPEN",
    "INSTALLED": "OPEN",
    "REJECTED": "OPEN",
    "ANSWERED": "OPEN",
    "APPROVED": "OPEN",
    "CORRECTIVE ACTION": "OPEN",

    # Closed-ish
    "CLOSED": "CLOSED",
    "APPROVED & CLOSED": "CLOSED",
}

def parse_bool(s: str) -> bool:
    s = (s or "").strip().lower()
    return s in ("1", "true", "yes", "y")

def normalize_status(raw: str) -> str:
    x = (raw or "").strip().upper()
    x = " ".join(x.split())
    if x in STATUS_MAP:
        return STATUS_MAP[x]
    raise ValueError(f"Unknown status '{raw}'")

def parse_csv(content: str) -> List[Dict[str, str]]:
    lines = [ln.strip() for ln in content.splitlines() if ln.strip()]
    if not lines:
        return []
    header = [h.strip() for h in lines[0].split(",")]
    if header[:len(CSV_HEADER)] != CSV_HEADER:
        raise ValueError(f"CSV header must start with: {CSV_HEADER}")
    out: List[Dict[str, str]] = []
    for ln in lines[1:]:
        parts = [p.strip() for p in ln.split(",")]
        if len(parts) < len(CSV_HEADER):
            raise ValueError(f"Bad row (missing columns): {ln}")
        out.append(dict(zip(CSV_HEADER, parts[:len(CSV_HEADER)])))
    return out

def validate_rows_strict(rows: List[Dict[str, str]]) -> List[Dict[str, Any]]:
    """
    Row-level validation report. Returns list of errors with {row,line,field,msg}.
    Does NOT raise. Caller decides whether to proceed.
    """
    errors: List[Dict[str, Any]] = []
    seen = set()
    for idx, r in enumerate(rows, start=2):  # header line = 1
        ext = (r.get("external_ref") or "").strip()
        if not ext:
            errors.append({"line": idx, "field": "external_ref", "msg": "required"})
        else:
            if ext in seen:
                errors.append({"line": idx, "field": "external_ref", "msg": f"duplicate in file: {ext}"})
            seen.add(ext)

        sd = (r.get("submission_date") or "").strip()
        try:
            date.fromisoformat(sd)
        except Exception:
            errors.append({"line": idx, "field": "submission_date", "msg": f"must be YYYY-MM-DD, got '{sd}'"})

        imp = (r.get("impact_factor") or "1.0").strip()
        try:
            imp_f = float(imp)
            if not (0.1 <= imp_f <= 5.0):
                errors.append({"line": idx, "field": "impact_factor", "msg": f"out of range 0.1..5.0: {imp_f}"})
        except Exception:
            errors.append({"line": idx, "field": "impact_factor", "msg": f"must be number, got '{imp}'"})

        try:
            parse_bool(r.get("is_critical", "false"))
            parse_bool(r.get("notice_required", "false"))
        except Exception:
            errors.append({"line": idx, "field": "bool", "msg": "invalid boolean"})

        st = r.get("status", "Open")
        try:
            normalize_status(st)
        except Exception as e:
            errors.append({"line": idx, "field": "status", "msg": str(e)})

    return errors

def status_transition_allowed(existing_status: str, incoming_status: str, allow_reopen: bool) -> bool:
    """
    Rules:
      - OPEN -> CLOSED allowed
      - CLOSED -> CLOSED allowed
      - OPEN -> OPEN allowed
      - CLOSED -> OPEN blocked unless allow_reopen=True
    """
    if existing_status == "CLOSED" and incoming_status == "OPEN":
        return allow_reopen
    return True

def upsert_event_from_row(
    session: Session,
    event_type: str,
    row: Dict[str, str],
    allow_reopen: bool
) -> Tuple[str, Optional[str]]:
    """
    Returns (result, note):
      result in {"created","updated","closed","skipped"}
      note optional extra info
    """
    ext = row["external_ref"].strip()
    title = row.get("title", "")
    sub_date = date.fromisoformat(row["submission_date"])
    impact = float((row.get("impact_factor") or "1.0").strip())
    is_crit = parse_bool(row.get("is_critical", "false"))
    notice = parse_bool(row.get("notice_required", "false"))
    incoming_status = normalize_status(row.get("status", "Open"))

    dept = DEPT_MAP[event_type]
    weight = EVENT_WEIGHTS[event_type]
    due = add_working_days_from_next_day(sub_date, SLA_WORKING_DAYS)

    existing = session.exec(
        select(Event).where(Event.event_type == event_type, Event.external_ref == ext)
    ).first()

    if existing is None:
        ev = Event(
            external_ref=ext,
            event_type=event_type,
            department=dept,
            title=title,
            submission_date=sub_date,
            due_date=due,
            weight=weight,
            impact_factor=impact,
            is_critical=is_crit,
            notice_required=notice,
            status="OPEN",
            updated_at=datetime.utcnow(),
        )
        session.add(ev)
        session.commit()
        audit(session, "CREATE", "Event", f"{event_type}:{ext}", "Imported from CSV")
        existing = ev
        # handle close if incoming is CLOSED
        if incoming_status == "CLOSED":
            existing.status = "CLOSED"
            existing.closed_at = datetime.utcnow()
            # Freeze (B)
            existing.override_due_date = existing.closed_at.date()
            existing.override_reason = "AUTO_CLOSE_FROM_CSV"
            existing.overridden_at = existing.closed_at
            existing.updated_at = datetime.utcnow()
            session.add(existing)
            session.commit()
            audit(session, "AUTO_CLOSE", "Event", f"{event_type}:{ext}", "Closed on create via CSV")
            close_all_escalations_for_event(session, existing)
            return "closed", "created_then_closed"
        return "created", None

    # existing: transition rules
    if not status_transition_allowed(existing.status, incoming_status, allow_reopen):
        return "skipped", "blocked_transition_CLOSED_to_OPEN"

    # detect no-change to avoid noisy audit
    no_change = (
        existing.title == title and
        existing.submission_date == sub_date and
        existing.due_date == due and
        abs(existing.impact_factor - impact) < 1e-9 and
        existing.is_critical == is_crit and
        existing.notice_required == notice and
        existing.status == ("CLOSED" if incoming_status == "CLOSED" else existing.status)  # handled later
    )

    # update allowed fields
    existing.title = title
    existing.submission_date = sub_date
    existing.due_date = due
    existing.impact_factor = impact
    existing.is_critical = is_crit
    existing.notice_required = notice
    existing.updated_at = datetime.utcnow()

    # apply incoming status
    if incoming_status == "CLOSED":
        if existing.status != "CLOSED":
            existing.status = "CLOSED"
            existing.closed_at = datetime.utcnow()
            # Freeze (B)
            existing.override_due_date = existing.closed_at.date()
            existing.override_reason = "AUTO_CLOSE_FROM_CSV"
            existing.overridden_at = existing.closed_at
            audit(session, "AUTO_CLOSE", "Event", f"{event_type}:{ext}", "Closed via CSV import and frozen")
            close_all_escalations_for_event(session, existing)

    if no_change and incoming_status != "CLOSED":
        # keep open; just avoid extra update
        session.add(existing)
        session.commit()
        return "skipped", "no_change"

    session.add(existing)
    session.commit()
    audit(session, "UPDATE", "Event", f"{event_type}:{ext}", "Updated from CSV")
    return ("closed" if incoming_status == "CLOSED" else "updated"), None


# -----------------------------
# API
# -----------------------------
app = FastAPI(title="Project Sentinel SUPER", version="1.1.0")

@app.on_event("startup")
def _startup():
    init_db()

@app.get("/")
def root():
    return {
        "status": "ok",
        "name": "Project Sentinel SUPER",
        "sla_working_days": SLA_WORKING_DAYS,
        "early_warning_days": EARLY_WARNING_DAYS,
        "profit_per_day_sar": PROFIT_PER_DAY,
        "holidays_count": len(HOLIDAYS),
        "db": "sqlite:///sentinel.db"
    }

def event_to_out(session: Session, ev: Event) -> EventOut:
    due = effective_due_date(ev)
    st, remaining, delay = compute_stage(today(), due)
    ensure_escalations(session, ev)

    risk = cumulative_risk(delay, ev.weight, ev.impact_factor) if ev.status == "OPEN" else 0.0
    expo = exposure_sar(delay, ev.is_critical, ev.notice_required) if ev.status == "OPEN" else 0.0

    return EventOut(
        external_ref=ev.external_ref,
        event_type=ev.event_type,
        department=ev.department,
        title=ev.title,
        submission_date=ev.submission_date,
        due_date=due,
        stage=st,
        remaining_days=remaining,
        delay_days=delay,
        cumulative_risk=round(risk, 2),
        exposure_sar=round(expo, 2),
        status=ev.status
    )

@app.post("/events", response_model=EventOut)
def create_event(payload: EventCreate):
    with Session(engine) as session:
        exists = session.exec(
            select(Event).where(Event.event_type == payload.event_type, Event.external_ref == payload.external_ref)
        ).first()
        if exists:
            raise HTTPException(status_code=409, detail="Event already exists (type + external_ref).")

        ev = Event(
            external_ref=payload.external_ref,
            event_type=payload.event_type,
            department=DEPT_MAP[payload.event_type],
            title=payload.title,
            submission_date=payload.submission_date,
            due_date=add_working_days_from_next_day(payload.submission_date, SLA_WORKING_DAYS),
            weight=EVENT_WEIGHTS[payload.event_type],
            impact_factor=payload.impact_factor,
            is_critical=payload.is_critical,
            notice_required=payload.notice_required,
            status="OPEN",
            updated_at=datetime.utcnow(),
        )
        session.add(ev)
        session.commit()
        audit(session, "CREATE", "Event", f"{payload.event_type}:{payload.external_ref}", "Manual create")
        return event_to_out(session, ev)

@app.get("/events", response_model=List[EventOut])
def list_events():
    with Session(engine) as session:
        events = session.exec(select(Event)).all()
        outs = [event_to_out(session, ev) for ev in events]
        outs.sort(key=lambda x: (x.stage != "CRITICAL_BREACH", x.stage != "BREACH", -x.cumulative_risk, -x.exposure_sar))
        return outs

@app.post("/events/{event_type}/{external_ref}/override", response_model=EventOut)
def override_due(event_type: EventType, external_ref: str, payload: OverrideReq):
    with Session(engine) as session:
        ev = session.exec(
            select(Event).where(Event.event_type == event_type, Event.external_ref == external_ref)
        ).first()
        if not ev:
            raise HTTPException(status_code=404, detail="Event not found.")

        ev.override_due_date = payload.new_due_date
        ev.override_reason = payload.reason
        ev.overridden_at = datetime.utcnow()
        ev.updated_at = datetime.utcnow()
        session.add(ev)
        session.commit()
        audit(session, "OVERRIDE", "Event", f"{event_type}:{external_ref}", f"new_due={payload.new_due_date} reason={payload.reason}")
        return event_to_out(session, ev)

@app.post("/events/{event_type}/{external_ref}/close", response_model=EventOut)
def close_event(event_type: EventType, external_ref: str):
    with Session(engine) as session:
        ev = session.exec(
            select(Event).where(Event.event_type == event_type, Event.external_ref == external_ref)
        ).first()
        if not ev:
            raise HTTPException(status_code=404, detail="Event not found.")

        if ev.status != "CLOSED":
            ev.status = "CLOSED"
            ev.closed_at = datetime.utcnow()
            # Freeze (B)
            ev.override_due_date = ev.closed_at.date()
            ev.override_reason = "MANUAL_CLOSE"
            ev.overridden_at = ev.closed_at
            ev.updated_at = datetime.utcnow()
            session.add(ev)
            session.commit()
            audit(session, "MANUAL_CLOSE", "Event", f"{event_type}:{external_ref}", "Closed manually and frozen")
        close_all_escalations_for_event(session, ev)
        return event_to_out(session, ev)

@app.get("/dashboard/health", response_model=HealthOut)
def dashboard_health():
    with Session(engine) as session:
        events = session.exec(select(Event)).all()
        outs: List[Dict[str, Any]] = []
        for ev in events:
            out = event_to_out(session, ev)
            outs.append({
                "external_ref": out.external_ref,
                "event_type": out.event_type,
                "department": out.department,
                "stage": out.stage,
                "cumulative_risk": out.cumulative_risk,
                "exposure_sar": out.exposure_sar,
                "status": out.status
            })
        snap = compute_health_snapshot(outs)
        return HealthOut(
            project_health_score=snap["project_health_score"],
            band=snap["band"],
            total_open_risk=snap["total_open_risk"],
            total_exposure_sar=snap["total_exposure_sar"],
            top_issues=snap["top_issues"],
            departments=snap["departments"],
            as_of=datetime.utcnow().isoformat() + "Z"
        )

@app.get("/escalations")
def escalations(limit: int = 200):
    with Session(engine) as session:
        rows = session.exec(select(Escalation).order_by(Escalation.id.desc()).limit(limit)).all()
        return [
            {
                "id": r.id,
                "event_id": r.event_id,
                "level": r.level,
                "status": r.status,
                "triggered_at": r.triggered_at.isoformat() + "Z",
                "resolved_at": (r.resolved_at.isoformat() + "Z") if r.resolved_at else None,
                "duration_working_days": r.duration_working_days
            }
            for r in rows
        ]

@app.get("/audit")
def audit_list(limit: int = 100):
    with Session(engine) as session:
        rows = session.exec(select(AuditLog).order_by(AuditLog.id.desc()).limit(limit)).all()
        return [
            {
                "ts": r.timestamp.isoformat() + "Z",
                "action": r.action,
                "entity": r.entity,
                "ref": r.ref,
                "details": r.details
            }
            for r in rows
        ]

@app.post("/import/csv", response_model=ImportReport)
async def import_csv(
    event_type: EventType = Query(...),
    allow_reopen: bool = Query(False, description="Allow CLOSED->OPEN transitions (default false)"),
    strict: bool = Query(True, description="If true, abort import when validation errors exist; else import valid rows only"),
    file: UploadFile = File(...)
):
    raw = (await file.read()).decode("utf-8", errors="ignore")

    try:
        rows = parse_csv(raw)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    # row-level validation
    errors = validate_rows_strict(rows)

    # If strict: abort if any errors
    if strict and errors:
        return ImportReport(
            event_type=event_type,
            rows=len(rows),
            created=0,
            updated=0,
            closed=0,
            skipped_no_change=0,
            errors=errors
        )

    created = updated = closed = skipped = 0
    with Session(engine) as session:
        # duplicate vs DB in same upload: check once (informational)
        # (we still upsert row-by-row)
        for idx, row in enumerate(rows, start=2):
            # skip rows that have validation errors if not strict
            if not strict:
                if any(e["line"] == idx for e in errors):
                    continue

            ext = (row.get("external_ref") or "").strip()
            if not ext:
                continue  # already in errors

            res, note = upsert_event_from_row(session, event_type, row, allow_reopen=allow_reopen)
            if res == "created":
                created += 1
            elif res == "updated":
                updated += 1
            elif res == "closed":
                closed += 1
            elif res == "skipped":
                skipped += 1
                if note and note != "no_change":
                    errors.append({"line": idx, "field": "transition", "msg": note})

    return ImportReport(
        event_type=event_type,
        rows=len(rows),
        created=created,
        updated=updated,
        closed=closed,
        skipped_no_change=skipped,
        errors=errors
    )
PY

echo "🧾 Writing CSV templates..."
cat > "$ROOT/rfi.csv" <<'CSV'
external_ref,title,submission_date,impact_factor,is_critical,notice_required,status
RFI-078,Façade anchor clarification,2026-03-01,1.2,true,true,Open
RFI-102,MEP shaft clearance,2026-03-05,1.0,false,false,Under Review
RFI-155,Fire pump room layout,2026-03-08,1.1,true,false,Closed
CSV

cat > "$ROOT/shop_drawing.csv" <<'CSV'
external_ref,title,submission_date,impact_factor,is_critical,notice_required,status
SD-FA-0234,Unitized façade mullion shop drawing,2026-03-02,1.3,true,false,Submitted
SD-STR-0112,Canopy steel connection details,2026-03-04,1.1,false,false,Under Review
SD-ARC-0066,Typical guestroom finishes,2026-03-01,1.0,false,false,Approved
CSV

cat > "$ROOT/material.csv" <<'CSV'
external_ref,title,submission_date,impact_factor,is_critical,notice_required,status
MS-GL-0042,Low-E glass unit sample,2026-03-03,1.2,true,true,Submitted
MS-AL-0101,Aluminium profiles,2026-03-06,1.1,true,false,Rejected
MS-FIN-0020,Stone cladding sample,2026-03-02,1.0,false,false,Approved
CSV

cat > "$ROOT/long_lead.csv" <<'CSV'
external_ref,title,submission_date,impact_factor,is_critical,notice_required,status
LL-CHILLER-01,Chiller package procurement,2026-02-20,1.3,true,true,RFQ
LL-BMU-01,Building maintenance unit system,2026-02-25,1.2,true,true,Awarded
LL-ELEV-01,Elevators and control system,2026-02-22,1.3,true,true,In Production
CSV

cat > "$ROOT/ncr.csv" <<'CSV'
external_ref,title,submission_date,impact_factor,is_critical,notice_required,status
NCR-015,Concrete honeycombing at core wall,2026-03-01,1.2,true,false,Raised
NCR-016,Rebar cover nonconformance,2026-03-04,1.1,false,false,Corrective Action
NCR-017,Facade sealant workmanship issue,2026-03-02,1.1,true,false,Closed
CSV

echo "✅ Installed & templates created."
echo "📌 Run:"
echo "   cd $ROOT"
echo "   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo "📌 Swagger:"
echo "   http://127.0.0.1:8000/docs"
