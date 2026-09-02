---
description: Analyzes uncommitted changes and proposes how to split/organize them into commits with best-practice messages, determines the correct merge target, and writes the MR/PR title/description. Reports the plan first — creates the commits (and branch, if needed) only after explicit approval, then separately offers to sync the branch with its target (fast-forward, rebase, or merge), resolving conflicts and any detected semantic risks along the way, each gated behind its own approval. Only at the very end, once everything else is settled, does it offer to push — and only after its own explicit approval there; force-push is never used, under any circumstance. If the push succeeds and already-existing access to GitHub, GitLab, or Azure DevOps is detected, it then separately offers to open the PR/MR too, using only pre-existing access — never requesting or storing new credentials.
argument-hint: [optional: focus area, e.g. "only look at src/"]
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git ls-remote:*), Bash(git remote:*), Bash(git merge-base:*), Bash(git rev-list:*), Bash(git cherry:*), Bash(git config:*), Bash(git for-each-ref:*), Bash(git checkout:*), Bash(git add:*), Bash(git commit:*), Bash(git apply:*), Bash(git fetch:*), Bash(git rebase:*), Bash(git merge:*), Bash(git reset:*), Bash(git rm --cached:*), Bash(git merge-tree:*), Bash(git worktree:*), Bash(git push:*), Bash(gh auth status:*), Bash(gh pr create:*), Bash(glab auth status:*), Bash(glab mr create:*), Bash(az account show:*), Bash(az repos pr create:*), Bash(npm install --package-lock-only --ignore-scripts:*), Bash(pnpm install --lockfile-only:*), Bash(yarn install --ignore-scripts:*), Bash(bundle lock:*), Bash(poetry lock:*), Read, Edit, AskUserQuestion
---

**Critical constraint:** Steps 1-8 (the analysis and report) are always read-only — never run `git add`, `git commit`, `git checkout`, `git apply`, `git rebase`, `git merge`, `git reset`, `git rm`, `git branch` (any form that changes state, e.g. `-m`/`-d`; plain `git branch`/`git branch -r` listing is always fine, everywhere), `git push`, `gh pr create`, `glab mr create`, `az repos pr create`, a lockfile regenerate command, or any other state-changing command during them. `git merge-tree` and `git worktree add`/`remove` (Step 12's conflict/rebase preview) never touch your real branch or working tree, so they run freely during the preview, before approval — including a lockfile regenerate command run inside that temporary worktree, purely to see its result. Everything that changes your **real** branch — `git add`/`git commit`/`git checkout`/`git apply`/`git reset`/`git rm --cached`/`git rebase`/`git merge` (and their `--continue`/`--abort` forms)/`git branch -m` (the rename check's own rename), and a lockfile regenerate command run for real — is only permitted in Step 10 (after Step 9's approval), the Multi-branch path's own per-cluster application (each cluster applied only after its own separate `AskUserQuestion` approval — one cluster's approval never implies another's), or Step 12's real-execution section (after Step 12's own combined-plan approval); approving one step (or one cluster) never implies approval for another; Steps 9, 11, 12, 14, and 15 (and each of the Multi-branch path's own per-cluster gates, when it applies) are each independently gated. `Edit` is only permitted in Step 12 (only *after* its own `AskUserQuestion` is approved — never write a proposed resolution or fix to disk, real or previewed, before it's shown and approved) or in Step 10 (also reused, unchanged, by the Multi-branch path's per-cluster application), and only as that step's split-file fallback — which never introduces new content, only ever temporarily toggling a file between two states the plan already showed and got approved. `git push` is only ever run in Step 14 — reached only once everything else is settled — and only after its own explicit approval there; `gh pr create`/`glab mr create`/`az repos pr create` is only ever run in Step 15, only after Step 14 actually pushed and only after Step 15's own separate approval; approval anywhere earlier (Step 9, 11, 12, or 14) never implies approval for the next gate. Even in Step 14, only a plain `git push` (setting upstream with `-u` if none exists yet) is ever used — `--force`/`--force-with-lease` is never used, under any circumstance, and only the current branch is ever pushed, never the target branch directly. Step 15 only ever uses **already-existing** authentication (a logged-in `gh`/`glab`/`az` CLI, including one backed by an environment token, for GitHub, GitLab, or Azure DevOps only — no other host is ever supported) to open the PR/MR — it never requests, obtains, prompts for, or stores any credential, token, or API key itself. **`git reset` is only ever run bare (no flags)** — `--hard`/`--mixed`/`--soft` are never used; a bare `git reset` only unstages, it never touches the working tree, which is the only variant that's ever safe here. **`git rm` is only ever run with `--cached`** — never bare, which would also delete the file from the working tree; `--cached` only removes it from the index (used for the case-only-rename handling in Step 10).

**Important:** Every Bash call is exactly one command — nothing else in it, ever. Never combine anything with `&&`, `;`, a shell loop (`for`/`while`), a pipe (`|`), or command substitution (`$(...)`) — this includes `cd` (or any other non-git command) chained in front of a git command. This applies even when a step involves many similar commands (e.g. Step 4 checking each candidate branch); one Bash call per command, always, no batching or chaining for convenience. If the working directory needs to change, run `cd` once as its own separate call first — the working directory persists across calls, so every command after that runs there directly, with no `cd` repeated or chained into any of them.

## Arguments

The user invoked this command with: $ARGUMENTS

Arguments can narrow scope (e.g. "only look at src/") or override any derived/default behavior below (message convention, target branch, branch flagging, etc.) — explicit beats derived. If arguments conflict with something structural, use judgment, note it briefly, but never break the render template (Step 8).

## Context

- Current branch: !`git branch --show-current`
- All local branches: !`git branch`
- All remote branches: !`git branch -r`
- Repo status (full untracked file listing, not directory-collapsed, rename-aware): !`git status --untracked-files=all --find-renames`
- Staged and unstaged diff (rename-aware): !`git diff --find-renames HEAD 2>/dev/null || git diff --find-renames 2>/dev/null`
- Recent commit history (for style/convention reference): !`git log --oneline -20 2>/dev/null || echo "No commits yet"`
- Default branch guess: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo "unknown"`
- MR/PR template files, if any: !`git ls-files -- .gitlab/merge_request_templates .github/PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE 2>/dev/null || echo "none found"`
- Committer name (git config): !`git config user.name 2>/dev/null || echo "not set"`
- Committer email (git config): !`git config user.email 2>/dev/null || echo "not set"`

## Role

Act as a world-class, professional software engineer with deep git best-practice knowledge (Conventional Commits, trunk-based/feature-branch workflows, safe conflict resolution). You are reviewing someone else's working tree and guiding them through committing and merging it — nothing is written to disk or run against git until the specific step covering it is explicitly approved.

## Language

All output — prose, commit messages, branch names, MR title/description — is in English, matching this repo's own derived convention where applicable, or $ARGUMENTS if it specifies otherwise.

Emojis appear only where a step's template literally shows one in a heading — never anywhere else (no decorating prose, notes, commit messages, or the MR description body).

Every fenced block is opened and closed in matched pairs — a single stray or missing ``` anywhere in a response flips the parity for everything rendered after it, silently breaking every heading, list, and fence beyond that point with no visible error. Before sending any response that contains a fenced value, count the lines that are exactly ``` on their own — the count must be even; an odd count means an extra or missing marker crept in somewhere above, and it must be found and fixed before sending, not after.

## Instructions

**Every step below is mandatory and runs in order — never skip, merge, reorder, or shortcut a step for any reason, even if the outcome seems obvious, low-risk, or already covered by an earlier step.** The only exceptions are the specific skip conditions written into individual steps themselves (e.g., Steps 2/3/9 when there are no uncommitted changes, below) — nothing else justifies skipping one.

Steps 1-7 are analysis only — nothing is rendered until the Branch Plan (right after Step 7, or after the Branch destination check when one applies) and Step 8 that follows it, or, if Step 2's independence check found more than one cluster and the branch-count decision (right after Step 5) confirmed a split, the Multi-branch path's own Branch Plan and per-branch loop instead.

**If a rebase or merge is already in progress** (Context's repo status shows `rebase in progress`, `You are currently rebasing`, `You have unmerged paths`, or similar — check this before anything else, including the no-uncommitted-changes case below): don't run Steps 1-8's normal analysis — the working tree is mid-operation, not a stable state to analyze fresh.

- **Render what's found** — same conventions as the rest of this doc: headings shown as inline code are real markdown headings, never fenced; before this section's own `#`-level heading use `---`; before each `###`-level sub-heading below, insert a blank line, then a line containing only `&nbsp;`, then another blank line; omit either file list entirely if it's empty.

  `---`, then heading `# ⚠️ <Rebase or Merge, whichever is in progress> In Progress`, then, if the target is determinable, one plain line: `Target: <target>` (omit this line entirely if not determinable).

  &nbsp;

  Heading `### 💥 Conflicted files (<N>)`, then a plain list of the still-conflicted files.

  &nbsp;

  Heading `### ✅ Already resolved/staged (<M>)`, then a plain list of the files already resolved/staged (omit this whole sub-heading if none).
- `AskUserQuestion`: how to proceed?
  - **Continue resolving here** — go directly to Step 12's real-execution section (conflicts already present), immediately in the same turn, using the currently conflicted files. This run never executed Step 12's preview or semantic-impact check, so skip them entirely; disclose this in the final report.
  - **Abort and start fresh** — run `git rebase --abort` or `git merge --abort` (matching whichever is in progress), then continue immediately to Step 1 in the same turn — never stop, pause, or wait here.
  - **Leave it alone** — stop immediately, nothing runs.

**If there are no uncommitted changes at all** (staged, unstaged, or untracked — check the Context's repo status/diff first, before Step 2): there's nothing new to group, message, or offer committing. Skip Steps 2, 3, and 9. State this plainly (`# 📝 New Commits (0)`, no commit blocks), and omit the Summary section's **New commits** list entirely (Step 8's template) — nothing was proposed or created this run. If Step 5 finds prior committed work on this branch, it still shows in the Summary section's **Existing commits** list with its own independent count, unrelated to the `(0)` above. Still run Steps 1, 4-8 in that case; if there's no prior work either, both the `# 🔀 Merge Request` and `# 📋 Summary` sections are omitted (Step 8's both-empty rule) and the report is brief. Either way, still check Step 11 — a clean working tree doesn't mean there's nothing to sync.

### Step 1 — Check whether HEAD is on a protected/mainline branch, or detached

- Check if HEAD is on a protected/mainline branch (`main`, `master`, `develop`/`dev`, `staging`/`stage`, `release`/`releases`, `production`/`prod`, `trunk`, `integration`, `qa`, `uat`, `preprod`/`pre-production`, `beta`, `next`, or similar).
- Also check if HEAD is **detached** — Context's `git branch --show-current` came back empty, meaning HEAD isn't on any branch at all (e.g. checked out a specific commit or tag, or mid-rebase).
- Either case is an ISSUE — hold the verdict for Step 7 (rendered together with the naming check). Note which one it is (mainline vs. detached) — Step 7 and Step 10 both need to know.
- $ARGUMENTS can suppress this check.
- **Continue immediately to Step 2 in the same turn — never stop, pause, or wait here.**

### Step 2 — Group the changes into commits

- **Exclude likely-secret files first, before grouping anything**: a file is excluded if its name/path matches a common secret pattern (`.env`, `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`, `credentials.json`, `secrets.json`/`.yml`/`.yaml`, `.aws/credentials`, or similar), **or** its diff content shows an obvious secret signature (a private-key header like `-----BEGIN...PRIVATE KEY-----`, or a suspiciously long/random-looking value assigned to a `SECRET`/`TOKEN`/`PASSWORD`/`API_KEY`-named variable) — check this directly off the diff already read for this step, no extra command needed. Excluded files are never included in any commit; list them separately (Step 8's template) for manual review.
  - **Pure renames need an extra look**: with rename detection on (Context), a renamed file with unchanged content shows no diff body at all — nothing for the content check above to scan. If a file appears as a pure rename (no `+`/`-` lines) and its new name doesn't clearly rule out being a secret, `Read` its actual current content and apply the same signature check to it directly.
- Group every remaining changed file (staged, unstaged, untracked) into commits by concern, not by count — tightly coupled changes are one commit, unrelated concerns (e.g. an unrelated bug fix mixed into a feature) are split into ordered commits. One commit per atomic, reviewable concern — no more, no fewer. A rename (Context is rename-aware) counts and is grouped as **one** file, never as a separate delete + add.
- A file can split across commits if its hunks (`@@ -a,b +c,d @@`) cleanly separate into unrelated concerns; if the changes overlap or interleave, keep it as one commit. **Never split a renamed file** — keep the whole rename (and any content change alongside it) in a single commit; a partial rename patch is fragile to reconstruct correctly.
- **Independence check**: after grouping, check whether any of these commit-groups are fully independent of each other — no shared files (rename paths included) and no genuine semantic dependency (one group's diff relying on/calling something only introduced or changed by another group — checked the same way as Step 12's semantic-impact check, just between these groups instead of against the target). Cluster them: two groups that share a file or have a real dependency belong to the same cluster; apply this transitively (if A-B and B-C are linked, A/B/C are one cluster) until no more merges apply. **If exactly one cluster results, ignore this entirely and continue below as normal.** If more than one cluster results, this doesn't change anything yet — Steps 3-5 still run exactly as written; the branch-count decision (right after Step 5) is where the user actually chooses whether to split, and only then does the **Multi-branch path** (described in its own section right after Step 7) potentially replace the single-branch Steps 8-15.
- **Continue immediately to Step 3 in the same turn — never stop, pause, or wait here.**

### Step 3 — Determine each commit's message

- Derive this repo's commit message convention from recent history — a prefix word, separator, casing, and scopes if the history consistently uses them, **or the deliberate absence of a prefix if that's what the history consistently shows** (a repo with plain, prefix-less subjects has its own real convention too — never impose one it doesn't use). Fall back to Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `perf:`, `build:`, `ci:`, `style:`) only when there's too little or too inconsistent history to tell any clear pattern at all, prefixed or not. $ARGUMENTS overrides both.
- Messages are imperative and concise (`fix: resolve null pointer in user service`, not `fixed a bug`).
- Add a body only when the diff's "why" isn't self-evident (non-obvious root cause, multi-file reason, side effects/breaking changes). Trivial changes (typos, renames, formatting, version bumps, obvious one-liners) stay subject-only.
- Every changed file is accounted for across the commits (split files per Step 2 across their specific commits).
- Also give each commit a short, human-friendly **Title** — the descriptive part of the subject, first letter capitalized, with any type prefix stripped if the message has one (message `fix: resolve null pointer in booking status lookup` → Title `Resolve null pointer in booking status lookup`; a message that was already prefix-less to begin with just becomes its own Title, capitalized). Display-only (commit headings, MR summary list) — never replaces the actual commit message.
- **Continue immediately to Step 4 in the same turn — never stop, pause, or wait here.**

### Step 4 — Determine the actual MR/PR target branch

The repo's default branch isn't necessarily the real MR target (e.g. default `main`, real target `develop`; or this branch is stacked on another feature branch). Determine the actual target:

- If $ARGUMENTS names a target, use it, skip the rest.
- **If HEAD is on a protected/mainline branch** (Step 1): skip Step 5 (no prior pushed commits exist yet) and resolve the target here instead of the distance algorithm below:
  - No other protected branch exists → target = HEAD's own branch.
  - Other protected branches exist → don't default to HEAD's branch. For each protected candidate, run `git rev-list --count --merges --first-parent <candidate>` (merge history, not branch refs — refs get deleted after merging, biasing toward whichever protected branch has more surviving stale branches). Weigh the counts with judgment: a clear gap wins outright; a close or low gap falls back to naming convention (`develop`/`dev`/`staging` over `main`/`master`/`release`).
  - No signal either way → target = HEAD's own branch. (Once Step 7's suggested branch exists, this is what it would target anyway.)
- **Otherwise** (HEAD is a feature branch — the normal case): find the exact fork-point boundary — the specific adjacent pair where a commit *is* contained by another branch, but its child (one step closer to HEAD) is contained *only* by HEAD's own branch. That pair pinpoints the true fork point; guessing from a candidate list is no longer needed. Distance `d` below means "`d` commits back from HEAD" (`d=0` is HEAD itself, `d=1` its parent, etc.).
  - **Normalize candidate names, everywhere below**: strip any `<remote>/` prefix from a candidate to get its logical branch name, but remember which remote(s) each one came from — needed below. If the same logical branch shows up more than once for the same boundary/position (a local branch, and/or the same branch tracked on multiple remotes) **and they all point to the same commit**, that's one candidate, not several — collapse them, preferring the local name for display. If they point to different commits (the remotes have diverged), treat them as genuinely separate candidates instead. `target` is never a bare `<remote>/<branch>` ref — Step 11 constructs `<target-remote>/<target>` itself, so a leftover prefix would break that.
  - **Determine `<target-remote>`**: once a final target is chosen, this is the remote its matching remote-tracking branch lives on — Step 11 needs it. If the target has remote-tracking copies on more than one remote (collapsed above because they matched), prefer `origin` if it's one of them, else whichever. If the target is a purely local branch with no remote-tracking counterpart on any remote, there's no `<target-remote>` — disclose this; Step 11 will have nothing to sync against.
  - Get HEAD's own commit count: `git rev-list --count --first-parent HEAD` (one call) — this is `N`.
  - **Phase 0 — check HEAD itself first**: `git branch --all --contains HEAD` (one call — `HEAD` is already a valid ref, no hash lookup needed). Already shared → the boundary is at `d=0`: this branch is already fully contained in another branch (rare — e.g. a fresh branch with no commits of its own yet). The branch(es) returned (other than HEAD's own) are the real candidates; skip Phases 1-2 entirely.
  - **If `N=1`** (HEAD has no parent at all — it's the repo's very first commit): there's nothing beyond `d=0` to check, so skip Phase 1 and Phase 2 entirely. Phase 0 already covered everything there is — if it didn't find a match, go straight to "No shared commit found anywhere" below.
  - **Phase 1 — gallop outward from HEAD** (most branches fork close to HEAD, so check there first instead of jumping to the middle of the whole history): check `d=1`, then `d=2`, then `d=4`, then `d=8`... doubling each time, stopping once the next distance would exceed `√N`. At each checked `d`: get that commit's hash with `git log --first-parent --skip=<d> -1 --format=%H HEAD`, then check who contains it with `git branch --all --contains <hash>` — two separate Bash calls per distance, never combined.
    - A checked distance comes back shared (contained by another branch too) → the boundary is between it and the previous distance checked (confirmed unshared — `d=0` if this is the first gallop check). Go to Phase 2 with that narrow pair as `[lo, hi]`.
    - Every distance up to the `√N` cutoff comes back unshared → don't keep doubling past that point (past `√N` a plain search over the rest is cheaper than continuing to gallop). Go to Phase 2 with `lo` = the last distance checked and `hi` = `N-1` (the last valid distance — there is no commit at distance `N`).
  - **Phase 2 — binary search the narrowed range** `[lo, hi]` for the smallest distance whose commit is shared — same two-call check as Phase 1 at the midpoint each step; unshared → search the later half, shared → search the earlier half — until `lo == hi`. That distance's commit is the fork point. The branch(es) `--contains` returned there (other than HEAD's own) are the real candidates.
  - **No shared commit found anywhere** (search exhausts HEAD's entire first-parent history without a hit — rare: e.g. an orphan branch with no shared history at all): target = HEAD's own branch, same as the mainline "no signal" case; disclose this in the output and skip the rest of this step.
  - Exclude any candidate that's a **strict** descendant of HEAD (`git merge-base --is-ancestor HEAD <candidate>` succeeds, but only counts if `<candidate>`'s tip is a different commit from HEAD's) — a real descendant can't be a merge target. Don't exclude a candidate that's sitting at the exact same commit as HEAD (the Phase 0 case) — `--is-ancestor` treats a commit as its own ancestor, so without this carve-out that candidate would wrongly get filtered out too.
  - One candidate left → that's the target. Multiple → apply the **Tie** rules below to pick one.
  - **Verify**: run `git merge-base HEAD <target>` once and confirm it matches the fork-point commit the search converged on.
    - Matches → confirmed, done.
    - Doesn't match → the algorithm itself is sound (proven above), so a mismatch means an execution slip, not a logic flaw. Re-run the search (Phase 0-2) once more from scratch, deriving each distance and hash consistently with the same method as the first pass, then verify again the same way.
      - Matches this time → confirmed, done.
      - Still doesn't match (two consecutive failed verifications) → fall back to the distance method below as a safety net, and disclose that the fallback was used after two failed verification attempts.
  - **Fallback** (only if both verification attempts above disagreed): candidates = all local + remote branches except HEAD's own; more than 30 → take the 30 most recently active (`git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ refs/remotes/`), disclose this in the output. For each candidate: `git rev-list --count <candidate>..HEAD --no-merges`, its own separate call, never batched. Exclude any candidate with count 0. Target = smallest remaining count.
  - **Tie**, in order:
    1. Naming convention wins if it disambiguates: a tied candidate named like `develop`/`dev`/`staging` beats one named like `main`/`master`/`release` (same convention as the mainline case above).
    2. Still tied → the repo's default branch wins, if it's one of the tied candidates.
    3. Still tied → use judgment and disclose the tie in the output (never guess silently).
- **Freshness check** (applies to the target from either branch above — mainline or fork-point search — but not one supplied directly via $ARGUMENTS; also skip entirely if the target has no `<target-remote>` per above — nothing to check against): confirm it still exists on the remote with a single `git ls-remote --exit-code <target-remote> <target>` (no object transfer, just a ref listing query — cheap, one network round-trip).
  - Exists → done, proceed with this target.
  - Doesn't exist (deleted on remote, stale local tracking ref) → exclude this candidate and re-derive once more:
    - Came from the fork-point search → re-run Phase 0-2 from scratch, treating the excluded branch as if `--contains` never returns it, so the search converges on the next real ancestor branch.
    - Came from the mainline path → re-apply the weighing rule among the remaining protected candidates, excluding the stale one; none remain → target = HEAD's own branch.
    - Re-determine `<target-remote>` for the new candidate, then validate it with one more `git ls-remote --exit-code <target-remote> <target>` check (skip if the new candidate also has no `<target-remote>`).
      - Exists → done.
      - Also stale (rare) → stop retrying — target = HEAD's own branch, disclosing that the branches found were already deleted on remote.
  - Whenever this check excluded a stale candidate, disclose it: `Note: <old-target> was determined as the target but no longer exists on the remote (likely deleted after merging) — <new-target> was used instead.`
- **Continue immediately to Step 5 in the same turn — never stop, pause, or wait here.**

### Step 5 — Refine the commit list against the target

- First, `git merge-base HEAD <target>` once — needed for the checks below.
- `git cherry <target> HEAD`: drop `-`-prefixed commits (already on target), keep `+`-prefixed ones.
- **If any `+`-prefixed (kept) commits remain** (git cherry misses multi-commit squashes): check exactly. Independent of Context — these calls deliberately skip `--find-renames`, so both stay in the same format and the cumulative-diff comparison below stays internally consistent:
  - `git log <merge-base>..HEAD --no-merges -p --reverse` gets all your own commits' diffs in one call (combine adjacent ones yourself for the cumulative comparison).
  - Read file names off that output (`diff --git a/<file> b/<file>` lines) — no extra command. Then `git log <merge-base>..<target> --no-merges -p -- <those file names>` gets target's new commits touching those files (a real squash must touch the same files, so this filters out unrelated contributors' commits; no `git patch-id` — needs a pipe, triggers permission friction).
  - Build the cumulative diff of our kept commits in order (1st alone, then +2nd, then +3rd...) and check each point against every remaining (unmatched) target commit. On a match, drop those commits, mark the target commit matched (never reuse it), and continue the cumulative build from the next own commit — different target commits may absorb different runs of ours.
  - Always run when kept commits exist — cheap (2 calls), and path-scoping keeps the target-side call small even in active repos.
- Only changes which commits get described — never the grouping/messages from Steps 2-3.
- Record the "Squash check" line: skipped (mainline, or nothing to check), ran/not detected, or ran/detected.
- **If Step 2's independence check found more than one cluster, continue immediately to the branch-count decision below in the same turn.** Otherwise, continue immediately to Step 6 in the same turn — never stop, pause, or wait here.

### Branch-count decision (only when Step 2's independence check found more than one cluster)

Decide **now**, before Step 6/7 run — this is the only place this question is asked, and it determines whether Step 6/7 run once (combined) or once per cluster (see the Multi-branch path, right after Step 7).

`AskUserQuestion`: state plainly that these changes look like `<K>` independent, unrelated concerns, listing each cluster's commit Titles (already known from Step 3 — no need for Title/Description yet), then ask how to proceed:
- **Use the suggested split**: keep each cluster as its own branch — continue to Step 6, applying it **per cluster** as the Multi-branch path (right after Step 7) describes, then follow that path through to its own ending instead of Step 8.
- **Keep everything on one branch**: ignore the clustering — treat every cluster's commits as one combined New Commits list and continue to Step 6 **once, combined**, exactly as it's written below; proceed through Step 7 and Step 8 normally from there.
- **Decline**: stop immediately — nothing is created, this stays advisory-only, same as declining Step 9.

### Step 6 — Write the MR/PR title and description

- Title and Description share one source: Step 5's surviving prior commits (if any) **plus** this run's new commits (Steps 2-3) — never just one side.
- If an MR/PR template file exists in context, `Read` it and fill its own sections (don't invent a layout). Otherwise, use a standard structure: `## Summary` (what and why — draw from each commit's subject and body, filling gaps with diff inference where the message alone doesn't explain it), `## Changes` (one bullet per commit/logical concern, written for a reviewer — not the raw subject copy-pasted, never a file dump), `## Testing` (only if something is inferable from the diff; omit rather than invent if nothing is).
- Title: one line, synthesizing the overall purpose across **all** commits in scope (Step 5's surviving prior + this run's new) — never any single commit's subject copied verbatim. If one concern is clearly primary (the reason this branch/PR exists) and the rest are supporting/minor, lead with the primary one; if several concerns carry equal weight, name the common theme rather than picking one arbitrarily or concatenating subjects. Apply this repo's own derived convention (Step 3) to this synthesized line too — a prefix if that's genuinely this repo's pattern, none if the repo's own commits are consistently prefix-less; merge strategy isn't visible locally, so matching the repo's real style, whichever it is, is the safe default — never Conventional Commits' prefixes forced onto a repo that doesn't actually use them. **This Title is synthesized fresh, separately from Step 3's per-commit Title** (which is always prefix-stripped, display-only, one per commit) — never copy a per-commit Title verbatim into this MR Title; decide independently, from this repo's convention, whether a prefix belongs on this line. $ARGUMENTS overrides style.
- **Continue immediately to Step 7 in the same turn — never stop, pause, or wait here.**

### Step 7 — Judge whether the branch name fits

- Derive this repo's branch naming convention (prefix, separator, casing) from context; fall back to best practice (`feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`, `perf/`, `build/`, `ci/`, `style/` + kebab-case) if too few/inconsistent branches.
- **If HEAD is detached** (Step 1), there's no name to compare — skip the comparison, this is automatically an ISSUE, go straight to proposing a name with the derived convention.
- Otherwise, compare the branch name against Step 6's full Title/Description (not just this run's diff). Flag a mismatch or confirm it fits — don't invent a problem.
- Combine with Step 1: either check failing → ISSUE, else OK. Propose a name using the derived convention when warranted.
- Only the OK/ISSUE status and (if ISSUE) the names are printed — not the derivation reasoning. $ARGUMENTS can override.
- **Track which check(s) caused ISSUE** (Step 1's mainline check, detached HEAD, this step's naming check, or a combination) — Step 10 needs this to know where to branch from.
- **If "Use the suggested split" was chosen at the branch-count decision, continue immediately to the Multi-branch path below in the same turn.** Otherwise (only one cluster ever existed, or "Keep everything on one branch" was chosen), continue immediately to the Branch destination check below in the same turn — never stop, pause, or wait here.

### Branch destination check (single-branch case — skipped entirely by the Multi-branch path, which has its own, narrower version of this for the continuing cluster only)

- **Skip this whole check and continue straight to the Branch Plan below if Status is OK** — nothing to decide, there's no alternative destination being proposed.
- **If ISSUE was caused by detached HEAD** (with or without a naming mismatch too): no question — a branch has to be created regardless, there's no "current branch" to commit to at all when detached. Continue straight to the Branch Plan below.
- **If ISSUE was caused (also) by Step 1's mainline check**: `AskUserQuestion` — state plainly that HEAD is on a protected/mainline branch (`<current-name>`), and ask whether to commit to a new branch (`<suggested-name>`, forked from the target) instead, or commit these changes **directly to `<current-name>`**, bypassing that protection.
  - **New branch**: proceed with Step 10's existing mainline mechanic (check out target, branch from there) unchanged.
  - **Commit directly to `<current-name>`**: treat Status as OK from here on — no branch is created, everything commits straight onto the current (protected) branch. This is a deliberate override the user asked for explicitly; disclose plainly, here and again in the Branch Plan/Summary, that commits are landing directly on a protected branch.
- **If ISSUE was caused only by Step 7's naming check** (not mainline, not detached): check whether the current branch name already exists under any remote (Context's "All remote branches" — no extra command needed) — this only changes what the question discloses, not whether it's asked; it's always asked. `AskUserQuestion`: state the suggested name, and (only if already pushed) that renaming later creates a **new** remote branch while the old one (`origin/<current-name>`) is left behind, orphaned, needing manual deletion — then ask:
  - **Keep the current name**: treat Status as OK from here on — no rename happens at all, ISSUE is resolved by keeping the name as-is.
  - **Rename to `<suggested-name>`**: proceed with the rename in Step 10 (`git branch -m`); if already pushed, the old remote branch's manual cleanup was already disclosed in the question itself — never done automatically here.
- **Continue immediately to the Branch Plan below in the same turn.**

### Branch Plan (single-branch case — the Multi-branch path has its own version of this)

Lightweight, same spirit as the Multi-branch path's overview: heading `# 🌿 Branch Plan (1 branch)`, then, on its own line, the final branch name (post Branch destination check above) in its own fence — no OK/ISSUE framing needed here, that check already resolved it. Right after the fence, one italic line whenever it applies (omit entirely otherwise, and then skip straight to the commit list below): `*(`<old-name>` → `<current-name>`)*` if a rename actually happened, or `*(kept as-is despite the naming mismatch — an explicit choice)*` if "keep the current name" was chosen — then, only when this italic line is shown, the usual real-spacing sequence (blank line, then a line containing only `&nbsp;`, then another blank line — a bare blank line alone would collapse invisibly) before the commit list below. **If "commit directly to `<current-name>`" was chosen for a protected/mainline branch instead**: right after the fence, heading `### ⚠️ Committing directly to a protected branch`, then one plain line: `This was an explicit choice at the branch destination check — commits are landing on <current-name> itself, not a new branch.` If Step 2 excluded any files as likely secrets, add one plain line right after (omit entirely if none): `Excluded (possible secrets — review manually): <file1>, <file2>` — shown here only, never repeated in Step 8. Then a plain list of this run's commit Titles, keycap-numbered — no messages, no files.

**Continue immediately to Step 8 in the same turn — never stop, pause, or wait here.**

### Multi-branch path (only reached from the branch-count decision's "Use the suggested split" choice)

Only reached this way: Step 2 found more than one cluster, **and** the branch-count decision (right after Step 5) was answered "Use the suggested split." Any other outcome (only one cluster ever existed, "Keep everything on one branch," or "Decline") never reaches here — Steps 6-16 below run as written for those cases, completely unaffected. This section replaces Steps 8-15 for this run (Step 16's plain stop still applies at the very end, once this section finishes).

**Target** is still determined exactly once by Step 4, the same way, against the real current HEAD — clustering never changes this. Once determined, pin it immediately as an exact commit hash (`git rev-parse <target>` — read-only) and reuse that same hash for every cluster's fork point below; never re-derive or re-fetch it partway through — every cluster must fork from the identical base, or the branch-switching mechanics below aren't safe.

**Which cluster (if any) continues on the current branch position**: at most one cluster may fork from HEAD's actual current commit (inheriting whatever Existing commits already sit there); every other cluster forks from the pinned target hash instead. Decide this now, before title/description/naming below, since those need to know which cluster (if any) is the continuing one.

**File-overlap check against Existing commits (do this first — it can force the choice, not just suggest it)**: Step 2's independence check only compared the new clusters against each other, since Step 5 (which determines Existing commits) hadn't run yet at that point. **Skip this whole file-overlap check entirely if Step 5 itself was skipped** (Step 4's mainline case — nothing exists to check against there, and continuing is already impossible on mainline per below regardless). Otherwise, now that Step 5 has run, check whether any new cluster shares a file (rename paths included) with Step 5's surviving Existing commits — reuse the file names already read off `git log <merge-base>..HEAD --no-merges -p --reverse` there, no extra command needed. **A cluster that shares a file with the Existing commits can never safely fork from target**: its uncommitted diff was computed against the working tree's current content, which already includes the Existing commits' changes to that file — applying it to target's older version (without those changes) would use the wrong context and likely fail or apply incorrectly. So a cluster in this situation is **forced** to be the one that continues on the current branch (alongside the Existing commits it shares a file with). At most one cluster should ever be forced this way — if the independence check's own file/semantic rules are correct, only one cluster can share a file with any single, contiguous piece of already-committed history. If this ever produces more than one forced candidate anyway, that's a sign the independence check's own result was wrong — don't ask another question at this point (the user already chose to split, back at the branch-count decision); instead, disclose the inconsistency plainly and fall back automatically to the same behavior as "Keep everything on one branch" would have produced (combined title/description/name, normal single-branch Steps 6-15 from there).

Continuing is only possible at all if HEAD is not on a protected/mainline branch and not detached (Step 1) — otherwise no cluster continues, every cluster forks from the pinned target hash, and any Existing commits are simply left behind on the abandoned original branch (disclose this plainly).

**If no cluster was forced by the file-overlap check above**, deciding who continues is a pure convenience choice, never a correctness requirement — a light comparative judgment across clusters' raw commits (Steps 2-3), not the full Step 6/7 machinery, which only runs afterward, once, for whichever cluster (if any) this settles on:
1. If there are Existing commits but no cluster shares a file with them, whichever cluster's commits best match those Existing commits' subjects in *content/topic* (not files) may continue — disclose this as a judgment call.
2. If there are no Existing commits at all, whichever cluster's content best fits the current branch's own name may continue instead.
3. If neither yields a clear match, no cluster continues — every cluster forks fresh from the pinned target hash, and the current branch is simply left as it is, unused by this run.

**Fixed processing order, from here on (overview and application both use it)**: if a cluster continues, it is always treated as **Branch 1**, regardless of where Step 2's clustering originally placed it — every other cluster follows after it, in Step 2's original relative order. This isn't cosmetic: the continuing cluster's own mechanics depend on HEAD still being at its original starting position when it's reached; if any forking cluster were processed first, HEAD would already have moved to that forking cluster's branch by the time the continuing one is reached, and "HEAD's current position" would no longer mean what it's supposed to. If no cluster continues, Step 2's original order is used as-is.

**Per-cluster title/description**: apply Step 6 independently to each cluster. For the continuing cluster (just decided above, if any), "that cluster's own commits" means its own new commits **plus** any Existing commits it inherits — same as Step 6's own rule, just scoped to this cluster instead of the whole branch. Every forking cluster has no Existing commits by construction, so its title/description comes from its own new commits alone. Never mix one cluster's commits into another's title/description.

**Per-cluster naming**: for the continuing cluster (if any), run Step 7 in full — its actual fit-check against the current branch's real name, using its own Title/Description from above. Every forking cluster has no existing name to compare against — just derive a fresh suggested name from its own commits' Title/Description, using the same convention Step 7 derives from context; skip the fit-check entirely for these, there's nothing to compare it to.

**Rename check, continuing cluster only** (forking clusters never have an existing name, so this never applies to them; and the continuing cluster can never be on mainline/detached — that's already excluded by the "which cluster continues" rule above — so this is always the naming-only case): same mechanism as the single-branch version — skip entirely unless the continuing cluster's own naming fit-check above found an ISSUE. If it did, `AskUserQuestion` is **always** asked (check whether already pushed first, same as the single-branch version, only to know whether to add the remote-cleanup disclosure to the question — never to decide whether to ask at all): keep the current name (ISSUE resolved, no rename) or rename to the suggested name.

**Render a simple overview first** — lightweight, no commit messages, no files, no Merge Request content, no Committer; just enough to judge whether the split itself makes sense. Same rendering conventions as Step 8: headings shown here as inline code are real markdown headings, never fenced; before every `###`-level line and between blocks, insert a blank line, then a line containing only `&nbsp;`, then another blank line.

Heading `# 🌿 Branch Plan (<K> branches)` — no leading `---`, this is the first thing rendered this run. Directly below, blank + `&nbsp;` + blank, then heading `### 🎯 Assumed target`, then its own fence with the pinned target — shown **once here**, the same for every cluster (forking clusters all fork from it; the continuing cluster's own note already explains why it doesn't). This doesn't replace each cluster's own Assumed target inside its full render later — that's still shown there too, self-contained. If Step 2 excluded any files as likely secrets, add one plain line right after (omit entirely if none): `Excluded (possible secrets — review manually): <file1>, <file2>` — shown **once here only**, never repeated per cluster, since these files were excluded before clustering and don't belong to any one cluster.

For each cluster, in the fixed processing order above (continuing cluster first, if any) — before every one of these, including the very first: a blank line, then a line containing only `&nbsp;`, then another blank line (same `###`-level spacing rule as everywhere else, never `---`, this isn't a main section): heading `### 🌿 Branch <i> — <suggested-branch-name>`. For the one continuing cluster, if any, directly below the heading, one italic line (same pattern as the Sync Plan's semantic-risk grouping): `*(continues current branch — shares <file> with the existing commits)*` (file-overlap-forced case), `*(continues current branch — matches the existing commits' subject)*` (convenience case 1), or `*(continues current branch — matches the current branch's name)*` (convenience case 2). Then a plain list of just this cluster's commit Titles, keycap-numbered — no messages, no files, nothing else.

No question here — "Use the suggested split" was already chosen at the branch-count decision (right after Step 5) to even reach this path. Continue immediately, in the same turn, to each branch one at a time, below, full detail, one approval and immediate application per branch, never batched together:

For each cluster —

- **Render this cluster's own Branch, New Commits, Merge Request, and Committer** — the Branch section is brought back just for this per-cluster render (unlike the single-branch case, where Branch Plan sits immediately before Step 8 and repeating it would be redundant; here, each cluster's full render happens much later, in its own separate approval turn, so it needs to stand on its own). By this point the destination is already a settled fact (decided back at the rename check, before Branch Plan even rendered) — so this is never an unresolved Current/Suggested choice, just one final name:
  - Heading `# <✅ or ⚠️> Branch (<i> of <K>)` — the `(<i> of <K>)` is part of the heading text itself, not a separate line. **✅** if this cluster's name was always fine, or the rename check resolved to rename. **⚠️** if the rename check resolved to "keep the current name" despite a real mismatch (same rule as Summary's own ✅/⚠️).
  - Then, on its own line, the one final branch name in its own fence (never a Current/Suggested split — there's nothing left unresolved to show two states for).
  - **If a rename actually happened**: right after the fence, one italic line: `*(`<old-name>` → `<current-name>`)*`. **If "keep the current name" was chosen despite a mismatch**: `*(kept as-is despite the naming mismatch — an explicit choice)*`. Omit entirely if this cluster's name was always fine.
  - Then, exactly as Step 8 describes, in full, every emoji/fence/spacing rule included, nothing abbreviated: New Commits, Merge Request, Committer — using this cluster's own per-cluster title/description/name from above (and, for the continuing cluster, its own Existing commits too, per Step 6's own rule) — except the excluded-secrets line, which was already shown once in the overview above and is never repeated here.
  - Before this cluster's whole block (including the very first): `---`, then a blank line, then go straight to the `# <✅ or ⚠️> Branch (<i> of <K>)` heading above.
- `AskUserQuestion` (same role as Step 9, scoped to just this one branch): ask whether to create this branch's commit(s) exactly as shown — locally only, no push yet.
  - **Declined**: this branch is not created — move on to the next cluster (if any); nothing else about this one happens.
  - **Approved**: apply it immediately, before moving to the next cluster:
    - **If this is the first cluster approved this run**: first verify the working tree still matches the overall plan and normalize the starting state, exactly as Step 10 describes (bare `git reset`, file-identity check against Context) — once, never repeated for later clusters.
    - **If this is the continuing cluster**: gated by its own rename check above — if it resolved to "keep the current name" (or the names already matched to begin with), just stay where you are, nothing to rename. Otherwise, rename via `git branch -m <current-name> <suggested-name>` — a true rename, same mechanism as Step 10's own version, no orphaned local branch left behind. Never fork from target for this one, so its Existing commits stay attached.
    - **Otherwise** (a forking cluster): `git checkout <pinned-target-hash>` then `git checkout -b <cluster's-suggested-name>` — a fresh fork from the exact pinned commit, never re-derived or re-fetched.
    - Stage and commit this cluster's own commits only, using the exact same per-commit mechanics as Step 10 (whole-file `git add`, split-file heredoc `git apply --cached` with its retry-then-checkpointed-`Edit` fallback) — scoped to just this cluster's files/hunks. Files belonging to any cluster not yet reached stay uncommitted in the working tree, untouched by this checkout — their tracked content is identical across every not-yet-forked cluster, since they all share the same pinned fork point.
    - `---`, then re-render this cluster's own `# 📋 Summary` section in full, using Step 10's exact Summary template (including its own New-Commits-applied hashes and its own Manual staging needed, if any) — but with `(Branch <i> of <K>)` appended to the `# 📋 Summary` heading text itself (the word "Branch" included here, unlike the Branch heading's own parenthetical, since "Summary (1 of 2)" alone wouldn't say *what* it's 1 of 2 of) — no separate label line.

**Once every cluster has been gone through** (whether approved or declined):
- **Only once, after the last cluster** (never earlier — a not-yet-processed cluster's still-uncommitted files would otherwise get mistaken for unexpected leftovers): run Step 10's leftover check once, globally. "Expected" here is the union of: every applied cluster's committed files, Step 2's excluded-secret files, any split file that failed hunk verification in any applied cluster (same as Step 10's own definition) — **plus** every declined cluster's files (deliberately left uncommitted — expected to remain exactly as they were, not a surprise). Only flag something as an unexpected leftover if it matches none of these. Attach any finding to the last **applied** cluster's Summary above; skip this check entirely if none were applied.
- **Steps 11-15 are skipped entirely for this run.** If at least one branch was created, report plainly: `<M> branch(es) created: <name-1>, <name-2>, ... — currently on <last-branch-name>. Switch to any of them and re-run this command to sync it with <target>, push it, and open its PR/MR, exactly as it would for a single branch.` (`<M>` may be fewer than `<K>` if any cluster was declined.) If every cluster was declined, just report plainly that nothing was created.
- Continue immediately to Step 16 — stop.

### Step 8 — Render the full output

Follow this structure exactly — same headings, order, and labels; only the bracketed parts change.

**Two kinds of elements below, never confuse them:**
- **Headings**, shown here as inline code like `### 🏷️ Title` — render these as **real markdown headings** in your actual output, never inside a fenced code block.
- **Fenced values**, shown here inside an actual ``` code block — render these **inside a real fenced code block** in your actual output, exactly as shown. Only five things ever get a fence: the current/suggested branch name, the target branch name, each commit's message, the MR title, and the MR description. Nothing else is ever fenced — not headings, not the file list, not the commit lists.

**Spacing:** two different separators, don't mix them up. Between the four **main** (`#`-level) sections — New Commits, Merge Request, Committer, Summary — use `---` as before. Before every **sub**-heading (every `###`-level line shown here as inline code, e.g. `### 🏷️ Title`) and between commit blocks, instead insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly in this output, `&nbsp;` on its own line is what actually produces visible breathing room.

**Copy-paste hygiene** (for the five fenced values): each gets its own fence, without exception, even a single short line — no blank line before or after the content. A multi-line message (subject, blank line, body) is still **one single fence** — the blank line between subject and body is part of the content, not a fence boundary; never close the fence there and let the body spill out as plain text below it. Example — heading `### Message` (real heading), then the message in its own fence:

```
fix: correct X

Body explaining why, ending here.
```

**Counting hygiene:** count from the list you actually wrote, never estimate. Cross-check: unique filenames across all commits (a split file counts once) + excluded-as-secret files = total changed files from context.

Branch info is never rendered here — the Branch Plan (shown right before this step, for every run) already covers it. Start directly with:

`---`, then heading `# 📝 New Commits (<N>)`. (The excluded-secrets disclosure line, if any, already rendered once in the Branch Plan just before this step — never repeated here.)

For each commit, in order — heading, then Message (its own fence), then Files (a plain list, never fenced). The `&nbsp;` spacing (above) goes between commit blocks too, not just before headings.

Heading `### <N — keycap emoji, e.g. 1️⃣> - Commit - <Title>`, then plain text `Message:`, then the message in its own fence:

```
<commit-message>
```

then plain text `Files (<N>):` followed by a plain list — never fenced:
- <file1.ext>
- <file2.ext> (new)
- <file3.ext> (deleted)
- <file4.ext> (renamed from <old-path>) — one entry, not two, for a rename (even with content changes alongside it)
- <file5.ext> — lines <a>-<b> (<short description>, only for a file split across commits)

Filenames in this list are filenames only, no path (add minimal parent folder only to disambiguate same-name files in different folders).

After the last commit block, `---`, then the Merge Request section, then `---`, then the Committer section, then `---`, then the Summary section — **the Summary template is what Steps 10 and 13 reuse when they re-render later; the Merge Request and Committer sections themselves render once here and are never repeated**.

**If both New commits and Existing commits counts are 0** (nothing new to propose and nothing prior found), there's no actual merge request to describe — omit **both** the `# 🔀 Merge Request` and `# 📋 Summary` sections entirely, headings and all — a title/description for a non-existent PR isn't useful, and a summary of nothing isn't either.

Heading `# 🔀 Merge Request` — this section is **pure MR/PR content only**, exactly what you'd paste into the host's own PR/MR form: no commit lists here.

Heading `### 🎯 Assumed target`, then its own fence:

```
<target-branch-name>
```

Right after the target code block, one plain parenthetical line — not a separate heading or label: `(squash check: <ran, detected / ran, not detected / skipped — HEAD was on a mainline branch>)`

If Step 4 needed a judgment-call tiebreak, add: `Note: also equidistant from feat/C — picked feat/A based on branch naming.` If Step 4's fork-point search found nothing shared, add: `Note: no shared history found with any other branch; defaulted to this branch as its own target.` If Step 4's verification disagreed and it fell back to the distance method, add: `Note: fork-point search couldn't be verified; fell back to distance-based candidate check.` If that fallback capped candidates at 30, add: `Note: repo has 214 branches — only the 30 most recently active were checked; specify via arguments if the real target is older.` If Step 4's freshness check excluded a stale target, add: `Note: <old-target> was determined as the target but no longer exists on the remote (likely deleted after merging) — <new-target> was used instead.` Omit any note that doesn't apply. **These five are the only notes that ever appear here — never invent a new one, even if some part of Step 4's computation seems unusual or worth explaining; if none of the five apply, show nothing.**

&nbsp;

Heading `### 🏷️ Title`, then its own fence:

```
<mr-title>
```

Heading `### 📄 Description`, then its own fence — no `&nbsp;` between Title and Description, they sit back to back — the whole Summary/Changes/Testing markdown goes inside this one block as literal text, not rendered as real headings:

```
<mr-description>
```

Title and Description cover the full change — all commits combined (many git hosts auto-populate the MR/PR description from only the first commit). See Step 6.

`---`, then heading `# 👤 Committer` (real heading), then plain text, never fenced:

Name: <committer-name>
Email: <committer-email>

Copy directly from context — don't alter or guess.

`---`, then heading `# 📋 Summary` — this section recaps **everything from the whole report at a glance**: Branch, both commit lists, the MR fields, and the Committer, all in one place. It's what Steps 10 and 13 re-render in full after later steps run, so the user always has the full picture without scrolling back.

Heading `### <✅ or ⚠️> Branch`, then the **current** branch name (whatever it actually is at the moment of this render — the newly-created/renamed branch if Step 10 already ran) in its own fence. **✅** if Status was OK all along, or if an ISSUE was actually resolved (a new branch created, or a rename applied). **⚠️** if an ISSUE was knowingly left as-is by explicit choice at the Branch destination check ("keep the current name" despite a naming mismatch, or "commit directly to `<current-name>`" on a protected branch) — the situation the ISSUE flagged still genuinely exists, just accepted on purpose, so it's never quietly shown as fine. Right after the fence, one italic line whenever it applies (omit entirely otherwise, and skip the blank line below too in that case): `*(`<old-name>` → `<current-name>`)*` if a rename actually happened (the fence already has the new name — this line's job is just showing the transition, old on the left, arrow, current on the right), `*(kept as-is despite the naming mismatch — an explicit choice)*` if "keep the current name" was chosen, or `*(a protected branch — commits landing here by explicit choice)*` if "commit directly to `<current-name>`" was chosen for mainline. Whenever this italic line is shown, follow it with the usual real-spacing sequence — a blank line, then a line containing only `&nbsp;`, then another blank line — before `### 🎯 Assumed target` below (a bare blank line alone would collapse invisibly, same rule as everywhere else in this output):

```
<current-branch-name>
```

Heading `### 🎯 Assumed target`, then **just** its own fence — no `&nbsp;` between Branch and Assumed target, they sit back to back; no squash-check parenthetical, no Step 4 notes here, those stay in the Merge Request section above and aren't repeated:

```
<target-branch-name>
```

&nbsp;

Two separate lists, each with its own count and its own independent keycap-emoji numbering (both start at 1️⃣), each a **plain list — never fenced**. **Omit either list entirely if its count is 0.**

Heading `### 📝 Existing commits (<M>)`, then plain list:
1️⃣ <real commit subject line-1>
2️⃣ <real commit subject line-2>

&nbsp;

Heading `### 📝 New commits (<N>)`, then plain list:
1️⃣ <Title-1>
2️⃣ <Title-2>

**Existing commits** = Step 5's surviving prior commits (already committed before this run, not yet on the target), if any — completely independent count from `<N>` below, no cross-check between the two. Since these commits weren't authored by this run, don't invent a Title for them — show each one's **real commit subject line** (first line of its actual message) as-is.

**New commits** = this run's proposed commits (Steps 2-3), if any. `<N>` must match the commit count shown in `# 📝 New Commits (<N>)` exactly, same counting-hygiene rule (count the list, don't estimate). Each line is the matching commit's **Title** (not the message subject, not the body). The label itself reflects what actually happened this run — one of two states: `New commits to be applied` (Step 9 not yet approved/declined) or `New commits applied` (Step 10 already applied them, re-renders with this).

&nbsp;

Heading `### 👤 Committer`, then plain text, never fenced:

Name: <committer-name>
Email: <committer-email>

&nbsp;

Heading `### 🏷️ Title`, then its own fence:

```
<mr-title>
```

Heading `### 📄 Description`, then its own fence — no `&nbsp;` between Title and Description, they sit back to back:

```
<mr-description>
```

- Render the full response in this exact order: New Commits, Merge Request, Committer, Summary — the Branch Plan (Branch info) already rendered just before this step.
- **Rendering this output does not end the step — immediately continue to Step 9 in the same turn; never stop, pause, or wait after rendering.**

### Step 9 — Ask whether to apply the plan

- After rendering (Step 8), use `AskUserQuestion` to ask whether to create the commit(s) exactly as shown — same messages, same files, split files committed with only their split hunks — locally only, no push. If Branch status is ISSUE, mention what will actually happen, per the Branch destination check's resolution: a new branch (detached, or mainline where "new branch" was chosen), a rename (naming-ISSUE where "rename" was chosen), or — if "keep the current name" or "commit directly to `<current-name>`" was chosen — explicitly confirm that everything commits straight onto the current branch as-is, **including calling out plainly if that branch is still the protected one** (mainline override case), so this is never a surprise. The decline option's own description should say that if they commit it themselves instead, re-running this command afterward will check whether syncing with the target is needed.
- If not approved, stop — nothing else happens, this stays advisory-only.
- If approved, continue immediately to Step 10 in the same turn — don't stop or wait after receiving the answer.

### Step 10 — Apply the plan (only if Step 9 was approved)

- **First, verify the working tree still matches the plan**: run `git status --untracked-files=all` and compare the set of changed files against Context's original repo status — same files changed/added/deleted, nothing more, nothing less (file identity only, not content). If they differ (a new file appeared, a planned file is gone, etc.), stop here — don't create anything, don't touch any branch — and report that the working tree changed since the plan was built; the user should re-run the command for an updated plan.
- **Then, normalize the starting state**: run a bare `git reset` (no flags) to unstage everything, regardless of whatever mix of staged/unstaged/untracked the files were already in. This only touches the index, never the working tree — nothing is lost. Do this before touching any branch or file, so every subsequent `git add`/`git apply --cached` starts from the same known, clean baseline instead of assuming nothing was pre-staged.
- **Branch, if Status was ISSUE**:
  - Caused (also) by Step 1's mainline check → gated by the Branch destination check (right after Step 7): if it resolved to "commit directly to `<current-name>`," there's nothing to do here — proceed as if Status were OK, committing straight onto the current (protected) branch, exactly as the user explicitly chose. Otherwise (new branch chosen, the default), check out the Assumed target first (if different from current HEAD), then create and switch to the suggested branch name from there (`git checkout -b`, a real new branch — there's no existing name to preserve here).
  - Caused by detached HEAD (with or without a naming mismatch too) → create and switch to the suggested branch name from HEAD's current position via `git checkout -b` — never from the target, that would strand any existing commits already on this branch. There's no existing branch name to preserve (detached HEAD has none) and no question was asked for this case — a branch is always created.
  - Caused **only** by Step 7's naming check (not mainline, not detached) → this is gated by the Branch destination check (right after Step 7, or the Multi-branch path's own version for the continuing cluster): if it resolved to "keep the current name," there's nothing to do here at all — proceed as if Status were OK. Otherwise (rename confirmed), use `git branch -m <current-name> <suggested-name>` — a true rename, not a new branch — so no orphaned local branch name is left behind.
  - If branch creation/rename fails, stop immediately and report the error — don't attempt any commits.
- **Per commit, in order**:
  - Never `git add` a file Step 2 excluded as a likely secret, even if it would otherwise belong to this commit's concern — it was deliberately left out of every commit's file list.
  - Whole (unsplit) files: `git add <file>` (handles new/modified/deleted correctly). For a rename, `git add <old-path> <new-path>` in that same single call — both paths together, so the deletion and the addition are staged as one rename, not a stray delete plus an untracked add. **Exception — case-only rename** (old and new path are identical except for letter case, e.g. `Foo.txt` → `foo.txt`): on a case-insensitive filesystem (Windows, default macOS) the combined `git add <old-path> <new-path>` call can get confused since both paths resolve to the same physical file. Instead, `git rm --cached <old-path>` (index only — nothing to touch in the working tree anyway) then `git add <new-path>`.
  - Split files: apply just the relevant hunk(s) (file header + those `@@ ... @@` blocks only, copied verbatim from the diff) with a single `git apply --cached` call fed via a quoted heredoc — `git apply --cached <<'PATCH_EOF'` then the hunk content then `PATCH_EOF` — no temp file, git reads the patch straight from stdin. **The heredoc delimiter must be quoted** (`<<'PATCH_EOF'`, not `<<PATCH_EOF`), so the shell doesn't expand `$`, backticks, or other special characters that may appear inside the diff. **Transcribe every hunk with care — this is the actual common failure point, not the heredoc mechanism itself, and a correctly-transcribed hunk (blank context lines and all) applies via heredoc without issue**: a blank line inside a hunk's unchanged (context) region must be copied as a line containing exactly one space character, never a truly empty line; the `@@ -a,b +c,d @@` header's own declared counts (`b` = old-file context+removed lines that follow, `d` = new-file context+added lines that follow) must exactly match the number of such lines actually transcribed; and a hunk's context extends on **both** sides of the change — the trailing context lines right before the *next* hunk's `@@` header (or the end of the diff) belong to *this* hunk and are easy to mistake for a mere gap and drop. Get any of this wrong and git rejects it with `error: corrupt patch at line N`, unrelated to quoting. Then verify with `git diff --cached <file>` that only the intended hunk(s) got staged.
  - **If the heredoc attempt fails** (a shell error, or `error: corrupt patch...`): re-examine the hunk specifically for the mistakes above (a dropped or miscounted context line — especially at the hunk's trailing boundary — or a blank context line missing its single space) and retry the heredoc **once more** with the correction. If this second attempt also fails, stop retrying the heredoc and switch to this fallback instead — it never transcribes hunk syntax at all (so it can't hit the same failure) and is checkpointed at every step so a mistake here can never lose the plan's already-approved content:
    - **Checkpoint**: `git add <file>` — stages the file's current content (still this plan's exact, fully-approved final state at this point) into the index. From here on, `git checkout -- <file>` always restores exactly this state, no matter what happens next.
    - Use `Edit` to rewrite the working tree file back to just this commit's intended intermediate content (undo only the string changes belonging to the *other* commit(s) in this split, keeping this commit's own change in place — plain, exact `old_string`/`new_string` substitutions, no line-counting involved).
    - **Verify before staging**: `git diff <file>`. If it shows anything other than exactly the expected reversal, automatically run `git checkout -- <file>` then a bare `git reset -- <file>` (restores the checkpoint above and leaves it unstaged — nothing is lost), skip auto-committing this file, and note in the final report that it needs manual staging — don't ask first, don't attempt a third rewrite.
    - If it matches: `git add <file>`, then commit with this commit's exact message. The commit itself is now the new checkpoint — permanent and safe.
    - For each further split commit on this same file: use `Edit` again to redo the next chunk of undone changes, verify with `git diff <file>` the same way, and either commit (extending the checkpoint chain) or — on a mismatch — automatically `git checkout -- <file>` plus a bare `git reset -- <file>` (restores the *previous* commit's state; everything up to and including it stays safe) and report that this remaining commit needs manual staging.
  - Commit with the exact message from the plan — subject via `-m`, body (if any) via a second `-m` — no Co-Authored-By trailer, no wording changes.
  - Before committing the next file that was split further down (later hunks of the same file), re-derive its remaining diff from the current state — the file has changed since the last commit.
- **Once all commits are made, verify nothing was left behind**: run one more `git status --untracked-files=all` and compare against what's expected to still show — Step 2's excluded-secret files, and any split file that failed hunk verification above. Anything else still staged/unstaged/untracked wasn't accounted for by the plan; note it in the final report as an unexpected leftover (don't stop, don't ask — just disclose it).
- **Re-render the `# 📋 Summary` section in full** — not the Merge Request section, which rendered once in Step 8 and is never repeated — using this template (same as Step 8's Summary — repeated here so it's rendered right at this point, not recalled from a distant definition). Headings shown here as inline code (e.g. `### 🏷️ Title`) are **real markdown headings, never fenced**; only content inside an actual ``` block below gets a real fence in your output. **Spacing**: before every heading, insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly here, `&nbsp;` on its own line is what actually produces visible breathing room; never use `---`:

  Heading `# 📋 Summary`.

  &nbsp;

  Heading `### <✅ or ⚠️> Branch`, then the **current** branch name (whatever it actually is right now, post-Step-10 — the newly-created branch if one was made) in its own fence:

  ```
  <current-branch-name>
  ```

  Heading `### 🎯 Assumed target`, then **just** its own fence — no `&nbsp;` between Branch and Assumed target, they sit back to back; no squash-check parenthetical, no notes, those live only in Step 8's Merge Request section:

  ```
  <target-branch-name>
  ```

  &nbsp;

  Both lists — heading `### 📝 Existing commits (<M>)` then plain list `1️⃣ <real commit subject line-1>` ...; heading `### 📝 New commits (<N>)` then plain list `1️⃣ <Title-1>` ... — own count and keycap numbering each, never fenced, omit either if its count is 0, omit the whole section if both are 0.

  The **Existing commits** list, if shown, is unaffected by this re-render. Change the **New commits** label to `New commits applied (<N>)` instead of `New commits to be applied (<N>)`, and append each commit's real short hash to its own line — `1️⃣ <Title-1> — <short-hash-1>` — confirms exactly what happened and exactly which real commit it landed as.

  If any file needed manual staging (the split-file fallback's mismatch case): &nbsp;, then heading `### ⚠️🔧 Manual staging needed (<N>)`, then a plain list of just the filenames, then one closing plain line covering all of them: `Stage and commit these manually — the automated split fallback couldn't verify their content matched the plan.`

  If any unexpected leftover files were found: &nbsp;, then heading `### ⚠️🗑️ Unexpected leftovers (<N>)`, then a plain list of those files.

  &nbsp;

  Heading `### 👤 Committer`, then plain text, never fenced:

  Name: <committer-name>
  Email: <committer-email>

  &nbsp;

  Heading `### 🏷️ Title`, then its own fence:

  ```
  <mr-title>
  ```

  Heading `### 📄 Description`, then its own fence — no `&nbsp;` between Title and Description, they sit back to back:

  ```
  <mr-description>
  ```

  Title and Description are unchanged from Step 8's render unless something here (e.g. a manual-staging fallback) actually changes what's being proposed.

  Pushing is never offered here — that only happens at the very end, in Step 14, once everything else is settled.
- **Rendering this does not end the step — immediately continue to Step 11 in the same turn; never stop, pause, or wait after rendering.**

### Step 11 — Offer to sync with the target

- Applies regardless of whether Step 10 ran — the real condition is whether HEAD has any local commits ahead of the target: newly created ones from Step 10, ones already on the branch before this run, or both.
- **If HEAD is still detached** (Step 10 never ran, e.g. nothing was uncommitted, so no branch got created to fix it): there's no branch to check "pushed" status for or sync — skip this step entirely, and disclose that a branch still needs to be created before this can be synced.
- **If Step 4 found no `<target-remote>` for the target** (a purely local branch, no remote-tracking counterpart on any remote): there's nothing to fetch or sync against — skip this step entirely, and disclose that the target only exists locally.
- `git fetch <target-remote> <target>` (or plain `git fetch`) for the target's true current state.
- **If the fetch fails**: check why.
  - Couldn't find the remote ref (e.g. `couldn't find remote ref <target>`) → the target branch likely no longer exists on the remote (deleted, e.g. after being merged elsewhere). Disclose this plainly.
  - Any other failure (network, auth, no remote configured) → disclose the failure plainly — sync can't be verified right now.
  - Either way, continue immediately to Step 13 in the same turn — never stop, pause, or wait here; the final report notes that syncing was skipped and why.
- Skip this step entirely (no question, no output) unless the target has moved since it was last checked (new commits on `<target-remote>/<target>` beyond what Step 4 saw). If it hasn't moved, there's nothing to sync — don't ask.
- **If HEAD has zero commits ahead of the target** (a fresh/empty branch, or Step 5 found everything already landed): nothing of ours to reconcile — this is a plain update, not a sync. Skip the semantic-impact and push-status checks below; ask via `AskUserQuestion` to fast-forward with `git merge --ff-only <target-remote>/<target>` (explicit `--ff-only`, not a bare `git merge` — don't rely on the user's `merge.ff` config; if it can't fast-forward, it fails loudly instead of silently creating a merge commit, meaning the ahead-count read was stale and needs re-checking, not a silent merge). State plainly in the prompt that this branch has no commits of its own yet and this only moves it to the target's latest point.
  - Approved → run it, then continue immediately to Step 13 in the same turn — never stop, pause, or wait here (a fast-forward can't conflict, and there's no diff of ours to check semantically).
  - Declined → stop, nothing changes.
- **Otherwise** (HEAD has at least one commit ahead of the target):
  - **Check whether this branch has ever been pushed**: run `git branch -r` (fresh — Context's snapshot may be stale) and check whether `<current-branch>` appears under **any** remote, not just `<target-remote>` — your own branch may live on a different remote than the target (e.g. a fork workflow: target on `upstream`, your branch pushed to `origin`). Found under any remote → someone (not necessarily this session) has pushed it before. Found under none → it hasn't.
    - **Never pushed** → rebase is safe (nothing shared to rewrite): `git rebase <target-remote>/<target>`.
    - **Already pushed** → rebase would rewrite history others may have already pulled; use merge instead: `git merge <target-remote>/<target>`.
  - `AskUserQuestion`: state which of the two will be used and why (pushed vs. not), and ask whether to proceed.
    - **Approved** → continue immediately to Step 12 in the same turn — never stop, pause, or wait here.
    - **Declined** → stop, nothing changes.

### Step 12 — Preview everything, then sync for real (only reached if Step 11 was approved, or via the mid-rebase/merge guard above)

**If reached from Step 11's approval** (i.e. not already mid-rebase/merge): build a complete preview first — nothing touches your real branch or working tree until the single approval below.

**Conflict preview**

- **Merge path**: `git merge-tree --write-tree HEAD <target-remote>/<target>` — a pure in-memory simulation; reports the resulting tree (clean) or the conflicting files and their content, without touching the working tree, the index, or creating any commit. No worktree needed here.
- **Rebase path**: `<temp-path>` = `${TMPDIR:-${TEMP:-/tmp}}/merge-pilot-worktree` — a fixed name under the OS's real temp directory (tries `TMPDIR`, then `TEMP` for Windows, then `/tmp`; this is plain variable expansion, not command substitution, so it's still one command). If a leftover directory from an earlier interrupted run already exists there, remove it first (`git worktree remove --force <temp-path>`). Create an isolated worktree there at HEAD (`git worktree add --detach <temp-path> HEAD`), then attempt the **real** `git rebase <target-remote>/<target>` inside it only (every command with `git -C <temp-path> ...`) — a faithful, real rebase attempt your actual branch and working tree never see.
  - At each conflict this hits: record which files conflict. To reach any later commits and see whether they conflict too, you need to move past this one — for **normal** files, write the same resolution you'd actually propose (combining both sides' intent, the real one — never an arbitrary `--ours`/`--theirs` pick, since a wrong intermediate resolution can hide or fabricate conflicts in the commits that follow) and `git -C <temp-path> add` it; for **lockfile**/**binary** files with no decision yet, use a placeholder (e.g. keep the "ours" side) purely to keep the walk-through moving — the one place this preview isn't fully guaranteed accurate, since lockfile/binary content rarely (but could) affect unrelated files' conflicts. Then `git -C <temp-path> rebase --continue` and repeat until the whole rebase finishes.
  - **Don't remove the worktree yet if any lockfile conflict was found** — keep it for the lockfile regenerate preview below. Otherwise remove it now: `git worktree remove <temp-path>`.
  - Your real branch and working tree were never touched throughout any of this.

**Classify** every conflicting file found above: **normal** (text), **lockfile** (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `poetry.lock`, and similar), or **binary** (anything else non-text).

**Semantic-impact check** (uses the conflict preview's results as evidence, not just isolated diffs): `git log HEAD..<target-remote>/<target> -p --no-merges` for the target's incoming diff, compared against your own changes (Step 10's commits, or Step 2-3's plan/Context diff if Step 10 didn't run) — and also read the **normal** conflicting files' actual content from the preview above (the same files you're already resolving carry the strongest signal for semantic risk, since both sides were actively changing the same area). Read all of it like a reviewer, not a name/signature matcher — this is independent of git's own line-level conflict detection, so flag it whether or not the files involved textually conflict:
- Does the incoming side change the *behavior* of anything your side calls or depends on (a function/method body changed even if its signature didn't, a return value/type's meaning shifted, a config/field's semantics changed, something your side calls was removed or renamed)?
- Does your side change the behavior of anything the incoming side now calls or depends on (same checks, reversed direction)?
- List every instance found, not just the first. **For the rebase path**, also identify which one (or more) of your own commits (from Step 2-3's plan, or Step 5's surviving prior commits) actually introduces or last touches the affected code — order them earliest to latest if more than one; needed to insert each fix at the right point later. When referring to which commit is affected (here, in the plan, and in the final report), use the same identifier convention as the rest of the output: **Step 2-3's Title** if it's one of this run's new commits, or the **real commit subject line** if it's one of Step 5's existing prior commits — never invent a Title for an existing commit.

**If the conflict preview found nothing and the semantic-impact check found nothing**: there's genuinely nothing to resolve — skip everything below (lockfile/binary previews, the combined plan, the `AskUserQuestion`) and don't ask anything; just run the real sync command directly (`git merge <target-remote>/<target>` with git's default merge message, or plain `git rebase <target-remote>/<target>`, which simply finishes since nothing conflicts) and continue immediately to Step 13 in the same turn.

**Lockfile regenerate preview** (if any lockfile conflicted): reuse the worktree still open from the rebase conflict-preview above if there is one; otherwise (merge path, or no worktree was kept open) create one now, just for this, the same way as above: `<temp-path>` = `${TMPDIR:-${TEMP:-/tmp}}/merge-pilot-worktree`, removing any leftover first (`git worktree remove --force <temp-path>`), then `git worktree add --detach <temp-path> HEAD`. Run the matching command there —
- `package-lock.json` → `npm install --package-lock-only --ignore-scripts`
- `pnpm-lock.yaml` → `pnpm install --lockfile-only`
- `yarn.lock` → `yarn install --ignore-scripts`
- `Gemfile.lock` → `bundle lock`
- `poetry.lock` → `poetry lock`

then diff the regenerated file against both sides' pre-conflict versions — fetched by commit, not by index stage (stage numbers are transient and `git merge-tree` never populates them at all): **merge path** — ours = `git show HEAD:<file>`, theirs = `git show <target-remote>/<target>:<file>`; **rebase path** — ours = `git show <the running base's current commit>:<file>` (the worktree's HEAD at that point in the walk-through), theirs = `git show <the original commit being replayed>:<file>` (note git's own labels are flipped during a rebase — the commit you're replaying counts as "theirs", not "ours"). See which packages resolved to a version different from both originals. Remove the worktree once done. If the command fails or the toolchain isn't available, note that manual resolution will be the only option.

If creating a fresh worktree just for this (the merge path, or no worktree was kept open): before running the regenerate command, write the already-resolved manifest file (`package.json`/`pyproject.toml`/`Gemfile`, from the normal-file resolutions above) into it — otherwise the command runs against the conflicted or stale manifest instead of the actual resolved dependencies.

**Binary comparison prep** (if any binary conflicted): fetch each side the same commit-based way as above (merge: `git show HEAD:<file>` / `git show <target-remote>/<target>:<file>`; rebase: running-base commit / originally-replayed commit, same ours/theirs flip). Just note the two sizes/paths — no visual comparison, even for images; there's no meaningful way to judge which is "correct," so leave that call to the user.

**Build the Sync Plan and show it** — same rendering conventions as Step 8: headings shown here as inline code (e.g. `### 💥 Text conflicts`) are real markdown headings, never fenced; before this section's own `#`-level heading use `---`; before each `###`-level sub-heading below, insert a blank line, then a line containing only `&nbsp;`, then another blank line. **Omit any sub-section that has nothing to show, heading and all** (e.g. no binary conflicts found → no `### 📦 Binary` at all).

`---`, then heading `# 🔄 Sync Plan`.

&nbsp;

Heading `### 💥 Text conflicts` (only if any normal file conflicted), then a plain list — never fenced — one entry per file: `- <file> — <how both sides are combined, in plain language>`.

&nbsp;

Heading `### 🧠 Semantic risks` (only if the semantic-impact check found anything). Content depends on the path:
- **Merge path**: a flat plain list, one entry per risk: `- <what changed on the incoming side, and why it's a risk> — affects <keycap-emoji> "<commit identifier>"; included in the merge commit.`
- **Rebase path**: grouped under each affected commit, earliest to latest. For each: a bold line `**<keycap-emoji> "<commit identifier>"**`, then directly below it on its own line, in italics, the landing mechanic — `*(also conflicts above — fix lands together with it, one commit)*` if this same commit already has a Text conflicts entry, otherwise `*(applies cleanly — fix folded in via `git commit --amend`)*` — then a plain list of the fix(es) for that commit. A blank line separates each commit's group from the next; no `&nbsp;` needed there, only around the whole sub-heading.

In both cases, `<keycap-emoji>` and `<commit identifier>` are copied from wherever that commit already appears in this run's report — the New-commits list's own number and Title if it's one of Step 2-3's commits, or the Existing-commits list's own number and real commit subject line if it's one of Step 5's surviving prior commits — never invent a Title for an existing commit.

&nbsp;

Heading `### 🔒 Lockfile` (only if any lockfile conflicted), then a plain list — one entry per file: `- <file> — regenerated preview: <which packages changed, old/new versions, additions/removals>.`

&nbsp;

Heading `### 📦 Binary` (only if any binary file conflicted), then a plain list — one entry per file: `- <file> — ours: <size>, theirs (<target>): <size>. No way to judge visually which is correct.`

If either Lockfile or Binary was shown: &nbsp;, then one closing plain line (not a heading): `Each lockfile and binary item above still needs its own choice — asked next, once this plan is approved.`

`AskUserQuestion`: how do you want to proceed?
- **Apply the plan**: continue below — one more round of questions for each lockfile/binary choice, then the real execution.
- **Start the sync, but leave conflicts for me**: run the real sync command (`git merge --no-commit --no-ff <target-remote>/<target>` or plain `git rebase <target-remote>/<target>`, whichever applies) and stop immediately — don't apply any resolution, don't touch the semantic fix, leave every conflict exactly as git reports it. Report that a rebase/merge is now in progress and needs manual resolution; re-running this command later will pick it up via the mid-rebase/merge guard.
- **Decline**: nothing was ever touched — no abort needed, nothing real ever ran. Stop.

**If "Apply the plan" was chosen**: ask the remaining per-file choices before doing anything else — one or more `AskUserQuestion` calls (up to 4 questions each, split across multiple calls if there are more), one question per lockfile ("use the regenerated result, or leave for manual?") and one per binary file ("keep ours, keep theirs, or leave for manual?"). Once every choice is made, continue to the real execution below.

**If reached from the mid-rebase/merge guard instead**: skip the preview above entirely — the sync command already ran (outside this run, or in an earlier run that stopped here) and is already conflicted for real; no semantic-impact finding is available in this case (Step 11 never ran), so the Sync Plan's `### 🧠 Semantic risks` sub-section never applies here. Build the same Sync Plan template above, using only what's actually conflicted right now:

- Classify the currently conflicting files (normal/lockfile/binary), propose resolutions for normal files, and prepare a lockfile-regenerate preview and binary comparison the same way as above — directly against the real, already-conflicted state (no worktree needed, it's already real, not a simulation).
- Show this plan. `AskUserQuestion`: how do you want to proceed?
  - **Resolve and continue**: same per-file follow-up questions as above (lockfile regenerate-or-manual, binary ours/theirs/manual), then write the resolutions for real and finalize — but **don't re-run the command that starts the sync** (`git merge --no-commit --no-ff` / `git rebase <target-remote>/<target>`) — it's already in progress from before this run; just stage the resolutions and finalize (`git rebase --continue` / `git commit`) from that point on, as those sections describe.
  - **Leave it as-is**: stop immediately — don't resolve or write anything, the conflict stays exactly as it is, for manual resolution.
  - **Abort**: `git rebase --abort` or `git merge --abort`, report the conflicting files, and stop.

**Real execution — merge path**

- `git merge --no-commit --no-ff <target-remote>/<target>` on your real branch — stages the merge (reporting the same conflicts already seen in preview) without committing yet.
- Write each already-known normal-file resolution and `git add` it. Apply each lockfile/binary choice just made for real (re-run the regenerate command for real — the preview worktree's result can't be reused directly — or `git checkout --ours`/`--theirs` then `git add`).
- If any file was left for manual resolution, don't finalize — stop and report the exact resume path (`git add` the file yourself, then `git commit`), plus `git merge --abort` as the alternative.
- Otherwise: also write the semantic-impact fix(es) now, into the **same** staged change, then a **single** `git commit` — conflict resolution and semantic fix land together, one commit, never split. (No conflicts and no semantic risk → just `git commit` with git's default merge message.)

**Real execution — rebase path**

The goal: by the time any commit lands in history, it already contains its own fix — never leave a commit that's known to be broken. Rebase auto-commits each replayed commit one at a time, so once you're past one, you can't reach back into it — instead of one plain pass, deliberately stop right at each affected commit, patch it, then continue: you're choosing where git creates the real commits, not leaving it to run straight through.

- **No semantic risk found** (Step 11's approval path): plain `git rebase <target-remote>/<target>` on your real branch to start it. Then, whether starting fresh here or resuming from the mid-rebase/merge guard (which skips this start command entirely — it's already running): resolve each conflict with the already-known resolution, `git add`, `git rebase --continue`, repeating until it finishes. If any file is left for manual resolution at any point, don't finalize — stop and report the resume path, plus `git rebase --abort`.
- **One or more commits affected by semantic risk**: order them earliest to latest, then chain `--onto` stops, one per affected commit:
  - **First stop**: `git rebase <target-remote>/<target> <hash of the first affected commit>` — a commit hash (not a branch name) as the endpoint leaves you in detached HEAD once it finishes, whether or not that commit itself conflicted. Resolve any conflicts along the way with the already-known resolutions. At the affected commit itself: if it conflicted, write the textual resolution *and* the semantic fix together, one `git add`, one `git rebase --continue` — the fix lands as part of finishing that commit. If it applied cleanly (no conflict of its own), it's already committed — write the fix now and fold it in with `git commit --amend`.
  - **Middle stops** (if more than one commit is affected): `git rebase --onto <the commit you just fixed> <that commit's original hash> <the next affected commit's hash>` — the endpoint is the *next* affected commit's hash, not your branch name yet. Resolve conflicts along the way normally; at that next affected commit, apply the same conflict-or-clean fix-folding logic as the first stop.
  - **Last stop**: once the final affected commit is fixed, `git rebase --onto <that commit> <its original hash> <your real branch name>` — a branch name here, so this one actually moves your real branch's ref, carrying the remaining (unaffected) commits along. Resolve any remaining conflicts normally.
  - If any file is left for manual resolution at any point in this sequence, don't finalize — stop and report the resume path, plus `git rebase --abort` to cancel the whole in-progress sequence.

Once finalized cleanly (either path): continue immediately in the same turn — go to Step 13.

### Step 13 — Render the final sync report

- **Re-render the `# 📋 Summary` section in full**, once more — not the Merge Request section, which rendered once in Step 8 and is never repeated — using this template (same as Step 8's Summary — repeated here so it's rendered right at this point, not recalled from a distant definition). Headings shown here as inline code (e.g. `### 🏷️ Title`) are **real markdown headings, never fenced**; only content inside an actual ``` block below gets a real fence in your output. **Spacing**: before every heading, insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly here, `&nbsp;` on its own line is what actually produces visible breathing room; never use `---`:

  Heading `# 📋 Summary`.

  &nbsp;

  Heading `### <✅ or ⚠️> Branch`, then the **current** branch name (whatever it actually is right now) in its own fence:

  ```
  <current-branch-name>
  ```

  Heading `### 🎯 Assumed target`, then **just** its own fence — no `&nbsp;` between Branch and Assumed target, they sit back to back; no squash-check parenthetical, no notes, those live only in Step 8's Merge Request section:

  ```
  <target-branch-name>
  ```

  &nbsp;

  Both lists — heading `### 📝 Existing commits (<M>)` then plain list `1️⃣ <real commit subject line-1>` ...; heading `### 📝 New commits (<N>)` then plain list `1️⃣ <Title-1>` ... — own count and keycap numbering each, never fenced, omit either if its count is 0, omit the whole section if both are 0.

  Same content and labels as whichever version — `New commits to be applied`, `New commits applied`, or omitted — was last shown; don't relabel it here.

  If Step 10 showed `### ⚠️🔧 Manual staging needed` and/or `### ⚠️🗑️ Unexpected leftovers`: carry them forward here unchanged, same files, right after the commit lists, same as Step 10's Summary — don't re-derive or re-check them.

  &nbsp;

  Heading `### 👤 Committer`, then plain text, never fenced:

  Name: <committer-name>
  Email: <committer-email>

  &nbsp;

  Heading `### 🏷️ Title`, then its own fence:

  ```
  <mr-title>
  ```

  Heading `### 📄 Description`, then its own fence — no `&nbsp;` between Title and Description, they sit back to back:

  ```
  <mr-description>
  ```

  Follow it with the `# 🏁 Sync Result` section — same rendering conventions as the Sync Plan above: headings shown as inline code are real markdown headings, never fenced; before this section's own `#`-level heading use `---`; before each `###`-level sub-heading below, insert a blank line, then a line containing only `&nbsp;`, then another blank line; omit any sub-section that has nothing to show, heading and all.

  `---`, then heading `# 🏁 Sync Result`, then one plain line: `Synced with <target>: <rebase/merge/fast-forward> completed.`

  &nbsp;

  Heading `### 🔧 Conflicts resolved (<N>)` (only if any conflict was actually resolved), then a plain list of the resolved files — the same files already named in the Sync Plan's Text conflicts/Lockfile/Binary sections above.

  &nbsp;

  Heading `### 🧠 Semantic risks fixed (<N>)` (only if semantic risk was found and fixed):
  - **Merge path**: a flat plain list — `- <short description of the fix>; included in the merge commit.`
  - **Rebase path**: one line per affected commit — `- <short-hash> <keycap-emoji> "<commit identifier>" — <short description of the fix>` — same `<keycap-emoji>`/`<commit identifier>` convention as the Sync Plan.

  If semantic risk was found but couldn't be auto-applied instead: heading `### ⚠️ Semantic risk not auto-applied`, then one plain line: `Found but couldn't be auto-applied — see the Sync Plan above, resolve manually.`
- Pushing is never offered here — that only happens at the very end, in Step 14, once everything else is settled.
- **Rendering this does not end the step — immediately continue to Step 14 in the same turn; never stop, pause, or wait after rendering.**

### Step 14 — Offer to push

- **Applies regardless of which path led here** — whether Steps 9-13 ran in full, Step 11 found nothing to sync, or nothing at all happened this run (no uncommitted changes and nothing to sync). This step is only ever reached by the flow completing naturally; a decline anywhere earlier (Step 9, 11, or 12) is its own hard stop and never reaches here.
- **Determine what there is to push**, independently of whatever happened above: the **current branch** (HEAD) — never the target branch, never any other branch.
  - If the current branch has an upstream configured (`git rev-parse --abbrev-ref --symbolic-full-name @{u}` succeeds): check whether it has any commits not yet on that upstream (`git rev-list --count @{u}..HEAD`).
  - If it has no upstream yet: check whether it has any commits at all (`git rev-list --count HEAD` if the branch was just created off an empty point, or simply whether the branch exists with commits of its own).
  - **Nothing to push either way** (no upstream and no local-only commits, or an upstream that's already fully up to date): skip this step entirely — no question, no output.
- **If there's something to push, determine the remote**:
  - Current branch already has an upstream → push there, no remote to choose.
  - No upstream yet → use `<target-remote>` from Step 4 if one was found; otherwise `origin` if that remote exists; otherwise there's no remote to push to — skip this step, disclosing that the branch has no configured remote.
- `AskUserQuestion`: state exactly what will happen — the branch, the remote, whether this sets a new upstream or updates an existing one, and how many commits are being pushed — and ask whether to push now.
  - **Declined** → stop, nothing pushed.
  - **Approved** → run exactly one of:
    - Existing upstream: `git push`
    - No upstream yet: `git push -u <remote> <current-branch>`
  - **Never use `--force`/`--force-with-lease`, under any circumstance.** If the push is rejected (remote has moved ahead, non-fast-forward), report the rejection plainly and stop — don't force, don't retry differently; suggest re-running this command so Steps 11-12 can sync with the target's new state first.
  - On success, report what was pushed (branch, remote, commit count).
- **Continue immediately to Step 15 in the same turn — never stop, pause, or wait here.**

### Step 15 — Offer to open a PR/MR

- **Only reached if Step 14 actually pushed** — if Step 14 was skipped (nothing to push) or declined, skip this step entirely too; there's nothing pushed to open a PR/MR from.
- **Also skip** if the current branch is the same as the target (Step 4) — a PR/MR needs two different branches — or if no target was ever determined.
- **Detect the hosting platform and whether access already exists in one pass — never obtain, request, or store new credentials, never ask the user to paste a token or API key**: get the pushed-to remote's hostname with `git remote get-url <remote>`, then try, in order:
  - Hostname is `dev.azure.com` or ends in `.visualstudio.com` → **Azure DevOps**. Check `az account show` — succeeds → already logged in with the Azure CLI (also reflects a service-principal or token-based `az` session). Fails → no access; stop checking, skip this step.
  - Otherwise, try `gh auth status --hostname <hostname>` → succeeds → **GitHub** (covers both github.com and a GitHub Enterprise Server instance `gh` is already configured for; also reflects a `GH_TOKEN`/`GITHUB_TOKEN` environment token).
  - Otherwise, try `glab auth status --hostname <hostname>` → succeeds → **GitLab** (covers both gitlab.com and a self-managed instance `glab` is already configured for; also reflects a `GITLAB_TOKEN`/`GLAB_TOKEN` environment token).
  - **None of the above succeeded** → skip this step entirely — no question, no output beyond a plain one-line disclosure of why (host not recognized by any known CLI / recognized but not authenticated). Never guess at a command for an unrecognized host — only these three platforms are ever supported.
- **If access exists**: `AskUserQuestion` — show the exact Title and Description last rendered (Step 6, unchanged since unless Step 12 revised it), the source branch (current branch) and base branch (Step 4's target), and ask whether to open the PR/MR now.
  - **Declined** → stop, nothing created.
  - **Approved** → run exactly one of:
    - GitHub: `gh pr create --title "<mr-title>" --body "<mr-description>" --base <target> --head <current-branch>`
    - GitLab: `glab mr create --title "<mr-title>" --description "<mr-description>" --target-branch <target> --source-branch <current-branch>`
    - Azure DevOps: `az repos pr create --title "<mr-title>" --description "<mr-description>" --source-branch <current-branch> --target-branch <target>` (org/project/repository are auto-detected from the current repo; only pass them explicitly if that detection fails)
  - On success, report the returned PR/MR URL. On failure, report the error plainly — don't retry with different flags or fall back to any other approach.
- **Continue immediately to Step 16 in the same turn — never stop, pause, or wait here.**

### Step 16 — Stop
