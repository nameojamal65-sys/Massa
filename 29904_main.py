from fastapi import FastAPI\napp = FastAPI()\n\n@app.get('/')\ndef read_root():\n    return {'status': 'Backend Ready'}
