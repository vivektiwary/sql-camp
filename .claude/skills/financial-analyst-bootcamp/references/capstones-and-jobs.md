# Capstones, portfolio and getting hired

The course is not finished when Module 24 is. It is finished when the student
has four pieces of work they can show a stranger and talk about for ten
minutes each, and can survive a technical interview.

Contents:
- [The four capstones](#capstones)
- [Building the portfolio](#portfolio)
- [Mock interview 1 — SQL round](#mock1)
- [Mock interview 2 — modelling test](#mock2)
- [Mock interview 3 — case and behavioural](#mock3)
- [Job-readiness checklist](#checklist)
- [What to learn next](#next)

---

<a name="capstones"></a>
## The four capstones

Each is a week of real work and produces something portfolio-worthy. Run them
in this order — they get progressively less prescribed, which is the point.

### Capstone 1 — The monthly management pack *(after Module 12)*

**Brief.** "Produce the FY26 management pack for Meridian Softworks. It goes
to the board unedited."

**Deliverables.** A single SQL file that produces every number; an Excel
workbook with P&L versus budget and prior year, department analysis,
headcount and cost per head, cash collections, and a receivables ageing; one
page of written commentary.

**What is really being tested.** Whether they can produce a *complete,
consistent* pack where every number ties to every other number. Students
routinely produce eight correct exhibits that disagree with each other,
because each was built independently. Mark that hard — inconsistency between
your own exhibits is the fastest way to lose a room.

### Capstone 2 — The equity research initiation *(after Module 19)*

**Brief.** "Initiate coverage on Kaveri Retail with a target price and a
recommendation."

**Deliverables.** A three-statement forecast model; a DCF; a comps table; a
football field; a six-page note with an investment thesis, the three key
drivers, valuation, risks, and a price target.

**What is really being tested.** Whether they have a *view*. A model with no
thesis is a spreadsheet. Ask them the question every portfolio manager asks:
"what do you believe that the market does not?"

### Capstone 3 — The credit and LBO screen *(after Module 22)*

**Brief.** "Screen all 20 companies. Which three are the best LBO candidates,
and which two would you refuse to lend to?"

**Deliverables.** A SQL screen with your criteria and why you chose them; a
quick LBO for the top three; a credit summary for the two refusals with the
covenant that breaks and when.

**What is really being tested.** Screening logic and the ability to say no
with a reason. Anyone can model a company they were handed; deciding which
company to model is the more senior skill.

### Capstone 4 — Own it *(after Module 24)*

**Brief.** The student picks the question. It must use the database, produce
a model or analysis, and end in a recommendation.

**What is really being tested.** Whether they can frame a question worth
answering without being given one. If they cannot think of a question, that is
itself the finding — spend a session on it, because "find the interesting
question" is most of what senior analysts do.

Good examples if they need a nudge: which customer cohorts are actually
profitable after acquisition cost; whether Meridian should raise prices;
which of the 20 companies has the best cash conversion and why; whether the
Bluewater portfolios are taking sector risk they intend to.

### Capstone 5 — The live management pack *(after Module 27)*

Full brief in `references/powerbi-track.md`. Rebuild Capstone 1 as a Power BI
dashboard connected to `sqlcamp`, with a documented star schema, a described
measure set, three report pages and working row-level security.

**What is really being tested.** Whether the numbers agree with Capstone 1.
Rebuilding a pack in a new tool and getting different totals is the most
common and most damaging outcome, because it destroys trust in both versions.
Reconciling them is the exercise.

---

<a name="portfolio"></a>
## Building the portfolio

By the end, the student should have a public GitHub repository containing:

* **A README** that explains, in plain English, what is in the repository and
  what the data is. Written for a hiring manager who will spend ninety
  seconds on it.
* **The SQL**, organised and commented. Not a dump of every query they ever
  wrote — a curated set that shows range: aggregation, window functions, a
  reconciliation, a data-quality test suite, a cleaning script.
* **Two or three Excel models**, with the checks visible.
* **The Python script** that produces the monthly pack.
* **The Power BI file**, with a screenshot in the README - most people looking
  at the repository will not have Power BI installed, and a dashboard nobody
  can see is a dashboard nobody credits you for.
* **Three short write-ups** — the board commentary, the research note, the
  credit memo. These matter more than the code and get read first.

**Say this to the student explicitly:** the write-ups are the differentiator.
A great many candidates can produce a query. Very few can produce a paragraph
that a CFO would forward without editing. The portfolio should lead with the
writing and let the code support it.

**One caution.** Everything in the practice database is fictional, and the
README must say so plainly. Presenting synthetic data as real analysis of real
companies would be dishonest and is easily spotted — and the work is
impressive as what it is.

---

<a name="mock1"></a>
## Mock interview 1 — the SQL round *(after Module 12)*

Live, 45 minutes, no autocomplete, talking out loud. Interrupt them. Ask "why
did you do that?" mid-query. That is what the real thing is like.

**Warm-up (5 min).** "Walk me through a query you have written that you were
pleased with." *Listening for: can they explain their own work to a
non-expert?*

**Fundamentals (10 min).**
* Difference between `WHERE` and `HAVING`?
* What does `LEFT JOIN` do and when do you need it?
* What is `NULL` and how does it behave in `SUM`, `COUNT` and `=`?
* You join two tables and the row count goes up. What happened?

**Live coding (20 min).** Give the schema, no data, and build up:
1. Total revenue by month for FY26.
2. Now add month-on-month growth.
3. Now only months where growth was negative.
4. Now the top three customers in each of those months.
5. Now: how would you check this is right?

Step 5 is the one that separates candidates. A student who answers "I'd tie
the total back to the ledger and check the row count per month" is hired; one
who says "it ran" is not.

**Judgement (10 min).** "Your query says revenue fell 30% last month. What do
you do before telling anyone?" *Listening for: check the data before the
conclusion. Was a source late? Is a period partially loaded? Did a big
customer's billing shift? Do not walk into a CFO's office with a 30% drop you
have not verified.*

**Feedback.** Score each area 1–5 and give one specific improvement per area.

---

<a name="mock2"></a>
## Mock interview 2 — the modelling test *(after Module 20)*

Ninety minutes, Excel, given a one-page case and historical financials. This
is the standard banking and PE screen.

**The task.** "Here are three years of financials for Nilgiri Spice Foods.
Build a three-year forecast and tell me what the business is worth."

**What is actually being marked**, in order of weight:
1. Does the model balance? *If not, almost nothing else counts.*
2. Is it laid out so a reviewer can follow it in two minutes?
3. Are the assumptions anchored to history and visible?
4. Is there a sensible answer at the end, and can they defend it?
5. Speed — did they finish?

**The verbal follow-ups**, which are half the marks in a real one:
* "Why did you assume 8% growth?"
* "What happens to your valuation if WACC is 100bps higher?" *They should
  answer from the sensitivity table they already built, in five seconds.*
* "Walk me through what happens to all three statements if depreciation goes
  up ₹100."
* "How much of your value is terminal value? Are you comfortable with that?"

**Common failures to warn about in advance:** running out of time because
they formatted for forty minutes; hardcoding the historical balance sheet
check to zero to make it look balanced *(this is treated as dishonest, not
sloppy — say so)*; building an elaborate revenue driver tree and then a
one-line cost forecast; no sanity check on the final answer.

---

<a name="mock3"></a>
## Mock interview 3 — case and behavioural

**Case, 30 minutes.** "A subscription business tells you revenue grew 20% but
cash fell. Explain how, and what you would look at."

*Good answer: growth consumes working capital; annual billings moved to
monthly so cash arrives later; deferred revenue unwound; a large customer
went to 90-day terms; collections deteriorated; costs were paid up front for
growth. Then: I would look at DSO, the deferred revenue balance, the
collections curve by cohort, and the billing-term mix.*

Score on structure, not on getting the "right" answer.

**Behavioural.** These get less preparation than they deserve and are where
technically strong candidates lose offers. Prepare four stories, each with a
number in it:
* A time you found an error in someone else's work. *(Tests: care, and tact.)*
* A time you had to explain something technical to someone senior.
* A time you were wrong.
* A time you had to deliver under time pressure with incomplete data.

**The question they must be ready for:** "You are from a finance background,
not a technical one. Why should we believe you can do the data side?" The
honest answer is the strong one: *"I learned SQL specifically to stop waiting
for extracts. Here is a repository of what I built with it — including a
reconciliation that found three cost variances nobody had flagged. I am not a
software engineer and do not need to be; I get my own data and I know when a
number is wrong."*

---

<a name="checklist"></a>
## Job-readiness checklist

Go through this with the student honestly. Anything unticked is next week's
work, and pretending otherwise helps nobody.

**SQL**
- [ ] Writes a multi-table aggregate query without looking anything up
- [ ] Uses window functions naturally for growth, ranking and running totals
- [ ] Always checks row counts around a join
- [ ] Handles NULLs deliberately rather than by accident
- [ ] Can reconcile two sources and explain the difference
- [ ] Can clean a genuinely dirty table and document the decisions
- [ ] Reads an error message and fixes it without help

**Accounting and modelling**
- [ ] Can walk any transaction through all three statements, with tax
- [ ] Builds a balancing three-statement model unaided
- [ ] Diagnoses an imbalance from its size
- [ ] Builds a DCF and knows exactly how fragile it is
- [ ] Builds an LBO and can do a paper one in five minutes
- [ ] Knows the ratios cold and what each one is really asking

**FP&A**
- [ ] Produces a management pack where every exhibit ties to every other
- [ ] Decomposes a variance into price, volume and mix
- [ ] Distinguishes timing from permanent
- [ ] Writes commentary a CFO would forward unedited

**Power BI**
- [ ] Builds a star schema and can justify every relationship's direction
- [ ] Writes measures rather than calculated columns, and knows why
- [ ] Uses CALCULATE confidently, including time intelligence
- [ ] Handles the April-March fiscal year correctly in DAX
- [ ] Designs a page that leads with the answer, not with the slicers
- [ ] Can reconcile a dashboard back to the underlying SQL, to the rupee

**Professional**
- [ ] Explains a technical result to a non-technical person in one sentence
- [ ] Says "I don't know, here is how I would find out"
- [ ] Sanity-checks every number before sending it
- [ ] Documents assumptions without being asked
- [ ] Has a portfolio, and can talk about any piece in it for ten minutes

---

<a name="next"></a>
## What to learn next

Once the checklist is complete, in rough order of return on effort for this
student's target roles:

1. **dbt** — how teams manage SQL properly. A weekend to learn, and it appears
   in a growing share of finance-analytics job specs.
2. **Tableau, if a target employer uses it** — the concepts transfer directly
   from Modules 25-27; only the syntax changes.
3. **Deeper Python** — proper pandas, then `statsmodels` if forecasting
   interests them.
4. **A domain certification if the target role demands it** — CFA for research
   and asset management; FMVA or a banking modelling course for a CV that
   needs an external signal; neither is a substitute for the portfolio.
5. **Version control (git)** — enough to keep the portfolio tidy and to not be
   the only person on the team who emails `model_v7_final_FINAL.xlsx`.
