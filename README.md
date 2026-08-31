# SQL Camp — a job-ready course in SQL and financial modelling

A complete vocational course for someone with a **finance background and no
technical training**, taking them from "I have never opened a database" to
"I can pull my own data, build a model, and defend a recommendation".

It is packaged as a Claude Code skill, so you learn by talking to a tutor
that has the whole curriculum, the practice database and the mark schemes
loaded — not by reading a textbook alone.

## What is in here

```
.claude/skills/financial-analyst-bootcamp/
├── SKILL.md                          the tutor's operating manual
├── references/
│   ├── setup-macos.md                installing PostgreSQL, DBeaver, Python
│   ├── teaching-playbook.md          how to explain this to a non-technical person
│   ├── curriculum-sql.md             Part 1: Modules 0-12
│   ├── curriculum-modelling.md       Part 2: Modules 13-24
│   ├── assessment-bank.md            quizzes, unit tests, midterm, final, rubrics
│   ├── capstones-and-jobs.md         projects, portfolio, mock interviews
│   └── glossary.md                   plain-English definitions
├── assets/
│   ├── dataset/                      the practice database (schema + data + health check)
│   └── templates/                    progress tracker, model build checklist
└── scripts/setup_db.sh               one command to build the database
```

## Getting started

**1. Install PostgreSQL** (macOS):

```bash
brew install postgresql@16
brew services start postgresql@16
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Full walkthrough, including what to do when it goes wrong:
[`references/setup-macos.md`](.claude/skills/financial-analyst-bootcamp/references/setup-macos.md)

**2. Build the practice database:**

```bash
./.claude/skills/financial-analyst-bootcamp/scripts/setup_db.sh
```

Every line of the health check must say `PASS`.

**3. Start learning.** Open Claude Code in this folder and say:

> Teach me Module 0.

or `quiz me on joins`, or `check this query`, or `set me the midterm`.

## The course

**Part 1 — SQL for finance (Modules 0–12).** Reading tables, calculations and
data types, aggregation, the fiscal calendar, joins, pivoting, CTEs, window
functions, reconciliation, writing data safely, performance, data quality and
warehouse modelling.

**Part 2 — Financial modelling (Modules 13–24).** Accounting for modellers,
Excel discipline, the three-statement model, forecasting, time value of money,
DCF, comps, LBO, M&A accretion/dilution, credit analysis, FP&A and variance
analysis, unit economics, scenarios and Python.

Assessment runs throughout: check-yourself questions every lesson, a quiz
every module, six timed unit tests, a midterm and a final exam, four capstone
projects and three mock interviews. Pass mark is 70%.

Roughly 20 weeks at two 90-minute sessions a week, plus homework.

## The practice database

About 50,000 rows across 20 tables: 20 fictional listed companies with three
years of quarterly financial statements and daily prices, a full general
ledger and budget for one of them, 900 subscription customers with invoices
and payments, three investment portfolios, and one deliberately filthy vendor
extract to clean.

Three things make it unusual as teaching data:

* **The three statements genuinely tie.** The balance sheet balances and the
  cash flow reconciles in every one of the 240 company-quarters, because the
  data was generated the way a real three-statement model is built.
* **It is deterministic.** The same numbers appear on every machine, so answer
  keys can be exact.
* **The flaws are deliberate.** Missing market holidays, three planted cost
  anomalies, sources that do not reconcile, and a vendor table containing
  every data-quality sin at once.

Data dictionary:
[`assets/dataset/README.md`](.claude/skills/financial-analyst-bootcamp/assets/dataset/README.md)

Everything in it is **fictional**. No real company, customer or price appears
anywhere, which means you can publish your work freely.
