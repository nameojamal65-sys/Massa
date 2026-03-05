import aiosqlite

DB_FILE = "memory.db"

async def init_db():
    async with aiosqlite.connect(DB_FILE) as db:
        await db.execute("""
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            input TEXT,
            case TEXT,
            result TEXT
        )
        """)
        await db.commit()

async def save_log(input_text, case, result):
    async with aiosqlite.connect(DB_FILE) as db:
        await db.execute(
            "INSERT INTO logs (input, case, result) VALUES (?, ?, ?)",
            (input_text, case, result)
        )
        await db.commit()
