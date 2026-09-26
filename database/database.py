import sys
import json
import sqlite3
from pathlib import Path
from typing import List, Dict, Optional


if hasattr(sys, "_MEIPASS"):
    ROOT_DIR = Path(sys.executable).parent
else:
    ROOT_DIR = Path(__file__).parent.parent

DATA_DIR = ROOT_DIR / "data"


class KeysDatabase:
    def __init__(self, db_path: Optional[str] = None):
        if db_path is None:
            self.db_path = DATA_DIR / "keys.db"
        else:
            self.db_path = Path(db_path)

        self.connection: Optional[sqlite3.Connection] = None
        self._initialize_database()

    def _initialize_database(self):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            self._connect()
            self._run_migrations()
        except sqlite3.DatabaseError:
            print(f"⚠️ База данных повреждена, создаётся новая: {self.db_path}")
            self._recreate()

    def _connect(self):
        self.connection = sqlite3.connect(self.db_path, check_same_thread=False)
        self.connection.row_factory = sqlite3.Row
        self.connection.execute("PRAGMA integrity_check")
        print(f"✅ Подключено к БД: {self.db_path}")

    def _recreate(self):
        if self.connection is not None:
            self.connection.close()
            self.connection = None
        if self.db_path.exists():
            self.db_path.unlink()
        self._connect()
        self._run_migrations()

    def _run_migrations(self):
        cursor = self.connection.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS api_keys (
                provider   TEXT PRIMARY KEY,
                api_key    TEXT NOT NULL,
                models     TEXT NOT NULL DEFAULT '[]',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        self.connection.commit()

    def _ensure_connection(self):
        if self.connection is None:
            self._connect()
        else:
            try:
                self.connection.execute("SELECT 1")
            except sqlite3.Error:
                self._connect()

    def save_key(self, provider: str, api_key: str, models: List[str]) -> bool:
        if not provider or not api_key:
            return False

        self._ensure_connection()
        cursor = self.connection.cursor()
        cursor.execute(
            """
            INSERT INTO api_keys (provider, api_key, models, updated_at)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(provider) DO UPDATE SET
                api_key    = excluded.api_key,
                models     = excluded.models,
                updated_at = CURRENT_TIMESTAMP
            """,
            (provider, api_key, json.dumps(models)),
        )
        self.connection.commit()
        print(f"✅ Ключ сохранён: provider='{provider}', моделей={len(models)}")
        return True

    def delete_key(self, provider: str) -> bool:
        self._ensure_connection()
        cursor = self.connection.cursor()
        cursor.execute("DELETE FROM api_keys WHERE provider = ?", (provider,))
        self.connection.commit()
        return cursor.rowcount > 0

    def get_key(self, provider: str) -> Optional[str]:
        self._ensure_connection()
        cursor = self.connection.cursor()
        cursor.execute("SELECT api_key FROM api_keys WHERE provider = ?", (provider,))
        row = cursor.fetchone()
        return row["api_key"] if row else None

    def get_all_keys(self) -> List[Dict]:
        self._ensure_connection()
        cursor = self.connection.cursor()
        cursor.execute("SELECT provider, api_key, models FROM api_keys ORDER BY provider")
        rows = cursor.fetchall()
        return [
            {
                "provider": row["provider"],
                "api_key": row["api_key"],
                "models": json.loads(row["models"]),
            }
            for row in rows
        ]

    def close(self):
        if self.connection:
            self.connection.close()
            self.connection = None
