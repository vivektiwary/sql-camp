# Getting set up on a Mac

**Read this to the student one step at a time.** Do not paste the whole page.
Wait for them to confirm each step worked before moving on — a student who
runs six commands and then reports "it didn't work" has no idea which one
failed, and neither will you.

Total time: about 30 minutes. About 25 of those are downloads.

---

## What we are installing, and why

| Thing | What it actually is | The Excel comparison |
|---|---|---|
| **PostgreSQL** | The database engine. It stores the data and answers questions about it. | The Excel *calculation engine* — the part that actually does the work |
| **psql** | A text window where you type questions and get answers. Comes free with PostgreSQL. | The formula bar, if the formula bar were the whole app |
| **DBeaver** | A friendly window with tables on the left and results in a grid. | The Excel *window* — menus, grid, tabs |
| **The sqlcamp database** | Our practice data: companies, ledgers, customers, portfolios | The workbook you open |

You need PostgreSQL. DBeaver is optional but strongly recommended — seeing
your results in a grid instead of text makes the first two weeks far less
disorienting.

---

## Step 1 — Open Terminal

Press `Cmd + Space`, type `Terminal`, press Enter.

A window appears with some text and a blinking cursor. This is a place where
you type instructions instead of clicking them. Nothing you type here can
break your Mac by accident; the commands in this guide are all installers
and queries.

Type this and press Enter:

```bash
echo hello
```

It should print `hello`. That is the whole idea of the Terminal: you type a
line, press Enter, it does the thing.

---

## Step 2 — Install Homebrew

Homebrew is the App Store for developer tools, without the Store. It is how
almost every Mac in a data team installs things.

First check whether you already have it:

```bash
brew --version
```

If that prints a version number, skip to Step 3. If it says
`command not found`, install it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

* It will ask for your Mac password. **Nothing appears as you type it** — no
  dots, no stars. That is normal. Type it and press Enter.
* It may ask you to install "Command Line Tools". Say yes. This is a large
  download and can take ten minutes.
* At the end it may print two `echo` commands starting with
  `>> /Users/yourname/.zprofile`. **Run them.** They tell your Mac where
  Homebrew put things.

Confirm:

```bash
brew --version
```

---

## Step 3 — Install PostgreSQL

```bash
brew install postgresql@16
```

Five to ten minutes. Then start it, and tell it to start again whenever you
restart your Mac:

```bash
brew services start postgresql@16
```

Now make the `psql` command available from any Terminal window:

```bash
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

> On an older Intel Mac, replace `/opt/homebrew` with `/usr/local` in that
> line. To tell which you have: `uname -m` prints `arm64` on Apple Silicon
> (M1/M2/M3/M4) and `x86_64` on Intel.

Confirm both the client and the server:

```bash
psql --version
psql -d postgres -c 'SELECT 1 AS it_works'
```

The second command should print a small table with `it_works = 1`. **That is
your first SQL query.** It asks the database for the number 1 and the
database hands it back. Everything else in this course is that, with more
interesting questions.

---

## Step 4 — Build the practice database

From the folder containing this course:

```bash
cd path/to/sql-camp
./.claude/skills/financial-analyst-bootcamp/scripts/setup_db.sh
```

It creates a database called `sqlcamp`, loads about 50,000 rows across 20
tables, and then prints a health check. **Every line must say PASS.** If any
line says FAIL, stop and report which one — do not start the course on a
broken dataset.

To wipe it and start clean at any point (this is safe, and you will want it
after Module 10 when you start changing data):

```bash
./.claude/skills/financial-analyst-bootcamp/scripts/setup_db.sh --reset
```

---

## Step 5 — Your first real query

```bash
psql -d sqlcamp
```

The prompt changes to `sqlcamp=#`. You are now inside the database. Type:

```sql
SELECT ticker, company_name, sector FROM dim_company ORDER BY sector;
```

Press Enter. Twenty companies appear.

**The semicolon is not optional.** It means "I have finished my question, go
and answer it". If you press Enter and nothing happens except the prompt
changing to `sqlcamp-#`, you forgot it — type `;` and press Enter.

Useful things inside psql:

| You type | What happens |
|---|---|
| `\dt` | list all tables |
| `\d dim_company` | show one table's columns |
| `\x` | switch between wide grid and one-field-per-line (handy for wide tables) |
| `\timing` | show how long each query took |
| `\q` | quit |
| `Ctrl + C` | abandon the line you are typing |

---

## Step 6 — Install DBeaver (recommended)

```bash
brew install --cask dbeaver-community
```

Or download it from dbeaver.io if you prefer clicking.

Connect it:

1. Open DBeaver → **Database → New Database Connection** → **PostgreSQL** → Next
2. Host `localhost`, Port `5432`, Database `sqlcamp`
3. Username: your Mac username (find it with `whoami` in Terminal). Password: leave blank.
4. **Test Connection**. If it offers to download drivers, say yes.
5. Finish.

On the left you now have a tree: `sqlcamp → Schemas → public → Tables`.
Click any table, then the **Data** tab, and you are looking at a
spreadsheet-like grid of real rows. Open a SQL editor with
`Cmd + ]`, type a query, and run it with `Cmd + Enter`.

**Which one should the student use day to day?** DBeaver for exploring and
for anything with lots of columns. psql for quick checks and for anything
they want to paste into a chat. Both talk to the same database, so nothing
is lost by switching.

---

## Step 7 — Python (not yet — Module 24)

Do **not** install Python at the start of the course. It is a second set of
things that can go wrong, at exactly the moment the student is least able to
tell a SQL problem from a Python problem. When you reach Module 24:

```bash
brew install python@3.12
python3 -m venv ~/sqlcamp-env
source ~/sqlcamp-env/bin/activate
pip install pandas numpy numpy-financial matplotlib openpyxl psycopg2-binary jupyterlab
jupyter lab
```

A browser tab opens. That is the notebook environment — think of it as a
worksheet where each cell can run code and show a chart underneath.

---

## Excel

Use whatever the student already has. Microsoft 365 desktop Excel for Mac is
ideal. Two settings to change on day one of Part 2:

* **Excel → Settings → Formulas → uncheck "Use R1C1 reference style"** if it
  is on (it will confuse every tutorial they read).
* **Excel → Settings → Calculation → tick "Use iterative calculation"**, max
  iterations 100. Module 15 needs this, because a three-statement model with
  an interest-on-average-debt formula genuinely refers to itself.

If they only have Google Sheets, most of Part 2 still works, but the LBO and
the data-table sensitivity work in Module 18 and 20 will be painful. Say so
early so they can arrange access rather than discovering it in week 12.

---

## Troubleshooting

| What you see | What it means | Fix |
|---|---|---|
| `command not found: brew` | Homebrew is not on your PATH | Re-run the two `echo` lines Homebrew printed, then `source ~/.zprofile` |
| `command not found: psql` | PostgreSQL installed but not on your PATH | Re-run the `export PATH` line in Step 3, then `source ~/.zshrc` |
| `connection refused` / `could not connect to server` | Server is not running | `brew services start postgresql@16` |
| `database "sqlcamp" does not exist` | Setup did not finish | Re-run `setup_db.sh` and read the first error, not the last |
| `role "yourname" does not exist` | Postgres has no user matching your Mac account | `createuser -s $(whoami)` then try again |
| `psql: FATAL: role "postgres" does not exist` | You typed `-U postgres`; on Homebrew Postgres your user is your Mac username | Drop the `-U postgres` part |
| Prompt is stuck at `sqlcamp-#` | Missing semicolon | Type `;` and press Enter |
| Query never finishes | Usually a join that has gone wrong | `Ctrl + C` to cancel. Then count the rows before joining. |
| `permission denied` running setup_db.sh | Script is not marked executable | `chmod +x .claude/skills/financial-analyst-bootcamp/scripts/setup_db.sh` |
| DBeaver: `FATAL: password authentication failed` | Wrong username | Use the output of `whoami`, blank password |

**How to help when none of these match:** ask for the *entire* error message,
not a summary. Postgres error messages are unusually good — they normally
name the line and the column. Teaching the student to read them is itself a
Module 0 objective, because a person who can read an error message is
independent, and a person who cannot will be blocked forever.
