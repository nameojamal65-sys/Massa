import asyncio

async def process(case: str, text: str):
    await asyncio.sleep(0)
    if case == "error":
        return f"⚠ تم اكتشاف خطأ: {text}"
    elif case == "analysis":
        return f"📊 تحليل للنص: {text}"
    return f"✅ معالجة عامة: {text}"
