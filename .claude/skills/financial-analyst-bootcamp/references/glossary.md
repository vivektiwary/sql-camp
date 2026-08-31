# Glossary

Plain English, no jargon used to define jargon. Send the student here rather
than explaining a term for the fourth time.

## Database and SQL terms

**Aggregate** — a function that squashes many rows into one number: `SUM`,
`COUNT`, `AVG`. The Values area of a pivot table.

**Alias** — a nickname for a table or column inside a query, so you can write
`i.revenue` instead of `fs_income_statement.revenue`.

**CTE (Common Table Expression)** — a named intermediate step in a query,
written `WITH name AS (...)`. An intermediate tab in a model.

**Column / field** — one attribute of a record. A column in a spreadsheet,
except every value in it must be the same kind of thing.

**Constraint** — a rule the database enforces, like "this must be unique" or
"this cannot be blank".

**Data type** — what kind of value a column can hold. `NUMERIC` for money,
`DATE` for dates, `TEXT` for words, `INT` for whole numbers.

**Fan-out** — when a join multiplies rows because the key is not unique on
one side. The reason your revenue total is suddenly three times too big.

**Fact table / dimension table** — facts are the events (journal lines,
trades, invoices). Dimensions describe them (accounts, companies, dates).

**Foreign key** — a column pointing at another table's key. The customer code
on an invoice.

**Grain** — what one row of a table means. Always the first question.

**Idempotent** — running it twice gives the same result as running it once.
What you want from a month-end job.

**Index** — a lookup structure that lets the database find rows without
reading every one. The index at the back of a book.

**Join** — combining two tables side by side on a matching column. VLOOKUP,
but for many columns at once.

**NULL** — unknown or missing. Not zero, not blank text. `NULL = NULL` is not
true.

**Primary key** — the column that uniquely identifies a row. The invoice
number.

**Query plan** — the database's explanation of how it intends to answer your
question. Shown by `EXPLAIN`.

**Row / record** — one thing: one invoice, one trade, one journal line.

**Schema** — the structure: which tables exist and what columns they have.

**Star schema** — one fact table surrounded by its dimension tables. The
standard layout for reporting data.

**Table** — a worksheet with strict rules: named columns, one type per column,
no blank rows above the header.

**Transaction** — a group of changes that all happen or none do. `COMMIT`
saves, `ROLLBACK` undoes.

**View** — a saved query. Behaves like a table but stores no data of its own.

**Window function** — a calculation across nearby rows that keeps every row.
Growth versus last month, running totals, rankings.

## Finance and modelling terms

**Accretion / dilution** — whether an acquisition raises or lowers the
acquirer's earnings per share.

**Accrual accounting** — recording revenue when earned and costs when
incurred, not when cash moves.

**ARR / MRR** — annual / monthly recurring revenue. Subscription revenue only.

**Basis point (bp)** — one hundredth of a percent. 100bps = 1%.

**CAC** — customer acquisition cost. Sales and marketing spend divided by new
customers won.

**Capex** — capital expenditure. Money spent on long-lived assets.

**Cash conversion cycle** — DSO + DIO − DPO. Days of cash tied up in the
operating cycle.

**Circular reference** — a formula that depends on itself. In a model,
interest depends on debt which depends on cash flow which depends on interest.

**Covenant** — a promise in a loan agreement, usually a ratio the borrower
must stay within.

**DCF** — discounted cash flow. Valuing something as the present value of the
cash it will produce.

**Deferred revenue** — cash received for something not yet delivered. A
liability, not revenue.

**DSO / DIO / DPO** — days sales outstanding (how long customers take to pay),
days inventory outstanding (how long stock sits), days payables outstanding
(how long you take to pay).

**EBITDA** — earnings before interest, tax, depreciation and amortisation. A
rough proxy for operating cash generation, and frequently abused as one.

**Enterprise value (EV)** — the value of the whole business: equity value plus
debt minus cash. What you would pay to own it free of its capital structure.

**Free cash flow** — cash left after running and investing in the business.
*Unlevered* free cash flow is before interest; *levered* is after.

**FY** — fiscal year. In this course, April to March. FY26 = Apr-2025 to
Mar-2026.

**Goodwill** — the amount paid for a business above the fair value of its
identifiable assets.

**IRR** — internal rate of return. The discount rate at which an investment's
NPV is zero.

**LBO** — leveraged buyout. Buying a company mostly with borrowed money.

**Leverage** — net debt divided by EBITDA. How many years of profit would
clear the debt.

**LTM** — last twelve months. The most recent four quarters, whenever the
financial year happens to end.

**LTV** — lifetime value of a customer.

**Mid-year convention** — discounting cash flows as if they arrive halfway
through the year rather than at the end, because they do.

**MoM (money multiple)** — proceeds divided by the amount invested. A 3.0×
means you tripled your money.

**Net revenue retention (NRR)** — what happened to last year's customers'
spend this year, including expansion and churn. Above 100% means the existing
base grows on its own.

**NPV** — net present value. Future cash flows discounted to today, less what
you pay.

**Plug** — the line in a model that absorbs the difference to make the balance
sheet balance. Usually cash or the revolver.

**PPE** — property, plant and equipment. Fixed assets.

**Roll forward** — opening balance + additions − reductions = closing balance.
The shape of every schedule in a model: debt, PPE, retained earnings.

**Terminal value** — the value of everything beyond the explicit forecast
period. Usually most of a DCF, and always the shakiest part.

**Tie out** — proving two numbers that should agree do agree, and explaining
them when they do not.

**Variance** — actual minus budget. Favourable or adverse, and worth
explaining only when it is one of timing, one-off or run-rate.

**WACC** — weighted average cost of capital. The blended return debt and
equity holders require, and therefore the discount rate for the business.

**Working capital** — receivables plus inventory minus payables. The cash the
business ties up just by operating.
