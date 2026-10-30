---
description: Runs /vuln-review on the whole project instead of a change — every reviewable file is read for vulnerabilities, old ones included. A project that is too big for one reviewer is offered in slices, with a choice of depth. Works in a folder that is not a git repository too. Run only on the user's explicit request.
argument-hint: [optional: a folder or files to limit it to, what you know about who uses the system and what is sensitive, or a lighter, quicker run — in your own words]
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/vuln-review-project`: they asked for the `vuln-review` skill on the whole project. Invoke the `vuln-review` skill with the Skill tool, passing as its arguments a first line `REVIEW SCOPE: WHOLE PROJECT` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
