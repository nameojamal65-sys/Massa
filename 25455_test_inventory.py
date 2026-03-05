from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def seed():
    client.post("/items", json={"name":"Keyboard","sku":"KB-001","quantity":5})
    client.post("/items", json={"name":"Mouse","sku":"MS-001","quantity":3})
    client.post("/items", json={"name":"Monitor","sku":"MN-001","quantity":2})

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True
    assert "version" in r.json()

def test_crud_and_search_pagination():
    seed()

    # list default
    r = client.get("/items")
    assert r.status_code == 200
    assert len(r.json()) == 3

    # search by sku
    r = client.get("/items", params={"q": "KB-"})
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert r.json()[0]["sku"] == "KB-001"

    # pagination
    r = client.get("/items", params={"limit": 2, "offset": 0, "sort": "name", "order": "asc"})
    assert r.status_code == 200
    assert len(r.json()) == 2

    # create conflict
    r = client.post("/items", json={"name":"X","sku":"KB-001","quantity":1})
    assert r.status_code == 409

    # get/update/delete
    r = client.get("/items/1")
    assert r.status_code == 200

    r = client.put("/items/1", json={"name":"Keyboard Pro","sku":"KB-001","quantity":7})
    assert r.status_code == 200
    assert r.json()["quantity"] == 7

    r = client.delete("/items/1")
    assert r.status_code == 204
    r = client.get("/items/1")
    assert r.status_code == 404
