#!/usr/bin/env bash
# Thinking Council — First-Run Initialization
# Creates data/council_sessions.db from data/schema.sql if it does not exist.
# Idempotent: safe to run multiple times.
#
# Hermes invokes this once before first Council session, per SKILL.md's
# First Run step. Can also be run manually:
#   bash scripts/init.sh

set -euo pipefail

# Resolve paths relative to the skill root, regardless of where this is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PATH="$SKILL_ROOT/data/council_sessions.db"
SCHEMA_PATH="$SKILL_ROOT/data/schema.sql"

echo "[Council init] Skill root: $SKILL_ROOT"
echo "[Council init] DB path:    $DB_PATH"

# Verify schema file exists
if [[ ! -f "$SCHEMA_PATH" ]]; then
    echo "[Council init] ERROR: schema.sql not found at $SCHEMA_PATH" >&2
    exit 1
fi

# If DB already exists, verify it has the expected tables and exit clean
if [[ -f "$DB_PATH" ]]; then
    echo "[Council init] Database already exists. Verifying schema..."

    # Check for the three core tables using Python's stdlib sqlite3
    # (avoids depending on the sqlite3 CLI tool, which may not be installed)
    TABLES=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_PATH')
tables = [r[0] for r in conn.execute(\"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name\")]
print(','.join(tables))
")

    if [[ "$TABLES" == *"council_sessions"* ]] \
       && [[ "$TABLES" == *"anonymization_audits"* ]] \
       && [[ "$TABLES" == *"stage_latencies"* ]]; then
        echo "[Council init] Schema verified. Tables present: $TABLES"
        echo "[Council init] No action needed."
        exit 0
    else
        echo "[Council init] WARNING: DB exists but schema is incomplete." >&2
        echo "[Council init] Tables found: $TABLES" >&2
        echo "[Council init] Expected: council_sessions, anonymization_audits, stage_latencies" >&2
        echo "[Council init] Refusing to modify existing DB. Resolve manually." >&2
        exit 2
    fi
fi

# DB does not exist — create it from schema
echo "[Council init] Database not found. Creating from schema..."

mkdir -p "$(dirname "$DB_PATH")"

python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_PATH')
with open('$SCHEMA_PATH') as f:
    conn.executescript(f.read())
conn.close()
print('[Council init] Schema applied successfully.')
"

# Verify creation worked
if [[ -f "$DB_PATH" ]]; then
    echo "[Council init] Database created: $DB_PATH"
    echo "[Council init] Initialization complete."
else
    echo "[Council init] ERROR: DB creation appeared to succeed but file not found." >&2
    exit 3
fi
