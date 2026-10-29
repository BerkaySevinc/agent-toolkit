---
description: Runs /bug-review on everything the current branch has added compared with its base branch — the branch's commits and the uncommitted changes together, the way a pull request would show it. The base branch is found from the shared history and shown for you to confirm. Run only on the user's explicit request.
argument-hint: [optional: a base branch to compare with, what the change is meant to do, or a lighter, quicker run — in your own words]
disable-model-invocation: true
allowed-tools: Skill
---

The user typed `/bug-review-branch`: they asked for the `bug-review` skill on the whole branch against its base. Invoke the `bug-review` skill with the Skill tool, passing as its arguments a first line `REVIEW SCOPE: BRANCH` followed, on the next line, by `$ARGUMENTS`. Then follow that skill; do nothing else here.
