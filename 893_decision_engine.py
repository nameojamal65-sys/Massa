def classify(text: str):
    if "خطأ" in text:
        return "error"
    elif "تحليل" in text:
        return "analysis"
    return "general"
