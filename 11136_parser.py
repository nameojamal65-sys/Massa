def parse_command(command: str):
    c = (command or "").strip()
    lc = c.lower()
    if "tenant:" in lc:
        parts = c.split()
        tenant = parts[0].split(":", 1)[1]
        rest = " ".join(parts[1:])
    else:
        tenant = "default"
        rest = c

    lcr = rest.lower()
    if "generate code" in lcr or "توليد كود" in rest or "code" in lcr:
        return {"type": "code", "tenant": tenant, "prompt": rest}
    if "generate video" in lcr or "توليد فيديو" in rest or "video" in lcr:
        return {"type": "video", "tenant": tenant, "prompt": rest}
    if "generate voice" in lcr or "توليد صوت" in rest or "voice" in lcr or "audio" in lcr:
        return {"type": "voice", "tenant": tenant, "prompt": rest}
    if "automation" in lcr or "أتمتة" in rest or "run " in lcr:
        return {"type": "automation", "tenant": tenant, "prompt": rest}
    return {"type": "unknown", "tenant": tenant, "prompt": rest}
