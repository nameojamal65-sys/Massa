from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)
H={"x-api-key":"test-key"}

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True

def test_auth_required():
    r = client.get("/api/v1/items")
    assert r.status_code == 401

def test_crud():
    r = client.post("/api/v1/items", headers=H, json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 201
    r = client.get("/api/v1/items", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1
