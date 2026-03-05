from __future__ import annotations

import os
from openai import OpenAI

def get_client() -> OpenAI:
    key = os.environ.get("OPENAI_API_KEY", "")
    if not key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    return OpenAI(api_key=key)
