from fastapi.testclient import TestClient
from app.main import app
import os

os.environ["INVENTORY_API_KEY"] = "test-key"

client = TestClient(app)
H = {"x-api-key":"test-key"}

def test_flow():
    r = client.get("/health")
    assert r.status_code == 200

    r = client.post("/api/v1/items", headers=H,
                    json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 200

    r = client.get("/api/v1/items", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/api/v1/export", headers=H)
    assert "csv" in r.json()
