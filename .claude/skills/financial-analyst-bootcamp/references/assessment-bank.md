# Assessment bank

Questions, papers, mark schemes and rubrics. Also — importantly — the rules
for *generating fresh questions*, because a student who resits the same paper
has learned the paper, not the subject.

Contents:
- [How to mark](#marking)
- [Check-yourself questions by module](#checks)
- [Module quizzes](#quizzes)
- [Unit tests](#unittests)
- [Midterm exam (after Module 12)](#midterm)
- [Final exam (after Module 24)](#final)
- [Rubrics](#rubrics)
- [Generating fresh questions](#fresh)

---

<a name="marking"></a>
## How to mark

**A query is correct when it returns the right answer for the right reason.**
A query that happens to give the right number on this data but would break on
a NULL, a duplicate, or next month's data is not correct. Say so, show the
input that would break it, and give partial credit only where the *reasoning*
was sound.

Mark against four things, and tell the student which one cost them the marks:

| Dimension | What you are looking for |
|---|---|
| **Correctness** | Right number, and right for the right reason |
| **Robustness** | Survives NULLs, duplicates, empty periods, division by zero |
| **Readability** | Someone else could review it. CTEs over nesting, sensible aliases, comments where the business logic is not obvious |
| **Communication** | Can they say what the number means, what it excludes, and what they are unsure about? |

Correctness and robustness carry most of the marks in Part 1. Communication
carries more in Part 2, because a model nobody understands is worthless
regardless of whether it balances.

**Grade bands.**

| Score | Meaning | What to do |
|---|---|---|
| 90–100 | Strong. Ready to be given real work on this topic | Move on; add a stretch exercise |
| 70–89 | Pass | Move on, note the weak spots in the recall bank |
| 50–69 | Not yet | Re-teach the specific weak concept, re-test with fresh questions |
| Below 50 | The foundation underneath is missing | Go back a module. Do not push forward |

**Always give the mark, the reason, and the one thing to fix.** Not "6/10" —
"6/10: the joins and the aggregation are right; you lost four marks because
you filtered on `SUM(amount)` in `WHERE` instead of `HAVING`, and because
three departments dropped out when you used an inner join. Fix the join type
first — that is the one that would have sent a wrong number to the CFO."

---

<a name="checks"></a>
## Check-yourself questions by module

Three per module, asked at the end of the lesson, answered out loud, marked
immediately. These test understanding, not recall of syntax.

**M0.** (1) What is the grain of `gl_journal_line`? (2) Why does every journal
have at least two lines? (3) What breaks if a table has no primary key?

**M1.** (1) Why does `WHERE end_date = NULL` return nothing? (2) What order do
rows come back in without `ORDER BY`? (3) `WHERE a AND b OR c` — what does it
actually mean, and why should you write brackets?

**M2.** (1) Why is `SELECT 7/2` equal to 3? (2) When is `AVG(margin)`
misleading? (3) A margin moves from 22.4% to 23.1%. By how many basis points?

**M3.** (1) Difference between `COUNT(*)` and `COUNT(end_date)`? (2) Why can
you not put `SUM(x) > 100` in a `WHERE`? (3) Sector EBITDA margin: is it
`SUM(ebitda)/SUM(revenue)` or `AVG(ebitda/revenue)`, and when would you use
each?

**M4.** (1) December 2025 is which fiscal year, quarter and month for us?
(2) Why does a monthly time series need a calendar table? (3) What is wrong
with `WHERE EXTRACT(YEAR FROM d) = 2025` besides style?

**M5.** (1) Name two ways a join can change your row count. (2) When is
`LEFT JOIN` the only right answer? (3) How do you find rows in A with no match
in B?

**M6.** (1) Why does the order of `CASE WHEN` branches matter? (2) Write the
`SUMIFS` equivalent in SQL. (3) What does `FILTER (WHERE ...)` do that a plain
`WHERE` cannot?

**M7.** (1) Why prefer a CTE to a nested subquery? (2) What does `NOT IN` do
when the subquery contains a NULL? (3) How do you debug a five-CTE query?

**M8.** (1) Aggregate versus window function — what is the difference in one
sentence? (2) Why can you not filter on `RANK()` in `WHERE`? (3) What does
`LAG(revenue, 4)` give you in quarterly data, and why is that the useful one?

**M9.** (1) `UNION` versus `UNION ALL` — which loses data, and when does that
matter? (2) Give three genuine reasons two finance systems disagree. (3) What
shape does a row-level reconciliation always take?

**M10.** (1) What does `ROLLBACK` undo? (2) Why run a `SELECT` before every
`UPDATE`? (3) Is a view a copy of the data?

**M11.** (1) What is an index, in one sentence, without jargon? (2) Why does
wrapping a column in a function defeat its index? (3) Why not index everything?

**M12.** (1) What is the grain of a table and why is it the first question?
(2) Type 1 versus Type 2 slowly changing dimension — which does finance want,
and why? (3) What does idempotent mean for a month-end job?

**M13.** (1) Depreciation up ₹100 at 25% tax — walk all three statements.
(2) Why can a profitable company run out of cash? (3) What does the cash flow
statement exist to explain?

**M14.** (1) What does blue font mean? (2) Why must a formula be identical
across a row? (3) What is a circuit breaker and when do you use it?

**M15.** (1) Which line links net income to the balance sheet? (2) Your model
is out by exactly net income — what is wrong? (3) Why is cash the plug?

**M16.** (1) Top-down versus bottom-up — which would you defend to a CFO?
(2) Three sanity checks on any revenue forecast. (3) Why is quarter-on-quarter
growth misleading in a retail business?

**M17.** (1) What does Excel's `NPV` assume about the first cash flow?
(2) When does IRR mislead? (3) Why does mid-year convention raise a valuation?

**M18.** (1) Why is free cash flow unlevered in a DCF? (2) What share of your
value sits in terminal value, and is that comfortable? (3) A 5% terminal
growth rate — defend or attack it.

**M19.** (1) Why does EV pair with EBITDA and equity value with net income?
(2) Why the median rather than the mean? (3) Why do precedent transactions
trade above comps?

**M20.** (1) What are the three sources of value creation in an LBO, and which
is luck? (2) Why does leverage raise returns and risk together? (3) A 5-year
3.0× — roughly what IRR?

**M21.** (1) When is an all-stock deal accretive before synergies? (2) What is
the breakeven synergy? (3) Where does goodwill come from?

**M22.** (1) How does a lender's question differ from an investor's?
(2) Maintenance versus incurrence covenant? (3) What is the actual deliverable
of a covenant model?

**M23.** (1) Decompose a revenue variance into price, volume and mix.
(2) Timing versus permanent variance — why does the distinction matter?
(3) What is a rolling forecast and why is it better than a budget by June?

**M24.** (1) Define net revenue retention and say what above 100% means.
(2) Why is LTV usually overstated? (3) What does automating the monthly pack
actually buy the business?

---

<a name="quizzes"></a>
## Module quizzes

Ten questions, roughly 20 minutes, 70% to pass. Structure every quiz the same
way so the student knows what is coming:

* Q1–Q4: multiple choice or short answer, testing concepts
* Q5–Q8: write the query / write the formula
* Q9: find the bug in a query or model that is subtly wrong
* Q10: a business question with no SQL given — they must decide what to
  compute and then compute it

Q9 and Q10 are worth double. Anyone can write a query when told exactly what
is wanted; the job is deciding what is wanted and spotting when something is
off.

### Sample quiz — Module 5 (Joins)

1. In one sentence, what does `LEFT JOIN` do that `INNER JOIN` does not? *(2)*
2. You join a 1,000-row table to a 1,000-row table and get 1,400 rows. Name the two possible causes. *(2)*
3. True or false: `USING (company_id)` and `ON a.company_id = b.company_id` always return identical columns. *(2)* — *False; `USING` collapses the key into one column.*
4. What does this return, in words? `FROM a LEFT JOIN b ON … WHERE b.id IS NULL` *(2)*
5. Every company with its FY26-Q4 revenue and its 31-Mar-2026 closing price. *(4)*
6. Every customer, including those never invoiced, with their total billed (zero if none). *(4)*
7. FY26 opex by department, actual and budget, in one row per department. *(6)*
8. The three companies with the largest gap between LTM revenue and prior-year LTM revenue. *(6)*
9. Find the bug: *(6)*

```sql
-- BROKEN ON PURPOSE: what is wrong with this, and what does it silently do?
SELECT d.dept_name, SUM(b.budget_amount) AS budget, SUM(l.debit - l.credit) AS actual
FROM gl_budget b
JOIN gl_journal_line l ON l.account_id = b.account_id
JOIN dim_department d ON d.dept_id = b.dept_id
WHERE b.fiscal_year = 2026
GROUP BY d.dept_name;
```

*Answer: the join is at the wrong grain and ignores `dept_id` and
`fiscal_month`, so every budget row multiplies against every matching ledger
line. Both totals are wrong, by a large factor, with no error. Fix: aggregate
both sides to (fiscal_year, fiscal_month, account_id, dept_id) first, then
join.*

10. The CFO asks: "are we collecting cash faster or slower than last year?"
    Decide what to compute, compute it, and answer in two sentences. *(6)*

*Marking note for Q10: full marks require a defined metric (DSO, or average
days invoice-to-payment), the comparison across two periods, and a stated
caveat — for example that open invoices are excluded and so the figure
flatters a worsening trend.*

### Sample quiz — Module 8 (Window functions)

1. One sentence: aggregate versus window function. *(2)*
2. What does `PARTITION BY` correspond to in a pivot table? *(2)*
3. Why does `WHERE rank = 1` fail? *(2)*
4. `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` — how many rows are in the window? *(2)*
5. Quarter-on-quarter and year-on-year revenue growth for company 7. *(4)*
6. Running total of cash collected by month in FY26. *(4)*
7. Top 2 companies by revenue within each sector at 31-Mar-2026. *(6)*
8. 20-day moving average of closing price for company 1, most recent 30 days. *(6)*
9. Find the bug: *(6)*

```sql
-- BROKEN ON PURPOSE
SELECT period_end, revenue,
       revenue / LAG(revenue) OVER (ORDER BY period_end) - 1 AS growth
FROM fs_income_statement;
```

*Answer: no `PARTITION BY company_id`, so the first quarter of each company is
compared with the last quarter of the previous company. It runs perfectly and
every twelfth row is nonsense — the most dangerous kind of bug. Also no
`NULLIF` on the denominator.*

10. "Which of our customers are growing and which are shrinking?" Define what
    that means, compute it, and name the top five in each direction. *(6)*

---

<a name="unittests"></a>
## Unit tests

Timed, closed-book, 45–60 minutes, at the end of each block. Closed-book is
deliberate and worth explaining: an interview whiteboard round is closed-book,
and the point is not memorisation but whether the *structure* of a query is
now automatic.

| Test | After | Covers | Format |
|---|---|---|---|
| **UT1** | Module 4 | Reading tables, calculations, aggregation, dates | 8 questions, 45 min |
| **UT2** | Module 8 | Joins, CASE, CTEs, window functions | 8 questions, 60 min |
| **UT3** | Module 12 | Reconciliation, writing data, performance, data quality | 6 questions + one cleaning task, 60 min |
| **UT4** | Module 16 | Accounting links, Excel discipline, three-statement build, forecasting | Written + a small model build, 90 min |
| **UT5** | Module 20 | TVM, DCF, comps, LBO | Written + a paper LBO under time pressure, 90 min |
| **UT6** | Module 24 | M&A, credit, FP&A, unit economics, Python | Written + a variance analysis, 90 min |

**UT1 sample paper.**

1. What is the grain of `saas_payment`? *(3)*
2. Ten largest ledger transactions in FY26, with account and department names. *(8)*
3. Revenue by fiscal quarter for FY25 and FY26, side by side. *(10)*
4. EBITDA margin by sector at 31-Mar-2026, weighted correctly. State why you weighted it that way. *(12)*
5. Customers per segment per country, only combinations above 20. *(8)*
6. Why does `WHERE due_date = NULL` return nothing? *(4)*
7. Find the bug: `SELECT segment, SUM(amount) FROM saas_invoice GROUP BY 1` — *(there is no `segment` column on `saas_invoice`; it needs a join to `dim_customer`)* *(5)*
8. "Is our revenue seasonal?" Compute something that answers it, and answer in two sentences. *(10)*

Total 60. Pass 42.

**UT5 sample paper.**

1. Build a WACC from given inputs, show your working. *(10)*
2. NPV and IRR of a given cash flow stream, with and without mid-year convention. Explain the difference. *(10)*
3. Given a five-year FCF forecast and a WACC, compute enterprise value both terminal value ways, and state the implied growth rate of the exit multiple method. *(15)*
4. Given a comp set, compute EV/EBITDA for each and the median. Which company would you exclude and why? *(10)*
5. Paper LBO, out loud, five minutes, given entry multiple, leverage, EBITDA growth and exit multiple. IRR and MoM. *(15)*
6. What proportion of your Module 18 DCF value is terminal value, and what does that imply about how much of your answer is really a forecast? *(10)*

Total 70. Pass 49.

---

<a name="midterm"></a>
## Midterm exam — after Module 12

**Two hours. Open database, closed notes. Deliverable: a written memo with
your queries as an appendix.**

> **The brief.** You have joined Bluewater Capital. The CFO of Meridian
> Softworks, a portfolio company, is presenting to the board next week and has
> asked for an analysis pack. She has given you a database and one afternoon.

**Section A — data foundations (20 marks)**

1. State the grain of `gl_journal_line`, `gl_budget`, `saas_invoice` and
   `fact_price`. *(4)*
2. Write three data-quality tests that each return zero rows on healthy data,
   covering uniqueness, referential integrity and a control total. *(9)*
3. Prove that every journal in the ledger balances. *(3)*
4. The ledger and Meridian's reported statements do not reconcile. Give four
   reasons two such sources genuinely differ in a real company. *(4)*

**Section B — the analysis (50 marks)**

5. FY26 revenue by month, with month-on-month and year-on-year growth. *(8)*
6. FY26 opex by department against budget, with variance in rupees and
   percent, worst first. *(10)*
7. Identify the FY26 cost variances that deserve board commentary. For each,
   classify it as timing, one-off or run-rate, and give your evidence. *(12)*
8. A receivables ageing at 30-Jun-2026 by segment, plus DSO, plus whether
   collections are improving or worsening versus the prior year. *(10)*
9. Customer concentration: what share of billings comes from the top 10
   customers, and what is the risk? *(10)*

**Section C — judgement (30 marks)**

10. Write the one-page board commentary. What are the three things the board
    must know, and what would you recommend? *(20)*
11. Name two numbers in your own pack you are least confident about, and say
    what you would do to firm them up. *(10)*

**Mark scheme notes.** Section C carries 30% because a technically flawless
pack with no point of view is a junior analyst's most common failure. Q11
exists to reward calibrated honesty — a student who claims full confidence in
everything should lose marks, and should be told plainly why.

**Total 100. Pass 70.**

---

<a name="final"></a>
## Final exam — after Module 24

**Three hours, or a weekend take-home if the student prefers realism over
time pressure. Deliverables: one Excel model, one SQL file, one two-page memo.**

> **The brief.** Bluewater is considering acquiring Kaveri Retail (KVRA) at a
> 25% premium to its 31-Mar-2026 closing price. The investment committee meets
> on Monday. They want a recommendation, not a spreadsheet.

**Part 1 — Get the data (15 marks).** One SQL file that pulls everything the
model needs: three statements, prices, sector comps. It must run start to
finish, be commented, and be re-runnable.

**Part 2 — The model (45 marks).**
* A three-statement forecast, five years, balancing every period *(15)*
* A DCF with both terminal value methods and a WACC you built *(15)*
* A comps table with the sector peers, median and quartiles *(8)*
* A checks block, and colour and unit conventions followed throughout *(7)*

**Part 3 — The transaction (20 marks).**
* Sources and uses at the offer price *(5)*
* Five-year LBO returns: IRR, MoM, and returns attribution *(10)*
* Credit view: leverage at entry, covenant headroom, the downside case *(5)*

**Part 4 — The recommendation (20 marks).**
* Two pages. Your value, your recommended maximum price, the three
  assumptions it hinges on, and the two things that would change your mind.
* Marked on judgement and clarity, not length. A committee member who cannot
  find the recommendation in ten seconds has been failed by the memo.

**Automatic deductions**, applied without negotiation, because these are the
things that end careers rather than lose marks:
* Balance sheet does not balance: **−15**
* A hardcoded number inside a formula in the calculation area: **−5 each, up to −15**
* Sources do not equal uses: **−10**
* A number in the memo that cannot be traced to the model: **−10**

**Total 100. Pass 70.** Below 70, identify the weakest part, re-teach it, and
re-sit with a different target company — Nilgiri Spice Foods or Godavari
Cement work equally well.

---

<a name="rubrics"></a>
## Rubrics

### Marking a query (10 marks)

| Marks | Standard |
|---|---|
| 9–10 | Right answer, robust to NULLs and duplicates, readable, correctly named columns, would pass review unchanged |
| 7–8 | Right answer, minor robustness or readability issues |
| 5–6 | Right answer by luck — works on this data, would break on realistic variation |
| 3–4 | Wrong answer, right approach |
| 1–2 | Wrong approach, some relevant SQL |
| 0 | Blank, or does not run |

### Marking a model (100 marks)

| Area | Marks | What earns them |
|---|---|---|
| Mechanics | 25 | Balances, ties, no circular errors, no broken links |
| Structure | 20 | Inputs separated, consistent formulas, colour convention, units labelled |
| Assumptions | 20 | Anchored in history, each one justified in writing |
| Analysis | 20 | Sensitivities, scenarios, the right output for the question asked |
| Communication | 15 | A reviewer can understand it without the author present |

### Marking written commentary (20 marks)

| Marks | Standard |
|---|---|
| 17–20 | States the answer first, quantifies it, names the risk, recommends an action |
| 13–16 | Correct and clear, but buries the conclusion or omits the "so what" |
| 9–12 | Describes what the numbers did without explaining why or what to do |
| 5–8 | Vague, hedged, or contains claims the data does not support |
| 0–4 | Not usable |

The commonest failure is 9–12: an accurate description of movements with no
insight. Name it every time it happens. "You have told me revenue fell 4%.
The board can read that off the chart. Tell me why, whether it continues, and
what you want them to do."

---

<a name="fresh"></a>
## Generating fresh questions

For re-tests and extra practice, generate new questions rather than reusing
old ones. The dataset is deliberately rich enough to support this
indefinitely. Vary along these axes:

* **Entity**: 20 companies, 8 departments, 3 portfolios, 4 customer segments,
  10 industries, 10 sectors
* **Period**: 12 quarters, 39 months, two full fiscal years of budget
* **Metric**: any ratio in Module 13, any SaaS metric in Module 24
* **Shape**: "compute X", "compare X across Y", "find the outlier in X",
  "explain why X and Y disagree", "what should we do about X"

**Keep the difficulty by keeping the shape.** A question is hard because of
what it asks the student to *decide*, not because of how many tables it
touches. "Total revenue by sector" across eight joins is easy. "Is our revenue
quality improving?" across two tables is hard, because they must first decide
what revenue quality means.

**Always include one question with no single right answer**, and mark the
reasoning. Real work is mostly those.
