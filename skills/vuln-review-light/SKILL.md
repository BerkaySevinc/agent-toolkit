---
description: The lighter, faster version of /vuln-review — a quick scan with the three core angles and no sweep, about 7–10 sub-agent calls instead of 10–21; for a scope that is too big, every slice gets the quick scan. Same verification of every finding, same report. Run only on the user's explicit request.
argument-hint: [optional: what to review, in your own words — defaults to your uncommitted changes — and what you know about who uses the system and what is sensitive]
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/vuln-review-light`: they asked for the `vuln-review` skill in its lighter, faster mode. Invoke the `vuln-review` skill with the Skill tool, passing as its arguments a first line `REVIEW MODE: LIGHT` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
