# Reference models

Three complete, working Excel models. They are the **target** a student
compares their own build against — not something to copy.

| File | What it is |
|---|---|
| `01_three_statement_model.xlsx` | Kaveri Retail: three years of actuals, a five-year forecast, balancing in every period |
| `02_dcf_and_comps.xlsx` | WACC build, DCF with both terminal value methods, two sensitivity grids, a 20-company comps table, and a reverse DCF |
| `03_lbo_model.xlsx` | Sources and uses, operating and debt model with a cash sweep, sponsor returns with attribution, a paper-LBO drill, IRR sensitivity |

Every sheet opens with a README tab explaining the layout, what to notice, and
one thing to try.

## How to use them, and when

**Not before the student has built their own.** Comparing your work against a
finished example teaches a great deal; copying one teaches nothing, and the
student cannot tell the difference until an interview does it for them.

The sequence that works:

1. Student builds their version from the curriculum brief.
2. It does not balance. They debug it using the fingerprints in Module 15.
3. *Then* open the reference model side by side and find the differences.
4. Discuss every difference: which is better, and why?

There will be differences that are not errors. A model is a set of judgement
calls, and defending yours against a different one is the actual skill.

## Rebuilding them

```bash
python3 scripts/build_reference_models.py assets/models
```

Then recalculate — openpyxl writes formulas but not their results, so a
freshly built file shows blanks until Excel or LibreOffice computes it. Open
each file in Excel once, or use the `xlsx` skill's `recalc.py`.

**Before trusting any rebuild, confirm the checks read zero:**

* `01`: Model!B103:I105 all zero, and Model!B107 reads `OK`
* `03`: 'Sources and Uses'!B15 zero, and Returns!B24 zero

The script pulls its historical figures from the `sqlcamp` database; the query
behind each block is quoted in the source. Point `COMPANY` at a different
company and the whole set rebuilds for it — which is how you set the same
capstone twice without setting the same capstone twice.

## What the models actually conclude

These are not rigged to produce a comfortable answer, and that is deliberate:

* The **DCF** values Kaveri at about ₹108 a share against a market price of
  ₹150. The reverse DCF shows the market is pricing roughly 7% terminal growth
  for a retailer — a real, defensible research disagreement.
* The **LBO** returns about 9.5% at the default 11× entry. No sponsor accepts
  that. The sensitivity grid shows you would have to enter near 9×, which
  means offering close to the undisturbed price, which means the board says
  no. That whole chain is a genuine deal conversation.

A model that always says "buy" has not been built, it has been arranged.
