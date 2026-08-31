# Model build checklist

Work down it. Do not skip a step because the model "looks fine" — every item
here exists because a real model failed on it.

## Before building

- [ ] What question is this model answering? Written down in one sentence at the top of the first sheet.
- [ ] Who reviews it, and what will they check first?
- [ ] Historical data pulled by query, not typed. Query saved alongside the model.
- [ ] Historical balance sheet balances in **every** period. Stop here if it does not.
- [ ] Units decided and written in every row label (₹m? ₹cr? units?).
- [ ] Sign convention decided and written down.

## Structure

- [ ] Inputs, calculations and outputs separated
- [ ] Every assumption is blue, on the input sheet, labelled, with the historical average shown beside it
- [ ] No hardcoded numbers inside formulas anywhere in the calculation area
- [ ] One formula per row, identical all the way across
- [ ] No merged cells; no hidden rows in the calculation area
- [ ] Timeline row at the top of every sheet, and every sheet uses the same one

## Schedules

- [ ] Revenue is driven by something, not a single growth percentage
- [ ] PPE rolls forward: opening + capex − depreciation = closing
- [ ] Debt rolls forward: opening + drawdown − repayment = closing
- [ ] Retained earnings roll forward: opening + net income − dividends = closing
- [ ] Working capital driven by DSO / DIO / DPO, not typed
- [ ] Circularity handled deliberately: iterative calculation on, or interest on opening debt
- [ ] Circuit breaker cell present and tested

## Checks block — visible on the front sheet

- [ ] Balance sheet: assets − (liabilities + equity) = 0, every period
- [ ] Cash flow: closing cash from the CF equals cash on the BS, every period
- [ ] Sources = uses (transaction models)
- [ ] Debt schedule closing balance equals the balance sheet debt line
- [ ] A single `Model OK?` cell, conditionally formatted, that goes red if any check fails
- [ ] Every check is a live formula. **A check hardcoded to zero is worse than no check** — it is a false assurance, and a reviewer who spots one stops trusting the whole model.

## Analysis

- [ ] Sensitivity table on the two variables that matter most
- [ ] Scenarios driven from one switch cell, not by editing assumptions by hand
- [ ] Output page a reader can understand without opening the calculations
- [ ] At least one chart, correctly labelled, with units

## Before sending

- [ ] Recalculated fully (`Cmd + =` on Mac) and all checks still pass
- [ ] Opened on a fresh screen and read as if you were the reviewer
- [ ] Every number in the summary traceable to a cell in the model
- [ ] The three key assumptions stated in writing, with where they came from
- [ ] What would have to be true for you to be materially wrong — written down
- [ ] Filename says what it is and when: `KVRA_DCF_2026-08-31_v3.xlsx`
