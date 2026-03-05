from datetime import date, datetime, timedelta
from typing import Optional, List, Dict, Literal
from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from sqlmodel import SQLModel, Field, create_engine, Session, select

# ---------------- CONFIG ----------------
SLA_DAYS = 15
EARLY_WARNING = 3
PROJECT_VALUE = 600_000_000
MARGIN = 0.02
PROFIT_TOTAL = PROJECT_VALUE * MARGIN
PROFIT_PER_DAY = int(PROFIT_TOTAL / 900)

EVENT_WEIGHTS = {
    "SHOP_DRAWING": 1.4,
    "MATERIAL_SUBMITTAL": 1.3,
    "RFI": 1.0,
    "LONG_LEAD": 2.0,
    "NCR": 1.5,
}

DEPT_MAP = {
    "SHOP_DRAWING": "TECHNICAL",
    "MATERIAL_SUBMITTAL": "TECHNICAL",
    "RFI": "TECHNICAL",
    "LONG_LEAD": "PROCUREMENT",
    "NCR": "QAQC",
}

engine = create_engine("sqlite:///sentinel.db", echo=False)

# ---------------- MODELS ----------------
class Event(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    external_ref: str
    event_type: str
    department: str
    submission_date: date
    due_date: date
    weight: float
    impact_factor: float = 1.0
    is_critical: bool = False
    notice_required: bool = False
    status: str = "OPEN"
    closed_at: Optional[datetime] = None
    override_due_date: Optional[date] = None

class Escalation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    event_id: int
    level: int
    triggered_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    status: str = "OPEN"
    duration_days: int = 0

class Audit(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    action: str
    ref: str

# ---------------- HELPERS ----------------
def today():
    return date.today()

def add_working_days(d, n):
    return d + timedelta(days=n)

def compute_stage(ev):
    due = ev.override_due_date or ev.due_date
    remaining = (due - today()).days
    if remaining > EARLY_WARNING:
        return "ON_TRACK"
    if remaining == EARLY_WARNING:
        return "PRE_WARNING"
    if remaining >= 0:
        return "WARNING"
    if remaining >= -5:
        return "BREACH"
    return "CRITICAL_BREACH"

def risk_multiplier(days):
    if days <= 3: return 1.0
    if days <= 7: return 1.3
    return 1.7

def cumulative_risk(delay, weight, impact):
    if delay <= 0: return 0
    total = 0
    for i in range(1, delay+1):
        total += weight * impact * risk_multiplier(i)
    return total

def exposure(delay, crit, notice):
    if delay <= 0: return 0
    factor = 1.5 if notice else 1
    critf = 1 if crit else 0.3
    return delay * PROFIT_PER_DAY * critf * factor

# ---------------- ESCALATION AUTO ----------------
def auto_escalate(session, ev):
    if ev.status == "CLOSED":
        return
    stage = compute_stage(ev)
    open_escalations = session.exec(
        select(Escalation).where(Escalation.event_id == ev.id, Escalation.status=="OPEN")
    ).all()
    levels = [e.level for e in open_escalations]

    if stage == "BREACH" and 1 not in levels:
        session.add(Escalation(event_id=ev.id, level=1))
        session.add(Audit(action="ESC_L1", ref=ev.external_ref))

    if stage == "CRITICAL_BREACH" and 2 not in levels:
        session.add(Escalation(event_id=ev.id, level=2))
        session.add(Audit(action="ESC_L2", ref=ev.external_ref))

    for e in open_escalations:
        e.duration_days = (today() - e.triggered_at.date()).days
        session.add(e)

    session.commit()

# ---------------- FASTAPI ----------------
app = FastAPI(title="Sentinel MASTER")

@app.on_event("startup")
def startup():
    SQLModel.metadata.create_all(engine)

@app.post("/events")
def create_event(data: dict):
    with Session(engine) as session:
        ev = Event(
            external_ref=data["external_ref"],
            event_type=data["event_type"],
            department=DEPT_MAP[data["event_type"]],
            submission_date=date.fromisoformat(data["submission_date"]),
            due_date=add_working_days(date.fromisoformat(data["submission_date"]), SLA_DAYS),
            weight=EVENT_WEIGHTS[data["event_type"]],
            impact_factor=data.get("impact_factor",1),
            is_critical=data.get("is_critical",False),
            notice_required=data.get("notice_required",False),
        )
        session.add(ev)
        session.commit()
        return {"status":"created"}

@app.get("/events")
def list_events():
    with Session(engine) as session:
        rows = session.exec(select(Event)).all()
        result = []
        for ev in rows:
            auto_escalate(session, ev)
            stage = compute_stage(ev)
            due = ev.override_due_date or ev.due_date
            delay = max(0, (today() - due).days)
            result.append({
                "ref": ev.external_ref,
                "stage": stage,
                "risk": cumulative_risk(delay, ev.weight, ev.impact_factor),
                "exposure": exposure(delay, ev.is_critical, ev.notice_required),
                "status": ev.status
            })
        return result

@app.get("/health")
def health():
    with Session(engine) as session:
        rows = session.exec(select(Event)).all()
        total_expo = 0
        total_risk = 0
        breaches = 0
        for ev in rows:
            auto_escalate(session, ev)
            stage = compute_stage(ev)
            due = ev.override_due_date or ev.due_date
            delay = max(0,(today()-due).days)
            total_expo += exposure(delay, ev.is_critical, ev.notice_required)
            total_risk += cumulative_risk(delay, ev.weight, ev.impact_factor)
            if stage in ["BREACH","CRITICAL_BREACH"]:
                breaches += 1
        score = max(0, 100 - breaches*10)
        return {
            "health_score": score,
            "total_exposure": total_expo,
            "total_risk": total_risk
        }

@app.post("/events/{event_type}/{ref}/close")
def close_event(event_type:str, ref:str):
    with Session(engine) as session:
        ev = session.exec(
            select(Event).where(Event.event_type==event_type, Event.external_ref==ref)
        ).first()
        if not ev:
            raise HTTPException(status_code=404, detail="Not found")
        ev.status="CLOSED"
        ev.closed_at=datetime.utcnow()
        ev.override_due_date=ev.closed_at.date()
        session.add(ev)
        session.add(Audit(action="AUTO_CLOSE", ref=ref))
        esc = session.exec(
            select(Escalation).where(Escalation.event_id==ev.id, Escalation.status=="OPEN")
        ).all()
        for e in esc:
            e.status="CLOSED"
            e.resolved_at=datetime.utcnow()
            session.add(e)
        session.commit()
        return {"status":"closed"}

@app.get("/audit")
def audit():
    with Session(engine) as session:
        rows=session.exec(select(Audit)).all()
        return rows
