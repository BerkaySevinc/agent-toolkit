---
description: The fixing version of /double-check — the same general check of your changes (secrets, bugs, forgotten things, anything that should not be in a public repo, anything unnecessary there), but it fixes what it can safely fix first and then reports what was fixed and what was not. Run only on the user's explicit request.
argument-hint: "[optional: what to check, in your own words — defaults to what this session changed]"
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/double-check-fix`: they asked for the `double-check` skill in its fixing mode. Invoke the `double-check` skill with the Skill tool, passing as its arguments a first line `MODE: FIX` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
