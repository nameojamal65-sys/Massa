from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from legendary.api.auth import authenticate_user, create_access_token
from legendary.utils.queue import push_task

app = FastAPI(title="Legendary V11 Termux SaaS")

@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    access_token = create_access_token({"sub": user["username"], "tenant": user["tenant"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/health")
def health():
    return {"status": "Legendary V11 Termux running"}

@app.post("/task")
def create_task(task: str, tenant: str = "global"):
    push_task(task, tenant)
    return {"status": "task queued", "tenant": tenant}
