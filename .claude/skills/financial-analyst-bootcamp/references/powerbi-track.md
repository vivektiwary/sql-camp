# Part 3 — Power BI for finance (Modules 25–27)

Sooner or later someone asks for a dashboard. This part turns the SQL and the
modelling into something a CFO can click through, and it is the piece that
most often gets a finance analyst onto a data team.

It comes **after** Module 24 for a reason. Power BI is a joy when the data
underneath is modelled properly and a nightmare when it is not, and the
student now knows what "modelled properly" means. Teaching Power BI to
someone who has never met a star schema produces dashboards that give
different totals depending on which slicer you touch.

Contents:
- [Before you start: the Mac problem](#mac)
- [Module 25 — Getting data in, and modelling it](#m25)
- [Module 26 — DAX](#m26)
- [Module 27 — Report design, security and publishing](#m27)
- [Capstone 5 and Unit Test 7](#assessment)

---

<a name="mac"></a>
## Before you start: the Mac problem

**Power BI Desktop only runs on Windows.** There is no Mac version and there
is not going to be one. Say this to the student plainly at the end of Module
24, not on the morning of Module 25, because two of the three fixes take a
day to arrange and one of them costs money.

Here are the honest options, best first.

### Option A — Windows in a virtual machine on the Mac *(recommended)*

A virtual machine is a whole Windows computer running in a window on macOS.
This is what most Mac-based analysts actually do, and it gives the real
product with nothing missing.

| Tool | Cost | Notes |
|---|---|---|
| **UTM** | Free | Open source. Fine on Apple Silicon with Windows 11 ARM. Slower to set up, no support. |
| **Parallels Desktop** | Paid, annual | Easiest by a distance. Downloads and installs Windows for you in about twenty minutes. |
| **VMware Fusion** | Free for personal use | In between: reliable, a bit more fiddly than Parallels. |

On Apple Silicon (M1 and later) you need **Windows 11 on ARM**, which
Microsoft distributes for this purpose. Power BI Desktop is an x64
application and runs under Windows' built-in emulation. It works. It is not
fast. Give the VM at least 8 GB of memory and 60 GB of disk, and expect the
first report to feel sluggish while it caches.

Install Power BI Desktop inside Windows from the Microsoft Store, which keeps
it updated, rather than the standalone installer.

### Option B — A cloud Windows PC

Windows 365 Cloud PC, or a small Azure or AWS Windows virtual machine. Costs
a monthly fee, needs no local resources, and performs better than emulation
on Apple Silicon. Sensible if the student's laptop is memory-constrained.
Remember to shut it down — an idle cloud VM bills all month.

### Option C — Power BI Service in the browser *(fallback, not equivalent)*

app.powerbi.com runs in Safari on the Mac and will build reports from data
you upload. Be straight about what is missing: no Power Query Editor, a
limited modelling experience, and no connection to a database on your own
machine. It is enough to learn report *design* and to see what a published
dashboard feels like. It is not enough to learn Power Query or proper
modelling, which is most of Module 25.

If the student ends up here, adapt: do Module 25's modelling concepts as
paper exercises against the sqlcamp schema they already know, and revisit
them the moment a Windows machine is available.

### Connecting Power BI to the practice database

Once Windows is running, Power BI needs to reach PostgreSQL, which is
installed on the Mac side.

1. **Let PostgreSQL listen beyond localhost.** Find the config file:
   ```bash
   psql -d sqlcamp -c "SHOW config_file;"
   ```
   In `postgresql.conf` set `listen_addresses = '*'`. In `pg_hba.conf` add a
   line allowing the VM's network, for example:
   ```
   host    sqlcamp    all    192.168.64.0/24    scram-sha-256
   ```
   Then `brew services restart postgresql@16`.

2. **Give your Mac user a password**, because a VM connection cannot use the
   trust-based local login:
   ```bash
   psql -d sqlcamp -c "ALTER USER \"$(whoami)\" WITH PASSWORD 'sqlcamp';"
   ```

3. **Find the Mac's address from inside Windows.** In Parallels it is usually
   `10.211.55.2`; in UTM check `ipconfig` in Windows and use the gateway. Or
   run `ipconfig getifaddr en0` on the Mac and use that.

4. **In Power BI Desktop**: Get Data → PostgreSQL database → server
   `<mac-ip>:5432`, database `sqlcamp` → Database credentials → your Mac
   username and the password you just set. Choose **Import**.

**This is a course environment, not a production one.** Opening a database to
the network with a simple password is fine on a laptop VM and unacceptable on
anything shared. Say so, and have the student revert `listen_addresses` when
they finish the module.

**If any of that fails**, do not spend a session on networking. Fall back to
extracts: run the queries in psql with `\copy ... TO 'file.csv' CSV HEADER`,
share the folder with the VM, and load the CSVs. Everything in Modules 25–27
still works. The student loses live refresh and gains an afternoon.

---

<a name="m25"></a>
## Module 25 — Getting data in, and modelling it

**Objective.** Load the sqlcamp tables into Power BI, shape them in Power
Query, and build a star schema whose totals are right from every angle.

**Open with this.** "You already know how to answer a question with SQL. The
difference here is that you are not answering one question — you are building
something that answers questions you have not thought of yet, asked by
someone who cannot write SQL. That changes what 'correct' means."

### Import versus DirectQuery

* **Import** copies the data into the `.pbix` file, compresses it hard, and
  is fast. It is the default and the right answer nearly always.
* **DirectQuery** leaves the data in PostgreSQL and sends a query for every
  visual. Use it only when the data is too large to import, or genuinely must
  be current to the second. It is slower and many DAX functions are limited.

Our whole database imports in seconds. Use Import, and explain when you would
not.

### Power Query — the part that is really SQL in disguise

Power Query is the ETL layer: rename, filter, remove columns, change types,
merge (a join), append (a UNION ALL), unpivot, group by. Every step is
recorded, so the whole cleaning process re-runs on refresh. That is the
Module 12 idea of a repeatable pipeline, with a mouse.

Two habits to build immediately, because they are what separate a report that
survives from one that is rebuilt every quarter:

1. **Push work upstream.** If a transformation can be done in SQL, do it in
   SQL. A view in PostgreSQL is faster, testable, and reusable by everything
   else. Power Query is for what is left.
2. **Remove every column you do not need**, on the way in. Power BI compresses
   by column; a wide table you never look at is pure cost.

Set the exercise of loading `raw_vendor_invoices` and cleaning it in Power
Query, having already cleaned it in SQL in Module 12. Then ask which they
would ship and why. The right answer is usually SQL — with the reason being
that a colleague can review a query and cannot easily review 22 clicks.

### The star schema, in Power BI

Load these and nothing else to start with:

| Table | Role |
|---|---|
| `gl_journal_line` | fact |
| `gl_budget` | fact |
| `dim_date` | dimension |
| `dim_account` | dimension |
| `dim_department` | dimension |

Then in Model view, create relationships:

* `dim_date[date_key]` → `gl_journal_line[entry_date]`, one-to-many, single direction
* `dim_account[account_id]` → `gl_journal_line[account_id]`
* `dim_department[dept_id]` → `gl_journal_line[dept_id]`
* and the same three dimensions to `gl_budget`

**Filters flow one way, from the dimension to the fact.** That is the whole
mechanism. Choosing a department filters both fact tables, so actual and
budget line up automatically. This is why two fact tables sharing conformed
dimensions is the right shape, and why joining fact tables to each other is
not.

**Mark `dim_date` as a date table** (Table tools → Mark as date table →
`date_key`). Time intelligence silently misbehaves without it.

**Do not turn on bidirectional filtering** because a total looks wrong.
Bidirectional relationships create ambiguous filter paths and are the single
most common cause of Power BI totals that change depending on the order you
click things. If a total is wrong, the model is wrong.

### The traps to demonstrate

1. **`gl_budget` has no date column** — it has `fiscal_year` and
   `fiscal_month`. Relating it to `dim_date` needs a key. Have the student
   solve it: either add a date column in Power Query, or build the
   relationship on a composite key created in SQL. This is a genuine modelling
   decision and there is more than one defensible answer.
2. **Auto date/time.** Power BI silently creates a hidden date table for every
   date column. Turn it off (Options → Data Load → uncheck Auto date/time).
   It bloats the file and it uses the calendar year, which is not our year.
3. **The wrong grain in one visual.** Put budget and actual on one chart
   before the relationships are right, and watch the budget repeat for every
   ledger line. It is the Module 5 fan-out again, wearing a different hat.
   Point that out explicitly — the student has met this before and should
   recognise it.

**Homework.** Build the model above, add `dim_customer`, `saas_invoice` and
`saas_subscription` as a second star, and write down the grain of every table
you loaded and the direction of every relationship.

---

<a name="m26"></a>
## Module 26 — DAX

**Objective.** Write measures that stay correct however the user slices them.

**Open with this.** "DAX looks like Excel formulas and behaves nothing like
them. An Excel formula computes one answer for one cell. A DAX measure is a
recipe that gets recomputed for every cell of every visual, under whatever
filters the user happened to click. Once that lands, DAX gets easy."

### Measures versus calculated columns

| | Calculated column | Measure |
|---|---|---|
| When computed | On refresh, row by row | On the fly, per visual cell |
| Stored | Yes, takes space | No |
| Responds to slicers | No | Yes |
| Use it for | Something you group or filter *by* | Anything you aggregate |

**Default to measures.** A calculated column that should have been a measure
is the commonest beginner mistake: it does not react to the user's filters, so
the number quietly stops matching the rest of the report.

### The measures for our management pack

Build these in order. They are a complete FP&A pack, and each one is a step
up in difficulty.

```dax
Actual =
    SUM ( gl_journal_line[debit] ) - SUM ( gl_journal_line[credit] )

Budget =
    SUM ( gl_budget[budget_amount] )

Variance = [Actual] - [Budget]

Variance % = DIVIDE ( [Variance], [Budget] )
```

`DIVIDE` is DAX's `NULLIF` — it returns blank instead of an error when the
denominator is zero. Use it always; never use `/`. Call back to Module 2 when
you teach it, because it is the same lesson in a different language.

```dax
Revenue =
    CALCULATE ( -[Actual], dim_account[category] = "Revenue" )

Opex =
    CALCULATE ( [Actual], dim_account[category] IN { "COGS", "Opex" } )
```

**`CALCULATE` is the whole of DAX.** It evaluates an expression with the
filter context changed — it is `SUMIFS` for a data model. Everything
complicated in DAX is `CALCULATE` with a more interesting second argument.
Spend a full session on it and do not rush.

The sign flip on Revenue is the ledger convention from Module 3 following
them into a new tool. Put the convention in the measure's description field
so the next person finds it.

```dax
Actual PY =
    CALCULATE ( [Actual], SAMEPERIODLASTYEAR ( dim_date[date_key] ) )

Actual YTD =
    TOTALYTD ( [Actual], dim_date[date_key], "3/31" )
```

That `"3/31"` is the fiscal year end. Leave it out and Power BI gives you a
calendar year-to-date, which for this company is wrong in nine months out of
twelve. Have the student produce both and see the difference — it is the
Module 4 fiscal calendar lesson, and it bites again here.

```dax
Headcount =
    SUM ( gl_headcount[headcount] )

Cost per head =
    DIVIDE ( [Opex], [Headcount] )

Top 5 customers by billings =
    CALCULATE (
        [Billings],
        TOPN ( 5, ALL ( dim_customer[customer_name] ), [Billings], DESC )
    )
```

### Row context versus filter context

The idea people find hardest, so give it the finance version:

* **Filter context** is the slicers and the row and column headers — "this
  cell is Marketing, in November, FY26". Every measure is computed inside one.
* **Row context** exists inside a calculated column or an iterator like
  `SUMX`, where you are walking one row at a time.

`SUMX ( table, expression )` walks the table and evaluates the expression per
row, then adds up. Use it when the calculation must happen row by row before
aggregating — for example weighted average price, where
`SUM(price) / SUM(qty)` is wrong and
`DIVIDE ( SUMX ( sales, sales[price] * sales[qty] ), SUM ( sales[qty] ) )` is
right. This is the same weighted-versus-simple-average trap from Module 3.
Name it as such; the recurrence is the point.

**Homework.** Build all the measures above plus: gross margin %, EBITDA,
month-on-month growth, a rolling three-month average of opex, and a measure
that returns the text "over budget" or "within budget" for conditional
formatting.

---

<a name="m27"></a>
## Module 27 — Report design, security and publishing

**Objective.** A dashboard a CFO would actually use, secured and refreshing.

### Design, for finance specifically

Finance dashboards fail in a predictable way: they show everything and say
nothing. The discipline is the same as the written commentary in Module 23.

* **One page, one question.** "How did we do against budget?" is a page.
  "Everything about the company" is not.
* **Lead with the answer.** Top-left is the most valuable space on the screen
  and the eye lands there first. Put the headline number and its variance
  there, not a slicer panel.
* **Variance, not just actual.** A bar chart of monthly spend is data. The
  same chart with budget as a reference line and the variance called out is
  information.
* **Consistent, meaningful colour.** Pick one colour for actual and one for
  budget and never swap them. Reserve red and green for adverse and
  favourable — and remember that for costs, over budget is bad while for
  revenue it is good, so drive the colour off the variance's *meaning*, not
  its sign.
* **Label units on everything.** ₹m or ₹ — the same mistake as in Excel, with
  a bigger audience.
* **Skip the decoration.** No 3-D, no gauges that use half a screen to show
  one number, no pie chart with eleven slices. A table is often the right
  answer and finance people are entirely happy with tables.
* **Write the commentary into the report.** A text box with three sentences of
  explanation is usually the most-read object on the page.

Accessibility matters more than people expect in a finance audience: about one
man in twelve has some colour vision deficiency, so never let colour alone
carry the message. Pair it with a sign, an arrow, or a label.

### Row-level security

A single report often serves people who must not see each other's numbers —
each department head sees their own costs. In Power BI that is **row-level
security**: define a role with a DAX filter on the dimension, then map users
to it in the Service.

```dax
[dept_name] = USERPRINCIPALNAME()          -- if the table stores the email
```

More usually you add a mapping table of user email to department and filter
through the relationship. Have the student build one role and test it with
"View as role". Explain that RLS is applied on the server, so it survives a
user downloading the report — unlike hiding a column, which does not.

### Publishing and refresh

* **Workspaces** hold reports; an **app** is how you distribute them to
  readers. Do not send people a `.pbix` file.
* **Scheduled refresh** for imported data, up to eight times a day on a Pro
  licence.
* **A data gateway** is required whenever the source is not reachable from the
  cloud — which includes PostgreSQL on the student's own laptop. Explain what
  it is; do not spend a session installing one.
* **Licensing, briefly, because it comes up in interviews:** Free lets you
  build; Pro lets you share; Premium Per User and capacity licences raise the
  limits. Somebody in the room will ask what it costs.

### Performance

If a report is slow, the causes in order of likelihood are: no star schema, a
calculated column that should be a measure, bidirectional relationships, too
many visuals on one page, and DirectQuery where Import would do.

**Homework.** Build the FP&A dashboard: a summary page with revenue, opex,
EBITDA and headcount against budget and prior year; a department detail page;
a variance page listing the largest variances with commentary; and a working
row-level security role.

---

<a name="assessment"></a>
## Capstone 5 and Unit Test 7

### Capstone 5 — the live management pack

**Brief.** "Rebuild Capstone 1 as a dashboard. The CFO wants to stop reading
a PDF once a month and start clicking."

**Deliverables.** A Power BI file connected to `sqlcamp`; a documented star
schema; the measure set with descriptions; three report pages; row-level
security by department; and a one-page note on what you moved into SQL views
and why.

**What is really being tested.** Whether the numbers agree with Capstone 1.
Rebuilding a pack in a new tool and getting different totals is the single
most common — and most damaging — outcome, because it destroys trust in both
versions. Reconciling them is the exercise.

### Unit Test 7 — after Module 27, 60 minutes

1. Import versus DirectQuery: pick one for a stated scenario and justify it. *(6)*
2. Given a schema, draw the star and state every relationship's direction and cardinality. *(10)*
3. Write measures for actual, budget, variance, variance % and prior year. *(15)*
4. What does `CALCULATE` do, and what is the difference between row and filter context? *(10)*
5. A budget total repeats for every ledger line. Diagnose and fix it. *(10)*
6. Critique a supplied dashboard: three things wrong, three fixes, in priority order. *(12)*
7. When would you use row-level security, and why is it safer than hiding a column? *(7)*

Total 70. Pass 49.

### Where this sits in the job-readiness checklist

Add to the checklist in `capstones-and-jobs.md`:

- [ ] Builds a star schema in Power BI and can justify every relationship
- [ ] Writes measures rather than calculated columns, and knows why
- [ ] Uses `CALCULATE` confidently, including with time intelligence
- [ ] Handles the April–March fiscal year correctly in DAX
- [ ] Designs a page that leads with the answer, not with the slicers
- [ ] Can reconcile a dashboard back to the underlying SQL, to the rupee
