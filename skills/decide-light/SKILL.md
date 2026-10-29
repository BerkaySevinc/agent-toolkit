---
description: The lighter, faster version of the /decide council — fewer advisors, no challenge or defense stage, about 10–12 sub-agent calls instead of 13–23. Same neutral brief, anonymous reviews, and result format. Run only on the user's explicit request.
argument-hint: [optional: the decision to analyze — defaults to the latest topic in this conversation]
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/decide-light`: they asked for the `decide` council in its lighter, faster mode. Invoke the `decide` skill with the Skill tool, passing as its arguments a first line `COUNCIL MODE: LIGHT` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
