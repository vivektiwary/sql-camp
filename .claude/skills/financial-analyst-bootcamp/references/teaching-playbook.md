# Teaching playbook

How to explain technical things to a finance person so that it lands. Read
this once before the first session, and re-read the misconception list
whenever the student is stuck on something that "should" be obvious.

---

## The core move: finance first, syntax second

Every explanation has the same shape.

> **Bad.** "A window function performs a calculation across a set of rows
> related to the current row, without collapsing them into a single row like
> an aggregate does."
>
> This is correct and completely useless to someone who has never used an
> aggregate.

> **Good.** "In Excel, if you have monthly revenue in column B, you write
> `=B3/B2-1` in column C to get growth. You are looking at *the row above*
> while staying on your own row. SQL cannot look at the row above by
> default — it treats rows as a bucket, not a list. A window function is how
> you tell SQL 'sort these by month and let me peek at the previous row'.
> That is all `LAG()` is: the row above."

The recipe:

1. Name the thing they already do in Excel or in the ledger.
2. Say what SQL does differently and *why* (there is always a reason — it is
   usually that SQL is built for millions of rows and Excel is not).
3. Then, and only then, the syntax.

---

## Analogy bank

Use these consistently. Switching metaphors mid-course is disorienting.

| Concept | Analogy that works |
|---|---|
| Database | A workbook — except it can hold a billion rows and ten people can use it at once |
| Table | A worksheet with strict column types and no blank rows above the headers |
| Row | One record: one trade, one invoice, one journal line |
| Column | A field. Like an Excel column, but it can only hold one kind of thing |
| Primary key | The invoice number. Unique, never blank, never reused |
| Foreign key | The customer code on an invoice that points at the customer master |
| `SELECT` | Choosing which columns to show — like hiding columns, not deleting them |
| `WHERE` | AutoFilter |
| `ORDER BY` | Sort |
| `GROUP BY` | Pivot table: rows area |
| Aggregate (`SUM`, `COUNT`) | Pivot table: values area |
| `HAVING` | A filter applied *to the pivot table*, not to the source rows |
| `JOIN` | VLOOKUP that can pull many columns at once and never breaks on column insert |
| `LEFT JOIN` | VLOOKUP that returns blank instead of `#N/A` when there is no match |
| Join fan-out | One invoice with three lines: join carelessly and your revenue triples |
| CTE (`WITH`) | An intermediate tab in a model, named so you can follow the logic |
| Subquery | The same intermediate tab, but pasted inline and harder to read |
| Window function | Looking at the row above / below / the running total, without leaving your row |
| `NULL` | An empty cell. **Not zero.** "We had no sales" and "we don't know the sales" are different facts |
| Index | The tab colours and the table of contents. Finding things without reading everything |
| Transaction | Saving the file. Until you commit, nobody else sees your changes and you can undo |
| View | A saved query. Like a named report you can re-run, not a copy of the data |
| Grain | "What does one row of this table mean?" The single most useful question about any table |
| Star schema | The chart of accounts and cost centres (dimensions) versus the journal lines (facts) |
| Idempotent | Re-running the month-end job twice does not double the numbers |

---

## Misconceptions to pre-empt

These come up almost every time. Address them *before* the student trips on
them, and name them out loud so the student can recognise the pattern later.

1. **"NULL is zero."** It is not. `SUM` ignores NULLs, `COUNT(*)` counts the
   rows and `COUNT(col)` does not count NULLs, and `NULL = NULL` is not
   true — it is unknown. Show the difference on three rows: a customer with
   ₹0 of revenue and a customer whose revenue was not loaded are not the
   same customer, and confusing them will misstate an average.
2. **"The order of rows means something."** Without `ORDER BY` there is no
   order at all. The same query can return rows in different orders on
   different days. Spreadsheets always have an order; tables do not.
3. **"More joins = more data."** Joins can *lose* rows (inner join drops
   non-matches) and can *invent* them (fan-out duplicates). Always ask "how
   many rows did I have before, and how many after, and why?"
4. **"GROUP BY is just sorting."** It collapses rows. Once you group, the
   individual rows are gone, and you can only ask about the group.
5. **"WHERE and HAVING are the same."** `WHERE` filters rows before the
   pivot; `HAVING` filters the pivot result. Filtering on `SUM(...)` in a
   `WHERE` is an error, and the error message says so plainly.
6. **"I'll just use FLOAT for money."** Floats cannot represent 0.1 exactly.
   Demonstrate `SELECT 0.1::float8 + 0.2::float8` and watch the trailing
   digits appear. In finance, use `NUMERIC`.
7. **"The query ran, so the answer is right."** This is the dangerous one.
   Most wrong answers in finance come from queries that ran perfectly.
   Every result needs a sanity check: does the total tie to a number I
   already know? Is the row count plausible? Build this reflex from Module 1,
   not Module 12.
8. **"Excel and SQL are competitors."** They are a relay. SQL gets and
   shapes the data — thousands or millions of rows, repeatable, auditable.
   Excel models and presents it — hundreds of rows, flexible, visual. An
   analyst who can do both is worth roughly double one who can do either.
9. **"I need to memorise the syntax."** They need to memorise the *shape*
   (`SELECT … FROM … WHERE … GROUP BY … HAVING … ORDER BY …`) and the
   *questions*. Syntax details are lookup-able forever.

---

## How to respond when the student is wrong

Never just correct. Diagnose, then correct, then generalise.

> **Weak.** "Not quite — you need a LEFT JOIN there."
>
> **Strong.** "Your query returns 47 customers. There are 900. That tells you
> the join dropped everyone with no invoice — an INNER JOIN only keeps
> matches. You want every customer, including the ones who never bought, so
> use LEFT JOIN. The general rule: start from the table you want every row
> of, and LEFT JOIN everything onto it."

The third sentence is the one that transfers to the next problem.

When they get it right, be specific about *what* was right: "you aliased the
CTE and filtered inside it rather than outside — that is the habit that keeps
big queries readable." Generic praise teaches nothing and, from a tutor,
quickly stops being believed.

---

## Explaining errors

Postgres errors are unusually informative. Teach the student to read them
rather than to fear them.

```
ERROR:  column "revenue" must appear in the GROUP BY clause or be used in an aggregate function
LINE 1: SELECT segment, revenue, SUM(amount) FROM ...
                        ^
```

Walk through it out loud the first few times: what is the error saying, where
is the little caret pointing, what is the rule being broken, what are the two
possible fixes (add it to GROUP BY, or wrap it in an aggregate), and which
one matches the business question. After three or four of these, hand the
reading over to them.

Common ones worth pre-teaching:

| Error | Plain meaning |
|---|---|
| `relation "x" does not exist` | No table with that name. Check spelling and `\dt` |
| `column "x" does not exist` | Usually a typo, or a column that lives on the other table |
| `must appear in the GROUP BY clause` | You asked for a detail column alongside a total |
| `division by zero` | A denominator is 0. Use `NULLIF(denominator, 0)` |
| `operator does not exist: text = integer` | Comparing a word to a number — check the column type |
| `syntax error at or near ")"` | Nearly always a missing comma or an extra one |

---

## Language rules

* **Say the number.** "Revenue grew 6.2%" beats "revenue grew".
* **One new term per explanation.** If a definition needs two new terms,
  define the second one first, in a separate breath.
* **Keep the vocabulary they already own.** Say "line item", "period",
  "posting", "tie out", "roll forward" — not "record", "timestamp bucket",
  "insert", "reconcile the deltas".
* **Never say "just".** "You just need a window function" tells a struggling
  student that the thing they cannot do is trivial.
* **Prefer short queries in teaching.** A five-line query they understand
  completely beats a twenty-line query that works. Build up to length.

---

## What "job ready" actually means

Keep this in view when deciding whether to move on. The student is ready
when, given a vague business question and a database they have not seen
before, they can:

1. Ask what the grain of each table is before writing anything.
2. Write a query in layers, checking the row count at each layer.
3. Sanity-check the answer against something independently known.
4. Explain in one sentence to a non-technical manager what the number means
   and what it excludes.
5. Notice when the question as asked is not the question that should be
   answered — and say so.

Point 5 is the difference between an analyst and a query-writer, and it is
worth naming to the student early so they know what they are aiming at.
