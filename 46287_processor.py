import asyncio

async def process(case: str, text: str):
    await asyncio.sleep(0)
    if case == "error":
        return f"⚠ Error detected: {text}"
    elif case == "analysis":
        return f"📊 Analysis result: {text}"
    return f"✅ Processed: {text}"
