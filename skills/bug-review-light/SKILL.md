---
description: The lighter, faster version of /bug-review — a quick scan with two angles and no sweep, about 6–9 sub-agent calls instead of 9–20; for a scope that is too big, every slice gets the quick scan. Same verification of every finding, same report. Run only on the user's explicit request.
argument-hint: [optional: what to review, in your own words — defaults to your uncommitted changes — and what the change is meant to do]
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/bug-review-light`: they asked for the `bug-review` skill in its lighter, faster mode. Invoke the `bug-review` skill with the Skill tool, passing as its arguments a first line `REVIEW MODE: LIGHT` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
