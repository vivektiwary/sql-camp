# Spaced repetition — how the drill works and how to run it

## Why this exists

A student who meets window functions in week 6 and never sees them again has,
by week 14, lost most of it. They will discover that in an interview rather
than in a lesson. The quiz score from week 6 will still say 85%, which is
exactly the problem: a quiz measures what someone knows the day you teach it,
and nothing measures what they know three months later unless something is
built to.

`scripts/srs.py` is that thing. It shows each fact again just before it would
have been forgotten, so the total effort is small and the retention is high.

## The five commands you will actually use

```bash
# Once, at the very start of the course
python3 scripts/srs.py init

# When you finish teaching a module, bring its cards into circulation
python3 scripts/srs.py unlock --module 8

# At the start of every session
python3 scripts/srs.py due --json --limit 5

# After asking each one
python3 scripts/srs.py grade 47 4

# Before every unit test, and whenever the student seems to be sliding
python3 scripts/srs.py stats
```

The student can also drill alone between sessions:

```bash
python3 scripts/srs.py review          # interactive: question, answer, self-grade
python3 scripts/srs.py forecast        # how many cards fall due over the next fortnight
```

The database lives at `progress/srs.db`, beside the progress file. Override
it with `--db` or the `SRS_DB` environment variable.

## The quality scale

Mark honestly. Inflated grades push a card months into the future and the
student loses it silently.

| Grade | Means |
|---|---|
| 5 | Answered instantly and correctly |
| 4 | Correct, needed a moment |
| 3 | Correct, but a struggle |
| 2 | Wrong, but recognised the answer immediately |
| 1 | Wrong, vaguely familiar |
| 0 | No idea |

Anything below 3 counts as a lapse: the card resets to tomorrow and its ease
falls.

**Grade the understanding, not the wording.** If the student explains DSO
correctly in their own words but does not say "days sales outstanding", that
is a 5. If they recite the definition and cannot say what it is for, that is a
2. The card text is a prompt, not a script.

## How the scheduling works

SM-2, the algorithm behind Anki. Each card carries an *ease* starting at 2.5.

* First correct answer → due in 1 day
* Second → 6 days
* After that → the previous gap multiplied by the ease

Answer well and the ease creeps up, so the gaps stretch: 1, 6, 16, 43, 120
days. Answer badly and the ease falls and the card comes back tomorrow. A card
the student finds easy costs almost nothing; a card they find hard gets shown
until it sticks.

## Leeches — the important bit

A card forgotten four or more times is flagged as a **leech**, in both
`due --json` (`"leech": true`) and `stats`.

**Do not just ask it again.** Repeated failure on one card almost never means
insufficient repetition. It means a mental model one layer down is missing —
someone who cannot keep GROUP BY straight usually does not really believe that
a table is an unordered set of rows. Go back to the curriculum, re-teach the
idea underneath, then:

```bash
python3 scripts/srs.py reset 47
```

That clears the card's history so it starts again from a genuine foundation.

## Reading `stats`

The **average ease** per module is the honest measure of retention, and it is
better than any quiz score because ease only falls when a student gets
something wrong *weeks* after being taught it.

| Average ease | Status | What to do |
|---|---|---|
| 2.4 and above | solid | Nothing |
| 2.0 – 2.4 | holding | Nothing yet, but watch it |
| 1.7 – 2.0 | shaky | Revisit in the next warm-up, add exercises |
| Below 1.7 | not learned | Re-teach the module before the next unit test |

Check `stats` before every unit test. A module below 1.7 will fail the test
regardless of how well the original lesson went, and finding that out
beforehand is the entire point.

## Adding cards

The seeded deck (`assets/srs/seed_cards.json`, 118 cards across all 28
modules) covers the concepts. **The best cards are the ones you add from the
student's own mistakes, in their own words**, on the day they make them:

```bash
python3 scripts/srs.py add --module 5 \
  --question "You joined budget to the ledger on account_id and the total was 147x too big. Why?" \
  --answer "Grain mismatch: budget is monthly per account and department, the ledger is per transaction. Aggregate both sides to a common grain first, then join."
```

Cards written this way are remembered far better than generic ones, because
they carry the memory of getting it wrong.

## Rules for good cards

* **One idea per card.** If the answer has two halves, it is two cards.
* **Ask for the reason, not the keyword.** "Why does NOT IN break on NULLs?"
  beats "What does NOT IN do?"
* **Keep answers short enough to say out loud.** If it takes a paragraph, the
  card is really a lesson.
* **Include numbers where numbers are the point.** "3.0x over five years is
  roughly what IRR?" is a good card because interviewers ask exactly that.
* **Never make a card the student cannot yet answer.** Cards are for
  retention, not instruction. Unlock a module only after teaching it.
