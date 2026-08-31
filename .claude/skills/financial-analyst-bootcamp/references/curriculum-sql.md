# Part 1 — SQL for finance (Modules 0–12)

Teach one module per one or two sessions. Each module below gives you: the
objective, the finance framing to open with, the concepts in teaching order,
a worked example on the real database, the trap to demonstrate deliberately,
and homework with an answer key.

**Run every query before you show it.** Queries marked
`-- BROKEN ON PURPOSE` are meant to fail — show the error, do not fix it
silently.

Contents:

- [Module 0 — What a database is](#module-0)
- [Module 1 — Reading a table](#module-1)
- [Module 2 — Calculations and data types](#module-2)
- [Module 3 — Aggregation](#module-3)
- [Module 4 — Dates and the fiscal calendar](#module-4)  ← *Unit Test 1 after this*
- [Module 5 — Joining tables](#module-5)
- [Module 6 — CASE WHEN and pivoting](#module-6)
- [Module 7 — Subqueries and CTEs](#module-7)
- [Module 8 — Window functions](#module-8)  ← *Unit Test 2 after this*
- [Module 9 — Set operations and reconciliation](#module-9)
- [Module 10 — Changing data safely](#module-10)
- [Module 11 — Performance](#module-11)
- [Module 12 — Data quality and data modelling](#module-12)  ← *Unit Test 3 + Midterm after this*

---

<a name="module-0"></a>
## Module 0 — What a database is, and getting set up

**Objective.** The student can install PostgreSQL, connect, list tables, and
run one query — and can say in their own words what a table, a row, a column
and a key are.

**Open with this.** "You already use a database every day. Your accounting
system is one. When you run a P&L in Tally or SAP or NetSuite, something is
storing millions of journal lines and answering your question in two seconds.
That something is a database. Today you get your own, and you learn to ask it
questions directly instead of waiting for someone to export you a CSV."

**Why this matters commercially.** The single most common complaint about
junior analysts is that they cannot get their own data. Someone who can pull
their own extract on a Friday afternoon is worth more than someone who files
a request and waits until Tuesday.

**Concepts, in order.**

1. Table = worksheet, row = record, column = field.
2. Every table has a **grain**: what one row means. `fact_price` is one
   company on one day. `gl_journal_line` is one line of one journal entry.
   Ask this question about every table, forever.
3. **Primary key**: the column that uniquely identifies a row. Invoice number.
4. **Foreign key**: a column that points at another table's key. The customer
   code on an invoice.
5. SQL is not a programming language in the way people fear. It is a way of
   describing *what you want*, not *how to get it*.

**Do this together.** Walk `references/setup-macos.md` step by step. Then:

```sql
\dt
\d dim_company
SELECT ticker, company_name, sector FROM dim_company ORDER BY sector;
```

Then open `assets/dataset/README.md` together and have the student state the
grain of five tables out loud. Correct them. This takes ten minutes and pays
for itself for the rest of the course.

**Check yourself.**
1. What is the grain of `saas_invoice`? *(One invoice.)*
2. If `dim_customer` has 900 rows and `saas_invoice` has 8,639, what does
   that tell you about the relationship? *(One customer, many invoices.)*
3. Why does `dim_date` exist when Postgres already understands dates?
   *(Because the fiscal year is April–March and nobody wants to re-derive
   that in fifty queries.)*

---

<a name="module-1"></a>
## Module 1 — Reading a table: SELECT, WHERE, ORDER BY, LIMIT

**Objective.** Pull any extract from a single table, filtered and sorted.

**Open with this.** "This is AutoFilter and Sort. That is genuinely all this
module is. The difference is that it works on sixteen thousand rows without
your laptop fan coming on, and you can send someone the *instruction* instead
of the file."

**Concepts.** `SELECT` (which columns), `FROM` (which table), `WHERE`
(which rows), `ORDER BY` (in what order), `LIMIT` (how many),
`DISTINCT` (unique values), column aliases with `AS`.

**The shape of every query.** Teach this as a fixed skeleton and have them
write it out by hand once:

```
SELECT    which columns
FROM      which table
WHERE     which rows
GROUP BY  how to bucket them
HAVING    which buckets to keep
ORDER BY  how to sort
LIMIT     how many
```

Clauses always appear in that order. Not every clause is needed, but you can
never put them in a different sequence.

**Worked example.** "Show me the ten biggest single days by traded value for
Kaveri Retail in FY26."

```sql
SELECT price_date, close_px, volume, ROUND(close_px * volume / 1e7, 2) AS turnover_crore
FROM fact_price
WHERE company_id = 1
  AND price_date BETWEEN DATE '2025-04-01' AND DATE '2026-03-31'
ORDER BY close_px * volume DESC
LIMIT 10;
```

Point out three things: `BETWEEN` includes both endpoints; you can sort by a
calculation you did not select; and dividing by `1e7` to get crores is the
kind of unit conversion that should be done once, in the query, not by hand
afterwards.

**Filtering vocabulary.** `=`, `<>`, `>`, `<`, `>=`, `<=`, `AND`, `OR`,
`NOT`, `IN (...)`, `BETWEEN a AND b`, `LIKE '%text%'`, `ILIKE` (case
insensitive), `IS NULL`, `IS NOT NULL`.

**The trap: NULL.**

```sql
-- Which subscriptions have NOT churned? This gives ZERO rows.
SELECT count(*) FROM saas_subscription WHERE end_date = NULL;

-- This is the right way.
SELECT count(*) FROM saas_subscription WHERE end_date IS NULL;
```

Explain why: NULL means "unknown". Asking "is unknown equal to unknown?" does
not give true, it gives unknown, and unknown rows are not returned. This is
the most common silent bug in finance SQL, and it produces an empty report
rather than an error.

**Homework.**
1. List every company in the Materials or Industrials sector, sorted by country then name.
2. How many distinct sectors are there? *(10)*
3. Find every subscription with MRR above ₹50,000 that has already churned.
4. List the 15 largest open invoices, showing customer id, date, amount and how many days past due they were at 30-Jun-2026.
5. Which acquisition channels exist in `dim_customer`? *(6)*

**Answer key, Q4:**

```sql
SELECT invoice_id, customer_id, invoice_date, amount,
       DATE '2026-06-30' - due_date AS days_past_due
FROM saas_invoice
WHERE status = 'Open'
ORDER BY amount DESC
LIMIT 15;
```

---

<a name="module-2"></a>
## Module 2 — Calculations, data types, and why money is never a FLOAT

**Objective.** Compute margins, growth and per-share figures correctly, and
know which type to use for money.

**Open with this.** "Every valuation error I have ever seen came from one of
three things: the wrong denominator, the wrong sign, or a rounding difference
nobody chased. All three live in this module."

**Concepts.** Arithmetic; `ROUND`, `ABS`, `GREATEST`, `LEAST`; `NULLIF` to
avoid division by zero; `COALESCE` to substitute for NULL; `CAST` / `::`;
integer division; the difference between `NUMERIC`, `FLOAT` and `INT`.

**Why money is `NUMERIC`.** Run this in front of them:

```sql
SELECT 0.1::float8 + 0.2::float8   AS float_answer,
       0.1::numeric + 0.2::numeric AS numeric_answer;
```

The float answer is `0.30000000000000004`. Explain: floats store numbers in
binary, and 0.1 in binary is a recurring fraction, exactly like 1/3 in
decimal. Fine for physics, unacceptable for a trial balance that must total
to zero. Every money column in this database is `NUMERIC`. Check any new
database you are handed.

**The integer division trap.**

```sql
SELECT 5 / 2          AS integer_division,   -- 2, not 2.5
       5.0 / 2        AS decimal_division,   -- 2.5
       5::numeric / 2 AS also_decimal;       -- 2.5
```

If both sides of a division are whole numbers, Postgres gives a whole number
answer. A margin calculated this way will read as 0%.

**Worked example.** Quarterly margins for one company:

```sql
SELECT period_end,
       revenue,
       ROUND(gross_profit / NULLIF(revenue, 0) * 100, 1) AS gross_margin_pct,
       ROUND(ebitda       / NULLIF(revenue, 0) * 100, 1) AS ebitda_margin_pct,
       ROUND(net_income   / NULLIF(revenue, 0) * 100, 1) AS net_margin_pct
FROM fs_income_statement
WHERE company_id = 7
ORDER BY period_end;
```

`NULLIF(revenue, 0)` turns a zero denominator into NULL, so the answer comes
back blank instead of crashing the whole query. In a report of 200 companies,
one shell company with zero revenue should not take the report down.

**Percentages vs basis points.** 1% = 100 bps. Margin moving from 24.1% to
24.6% is "up 50 basis points", not "up 2%". Both appear in real reports and
mixing them up in a meeting is memorable for the wrong reasons.

**Homework.**
1. For each company's FY26-Q4 quarter (period_end 2026-03-31), show revenue, EBITDA margin and net margin, sorted by EBITDA margin descending.
2. Compute EPS yourself from `net_income` and `shares_diluted_m` and check it matches the stored `eps_diluted`. Report any company where it differs by more than 0.0001.
3. Express each company's FY26-Q4 gross margin as a change in basis points versus its FY25-Q4 gross margin. *(This one needs two rows of the same table — if they reach for a join, that is a good sign; tell them Module 8 has a nicer way.)*
4. What is `SELECT 7/2*100` and why is it not 350? *(300 — integer division happens first.)*

---

<a name="module-3"></a>
## Module 3 — Aggregation: GROUP BY and HAVING

**Objective.** Build any pivot-table-shaped answer.

**Open with this.** "Drag `sector` into Rows and `revenue` into Values. That
is `GROUP BY sector` with `SUM(revenue)`. You have been writing GROUP BY for
years without the keyboard."

**Concepts.** `COUNT(*)` vs `COUNT(column)` vs `COUNT(DISTINCT column)`;
`SUM`, `AVG`, `MIN`, `MAX`; `GROUP BY` with several columns; `HAVING`;
`ROLLUP` for subtotals; the rule that every selected column must be either
grouped or aggregated.

**The rule, explained rather than asserted.** Once you group, individual rows
are gone. If you ask for `sector, revenue, SUM(revenue)`, the database has
five rows of revenue in the bucket and no way to know which one you meant. So
it refuses. Demonstrate:

```sql
-- BROKEN ON PURPOSE
SELECT sector, revenue, SUM(revenue) FROM fs_income_statement JOIN dim_company USING (company_id) GROUP BY sector;
```

Read the error together. It even names the column.

**Worked example.** FY26 revenue and margin by sector:

```sql
SELECT c.sector,
       count(DISTINCT c.company_id)                             AS companies,
       ROUND(SUM(i.revenue) / 1000, 1)                          AS revenue_bn,
       ROUND(SUM(i.ebitda) / NULLIF(SUM(i.revenue), 0) * 100, 1) AS ebitda_margin_pct
FROM fs_income_statement i
JOIN dim_company c USING (company_id)
WHERE i.period_end BETWEEN DATE '2025-04-01' AND DATE '2026-03-31'
GROUP BY c.sector
HAVING SUM(i.revenue) > 5000
ORDER BY revenue_bn DESC;
```

**The most important line in that query** is the margin. Point at it hard:
`SUM(ebitda) / SUM(revenue)` is **not** the same as `AVG(ebitda/revenue)`.
The first is the margin of the sector; the second is the average of the
companies' margins, which gives a ₹100 crore company the same weight as a
₹10,000 crore one. Both are legitimate numbers answering different questions.
Choosing the wrong one is one of the most common analytical errors in finance,
and it is invisible in the output.

Make them compute both and look at the gap:

```sql
SELECT c.sector,
       ROUND(SUM(i.ebitda) / NULLIF(SUM(i.revenue),0) * 100, 1) AS weighted_margin_pct,
       ROUND(AVG(i.ebitda / NULLIF(i.revenue,0)) * 100, 1)      AS simple_average_pct
FROM fs_income_statement i JOIN dim_company c USING (company_id)
WHERE i.period_end = DATE '2026-03-31'
GROUP BY c.sector ORDER BY 1;
```

**`WHERE` vs `HAVING`.** `WHERE` throws away rows before grouping. `HAVING`
throws away *groups* after. "Only Indian companies" is `WHERE`. "Only sectors
with revenue over X" is `HAVING`.

**Homework.**
1. Total FY26 ledger spend by department, biggest first. *(Watch the sign: expenses are debits.)*
2. Count customers by segment and country, showing only combinations with more than 20 customers.
3. Average invoice value by customer segment. Then: is the average the right statistic here, or is the median? Explain in two sentences.
4. Which five customers have paid the most in total, and how many invoices did each have?
5. For each department, the number of distinct accounts it has posted to in FY26.

**Answer key, Q1:**

```sql
SELECT d.dept_name, ROUND(SUM(l.debit - l.credit)) AS fy26_spend
FROM gl_journal_line l
JOIN dim_account a ON a.account_id = l.account_id
JOIN dim_department d ON d.dept_id = l.dept_id
WHERE l.fiscal_year = 2026 AND a.category IN ('COGS','Opex')
GROUP BY d.dept_name
ORDER BY fy26_spend DESC;
```

---

<a name="module-4"></a>
## Module 4 — Dates, periods and the fiscal calendar

**Objective.** Slice anything by month, quarter, fiscal year, MTD/QTD/YTD,
and compare like-for-like periods.

**Open with this.** "Nearly every finance question is really a date question.
'How are we doing?' means 'versus last month, last quarter, and the same
quarter last year'. Getting periods right is most of the job."

**Concepts.** `DATE` vs `TIMESTAMP`; `DATE_TRUNC('month', d)`; `EXTRACT`;
date arithmetic (`d + 30`, `d2 - d1` gives days); `INTERVAL`;
`AGE`; `TO_CHAR` for formatting; `generate_series` to build a calendar spine;
and above all **using `dim_date` instead of re-deriving the fiscal year**.

**The fiscal year, concretely.** Our year runs April–March. FY26 = 1-Apr-2025
to 31-Mar-2026. So December 2025 is *FY26, fiscal month 9, fiscal quarter 3*.
Make them read that off `dim_date` rather than believe you:

```sql
SELECT date_key, year, month, fiscal_year, fiscal_quarter, fiscal_month, fiscal_period
FROM dim_date
WHERE date_key IN (DATE '2025-03-31', DATE '2025-04-01', DATE '2025-12-31');
```

**Worked example.** Monthly revenue for our own company, FY26:

```sql
SELECT DATE_TRUNC('month', l.entry_date)::date AS month,
       ROUND(SUM(l.credit - l.debit)) AS revenue
FROM gl_journal_line l
JOIN dim_account a ON a.account_id = l.account_id
WHERE a.category = 'Revenue' AND l.fiscal_year = 2026
GROUP BY 1
ORDER BY 1;
```

**The trap: missing months.** If a month has no rows, it does not appear —
and a chart drawn from that result silently joins December to February. The
fix is to start from the calendar and join the data on:

```sql
SELECT m.month,
       COALESCE(ROUND(SUM(l.credit - l.debit)), 0) AS revenue
FROM (SELECT DISTINCT month_start_date AS month FROM dim_date
      WHERE fiscal_year = 2026) m
LEFT JOIN gl_journal_line l
       ON DATE_TRUNC('month', l.entry_date)::date = m.month
LEFT JOIN dim_account a ON a.account_id = l.account_id AND a.category = 'Revenue'
GROUP BY m.month
ORDER BY m.month;
```

This pattern — *calendar first, LEFT JOIN the facts on* — is worth naming and
repeating. It is how every correct time series in every reporting tool is
built. (It uses LEFT JOIN, which is Module 5; introduce it here as a taster
and return to it properly next module.)

**Homework.**
1. Quarterly traded volume for Zenith Telecom by fiscal quarter for FY25 and FY26.
2. How many days is our average invoice outstanding before payment? *(Join invoices to payments; this is DSO in disguise.)*
3. Which calendar month has the highest ledger spend across all years, and does that survive when you look at it per fiscal year?
4. Build the FY26 calendar spine with all 12 fiscal months and show marketing spend against each, with zeros where there was none.
5. Find every weekday between Apr-2023 and Jun-2026 with no price row for any company. *(There should be none — this is how you would detect a data gap in a real feed.)*

---

<a name="module-5"></a>
## Module 5 — Joining tables

**Objective.** Combine tables correctly, and know how many rows to expect
before running the query.

**Open with this.** "This is VLOOKUP, and it is where careers get made and
lost. A wrong VLOOKUP returns `#N/A` and you notice. A wrong JOIN returns a
number, and you send it to the board."

**Concepts.** `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL OUTER JOIN`,
`CROSS JOIN`; `ON` vs `USING`; joining on more than one column; table
aliases; self-joins; anti-joins (`LEFT JOIN … WHERE right IS NULL`).

**Teach it as a Venn diagram, then immediately as row counts.** The diagram
explains the idea; the row count is what protects you.

**The discipline: count before and after.** Every single join:

```sql
SELECT count(*) FROM saas_invoice;                       -- 8639
SELECT count(*) FROM saas_invoice i
JOIN dim_customer c USING (customer_id);                 -- 8639, good: nothing lost or gained
```

If the number changes and you did not expect it to, stop. Two causes: the
join key is not unique on the right (fan-out — rows multiply), or some rows
have no match (inner join — rows disappear). Both are silent.

**Fan-out, demonstrated — and this is the money example.** Actual versus
budget is the most common report in corporate finance, and the most commonly
broken. Start with the truthful budget total:

```sql
SELECT ROUND(SUM(budget_amount)) AS fy26_budget FROM gl_budget WHERE fiscal_year = 2026;
```

Now join the budget to the ledger on account and year — which looks perfectly
reasonable — and ask for the same budget total again:

```sql
SELECT ROUND(SUM(b.budget_amount)) AS fy26_budget_after_join
FROM gl_budget b
JOIN gl_journal_line l ON l.account_id = b.account_id
                      AND l.fiscal_year = b.fiscal_year
WHERE b.fiscal_year = 2026;
```

The number is now hundreds of times too big. Nothing errored. No warning
appeared. **Each budget row was duplicated once for every matching ledger
line**, and the budget got counted over and over.

This is the defining trap of the whole course, so make them sit with it. The
cause is grain: the budget is one row per month, account and department; the
ledger is one row per transaction. Joining them puts many ledger rows against
each budget row. The fix is to aggregate each side to a common grain *first*,
then join:

```sql
WITH actual AS (
    SELECT fiscal_year, fiscal_month, account_id, dept_id,
           SUM(debit - credit) AS actual_amount
    FROM gl_journal_line
    WHERE fiscal_year = 2026
    GROUP BY 1,2,3,4
),
budget AS (
    SELECT fiscal_year, fiscal_month, account_id, dept_id,
           SUM(budget_amount) AS budget_amount
    FROM gl_budget
    WHERE fiscal_year = 2026
    GROUP BY 1,2,3,4
)
SELECT ROUND(SUM(a.actual_amount)) AS actual,
       ROUND(SUM(b.budget_amount)) AS budget
FROM budget b
LEFT JOIN actual a USING (fiscal_year, fiscal_month, account_id, dept_id);
```

Now the budget total matches the first query. Say the rule out loud:
**aggregate to a common grain, then join. Never join and then aggregate,
unless you have proved the join key is unique on one side.**

Proving uniqueness takes one query and takes ten seconds:

```sql
SELECT count(*) AS duplicate_keys
FROM (SELECT customer_id FROM saas_subscription GROUP BY 1 HAVING count(*) > 1) z;
```

Teach the habit: **before joining on a key, prove the key is unique on the
side you are joining to.** That one habit prevents most fan-out disasters.

**Anti-join: the "who is missing?" question.** This is enormously useful and
under-taught:

```sql
-- Customers who have never been invoiced
SELECT c.customer_id, c.customer_name, c.segment
FROM dim_customer c
LEFT JOIN saas_invoice i ON i.customer_id = c.customer_id
WHERE i.invoice_id IS NULL;
```

Every reconciliation you will ever do is some version of this.

**Homework.**
1. FY26 actual vs budget by department: one row per department, three columns (actual, budget, variance). *(Needs `gl_journal_line`, `gl_budget`, `dim_department`, `dim_account`. Warn them about grain — the budget is monthly, the ledger is per transaction.)*
2. Every company with its FY26-Q4 revenue and its closing share price on 31-Mar-2026.
3. Which of the 20 companies have no trades in any portfolio?
4. For each portfolio at 31-Mar-2026: holdings, market value using that day's close, and cost basis.
5. Deliberately write the actual-vs-budget query with an INNER JOIN and explain, in one sentence, which departments vanish and why.

---

<a name="module-6"></a>
## Module 6 — CASE WHEN, conditional aggregation and pivoting

**Objective.** Turn rows into columns; bucket continuous values; build an
ageing report.

**Open with this.** "`CASE WHEN` is `IF()`. Conditional aggregation is
`SUMIFS`. Those two ideas together will produce most of the management
reports you have ever seen."

**Concepts.** `CASE WHEN … THEN … ELSE … END`; using CASE inside `SUM` to
pivot; `FILTER (WHERE …)` as the tidier Postgres way; bucketing with CASE;
`COALESCE` as shorthand for a simple CASE.

**The pattern that unlocks management reporting:**

```sql
SELECT d.dept_name,
       ROUND(SUM(l.debit - l.credit) FILTER (WHERE l.fiscal_year = 2025)) AS fy25,
       ROUND(SUM(l.debit - l.credit) FILTER (WHERE l.fiscal_year = 2026)) AS fy26
FROM gl_journal_line l
JOIN dim_account a ON a.account_id = l.account_id
JOIN dim_department d ON d.dept_id = l.dept_id
WHERE a.category IN ('COGS','Opex')
GROUP BY d.dept_name
ORDER BY fy26 DESC;
```

Explain what just happened: one pass over the ledger produced two columns.
The alternative — two queries and a manual paste — is how errors get in.

The same thing written with CASE, which they will see everywhere and must be
able to read:

```sql
SELECT d.dept_name,
       ROUND(SUM(CASE WHEN l.fiscal_year = 2025 THEN l.debit - l.credit ELSE 0 END)) AS fy25,
       ROUND(SUM(CASE WHEN l.fiscal_year = 2026 THEN l.debit - l.credit ELSE 0 END)) AS fy26
FROM gl_journal_line l
JOIN dim_account a ON a.account_id = l.account_id
JOIN dim_department d ON d.dept_id = l.dept_id
WHERE a.category IN ('COGS','Opex')
GROUP BY d.dept_name ORDER BY fy26 DESC;
```

**Worked example: the receivables ageing report.** This is a genuine
deliverable that a treasury or FP&A team produces every single month.

```sql
SELECT CASE WHEN DATE '2026-06-30' - due_date <= 0  THEN '1. Not yet due'
            WHEN DATE '2026-06-30' - due_date <= 30 THEN '2. 1-30 days'
            WHEN DATE '2026-06-30' - due_date <= 60 THEN '3. 31-60 days'
            WHEN DATE '2026-06-30' - due_date <= 90 THEN '4. 61-90 days'
            ELSE '5. 90+ days' END AS ageing_bucket,
       count(*)          AS invoices,
       ROUND(SUM(amount)) AS amount
FROM saas_invoice
WHERE status = 'Open'
GROUP BY 1
ORDER BY 1;
```

**The trap: CASE order matters.** CASE stops at the first match. If the 90+
line were written first, every overdue invoice would land in it. Show that by
reordering the branches and watching the report change.

**Homework.**
1. Revenue by plan and billing term as a pivot: plans down the side, Monthly and Annual as columns.
2. Bucket the 20 companies into Large / Mid / Small by FY26 revenue, with your own thresholds, and count each bucket.
3. A monthly FY26 opex report: months down the side, one column per expense category.
4. Rebuild the ageing report but by customer segment as well as bucket.
5. Which is safer for a report someone else will maintain, `FILTER` or `CASE`? Argue it in three sentences. *(There is no single right answer; the reasoning is what is marked.)*

---

<a name="module-7"></a>
## Module 7 — Subqueries and CTEs

**Objective.** Break a hard question into named, checkable steps.

**Open with this.** "Nobody builds a DCF in one cell. You have a revenue tab,
a cost tab, a working capital tab, and then the output. A CTE is a tab."

**Concepts.** Scalar subqueries; `IN` / `NOT IN` / `EXISTS` / `NOT EXISTS`;
subqueries in `FROM`; `WITH name AS (...)` — the CTE; chaining several CTEs;
why `NOT IN` with NULLs is dangerous.

**The style rule.** Prefer CTEs over nested subqueries, always. Not because
they are faster — usually they are the same — but because a query someone
else can read is a query someone else can check. In finance, unreviewable
work is worthless.

**Worked example.** "Which customers spend more than twice their segment's
average?" Built in layers:

```sql
WITH customer_spend AS (
    SELECT c.customer_id, c.customer_name, c.segment,
           SUM(i.amount) AS total_billed
    FROM dim_customer c
    JOIN saas_invoice i ON i.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
),
segment_average AS (
    SELECT segment, AVG(total_billed) AS avg_billed
    FROM customer_spend
    GROUP BY segment
)
SELECT s.customer_name, s.segment,
       ROUND(s.total_billed)                       AS total_billed,
       ROUND(a.avg_billed)                         AS segment_average,
       ROUND(s.total_billed / a.avg_billed, 2)     AS times_average
FROM customer_spend s
JOIN segment_average a USING (segment)
WHERE s.total_billed > 2 * a.avg_billed
ORDER BY times_average DESC;
```

**Teach them to debug it.** Run just the first CTE by itself
(`SELECT * FROM customer_spend` with the rest deleted) and check the row
count is 900-ish. Then add the second. A twelve-line query built and checked
in three steps is safer than a twelve-line query written in one go, exactly
like a model built one tab at a time.

**The `NOT IN` trap.** If the subquery returns even one NULL, `NOT IN`
returns nothing at all — silently:

```sql
-- Returns 0 rows, because at least one end_date is NULL
SELECT count(*) FROM dim_customer
WHERE customer_id NOT IN (SELECT customer_id FROM saas_subscription WHERE end_date IS NULL OR TRUE);
```

Use `NOT EXISTS` or a LEFT JOIN anti-join instead. Both are immune.

**Homework.**
1. For each sector, the company with the highest FY26 revenue.
2. Customers who have an open invoice but have never had one written off.
3. Companies whose FY26 EBITDA margin is above the all-company median.
4. Rewrite homework 2 three ways — `NOT IN`, `NOT EXISTS`, LEFT JOIN anti-join — and say which you would submit for review, and why.

---

<a name="module-8"></a>
## Module 8 — Window functions

**Objective.** Growth rates, running totals, rankings and moving averages
without leaving SQL. This is the module that changes what the student can do.

**Open with this.** "Everything you do in Excel by dragging a formula down a
column — growth versus last month, running cash balance, rank in the league
table, three-month moving average — is a window function. This is the single
most valuable thing in this course, and it is what separates 'can write SQL'
from 'can do analysis in SQL' on a CV."

**Concepts.** `OVER (PARTITION BY … ORDER BY …)`; `LAG` and `LEAD`;
`SUM/AVG … OVER` for running and moving figures; frames
(`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`); `ROW_NUMBER`, `RANK`,
`DENSE_RANK`; `NTILE` for quartiles; `FIRST_VALUE` / `LAST_VALUE`.

**The mental model.** An aggregate collapses the bucket to one row. A window
function keeps every row and *adds a column* computed over a group of rows.
`PARTITION BY` says which rows are in the group; `ORDER BY` says in what
order, which is what makes "the previous row" meaningful.

**Worked example 1: growth rates.**

```sql
SELECT period_end,
       revenue,
       LAG(revenue)   OVER w                                                    AS prior_quarter,
       ROUND((revenue / NULLIF(LAG(revenue)   OVER w, 0) - 1) * 100, 1)         AS qoq_pct,
       LAG(revenue, 4) OVER w                                                   AS same_quarter_last_year,
       ROUND((revenue / NULLIF(LAG(revenue, 4) OVER w, 0) - 1) * 100, 1)        AS yoy_pct
FROM fs_income_statement
WHERE company_id = 7
WINDOW w AS (ORDER BY period_end)
ORDER BY period_end;
```

The `LAG(revenue, 4)` is the moment to stop and make sure they see it: four
quarters back is the same quarter last year, which strips out seasonality.
Quarter-on-quarter growth in a seasonal business is close to meaningless on
its own, and reporting it without the year-on-year number beside it is how
analysts get embarrassed.

**Worked example 2: running total (a cash balance).**

```sql
SELECT month, monthly_net,
       SUM(monthly_net) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) AS cumulative
FROM (
    SELECT DATE_TRUNC('month', l.entry_date)::date AS month,
           SUM(l.credit - l.debit)                 AS monthly_net
    FROM gl_journal_line l
    JOIN dim_account a ON a.account_id = l.account_id
    WHERE a.statement = 'IS' AND l.fiscal_year = 2026
    GROUP BY 1
) m
ORDER BY month;
```

**Worked example 3: ranking within a group.**

```sql
SELECT sector, ticker, revenue, rank_in_sector
FROM (
    SELECT c.sector, c.ticker, i.revenue,
           RANK() OVER (PARTITION BY c.sector ORDER BY i.revenue DESC) AS rank_in_sector
    FROM fs_income_statement i
    JOIN dim_company c USING (company_id)
    WHERE i.period_end = DATE '2026-03-31'
) r
WHERE rank_in_sector <= 2
ORDER BY sector, rank_in_sector;
```

**Why the subquery?** You cannot filter on a window function in `WHERE` —
the window is computed after `WHERE` runs. This surprises everyone once.
Explain the order of operations rather than just stating the rule.

**Worked example 4: a 20-day moving average, the classic market analytic.**

```sql
SELECT price_date, close_px,
       ROUND(AVG(close_px) OVER (ORDER BY price_date
                                 ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2) AS ma20
FROM fact_price
WHERE company_id = 1
ORDER BY price_date DESC
LIMIT 15;
```

Note that the earliest 19 rows average fewer than 20 days. Whether that is
acceptable or should be blanked out is a judgement call — ask them to make it
and defend it.

**Homework.**
1. Month-on-month and year-on-year growth in our own company's ledger revenue for FY26.
2. Each company's FY26-Q4 revenue, its rank overall, and its rank within its sector.
3. A running cumulative total of paid invoice cash collected during FY26 by month.
4. For Kaveri Retail: 20-day and 50-day moving averages, plus a flag for each day where the 20-day crosses above the 50-day.
5. Split the 900 customers into quartiles by total billings and show each quartile's customer count, total billings, and share of the whole. *(Then answer in a sentence: what does this say about customer concentration risk?)*

---

<a name="module-9"></a>
## Module 9 — Set operations and reconciliation

**Objective.** Answer "why don't these two reports agree?" — which is, in
practice, a third of a finance analyst's working life.

**Concepts.** `UNION` vs `UNION ALL` (and why `UNION ALL` is usually what you
want); `INTERSECT`; `EXCEPT`; building a reconciliation as a full outer join
with a difference column; control totals.

**Worked example: a tie-out.** Does ledger revenue for FY26 agree with the
sum of invoices raised in FY26?

```sql
WITH ledger AS (
    SELECT ROUND(SUM(l.credit - l.debit)) AS amount
    FROM gl_journal_line l JOIN dim_account a ON a.account_id = l.account_id
    WHERE a.category = 'Revenue' AND l.fiscal_year = 2026
),
billings AS (
    SELECT ROUND(SUM(amount)) AS amount
    FROM saas_invoice
    WHERE invoice_date BETWEEN DATE '2025-04-01' AND DATE '2026-03-31'
)
SELECT (SELECT amount FROM ledger)   AS ledger_revenue,
       (SELECT amount FROM billings) AS invoiced,
       (SELECT amount FROM ledger) - (SELECT amount FROM billings) AS difference;
```

They will not agree. **That is the lesson.** Two systems built for different
purposes rarely agree, and the analyst's job is not to make the difference
disappear but to *explain* it: different populations, timing, revenue
recognised versus billed, deferred revenue, credit notes, intercompany. Have
them write three sentences explaining plausible reasons, then check which
ones they can actually evidence from the data. Being able to say "the gap is
₹X and here is what it consists of" is a senior-analyst skill.

**Worked example: a row-level reconciliation.**

```sql
SELECT COALESCE(a.invoice_id, b.invoice_id) AS invoice_id,
       a.amount AS invoiced, b.paid,
       COALESCE(a.amount, 0) - COALESCE(b.paid, 0) AS difference
FROM (SELECT invoice_id, amount FROM saas_invoice WHERE status = 'Paid') a
FULL OUTER JOIN (SELECT invoice_id, SUM(amount) AS paid FROM saas_payment GROUP BY 1) b
  ON a.invoice_id = b.invoice_id
WHERE COALESCE(a.amount, 0) <> COALESCE(b.paid, 0)
ORDER BY ABS(COALESCE(a.amount,0) - COALESCE(b.paid,0)) DESC;
```

This pattern — full outer join, coalesce the key, show the difference, filter
to non-zero — is the universal shape of a reconciliation. Have them keep it.

**Homework.**
1. Which companies appear in `fs_income_statement` but have no price rows, or vice versa? Use `EXCEPT` both ways.
2. Reconcile total FY26 opex from the ledger against total FY26 budget, by department, showing variance in both rupees and percent.
3. Reconcile portfolio holdings at 31-Mar-2026 against the cumulative sum of trades up to that date. They should agree exactly; prove it.
4. Explain the difference between `UNION` and `UNION ALL` and give a finance example where using the wrong one loses real rows. *(Two legitimate journal lines with identical amounts on the same day.)*

---

<a name="module-10"></a>
## Module 10 — Changing data safely

**Objective.** Create tables and views, insert and update data, and use
transactions — without ever being the person who broke production.

**Open with this.** "Up to now you have been reading. Now you can write, and
writing is how people get fired. There is one habit that prevents almost all
of it, and we are going to build it today."

**The habit.** Before any `UPDATE` or `DELETE`, run it as a `SELECT` first:

```sql
-- 1. Look at exactly the rows you are about to change
SELECT * FROM saas_invoice WHERE status = 'Open' AND invoice_date < DATE '2025-01-01';
-- 2. Only then, change them
BEGIN;
UPDATE saas_invoice SET status = 'Written Off'
WHERE status = 'Open' AND invoice_date < DATE '2025-01-01';
-- 3. Check the count, and that it matches step 1
SELECT count(*) FROM saas_invoice WHERE status = 'Written Off';
-- 4. Happy? COMMIT;   Not happy? ROLLBACK;
ROLLBACK;
```

**Concepts.** `CREATE TABLE`; `CREATE TABLE AS SELECT`; `INSERT`; `UPDATE`
with `FROM`; `DELETE`; `TRUNCATE`; `BEGIN` / `COMMIT` / `ROLLBACK`; views;
materialised views and when to refresh them; `CREATE OR REPLACE VIEW`.

**Transactions, in their language.** A transaction is the unsaved state of a
workbook. Nothing you do is visible to anyone else, and you can close without
saving. `COMMIT` is Save. `ROLLBACK` is Close Without Saving. The reason it
matters in finance: a journal has two sides, and a crash between them would
leave a ledger that does not balance. A transaction makes both sides land or
neither.

**Views.** A view is a saved query, not a copy of the data. Build one the
student will genuinely reuse:

```sql
CREATE OR REPLACE VIEW v_monthly_pl AS
SELECT l.fiscal_year, l.fiscal_month, a.category, a.subcategory,
       d.dept_name,
       SUM(l.debit - l.credit) AS net_amount
FROM gl_journal_line l
JOIN dim_account a    ON a.account_id = l.account_id
JOIN dim_department d ON d.dept_id = l.dept_id
WHERE a.statement = 'IS'
GROUP BY 1,2,3,4,5;

SELECT * FROM v_monthly_pl WHERE fiscal_year = 2026 AND category = 'Revenue' ORDER BY fiscal_month;
```

Sign convention: expenses are debits, revenue is credits, so `debit - credit`
makes costs positive and revenue negative. Decide a convention, write it in a
comment at the top of the view, and never change it silently. Half of all
management-reporting confusion is unwritten sign conventions.

**Homework.**
1. Create a table `my_watchlist` with a ticker, a target price, and a note. Insert five companies. Update one target. Delete one row. Do it all inside a transaction and roll it back, then do it again and commit.
2. Build a view `v_ar_ageing` that reproduces the Module 6 ageing report for any as-of date supplied as a filter.
3. Write an UPDATE you then deliberately roll back, and prove with a SELECT that nothing changed.
4. In two sentences: why is `DELETE FROM saas_invoice;` without a WHERE clause the most expensive keystroke in this course?

**Safety note for you as tutor.** Encourage experimentation here, and remind
them that `setup_db.sh --reset` rebuilds everything in a minute. A student
who is frightened of breaking the database will never learn to write to one.

---

<a name="module-11"></a>
## Module 11 — Performance: indexes and query plans

**Objective.** Know why a query is slow and what to do about it. Not a deep
dive — enough to be self-sufficient and to not annoy a data team.

**Open with this.** "You do not need to be a database engineer. You need to
know why the query that took two seconds yesterday takes four minutes today,
and be able to say something more useful than 'it's slow'."

**Concepts.** `EXPLAIN` and `EXPLAIN ANALYZE`; sequential scan vs index scan;
what an index is and what it costs; why an index on a low-cardinality column
rarely helps; why functions on the left of a comparison defeat indexes;
`\timing`.

**What an index is.** The index at the back of a textbook. Without it you
read every page. With it you jump straight there. The cost: the index has to
be rebuilt every time the book changes, so a table written to constantly does
not want twenty of them.

**Demonstrate.**

```sql
\timing on
EXPLAIN ANALYZE SELECT * FROM fact_price WHERE price_date = DATE '2025-06-16';
EXPLAIN ANALYZE SELECT * FROM fact_price WHERE close_px > 400;
```

The first uses `idx_price_date`; the second scans everything because there is
no index on `close_px`. Have them read the two plans and find the words
"Index Scan" and "Seq Scan", and the actual timings.

**The classic mistake:**

```sql
-- Cannot use the index: the column is wrapped in a function
EXPLAIN SELECT * FROM fact_price WHERE EXTRACT(YEAR FROM price_date) = 2025;
-- Can use the index: the column is left alone
EXPLAIN SELECT * FROM fact_price WHERE price_date >= DATE '2025-01-01' AND price_date < DATE '2026-01-01';
```

Same answer, very different plan. The rule: keep the column bare on the left
of the comparison and do the arithmetic on the right.

**Homework.**
1. Time a query over `gl_journal_line` filtered by `entry_date`, then add an index on `entry_date` and time it again. Report both numbers.
2. Find a query in your own homework that runs slowly and explain its plan.
3. Explain in three sentences why we should not simply index every column.

---

<a name="module-12"></a>
## Module 12 — Data quality and how analytics data is modelled

**Objective.** Clean a genuinely dirty table with SQL, and understand the way
a data team lays out a warehouse — so the student can talk to one.

**Part A — cleaning the landfill.**

`raw_vendor_invoices` has 40 rows and roughly a dozen distinct problems. Set
this as a real task with a real deliverable: *"Produce one clean row per
genuine vendor invoice, with a proper date, a numeric amount in rupees, and a
standardised vendor name. Tell me how many rows you dropped and why."*

Techniques they will need: `TRIM`, `UPPER` / `LOWER` / `INITCAP`,
`REPLACE`, `REGEXP_REPLACE`, `TO_DATE`, safe casting, `COALESCE`,
`ROW_NUMBER()` to de-duplicate, `DISTINCT ON`, and joining to
`fact_fx_rate` for the dollar invoices.

A worked fragment to get them moving — the amount column alone:

```sql
SELECT row_id, amount_text,
       CASE
         WHEN amount_text IS NULL                       THEN NULL
         WHEN amount_text !~ '[0-9]'                    THEN NULL   -- the word "pending"
         WHEN amount_text LIKE '(%)'                    THEN
              -1 * REPLACE(REPLACE(REPLACE(amount_text,'(',''),')',''),',','')::numeric
         ELSE REGEXP_REPLACE(amount_text, '[^0-9.\-]', '', 'g')::numeric
       END AS amount_clean
FROM raw_vendor_invoices
ORDER BY row_id;
```

Walk through the branches one at a time. Then hand them the dates and the
vendor names to do alone. Insist they *report* their cleaning decisions —
"I treated brackets as negative, I dropped row 31 as intercompany, I could
not resolve row 17 and excluded it, worth ₹0" — because in a real job the
decisions matter more than the SQL, and an undocumented cleaning rule is an
audit finding.

**Deduplication, the reusable pattern:**

```sql
SELECT *
FROM (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY UPPER(TRIM(vendor_name)), invoice_ref
                              ORDER BY row_id) AS rn
    FROM raw_vendor_invoices r
) z
WHERE rn = 1;
```

Discuss what makes two rows "the same invoice" — is it vendor + reference, or
vendor + date + amount? Rows 5, 6 and 7 in the data are designed so that the
wrong choice deletes a genuine invoice. Make them find it.

**Part B — how a warehouse is laid out.**

Concepts, all with the finance parallel:

* **Fact and dimension tables.** Journal lines are facts; the chart of
  accounts and cost centres are dimensions. Facts are long and thin and grow
  forever; dimensions are short and wide and describe.
* **Star schema.** One fact table surrounded by its dimensions. This is why
  our tables are named the way they are.
* **Grain.** Say it again: what does one row mean? Most warehouse bugs are
  two tables joined at different grains.
* **Slowly changing dimensions.** A customer moves from SMB to Enterprise.
  Do last year's reports change? Type 1 overwrites (history changes); Type 2
  keeps both rows with valid-from/valid-to dates (history is preserved). In
  finance you almost always want Type 2, and you should say so when asked.
* **Staging → intermediate → marts.** Raw data lands, gets cleaned, gets
  combined, gets shaped for reporting. Exactly like a model: input tabs,
  calculation tabs, output tabs. Never format the input tab.
* **Idempotency.** Re-running the month-end load must not double the numbers.
  The usual pattern is delete-then-insert for the period being loaded.
* **What dbt is, in one paragraph.** A tool that lets a team keep all of
  those SELECT statements in version control, run them in order, and test
  them. Worth naming so the student is not blank in an interview.
* **Tests worth writing.** Row counts, uniqueness of keys, no unexpected
  NULLs, control totals against a source, referential integrity.

**Homework.**
1. Deliver the cleaned vendor invoice table with a short written note on every judgement you made.
2. Write five data-quality tests as SQL that each return zero rows when the data is healthy — one uniqueness test, one not-null test, one referential-integrity test, one control total, one business-rule test of your own design.
3. Draw the star schema of the `saas_*` and `dim_customer` tables on paper and state the grain of each.
4. Our ledger and Meridian's reported statements do not reconcile. Write down five reasons why two such sources genuinely differ in real companies.

---

## After Module 12

Run **Unit Test 3** and then the **Midterm exam** (both in
`references/assessment-bank.md`), followed by the SQL mock interview in
`references/capstones-and-jobs.md`. Do not start Part 2 until the midterm is
passed at 70% — the modelling work assumes fluent SQL, and carrying a weak
foundation forward is how students end up unable to do either half well.
