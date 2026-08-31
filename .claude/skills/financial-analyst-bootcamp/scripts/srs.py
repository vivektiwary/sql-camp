#!/usr/bin/env python3
"""
srs.py -- spaced repetition for the Financial Analyst Bootcamp.

Forgetting is the default. A student who studies window functions in week 6
and never sees them again has, by week 14, lost most of it -- and will find
that out in an interview rather than in a lesson. Spaced repetition fixes
that by asking each thing again just before it would have been forgotten.

The tutor drives this at the start of every session:

    python3 scripts/srs.py due --json --limit 5     # what to ask today
    python3 scripts/srs.py grade 47 4               # how it went (0-5)
    python3 scripts/srs.py stats                    # where the student is weak

The student can also drill alone:

    python3 scripts/srs.py review                   # interactive
    python3 scripts/srs.py add --module 8 --question "..." --answer "..."

Scheduling is SM-2, the algorithm behind Anki. Each card carries an "ease"
that rises when you answer well and falls when you do not; the gap until the
next showing is the previous gap multiplied by that ease. Answer badly and
the card comes back tomorrow.

No dependencies beyond the Python standard library. State lives in
progress/srs.db (SQLite) next to the student's progress file.
"""
import argparse, json, os, sqlite3, sys, textwrap
from datetime import date, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
SEED = os.path.join(HERE, "..", "assets", "srs", "seed_cards.json")
DEFAULT_DB = os.path.join(os.getcwd(), "progress", "srs.db")

SCHEMA = """
CREATE TABLE IF NOT EXISTS card (
    id          INTEGER PRIMARY KEY,
    ref         TEXT UNIQUE,          -- stable id from the seed file
    module      INTEGER NOT NULL,
    part        TEXT    NOT NULL,     -- 'SQL' or 'Modelling' or 'BI'
    kind        TEXT    NOT NULL,     -- concept | query | formula | number | judgement
    question    TEXT    NOT NULL,
    answer      TEXT    NOT NULL,
    tags        TEXT    NOT NULL DEFAULT '',
    ease        REAL    NOT NULL DEFAULT 2.5,
    interval    INTEGER NOT NULL DEFAULT 0,
    reps        INTEGER NOT NULL DEFAULT 0,
    lapses      INTEGER NOT NULL DEFAULT 0,
    due         TEXT,                 -- ISO date; NULL = not yet introduced
    suspended   INTEGER NOT NULL DEFAULT 0,
    added       TEXT    NOT NULL
);
CREATE TABLE IF NOT EXISTS review (
    id        INTEGER PRIMARY KEY,
    card_id   INTEGER NOT NULL REFERENCES card(id),
    reviewed  TEXT    NOT NULL,
    quality   INTEGER NOT NULL,
    interval  INTEGER NOT NULL,
    ease      REAL    NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_card_due ON card(due);
"""

QUALITY_HELP = """quality scale
  5  answered instantly and correctly
  4  correct, needed a moment
  3  correct, but it was a struggle
  2  wrong, but recognised the answer immediately
  1  wrong, vaguely familiar
  0  no idea"""


def connect(path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    con = sqlite3.connect(path)
    con.row_factory = sqlite3.Row
    con.executescript(SCHEMA)
    return con


def sm2(ease, interval, reps, quality):
    """SM-2. Returns (ease, interval_days, reps, lapsed)."""
    lapsed = quality < 3
    if lapsed:
        # Back to the start, but keep some of the ease -- a card you have
        # known before is not the same as one you have never seen.
        reps = 0
        interval = 1
    else:
        reps += 1
        if reps == 1:
            interval = 1
        elif reps == 2:
            interval = 6
        else:
            interval = max(1, round(interval * ease))
    ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    ease = max(1.3, min(3.0, ease))
    return round(ease, 3), int(interval), reps, lapsed


# ---------------------------------------------------------------------------
def cmd_init(con, args):
    with open(os.path.abspath(SEED)) as fh:
        cards = json.load(fh)
    today = date.today().isoformat()
    added = updated = 0
    for c in cards:
        row = con.execute("SELECT id FROM card WHERE ref = ?", (c["ref"],)).fetchone()
        if row:
            con.execute("UPDATE card SET question=?, answer=?, tags=?, module=?, part=?, kind=? "
                        "WHERE ref=?",
                        (c["question"], c["answer"], ",".join(c.get("tags", [])),
                         c["module"], c["part"], c["kind"], c["ref"]))
            updated += 1
        else:
            con.execute("INSERT INTO card (ref, module, part, kind, question, answer, tags, added) "
                        "VALUES (?,?,?,?,?,?,?,?)",
                        (c["ref"], c["module"], c["part"], c["kind"], c["question"],
                         c["answer"], ",".join(c.get("tags", [])), today))
            added += 1
    con.commit()
    total = con.execute("SELECT count(*) FROM card").fetchone()[0]
    print(f"Loaded seed deck: {added} new, {updated} updated, {total} cards total.")
    print("Cards stay dormant until the module is unlocked:")
    print("    python3 scripts/srs.py unlock --module 3")


def cmd_unlock(con, args):
    """Make a module's cards live. Called when a module is taught."""
    today = date.today().isoformat()
    n = con.execute("UPDATE card SET due = ? WHERE module <= ? AND due IS NULL",
                    (today, args.module)).rowcount
    con.commit()
    print(f"Unlocked {n} cards up to module {args.module}. They are due from today.")


def _due_rows(con, limit, module=None):
    today = date.today().isoformat()
    sql = ("SELECT * FROM card WHERE suspended = 0 AND due IS NOT NULL AND due <= ? ")
    params = [today]
    if module is not None:
        sql += "AND module = ? "
        params.append(module)
    # Oldest overdue first, then the leeches, then the rest.
    sql += "ORDER BY due ASC, lapses DESC, module ASC LIMIT ?"
    params.append(limit)
    return con.execute(sql, params).fetchall()


def cmd_due(con, args):
    rows = _due_rows(con, args.limit, args.module)
    if args.json:
        print(json.dumps([{
            "id": r["id"], "module": r["module"], "part": r["part"], "kind": r["kind"],
            "question": r["question"], "answer": r["answer"],
            "lapses": r["lapses"], "reps": r["reps"], "due": r["due"],
            "leech": r["lapses"] >= 4,
        } for r in rows], indent=2))
        return
    if not rows:
        print("Nothing due today. Warm up with three questions from the last module instead.")
        return
    print(f"{len(rows)} card(s) due:\n")
    for r in rows:
        flag = "  [LEECH - re-teach this, do not just re-ask it]" if r["lapses"] >= 4 else ""
        print(f"[{r['id']}] M{r['module']} ({r['kind']}){flag}")
        print(textwrap.fill(r["question"], 78, initial_indent="    ",
                            subsequent_indent="    "))
        print()
    print("Ask these, then record each one:  srs.py grade <id> <0-5>")


def cmd_grade(con, args):
    r = con.execute("SELECT * FROM card WHERE id = ?", (args.card_id,)).fetchone()
    if not r:
        sys.exit(f"No card with id {args.card_id}")
    if not 0 <= args.quality <= 5:
        sys.exit("quality must be 0-5\n\n" + QUALITY_HELP)
    ease, interval, reps, lapsed = sm2(r["ease"], r["interval"], r["reps"], args.quality)
    due = (date.today() + timedelta(days=interval)).isoformat()
    con.execute("UPDATE card SET ease=?, interval=?, reps=?, due=?, lapses=lapses+? WHERE id=?",
                (ease, interval, reps, due, 1 if lapsed else 0, r["id"]))
    con.execute("INSERT INTO review (card_id, reviewed, quality, interval, ease) VALUES (?,?,?,?,?)",
                (r["id"], date.today().isoformat(), args.quality, interval, ease))
    con.commit()
    lapses = r["lapses"] + (1 if lapsed else 0)
    msg = f"Card {r['id']} (M{r['module']}): next due {due} (in {interval}d), ease {ease}"
    if lapses >= 4:
        msg += ("\n  This card has now lapsed 4+ times. Re-ASKING it will not fix it -- the "
                "underlying idea\n  is missing. Re-teach the concept from the curriculum, then "
                "reset with:  srs.py reset " + str(r["id"]))
    print(msg)


def cmd_review(con, args):
    rows = _due_rows(con, args.limit, args.module)
    if not rows:
        print("Nothing due. Well done -- come back tomorrow.")
        return
    print(QUALITY_HELP + "\n")
    for i, r in enumerate(rows, 1):
        print(f"--- {i}/{len(rows)}  Module {r['module']} ({r['kind']}) " + "-" * 30)
        print(textwrap.fill(r["question"], 78))
        input("\n[Enter to see the answer] ")
        print("\n" + textwrap.fill(r["answer"], 78))
        while True:
            q = input("\nHow did you do? (0-5, or q to stop) ").strip().lower()
            if q == "q":
                return
            if q.isdigit() and 0 <= int(q) <= 5:
                break
        args.card_id, args.quality = r["id"], int(q)
        cmd_grade(con, args)
        print()


def cmd_add(con, args):
    ref = args.ref or f"custom-{date.today().isoformat()}-{abs(hash(args.question)) % 10**6}"
    con.execute("INSERT INTO card (ref, module, part, kind, question, answer, tags, due, added) "
                "VALUES (?,?,?,?,?,?,?,?,?)",
                (ref, args.module, args.part, args.kind, args.question, args.answer,
                 args.tags or "", date.today().isoformat(), date.today().isoformat()))
    con.commit()
    print(f"Added card {con.execute('SELECT last_insert_rowid()').fetchone()[0]}, due today.")
    print("Tip: the best cards come from the student's own mistakes, in their own words.")


def cmd_reset(con, args):
    con.execute("UPDATE card SET ease=2.5, interval=0, reps=0, lapses=0, due=? WHERE id=?",
                (date.today().isoformat(), args.card_id))
    con.commit()
    print(f"Card {args.card_id} reset. Re-teach the concept before the next review.")


def cmd_stats(con, args):
    today = date.today().isoformat()
    total, live = con.execute(
        "SELECT count(*), count(due) FROM card WHERE suspended = 0").fetchone()
    due = con.execute("SELECT count(*) FROM card WHERE due IS NOT NULL AND due <= ? "
                      "AND suspended = 0", (today,)).fetchone()[0]
    print(f"Deck: {total} cards, {live} in circulation, {due} due today.\n")
    print(f"{'Module':>7}  {'Part':<10} {'Cards':>6} {'Seen':>6} {'Avg ease':>9} "
          f"{'Lapses':>7}  Status")
    rows = con.execute("""
        SELECT c.module, c.part, count(*) n,
               sum(CASE WHEN EXISTS (SELECT 1 FROM review r WHERE r.card_id = c.id)
                        THEN 1 ELSE 0 END) seen,
               avg(c.ease) ease, sum(c.lapses) lapses
        FROM card c WHERE c.due IS NOT NULL AND c.suspended = 0
        GROUP BY c.module, c.part ORDER BY c.module""").fetchall()
    for r in rows:
        # Ease is the honest signal: a module sitting near the 1.3 floor is one
        # the student keeps getting wrong, whatever the quiz score said.
        if r["ease"] >= 2.4:   status = "solid"
        elif r["ease"] >= 2.0: status = "holding"
        elif r["ease"] >= 1.7: status = "shaky - revisit"
        else:                  status = "NOT LEARNED - re-teach"
        print(f"{r['module']:>7}  {r['part']:<10} {r['n']:>6} {r['seen']:>6} "
              f"{r['ease']:>9.2f} {r['lapses']:>7}  {status}")
    leeches = con.execute("SELECT id, module, question FROM card WHERE lapses >= 4 "
                          "AND suspended = 0 ORDER BY lapses DESC").fetchall()
    if leeches:
        print(f"\n{len(leeches)} card(s) keep being forgotten. Re-teach these, do not just re-ask:")
        for l in leeches:
            print(f"  [{l['id']}] M{l['module']}: {l['question'][:70]}")
    n7 = con.execute("SELECT count(*) FROM review WHERE reviewed >= ?",
                     ((date.today() - timedelta(days=7)).isoformat(),)).fetchone()[0]
    print(f"\nReviews in the last 7 days: {n7}")
    if n7 == 0 and live:
        print("None. Spaced repetition only works if it actually happens -- put it in the warm-up.")


def cmd_forecast(con, args):
    print("Cards due over the next 14 days:\n")
    for i in range(14):
        d = (date.today() + timedelta(days=i)).isoformat()
        n = con.execute("SELECT count(*) FROM card WHERE due = ? AND suspended = 0",
                        (d,)).fetchone()[0]
        overdue = ""
        if i == 0:
            n = con.execute("SELECT count(*) FROM card WHERE due <= ? AND suspended = 0",
                            (d,)).fetchone()[0]
            overdue = "  (includes anything overdue)"
        print(f"  {d}  {'#' * min(n, 50)} {n}{overdue}")


def main():
    # Piping into `head` should not produce a traceback.
    try:
        from signal import signal, SIGPIPE, SIG_DFL
        signal(SIGPIPE, SIG_DFL)
    except (ImportError, ValueError):
        pass
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--db", default=os.environ.get("SRS_DB", DEFAULT_DB),
                   help="path to the SRS database (default progress/srs.db)")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init", help="create the database and load the seed deck").set_defaults(fn=cmd_init)

    u = sub.add_parser("unlock", help="bring a module's cards into circulation")
    u.add_argument("--module", type=int, required=True); u.set_defaults(fn=cmd_unlock)

    d = sub.add_parser("due", help="list the cards due today")
    d.add_argument("--limit", type=int, default=5)
    d.add_argument("--module", type=int)
    d.add_argument("--json", action="store_true", help="machine-readable, for the tutor")
    d.set_defaults(fn=cmd_due)

    g = sub.add_parser("grade", help="record how a card went", epilog=QUALITY_HELP,
                       formatter_class=argparse.RawDescriptionHelpFormatter)
    g.add_argument("card_id", type=int); g.add_argument("quality", type=int)
    g.set_defaults(fn=cmd_grade)

    rv = sub.add_parser("review", help="interactive drill for the student")
    rv.add_argument("--limit", type=int, default=10); rv.add_argument("--module", type=int)
    rv.set_defaults(fn=cmd_review)

    ad = sub.add_parser("add", help="add a card, usually from a mistake the student just made")
    ad.add_argument("--module", type=int, required=True)
    ad.add_argument("--question", required=True); ad.add_argument("--answer", required=True)
    ad.add_argument("--part", default="SQL"); ad.add_argument("--kind", default="concept")
    ad.add_argument("--tags", default=""); ad.add_argument("--ref")
    ad.set_defaults(fn=cmd_add)

    rs = sub.add_parser("reset", help="reset a card after re-teaching the concept")
    rs.add_argument("card_id", type=int); rs.set_defaults(fn=cmd_reset)

    sub.add_parser("stats", help="mastery by module, and which cards keep being forgotten"
                   ).set_defaults(fn=cmd_stats)
    sub.add_parser("forecast", help="how many cards fall due over the next fortnight"
                   ).set_defaults(fn=cmd_forecast)

    args = p.parse_args()
    con = connect(args.db)
    args.fn(con, args)


if __name__ == "__main__":
    main()
