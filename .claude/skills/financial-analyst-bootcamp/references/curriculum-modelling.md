# Part 2 — Financial modelling (Modules 13–24)

Excel first, Python second. Excel because that is where models are built,
reviewed and tested in interviews; Python at the end because that is how a
model becomes repeatable.

Every module pulls its raw data from the `sqlcamp` database the student
already knows. That is the whole point of the course design: **SQL gets the
numbers, Excel decides what they mean.** Have them export with a query, not
by typing.

Contents:

- [Module 13 — Accounting for modellers](#m13)
- [Module 14 — Excel craft and model discipline](#m14)
- [Module 15 — The three-statement model](#m15)
- [Module 16 — Forecasting and driver trees](#m16)  ← *Unit Test 4 after this*
- [Module 17 — Time value of money](#m17)
- [Module 18 — DCF valuation](#m18)
- [Module 19 — Comps and precedent transactions](#m19)
- [Module 20 — LBO modelling](#m20)  ← *Unit Test 5 after this*
- [Module 21 — M&A and accretion/dilution](#m21)
- [Module 22 — Credit analysis](#m22)
- [Module 23 — FP&A: budgets, forecasts, variance](#m23)
- [Module 24 — Unit economics, scenarios, and Python](#m24)  ← *Unit Test 6 + Final exam*

---

<a name="m13"></a>
## Module 13 — Accounting for modellers

**Objective.** The student can explain, without notes, how a rupee of
anything moves through all three statements.

Most finance students have done accounting. Very few have done it *the way a
modeller needs it*, which is: given a change, where does it show up, and does
the balance sheet still balance? Test that before assuming it.

**The one-sentence version of each statement.**

* **Income statement** — did we make a profit over a period? Accrual basis:
  revenue when earned, cost when incurred, regardless of cash.
* **Balance sheet** — what do we own and owe at one instant. Always balances,
  by definition, not by luck.
* **Cash flow statement** — the bridge. It exists precisely because profit is
  not cash.

**The three links, which the student must be able to draw from memory.**

1. Net income flows to retained earnings on the balance sheet, and is the top
   line of the cash flow statement.
2. Ending cash from the cash flow statement is the cash line on the balance
   sheet.
3. Depreciation reduces net income, is added back in the cash flow statement,
   and reduces net PPE on the balance sheet.

**The drill.** Give scenarios and make them state the effect on all three
statements, with the tax effect, out loud. Do at least ten. This is the most
common technical interview question in all of finance.

| Scenario | Answer to check against |
|---|---|
| Depreciation increases by ₹100 (25% tax) | IS: EBIT −100, net income −75. CF: NI −75, add back D&A +100, so cash +25. BS: PPE −100, cash +25, retained earnings −75. Balances. |
| We buy ₹500 of inventory on credit | IS: nothing. CF: inventory −500, payables +500, net zero. BS: inventory +500, payables +500. Balances. |
| A customer pays a ₹200 invoice | IS: nothing (revenue was recognised at invoice). CF: receivables −200 so cash +200. BS: cash +200, receivables −200. |
| We raise ₹1,000 of debt at 10% | Year 1 IS: interest −100, net income −75. CF: +1,000 financing, −75 net income +0 non-cash. BS: cash +925, debt +1,000, retained earnings −75. |
| We write off ₹300 of inventory | IS: COGS +300, net income −225. CF: NI −225, add back the non-cash write-off +300, cash +75 from the tax shield. BS: inventory −300, cash +75, RE −225. |

**Working capital, the thing that trips everyone.** An increase in a working
capital *asset* consumes cash; an increase in a working capital *liability*
provides it. Growing companies burn cash on receivables and inventory even
while profitable, and that is what kills them.

Make them prove it on our data:

```sql
SELECT period_end, net_income, change_in_wc, cfo, capex, cfo + capex AS free_cash_flow
FROM fs_cash_flow WHERE company_id = 1 ORDER BY period_end;
```

Then ask: in which quarters was this company profitable but cash-negative,
and why?

**Key ratios to memorise**, with what each one is really asking:

| Ratio | Formula | The question it answers |
|---|---|---|
| Gross margin | gross profit / revenue | Do we make money on the product itself? |
| EBITDA margin | EBITDA / revenue | Do we make money before capital structure? |
| ROE | net income / equity | What do shareholders earn? |
| ROIC | NOPAT / (debt + equity − cash) | Does the business earn more than capital costs? |
| Current ratio | current assets / current liabilities | Can we pay the next year's bills? |
| Net debt / EBITDA | (debt − cash) / EBITDA | How many years of profit would clear the debt? |
| Interest cover | EBIT / interest | How close are we to breaching a covenant? |
| DSO | receivables / revenue × 365 | How long do customers take to pay? |
| DIO | inventory / COGS × 365 | How long does stock sit? |
| DPO | payables / COGS × 365 | How long do we take to pay? |
| Cash conversion cycle | DSO + DIO − DPO | How many days of cash the business ties up |

**Homework.** Pull all three statements for two companies from `sqlcamp`,
compute every ratio above for FY26, and write 300 words on which is the
better business and why. That written paragraph is the deliverable — the
ratios are just evidence.

---

<a name="m14"></a>
## Module 14 — Excel craft and model discipline

**Objective.** Build models other people can open, understand and trust.

**Open with this.** "A model nobody can check is worth nothing, however
clever it is. Most of what follows is convention, not cleverness — but
breaking convention is how a reviewer decides you are junior in about four
seconds."

**The conventions, which are near-universal in banking and PE.**

* **Blue font = hardcoded input. Black font = formula. Green = link to
  another sheet.** No exceptions. A reviewer scans for blue to find every
  assumption in the model.
* **Never hardcode a number inside a formula.** `=B12*0.25` is wrong;
  `=B12*$C$4` with 25% in C4 labelled "tax rate" is right. Every hardcode
  inside a formula is a number nobody will ever find again.
* **One row, one formula, all the way across.** If column H differs from
  column G, a reviewer must be able to see why. Inconsistent formulas across
  a row are the single most common source of model error.
* **Inputs on their own sheet or block.** Calculations in the middle. Outputs
  at the end. Same idea as staging → intermediate → marts in Module 12.
* **Units in the row label**, always: "Revenue (₹m)", "Growth (%)". Mixing
  millions and units is the error that survives review.
* **Signs: one convention, stated at the top.** Costs positive and subtracted,
  or costs negative and added — either works, mixing them does not.
* **No merged cells. No hidden rows in the calculation area. No circular
  references you did not intend.**

**Formulas that matter, in rough order of usefulness.**

`SUM`, `SUMIFS`, `SUMPRODUCT`, `IF`, `IFS`, `IFERROR`, `MIN`, `MAX`,
`AND`/`OR`, `XLOOKUP` (or `INDEX`+`MATCH` if the student's Excel is older),
`EOMONTH`, `EDATE`, `YEARFRAC`, `NPV`, `XNPV`, `IRR`, `XIRR`, `PMT`,
`ROUND`, `CHOOSE`, `OFFSET` (know it, avoid it), `Data Table` for
sensitivities, `Goal Seek`, `Name Manager`.

**`INDEX`/`MATCH` versus `XLOOKUP`, and why it is worth teaching both.**
`XLOOKUP` is better in every way and the student should use it. They must
still be able to *read* `INDEX`/`MATCH`, because the model they inherit in
their first job was built in 2016.

**Anchoring.** `$` locks a row or column when you drag. Teach `F4` cycling.
Half of all "my model broke when I copied it right" is a missing dollar sign.
Have them build a 12×5 sensitivity grid from a single formula written once in
the top-left and dragged everywhere — it either works perfectly or not at all,
which makes it a superb drill.

**Circular references.** A three-statement model has a real one: interest
depends on average debt, debt depends on the cash flow, the cash flow depends
on interest. Two ways to handle it:

1. Turn on iterative calculation (Excel → Settings → Calculation → iterative,
   100 iterations, 0.001 change). Simple, and standard in banking.
2. Break the circularity by calculating interest on *opening* debt instead of
   average debt. Slightly less precise, far more robust, and preferred by
   many PE firms because it never produces the dreaded `#VALUE!` cascade.

Teach both. Have them build a **circuit breaker**: a cell `Circ_Break` with
0 or 1, and interest formulas wrapped in `=IF($C$2=1, 0, <interest calc>)`.
When the model blows up, flip it to 1, recalculate, flip it back. Every
banking model has one, and knowing why is an interview-worthy detail.

**Error checks.** Every model gets a checks block, visible on the front sheet:

* Balance sheet check: `total assets − (total liabilities + equity)` = 0
* Cash flow check: `closing cash from CF − cash on BS` = 0
* Sources = uses in any transaction model
* A single `Model OK?` cell: `=IF(SUM(all checks)=0,"OK","ERROR")`, conditionally formatted red

**Homework.** Rebuild the Module 13 ratio analysis as a properly formatted
Excel model: an input sheet holding the SQL output, a calculation sheet, an
output sheet with a small table and one chart, blue/black colour discipline,
units on every row, and a checks block. Mark it against the conventions
above, harshly. It is far kinder to be strict here than in their first job.

---

<a name="m15"></a>
## Module 15 — Building a three-statement model

**Objective.** Build a working, balancing, forecast three-statement model
from scratch. This is *the* deliverable of corporate finance.

Budget three sessions. Nobody gets this in one, and pretending otherwise
damages confidence.

**Get the history with SQL** — one query, no typing:

```sql
SELECT i.period_end, i.revenue, i.cogs, i.sga, i.rnd, i.other_opex,
       i.depreciation, i.amortisation, i.interest_expense, i.tax_expense, i.net_income,
       b.cash, b.accounts_receivable, b.inventory, b.accounts_payable,
       b.ppe_net, b.short_term_debt, b.long_term_debt, b.retained_earnings, b.total_equity,
       cf.capex, cf.dividends_paid
FROM fs_income_statement i
JOIN fs_balance_sheet b  USING (company_id, period_end)
JOIN fs_cash_flow    cf  USING (company_id, period_end)
WHERE i.company_id = 1
ORDER BY i.period_end;
```

**Build order — follow it exactly, and do not move on until each step ties.**

1. **Historical actuals**, three years, pasted into the input sheet. Check the
   balance sheet balances in every historical column *before building
   anything else*. If history does not balance, the forecast never will.
2. **Ratio analysis of history**: margins, growth, DSO/DIO/DPO, capex as % of
   revenue, D&A as % of opening PPE, effective tax rate. This is where
   assumptions come from — a forecast assumption with no historical anchor is
   a guess, and a reviewer will ask.
3. **Assumptions block**, all blue, all labelled, all with the historical
   average printed alongside for comparison.
4. **Revenue forecast**, driven (Module 16), never a flat "grows 8%".
5. **Cost forecast** as percentages of revenue, or per-unit where that is more
   honest.
6. **Down to EBITDA.** Stop. Sense-check the margin trend against history.
7. **Depreciation schedule.** Opening PPE + capex − depreciation = closing PPE.
   Depreciate as a % of opening PPE, or a full waterfall by asset year if you
   are being thorough.
8. **Down to EBIT.**
9. **Debt schedule.** Opening debt, mandatory repayment, revolver draw or
   repay, closing debt, interest on average or opening balance.
10. **Interest** → **pre-tax income** → **tax** → **net income.**
11. **Cash flow statement**: NI, add back D&A, working capital movements,
    capex, financing. Closing cash.
12. **Balance sheet**: link cash from step 11, working capital from the day
    assumptions, PPE from step 7, debt from step 9, retained earnings from
    step 10 less dividends.
13. **Balance.** It will not, the first time. See below.

**The working capital block, which drives half the cash flow:**

```
Accounts receivable = DSO / 365 × revenue
Inventory           = DIO / 365 × COGS
Accounts payable    = DPO / 365 × COGS
Change in working capital = −(ΔAR) − (ΔInventory) + (ΔAP)
```

**When the balance sheet does not balance.** It will not, and this moment is
where students give up, so pre-empt it. Teach the diagnostic, not the fix:

1. Find the **first period** that fails. Everything after is contamination.
2. The imbalance amount is a clue. Search the model for that exact number —
   Excel's Find on the value will usually land on the culprit.
3. Check the usual suspects in order: (a) net income not flowing to retained
   earnings, (b) cash on the balance sheet not linked to the cash flow
   statement, (c) a working capital movement with the wrong sign, (d) capex
   entered positive in one place and negative in another, (e) dividends
   deducted twice, (f) a row not summed into its total.
4. If the imbalance equals net income, it is (a). If it equals capex, it is
   (d). If it doubles each period, something is cumulative that should be
   periodic. **Teach these fingerprints** — an experienced modeller diagnoses
   an imbalance from its size in about ten seconds, and it looks like magic
   until you know the trick.

**Homework.** A four-year quarterly forecast three-statement model for Kaveri
Retail (company_id 1), balancing in every period, with a checks block and a
one-page written summary of every assumption and where it came from.

---

<a name="m16"></a>
## Module 16 — Forecasting and driver trees

**Objective.** Assumptions the student can defend in a meeting.

**Open with this.** "Anyone can type 8% into a growth cell. What gets you
hired is being able to answer 'why 8%?' with something other than 'it was
7.8% last year'."

**Top-down versus bottom-up.** Top-down: market size × share. Bottom-up:
units × price, or customers × ARPU, or stores × sales per store, or heads ×
productivity. Bottom-up is almost always more defensible and always more
useful, because each driver can be attacked and defended separately.

**Driver trees for the businesses in our data:**

* **Retail (Kaveri):** stores × average sales per store per month, split into
  footfall × conversion × basket size. Plus new store openings and the
  maturity curve of a new store.
* **Software (Meridian):** opening ARR + new ARR − churned ARR + expansion
  ARR = closing ARR. New ARR = leads × conversion × average deal size, or
  sales heads × quota × attainment.
* **Utility (Chenab):** capacity × utilisation × tariff.
* **Bank (Stonemark):** average interest-earning assets × net interest margin,
  plus fee income, less credit costs.

Have them build the software one against the actual subscription data:

```sql
WITH months AS (
    SELECT DISTINCT month_start_date AS m FROM dim_date
    WHERE date_key BETWEEN DATE '2023-04-01' AND DATE '2026-06-30'
)
SELECT m.m AS month,
       ROUND(SUM(s.mrr) FILTER (WHERE s.start_date <= m.m
                                AND (s.end_date IS NULL OR s.end_date > m.m))) AS mrr,
       count(*)         FILTER (WHERE s.start_date <= m.m
                                AND (s.end_date IS NULL OR s.end_date > m.m))  AS active_customers
FROM months m CROSS JOIN saas_subscription s
GROUP BY m.m ORDER BY m.m;
```

That query alone is a strong portfolio piece — it reconstructs a full
month-by-month recurring revenue history from raw subscription records, which
is genuinely what a fintech analyst is asked for in week one.

**Seasonality.** Compute a seasonal index from history (each month's share of
its year's total, averaged across years) and apply it to the forecast rather
than assuming flat months. Our retail and consumer companies have real
seasonality built in; make them find it rather than telling them it is there.

**Sanity checks on any forecast**, which they should apply to their own work
before anyone else does:

* Does the implied market share ever exceed something plausible?
* Does margin expand forever? Why would competition allow that?
* Does headcount grow slower than revenue? By how much, and is that credible?
* Does the model imply a working capital release that never reverses?
* What does the forecast imply about ROIC in the final year, versus history?

**Homework.** Build a bottom-up revenue forecast for Meridian Softworks from
the subscription data: cohort-based retention, new customer additions, ARPU
by segment. Compare it to a naive "grows at last year's rate" forecast and
write 200 words on where and why they diverge.

---

<a name="m17"></a>
## Module 17 — Time value of money

**Objective.** Discounting, and every function that does it.

**The idea, in their language.** ₹100 next year is not ₹100. It is ₹100
divided by (1 + the return you could have got elsewhere for the same risk).
That is the whole of valuation.

**Functions, and the traps in each.**

| Function | Use | Trap |
|---|---|---|
| `NPV` | Even, annual periods | Excel's `NPV` assumes the **first cash flow is one period away**. For a project with an outflow today, write `=C4 + NPV(rate, D4:H4)`. Getting this wrong overstates every project by one period of discounting. |
| `XNPV` | Actual dates | Needs a date for every cash flow. Almost always the right choice. |
| `IRR` | Even periods | Can return multiple answers when signs flip more than once, and fails on cash flows that never turn positive. |
| `XIRR` | Actual dates | Same caveats, but with real dates |
| `PMT` / `IPMT` / `PPMT` | Loan schedules | Signs. Excel returns a negative payment for a positive loan. |
| `EFFECT` / `NOMINAL` | Rate conversions | Monthly compounding is not annual ÷ 12 |

**Mid-year convention.** Cash arrives through the year, not on 31 December,
so discount at t = 0.5, 1.5, 2.5 rather than 1, 2, 3. It raises a valuation by
roughly half a year's discounting — several percent — and interviewers ask
about it precisely because it shows whether the candidate has built a DCF or
only read about one.

**WACC.** Build it once, properly, and never let them treat it as a given:

```
Cost of equity  = risk-free rate + beta × equity risk premium
Cost of debt    = pre-tax cost of debt × (1 − tax rate)
WACC            = E/(D+E) × cost of equity + D/(D+E) × after-tax cost of debt
```

Weights are **market** values, not book. Discuss levered versus unlevered
beta and why you re-lever a peer beta to the target's capital structure —
this is a standard interview question and a standard place to be caught out.

**Homework.**
1. A project costs ₹5,000 today and returns ₹1,400 a year for five years. NPV at 10%? IRR? Payback? Discounted payback? Do it with and without mid-year convention and explain the gap.
2. Build a WACC for Kaveri Retail using its actual debt from the balance sheet, a market cap from its share price × shares outstanding, an assumed beta of 1.1, a 7% risk-free rate and a 6% equity risk premium.
3. Show a case where IRR ranks two projects differently from NPV, and explain which you would follow and why.

---

<a name="m18"></a>
## Module 18 — DCF valuation

**Objective.** Build a defensible DCF and know exactly how fragile it is.

**The build.**

1. **Unlevered free cash flow** = EBIT × (1 − tax) + D&A − capex − Δworking capital.
   Say clearly why it is unlevered: we are valuing the *business*, before
   deciding who funds it. Interest is deliberately absent.
2. **Forecast period**, 5 to 10 years, ending when the business is plausibly
   at a steady state. If margins are still expanding in the final year, the
   forecast is too short.
3. **Terminal value**, two methods, always both:
   * Gordon growth: `TV = FCF_final × (1 + g) / (WACC − g)`, with g at or
     below long-run GDP growth. g of 5% in a 9% WACC world is not a forecast,
     it is a wish.
   * Exit multiple: `TV = EBITDA_final × multiple`, with the multiple taken
     from Module 19's comps.
   Then show the implied g from the exit multiple and the implied multiple
   from the g. If they disagree wildly, one of the assumptions is wrong.
4. **Discount** everything at WACC, mid-year convention.
5. **Enterprise value** = sum of discounted FCF + discounted TV.
6. **The bridge to equity value**: EV − net debt − minorities − preferred
   + associates = equity value. Then ÷ diluted shares = value per share.
7. **Sensitivity tables**: WACC against g, and WACC against exit multiple.
   Use Excel's Data Table.
8. **Football field chart**: the DCF range beside the comps range and the
   52-week trading range.

**The honesty conversation, which matters more than the mechanics.** In a
typical DCF, 60–80% of the value sits in the terminal value — a number
produced by two assumptions about a period beyond anyone's ability to
forecast. Have them compute that percentage in their own model and say it out
loud. A DCF is a structured way of showing what you must believe to justify a
price, not a machine that produces truth. Analysts who present it as truth get
found out.

**Homework.** A full DCF of Kaveri Retail off the Module 15 model: both
terminal value methods, both sensitivity tables, an EV-to-equity bridge, a
value per share, and a one-page memo stating your value, your three key
assumptions, and what would have to be true for you to be wrong by 30%.

---

<a name="m19"></a>
## Module 19 — Comparable companies and precedent transactions

**Objective.** Value a company by what similar ones are worth, and know when
that is misleading.

**Concepts.** Enterprise value versus equity value and why the numerator and
denominator must match: EV pairs with EBITDA, EBIT and revenue (pre-interest,
so available to everyone); equity value pairs with net income and EPS
(post-interest, so shareholders only). Pairing EV with net income is the
classic howler.

**The EV bridge**, which they must be able to recite:

```
Equity value (market cap)
+ total debt
+ preferred stock
+ minority interest
− cash and equivalents
= enterprise value
```

**Multiples to know:** EV/Revenue, EV/EBITDA, EV/EBIT, P/E, PEG, P/B (banks),
EV/EBITDAR (retail and airlines, where leases matter), price/AUM (asset
managers), EV/ARR (software).

**Calendarisation and LTM.** Companies have different year-ends — ours is
April–March, an American peer's is December. Comparing FY26 to CY2025 is not
comparing like with like. Teach LTM: *last twelve months* = last four
reported quarters, which our quarterly data supports directly:

```sql
SELECT c.ticker,
       SUM(i.revenue) AS ltm_revenue,
       SUM(i.ebitda)  AS ltm_ebitda,
       ROUND(SUM(i.ebitda) / NULLIF(SUM(i.revenue), 0) * 100, 1) AS ltm_margin_pct
FROM fs_income_statement i
JOIN dim_company c USING (company_id)
WHERE i.period_end > DATE '2025-03-31' AND i.period_end <= DATE '2026-03-31'
GROUP BY c.ticker
ORDER BY ltm_ebitda DESC;
```

**Building the comp set.** Screen on sector, then size, then growth and
margin. Then justify every inclusion *and every exclusion* in writing. The
comp set is where most of the answer is decided, and it is where a
disagreement in a meeting will actually happen — not over the arithmetic.

**Use the median, not the mean**, and show the quartiles. One company with a
150× multiple destroys a mean and tells you nothing.

**Precedent transactions.** Same idea, using prices actually paid in
acquisitions. They run higher than trading comps because of the control
premium and expected synergies. Note our dataset has no transaction data —
explain the method, and set the exercise as building the *template* they
would fill from a real source.

**Homework.** Build a comps table for the six software and analytics
companies: LTM revenue, LTM EBITDA, margins, growth, market cap from prices,
net debt from the balance sheet, EV, and EV/EBITDA plus EV/Revenue. Median
and quartiles. Then a paragraph: which one looks mispriced, and what is the
most likely innocent explanation?

---

<a name="m20"></a>
## Module 20 — LBO modelling

**Objective.** Build a leveraged buyout model and compute sponsor returns.

**The idea in one paragraph.** A private equity fund buys a company using
mostly borrowed money, secured on the company itself. The company's cash flow
pays the debt down. After five years the fund sells. Because the debt shrank
and the equity cheque was small, the equity multiplies — provided nothing
goes wrong, which is the entire risk.

**The build.**

1. **Entry.** Purchase enterprise value = LTM EBITDA × entry multiple.
2. **Sources and uses.** Uses: purchase equity, refinance existing debt, fees.
   Sources: new debt tranches, sponsor equity, rollover equity. **Sources must
   equal uses** — that is check number one.
3. **Debt tranches**, each with its own rate, amortisation and terms: revolver,
   term loan A, term loan B, mezzanine, sometimes PIK. Note PIK interest
   accrues rather than being paid, so it does not hit cash but does grow debt.
4. **Operating forecast**, five years, usually simpler than a full
   three-statement model but still needing a balance sheet if you want
   working capital to be honest.
5. **Cash sweep.** Free cash flow after mandatory amortisation pays down debt,
   usually the revolver then the term loans in order.
6. **Exit.** Exit EV = exit-year EBITDA × exit multiple. Equity at exit =
   exit EV − net debt at exit.
7. **Returns.** IRR from the sponsor's cheque to the exit proceeds, and MoM
   (money multiple) = proceeds ÷ cheque. A five-year 2.0× is roughly a 15%
   IRR; 3.0× is roughly 25%. Have them memorise that mapping, because it is
   asked constantly.
8. **Returns attribution.** Split the value created into three buckets:
   EBITDA growth, multiple expansion, and debt paydown. This is the single
   most revealing slide in any PE deck, because multiple expansion is luck and
   the other two are work.

**The paper LBO.** A PE interview will ask for one on paper, in five minutes,
no Excel. Drill it until they can: entry EBITDA 100, 10× entry = 1,000 EV,
6× debt = 600 debt and 400 equity; EBITDA grows to 150 by year 5; debt paid
down to 300; exit at 10× = 1,500 EV; equity = 1,200; 1,200 ÷ 400 = 3.0×; over
5 years that is about a 25% IRR. Make them do it out loud, with different
numbers, until it is automatic.

**Homework.** A full five-year LBO of Meridian Softworks: 11× entry, 5×
leverage across a term loan B and a revolver, 25% tax, exit at entry multiple.
Report IRR, MoM, and the returns attribution. Then a sensitivity grid of IRR
against entry and exit multiples, and a sentence on what leverage did to the
downside case.

---

<a name="m21"></a>
## Module 21 — M&A and accretion / dilution

**Objective.** Answer "does this deal add to earnings per share?" — the first
question anyone asks about an acquisition.

**The mechanics.**

1. Combined net income = acquirer NI + target NI + after-tax synergies
   − after-tax incremental interest on acquisition debt
   − after-tax lost interest income on cash used
   − incremental depreciation and amortisation from the purchase price
     allocation write-up.
2. New share count = acquirer shares + shares issued as consideration.
3. Pro-forma EPS = combined NI ÷ new shares. Compare to standalone EPS.
   Higher is accretive, lower is dilutive.

**The rule of thumb worth knowing.** In an all-stock deal, if the acquirer's
P/E is higher than the target's, the deal is accretive before synergies. The
intuition: you are buying earnings more cheaply than the market prices your
own. Have them derive it rather than memorise it.

**Purchase price allocation, briefly.** The premium over book value gets
allocated to identifiable assets written up to fair value, and the remainder
becomes goodwill. Written-up assets are depreciated or amortised, which hits
future earnings; goodwill is not amortised but is tested for impairment.

**Homework.** Model Cloudwell Systems acquiring Northgate Analytics at a 30%
premium, financed 50% cash at 8% debt and 50% stock. Compute EPS accretion or
dilution in year one, then find the breakeven synergy — the annual pre-tax
synergy at which the deal is exactly EPS-neutral. That breakeven number is the
one a board actually debates.

---

<a name="m22"></a>
## Module 22 — Credit analysis and covenant modelling

**Objective.** Assess whether a company can service its debt, and model what
happens when it cannot.

**The lender's question is different from the equity investor's.** Equity asks
"how much can this be worth?" Credit asks "what is the chance I do not get
paid back, and what do I recover if I don't?" Downside cases matter more than
base cases — the reverse of everything in Modules 18 and 20.

**Metrics.**

| Metric | Formula | Typical concern level |
|---|---|---|
| Leverage | net debt / EBITDA | Above 4–5× is stretched for most sectors |
| Interest cover | EBITDA / interest | Below 2× is uncomfortable |
| Fixed charge cover | (EBITDA − capex) / (interest + mandatory amortisation) | Below 1× means it cannot self-fund |
| DSCR | cash available for debt service / debt service | Below 1.2× breaches most loan agreements |
| Debt / equity | total debt / total equity | Sector-dependent |
| FFO / debt | funds from operations / total debt | Used by the rating agencies |

**Covenants.** A maintenance covenant is tested every quarter; an incurrence
covenant only bites when the company does something (raises debt, pays a
dividend). Build a covenant test row in the model: the ratio, the threshold,
and a pass/fail flag with conditional formatting. Then run a downside case and
find the exact quarter of breach. **That quarter is the deliverable** — a
credit memo says "covenants break in Q3 FY28 if revenue falls 12%", not
"leverage looks high".

**Build the credit screen from our data:**

```sql
WITH ltm AS (
    SELECT company_id, SUM(ebitda) AS ltm_ebitda, SUM(interest_expense) AS ltm_interest
    FROM fs_income_statement
    WHERE period_end > DATE '2025-03-31' AND period_end <= DATE '2026-03-31'
    GROUP BY company_id
)
SELECT c.ticker, c.sector,
       ROUND(l.ltm_ebitda) AS ltm_ebitda,
       ROUND(b.short_term_debt + b.long_term_debt - b.cash) AS net_debt,
       ROUND((b.short_term_debt + b.long_term_debt - b.cash) / NULLIF(l.ltm_ebitda,0), 2) AS net_leverage,
       ROUND(l.ltm_ebitda / NULLIF(l.ltm_interest,0), 2) AS interest_cover
FROM ltm l
JOIN dim_company c USING (company_id)
JOIN fs_balance_sheet b ON b.company_id = l.company_id AND b.period_end = DATE '2026-03-31'
ORDER BY net_leverage DESC;
```

**Also cover:** the Altman Z-score as a quick distress screen and its
limitations; what a rating agency actually looks at; the difference between
secured and unsecured recovery in a default.

**Homework.** Take the three most levered companies from that screen. For
each: a one-page credit summary with the ratios, a downside case (revenue
−15%, margin −300bps), the quarter any covenant would break, and a
recommendation to lend or decline with the rate you would want.

---

<a name="m23"></a>
## Module 23 — FP&A: budgets, rolling forecasts and variance analysis

**Objective.** Do the job that most finance graduates actually get hired to
do. This module is worth as much time as the DCF, and usually gets less.

**The annual cycle.** Strategic plan → annual budget → monthly actuals →
variance analysis → reforecast → next budget. The analyst lives in the middle
three.

**Variance analysis done properly.** "Marketing was ₹4m over budget" is a
data point. Analysis is *why*, decomposed:

* **Price/volume/mix** for revenue:
  * Volume variance = (actual units − budget units) × budget price
  * Price variance = (actual price − budget price) × actual units
  * Mix variance = the effect of selling a different blend of products
* **Rate/efficiency** for costs: paid more per unit, or used more units?
* **Timing versus permanent.** A cost that slipped from March to April is not
  an overspend, and calling it one wastes everyone's afternoon.
* **One-off versus run-rate.** The November legal bill in our ledger is one
  thing; the hosting cost that steps up permanently from January is quite
  another. One is noise, the other changes the forecast.

**The three planted anomalies.** Our ledger has three deliberate ones. Set
this as the module's core exercise: *"Find every FY26 variance worth
explaining, classify each as timing, one-off or run-rate, and write the
commentary you would send to the CFO."* Do not tell them how many there are.
Marking is on the classification and the commentary, not on finding them —
though a student who finds all three has genuinely earned it.

The starting query:

```sql
WITH actual AS (
    SELECT fiscal_month, account_id, dept_id, SUM(debit - credit) AS actual_amt
    FROM gl_journal_line WHERE fiscal_year = 2026 GROUP BY 1,2,3
),
budget AS (
    SELECT fiscal_month, account_id, dept_id, SUM(budget_amount) AS budget_amt
    FROM gl_budget WHERE fiscal_year = 2026 GROUP BY 1,2,3
)
SELECT a.account_name, d.dept_name, COALESCE(ac.fiscal_month, bu.fiscal_month) AS fm,
       ROUND(COALESCE(ac.actual_amt, 0))                              AS actual,
       ROUND(COALESCE(bu.budget_amt, 0))                              AS budget,
       ROUND(COALESCE(ac.actual_amt, 0) - COALESCE(bu.budget_amt, 0)) AS variance,
       ROUND((COALESCE(ac.actual_amt, 0) - COALESCE(bu.budget_amt, 0))
             / NULLIF(COALESCE(bu.budget_amt, 0), 0) * 100, 1)        AS variance_pct
FROM budget bu
FULL OUTER JOIN actual ac USING (fiscal_month, account_id, dept_id)
JOIN dim_account a    ON a.account_id = COALESCE(ac.account_id, bu.account_id)
JOIN dim_department d ON d.dept_id    = COALESCE(ac.dept_id, bu.dept_id)
WHERE ABS(COALESCE(ac.actual_amt,0) - COALESCE(bu.budget_amt,0)) > 200000
ORDER BY ABS(COALESCE(ac.actual_amt,0) - COALESCE(bu.budget_amt,0)) DESC;
```

**Also cover:**

* **Rolling forecasts** — always 12 months ahead, re-cut monthly. Compare to
  an annual budget that is stale by June.
* **Driver-based planning** — headcount plan drives salary, which drives
  benefits and recruitment. Our `gl_headcount` table supports this directly.
* **Month-end close** — accruals, prepayments, cut-off, the difference between
  a flash number on day 2 and a final number on day 5, and why the CFO wants
  both.
* **The management pack** — P&L versus budget and versus prior year, cash,
  headcount, KPIs, and one page of written commentary. The commentary is the
  bit that gets read, and the bit juniors write worst.

**Homework.** Produce a complete FY26 management pack for Meridian Softworks:
P&L by month against budget, department cost analysis, headcount and cost per
head, the top ten variances classified, a cash collections view from the
invoice data, and one page of written commentary a CFO could send onward
unedited. Mark the commentary hardest.

---

<a name="m24"></a>
## Module 24 — Unit economics, scenarios, and Python

**Objective.** The metrics a fintech or subscription business runs on, formal
scenario analysis, and enough Python to make the whole thing repeatable.

**Part A — SaaS and unit economics.** All computable from our data.

| Metric | Definition | The trap |
|---|---|---|
| MRR / ARR | Monthly / annual recurring revenue | One-off services revenue is not recurring. Do not include it. |
| ARR bridge | opening + new + expansion − contraction − churn = closing | The bridge must tie exactly. It is the first thing a fintech interviewer checks. |
| Gross churn | MRR lost ÷ opening MRR | Customer churn and revenue churn differ, and losing your biggest customer shows only in the second |
| Net revenue retention | (opening + expansion − contraction − churn) ÷ opening | Above 100% means the existing base grows by itself. This is the headline metric of the industry. |
| CAC | Sales and marketing spend ÷ new customers | Which period's spend against which period's customers? There is a lag. |
| LTV | ARPU × gross margin ÷ churn rate | Assumes churn is constant forever, which it is not. Cohort curves flatten. |
| LTV/CAC | Rule of thumb: above 3× | Very easy to flatter by choosing a convenient churn rate |
| CAC payback | CAC ÷ (ARPU × gross margin) | In months. Under 12 is good, over 24 is a funding problem. |
| Cohort retention | % of a signup cohort still paying after n months | The single most honest chart in software |

The cohort query — a genuine portfolio piece:

```sql
WITH cohorts AS (
    SELECT customer_id,
           DATE_TRUNC('month', start_date)::date AS cohort_month,
           start_date, end_date, mrr
    FROM saas_subscription
),
months AS (
    SELECT DISTINCT month_start_date AS m FROM dim_date
    WHERE date_key BETWEEN DATE '2023-04-01' AND DATE '2026-06-30'
)
SELECT c.cohort_month,
       (EXTRACT(YEAR FROM AGE(m.m, c.cohort_month)) * 12
        + EXTRACT(MONTH FROM AGE(m.m, c.cohort_month)))::int AS months_since_signup,
       count(*) FILTER (WHERE c.start_date <= m.m
                        AND (c.end_date IS NULL OR c.end_date > m.m)) AS active,
       ROUND(SUM(c.mrr) FILTER (WHERE c.start_date <= m.m
                        AND (c.end_date IS NULL OR c.end_date > m.m))) AS mrr
FROM cohorts c
JOIN months m ON m.m >= c.cohort_month
GROUP BY 1, 2
HAVING count(*) FILTER (WHERE c.start_date <= m.m
                        AND (c.end_date IS NULL OR c.end_date > m.m)) > 0
ORDER BY 1, 2;
```

Have them pivot that into a triangle in Excel — cohorts down, months across —
and shade it. It is the chart every investor asks for.

**Part B — Scenarios and sensitivity.**

* **Sensitivity**: move one variable, see the effect. Excel Data Table.
* **Scenario**: move a coherent *set* of variables together — base, upside,
  downside. Drive them from a single `CHOOSE`-based switch cell so that one
  input changes the whole model. Build it that way from the start rather than
  bolting it on.
* **Break-even / Goal Seek**: what growth rate justifies today's share price?
  This is the reverse DCF, and it is a far more honest question than "what is
  it worth?"
* **Monte Carlo, briefly**: sample the inputs from distributions, run
  thousands of times, look at the distribution of outcomes. Show it in Python
  rather than Excel. Be honest that its precision is mostly cosmetic if the
  input distributions are guesses.

**Part C — Python, at last.**

Install per Step 7 of `references/setup-macos.md`. Teach only what serves the
finance work — the student is not becoming a software engineer:

1. Connecting to the same database they already know:

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://localhost/sqlcamp")
df = pd.read_sql("""
    SELECT period_end, revenue, ebitda, net_income
    FROM fs_income_statement WHERE company_id = 1 ORDER BY period_end
""", engine)
print(df.head())
```

2. **pandas as a spreadsheet in code**: `df.head()`, `df.describe()`,
   `df.groupby()`, `df.merge()` (a JOIN), `df.pivot_table()`,
   `df.pct_change()` (a growth column), `df.rolling(4).mean()`.
   Teach each one by pointing at the SQL or Excel equivalent they already
   know — this module should feel like translation, not new learning.
3. `numpy_financial.npv`, `.irr` — the same functions from Module 17.
4. Charts with matplotlib; formatted Excel output with openpyxl.
5. **The point of all this**: a script that runs the monthly pack end to end —
   query the database, compute the variances, write a formatted Excel file,
   email-ready. Two hours of manual work becomes ten seconds, every month,
   identically. That is what automation buys, and it is the strongest single
   line on a junior analyst's CV.

**Homework.** Write `monthly_pack.py`: connects to `sqlcamp`, pulls FY26
actuals and budget, computes variances by department and account, flags
anything over a threshold, and writes a formatted multi-sheet Excel file.
It must run end to end from a cold start with one command.

---

## After Module 24

**Unit Test 6**, then the **Final exam**, then the capstones and mock
interviews in `references/capstones-and-jobs.md`.

Then **Part 3, Power BI** (`references/powerbi-track.md`). Raise the Windows
problem now rather than in three weeks: Power BI Desktop does not run on
macOS, and arranging a virtual machine takes a day and may cost money. The
options are set out at the top of that file.
