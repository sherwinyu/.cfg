#!/usr/bin/env python3
"""
PostToolUse hook to track Claude Code tool usage.
Receives JSON via stdin and logs to SQLite database.
"""
import json
import os
import sqlite3
import sys
from datetime import datetime
from pathlib import Path


DB_DIR = Path.home() / ".claude" / "tool-usage"


def get_repo_name(cwd: str) -> str:
    """Extract repo name from cwd path."""
    path = Path(cwd)
    # Look for common project indicators
    for parent in [path] + list(path.parents):
        if (parent / ".git").exists():
            return parent.name
    # Fallback to last directory component
    return path.name


def generate_permission_string(tool_name: str, tool_input: dict) -> str:
    """Generate a permission string for allowlisting."""
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        # Extract command prefix for permission string
        parts = cmd.split()
        if parts:
            base_cmd = parts[0]
            return f"Bash({base_cmd}:*)"
    elif tool_name == "Read":
        file_path = tool_input.get("file_path", "")
        return f"Read({file_path})"
    elif tool_name == "Write":
        file_path = tool_input.get("file_path", "")
        return f"Write({file_path})"
    elif tool_name == "Edit":
        file_path = tool_input.get("file_path", "")
        return f"Edit({file_path})"
    elif tool_name == "Glob":
        pattern = tool_input.get("pattern", "")
        return f"Glob({pattern})"
    elif tool_name == "Grep":
        pattern = tool_input.get("pattern", "")
        return f"Grep({pattern})"
    elif tool_name == "WebFetch":
        url = tool_input.get("url", "")
        # Extract domain
        try:
            from urllib.parse import urlparse
            domain = urlparse(url).netloc
            return f"WebFetch(domain:{domain})"
        except:
            return f"WebFetch({url})"
    elif tool_name == "WebSearch":
        query = tool_input.get("query", "")
        return f"WebSearch({query[:50]})"
    elif tool_name.startswith("mcp__"):
        return f"{tool_name}"
    else:
        return f"{tool_name}(*)"


def init_db(db_path: Path):
    """Initialize the database with required table."""
    conn = sqlite3.connect(db_path)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS tool_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tool_name TEXT NOT NULL,
            permission_string TEXT,
            tool_input TEXT,
            timestamp TEXT NOT NULL
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_tool_name ON tool_usage(tool_name)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_timestamp ON tool_usage(timestamp)")
    conn.commit()
    return conn


def main():
    try:
        # Read JSON from stdin
        data = json.load(sys.stdin)

        tool_name = data.get("tool_name", "unknown")
        tool_input = data.get("tool_input", {})
        cwd = data.get("cwd", os.getcwd())

        # Get repo name and set up database
        repo = get_repo_name(cwd)
        DB_DIR.mkdir(parents=True, exist_ok=True)
        db_path = DB_DIR / f"{repo}.db"

        # Generate permission string
        perm_string = generate_permission_string(tool_name, tool_input)

        # Store in database
        conn = init_db(db_path)
        conn.execute(
            "INSERT INTO tool_usage (tool_name, permission_string, tool_input, timestamp) VALUES (?, ?, ?, ?)",
            (tool_name, perm_string, json.dumps(tool_input), datetime.now().isoformat())
        )
        conn.commit()
        conn.close()

    except Exception as e:
        # Silently fail to not block Claude Code
        # Uncomment for debugging:
        # print(f"Error: {e}", file=sys.stderr)
        pass


if __name__ == "__main__":
    main()
