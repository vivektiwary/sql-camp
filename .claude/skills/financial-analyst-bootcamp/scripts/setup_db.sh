#!/usr/bin/env bash
# =====================================================================
# setup_db.sh -- build the SQL Camp practice database on macOS
# ---------------------------------------------------------------------
# Usage:
#   ./setup_db.sh              build the database (safe to re-run)
#   ./setup_db.sh --reset      delete it and build it again from scratch
#   ./setup_db.sh --verify     just run the health check
#
# What it does, in plain English:
#   1. checks PostgreSQL is installed and running
#   2. creates a database called "sqlcamp"
#   3. creates the tables and fills them with the practice data
#   4. runs a health check and prints PASS/FAIL for every table
#
# If anything fails it stops and tells you exactly what to do next,
# rather than leaving you with a half-built database.
# =====================================================================
set -uo pipefail

DB_NAME="${SQLCAMP_DB:-sqlcamp}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../assets/dataset"

green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
step()   { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

die() { red "ERROR: $*"; exit 1; }

# --- 1. is psql installed? -------------------------------------------
step "Checking that PostgreSQL is installed"
if ! command -v psql >/dev/null 2>&1; then
  red "psql was not found on your Mac."
  cat <<'HELP'

Install PostgreSQL with Homebrew, then run this script again:

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # only if you do not have Homebrew
    brew install postgresql@16
    brew services start postgresql@16
    echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc

Then run this script again. Full walkthrough: references/setup-macos.md
HELP
  exit 1
fi
green "Found $(psql --version)"

# --- 2. is the server running? ---------------------------------------
step "Checking that the PostgreSQL server is running"
if ! psql -d postgres -c 'SELECT 1' >/dev/null 2>&1; then
  red "PostgreSQL is installed but not accepting connections."
  cat <<'HELP'

Try starting it:

    brew services start postgresql@16

Then check it is up:

    psql -d postgres -c 'SELECT 1'

If that still fails, see the troubleshooting table in references/setup-macos.md
HELP
  exit 1
fi
green "Server is up"

# --- verify-only mode -------------------------------------------------
if [[ "${1:-}" == "--verify" ]]; then
  step "Running the health check on '$DB_NAME'"
  psql -d "$DB_NAME" -f "$DATA_DIR/04_verify.sql" || die "health check could not run"
  exit 0
fi

# --- 3. create (or recreate) the database ----------------------------
if [[ "${1:-}" == "--reset" ]]; then
  step "Deleting the existing '$DB_NAME' database"
  dropdb --if-exists "$DB_NAME" || die "could not drop $DB_NAME (is a query window still connected to it?)"
  green "Deleted"
fi

step "Creating the '$DB_NAME' database"
if psql -lqt | cut -d\| -f1 | grep -qw "$DB_NAME"; then
  yellow "'$DB_NAME' already exists -- reusing it. (Use --reset to start clean.)"
else
  createdb "$DB_NAME" || die "could not create $DB_NAME"
  green "Created"
fi

# --- 4. load the data -------------------------------------------------
for f in 01_schema.sql 02_seed_dimensions.sql 03_generate_facts.sql; do
  step "Loading $f"
  if ! psql -d "$DB_NAME" -q -v ON_ERROR_STOP=1 -f "$DATA_DIR/$f"; then
    die "$f failed. Nothing was half-loaded -- fix the error above and re-run with --reset."
  fi
  green "Loaded $f"
done

# --- 5. health check --------------------------------------------------
step "Health check"
psql -d "$DB_NAME" -f "$DATA_DIR/04_verify.sql"

cat <<EOM

$(green "Setup complete.")

Connect any time with:

    psql -d $DB_NAME

Try your first query:

    SELECT ticker, company_name, sector FROM dim_company ORDER BY sector;

Quit psql with \q

EOM
