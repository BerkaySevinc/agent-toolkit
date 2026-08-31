---
description: Analyzes uncommitted changes and proposes how to split/organize them into commits with best-practice messages, determines the correct merge target, and writes the MR/PR title/description. Reports the plan first — creates the commits (and branch, if needed) only after explicit approval, then separately offers to sync the branch with its target (fast-forward, rebase, or merge), resolving conflicts and any detected semantic risks along the way, each gated behind its own approval. Never pushes, ever.
argument-hint: [optional: focus area, e.g. "only look at src/"]
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git ls-remote:*), Bash(git merge-base:*), Bash(git rev-list:*), Bash(git cherry:*), Bash(git config:*), Bash(git for-each-ref:*), Bash(git checkout:*), Bash(git add:*), Bash(git commit:*), Bash(git apply:*), Bash(git fetch:*), Bash(git rebase:*), Bash(git merge:*), Bash(git reset:*), Bash(git rm --cached:*), Bash(git merge-tree:*), Bash(git worktree:*), Bash(npm install --package-lock-only --ignore-scripts:*), Bash(pnpm install --lockfile-only:*), Bash(yarn install --ignore-scripts:*), Bash(bundle lock:*), Bash(poetry lock:*), Read, Edit, AskUserQuestion
---

**Critical constraint:** Steps 1-8 (the analysis and report) are always read-only — never run `git add`, `git commit`, `git checkout`, `git apply`, `git rebase`, `git merge`, `git reset`, `git rm`, a lockfile regenerate command, or any other state-changing command during them. `git merge-tree` and `git worktree add`/`remove` (Step 12's conflict/rebase preview) never touch your real branch or working tree, so they run freely during the preview, before approval — including a lockfile regenerate command run inside that temporary worktree, purely to see its result. Everything that changes your **real** branch — `git add`/`git commit`/`git checkout`/`git apply`/`git reset`/`git rm --cached`/`git rebase`/`git merge` (and their `--continue`/`--abort` forms), and a lockfile regenerate command run for real — is only permitted in Step 10 (after Step 9's approval) or Step 12's real-execution section (after Step 12's own combined-plan approval); approving one step never implies approval for another; Steps 9, 11, and 12 are each independently gated. `Edit` is only permitted in Step 12, and only *after* its own `AskUserQuestion` is approved — never write a proposed resolution or fix to disk (real or previewed) before it's shown and approved. `git push` is never run, under any circumstance, approved or not. **`git reset` is only ever run bare (no flags)** — `--hard`/`--mixed`/`--soft` are never used; a bare `git reset` only unstages, it never touches the working tree, which is the only variant that's ever safe here. **`git rm` is only ever run with `--cached`** — never bare, which would also delete the file from the working tree; `--cached` only removes it from the index (used for the case-only-rename handling in Step 10).

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

Emojis are only allowed in these exact spots, nowhere else:
1. At the **start** of each top-level `#` heading: `# Branch` gets ✅ (OK) or ⚠️ (ISSUE), `# Commits` gets 📝, `# Merge Request` gets 🔀, `# Committer` gets 👤.
2. In each commit heading's ordinal number, using the keycap-style number emoji (1️⃣, 2️⃣, 3️⃣, ... up to 🔟). Past 10, use a plain digit.
3. At the start of each of the Merge Request section's `### New commits` / `### Existing commits` headings — same 📝 as the Commits heading.

No other emoji, icon, or symbol may appear anywhere in the output.

## Instructions

**Every step below is mandatory and runs in order — never skip, merge, reorder, or shortcut a step for any reason, even if the outcome seems obvious, low-risk, or already covered by an earlier step.** The only exceptions are the specific skip conditions written into individual steps themselves (e.g., Steps 2/3/9 when there are no uncommitted changes, below) — nothing else justifies skipping one.

Steps 1-7 are analysis only — nothing is rendered until Step 8, which renders everything together per its own template.

**If a rebase or merge is already in progress** (Context's repo status shows `rebase in progress`, `You are currently rebasing`, `You have unmerged paths`, or similar — check this before anything else, including the no-uncommitted-changes case below): don't run Steps 1-8's normal analysis — the working tree is mid-operation, not a stable state to analyze fresh.

- Summarize what's found: which operation (rebase or merge), the target if determinable, which files are still conflicted vs. already resolved/staged.
- `AskUserQuestion`: how to proceed?
  - **Continue resolving here** — go directly to Step 12's real-execution section (conflicts already present), immediately in the same turn, using the currently conflicted files. This run never executed Step 12's preview or semantic-impact check, so skip them entirely; disclose this in the final report.
  - **Abort and start fresh** — run `git rebase --abort` or `git merge --abort` (matching whichever is in progress), then continue immediately to Step 1 in the same turn — never stop, pause, or wait here.
  - **Leave it alone** — stop immediately, nothing runs.

**If there are no uncommitted changes at all** (staged, unstaged, or untracked — check the Context's repo status/diff first, before Step 2): there's nothing new to group, message, or offer committing. Skip Steps 2, 3, and 9. State this plainly (`# 📝 Commits (0)`, no commit blocks), and omit the Merge Request section's **New commits** list entirely (Step 8's template) — nothing was proposed or created this run. If Step 5 finds prior committed work on this branch, it still shows in the **Existing commits** list with its own independent count, unrelated to the `(0)` above. Still run Steps 1, 4-8 in that case; if there's no prior work either, the entire `# 🔀 Merge Request` section is omitted (Step 8's both-empty rule) and the report is brief. Either way, still check Step 11 — a clean working tree doesn't mean there's nothing to sync.

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
- **Continue immediately to Step 3 in the same turn — never stop, pause, or wait here.**

### Step 3 — Determine each commit's message

- Derive this repo's commit message convention (prefix word, separator, casing, scopes) from recent history; fall back to Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `perf:`, `build:`, `ci:`, `style:`) if too few/inconsistent commits to tell. $ARGUMENTS overrides both.
- Messages are imperative and concise (`fix: resolve null pointer in user service`, not `fixed a bug`).
- Add a body only when the diff's "why" isn't self-evident (non-obvious root cause, multi-file reason, side effects/breaking changes). Trivial changes (typos, renames, formatting, version bumps, obvious one-liners) stay subject-only.
- Every changed file is accounted for across the commits (split files per Step 2 across their specific commits).
- Also give each commit a short, human-friendly **Title** — the descriptive part of the subject, first letter capitalized, without the type prefix (message `fix: resolve null pointer in booking status lookup` → Title `Resolve null pointer in booking status lookup`). Display-only (commit headings, MR summary list) — never replaces the actual commit message.
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
- **Continue immediately to Step 6 in the same turn — never stop, pause, or wait here.**

### Step 6 — Write the MR/PR title and description

- Title and Description share one source: Step 5's surviving prior commits (if any) **plus** this run's new commits (Steps 2-3) — never just one side.
- If an MR/PR template file exists in context, `Read` it and fill its own sections (don't invent a layout). Otherwise, use a standard structure: `## Summary` (what and why — draw from each commit's subject and body, filling gaps with diff inference where the message alone doesn't explain it), `## Changes` (one bullet per commit/logical concern, written for a reviewer — not the raw subject copy-pasted, never a file dump), `## Testing` (only if something is inferable from the diff; omit rather than invent if nothing is).
- Title: one line, synthesizing the overall purpose across **all** commits in scope (Step 5's surviving prior + this run's new) — never any single commit's subject copied verbatim. If one concern is clearly primary (the reason this branch/PR exists) and the rest are supporting/minor, lead with the primary one; if several concerns carry equal weight, name the common theme rather than picking one arbitrarily or concatenating subjects. Always use Step 3's prefix convention (merge strategy isn't visible locally, so applying it is the safe default). $ARGUMENTS overrides style.
- **Continue immediately to Step 7 in the same turn — never stop, pause, or wait here.**

### Step 7 — Judge whether the branch name fits

- Derive this repo's branch naming convention (prefix, separator, casing) from context; fall back to best practice (`feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`, `perf/`, `build/`, `ci/`, `style/` + kebab-case) if too few/inconsistent branches.
- **If HEAD is detached** (Step 1), there's no name to compare — skip the comparison, this is automatically an ISSUE, go straight to proposing a name with the derived convention.
- Otherwise, compare the branch name against Step 6's full Title/Description (not just this run's diff). Flag a mismatch or confirm it fits — don't invent a problem.
- Combine with Step 1: either check failing → ISSUE, else OK. Propose a name using the derived convention when warranted.
- Only the OK/ISSUE status and (if ISSUE) the names are printed — not the derivation reasoning. $ARGUMENTS can override.
- **Track which check(s) caused ISSUE** (Step 1's mainline check, detached HEAD, this step's naming check, or a combination) — Step 10 needs this to know where to branch from.
- **Continue immediately to Step 8 in the same turn — never stop, pause, or wait here.**

### Step 8 — Render the full output

Follow this structure exactly — same headings, order, and labels; only the bracketed parts change.

**Two kinds of elements below, never confuse them:**
- **Headings**, shown here as inline code like `### Title` — render these as **real markdown headings** in your actual output, never inside a fenced code block.
- **Fenced values**, shown here inside an actual ``` code block — render these **inside a real fenced code block** in your actual output, exactly as shown. Only five things ever get a fence: the current/suggested branch name, the target branch name, each commit's message, the MR title, and the MR description. Nothing else is ever fenced — not headings, not the file list, not the commit lists.

**Spacing:** two different separators, don't mix them up. Between the four **main** (`#`-level) sections — Branch, Commits, Merge Request, Committer — use `---` as before. Before every **sub**-heading (every `###`-level line shown here as inline code, e.g. `### Title`) and between commit blocks, instead insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly in this output, `&nbsp;` on its own line is what actually produces visible breathing room.

**Copy-paste hygiene** (for the five fenced values): each gets its own fence, without exception, even a single short line — no blank line before or after the content. A multi-line message (subject, blank line, body) is still **one single fence** — the blank line between subject and body is part of the content, not a fence boundary; never close the fence there and let the body spill out as plain text below it. Example — heading `### Message` (real heading), then the message in its own fence:

```
fix: correct X

Body explaining why, ending here.
```

**Counting hygiene:** count from the list you actually wrote, never estimate. Cross-check: unique filenames across all commits (a split file counts once) + excluded-as-secret files = total changed files from context.

Heading `# <✅ or ⚠️ — reflects Branch status: OK or ISSUE> Branch`.

If OK, the current branch name in its own fence:

```
<current-branch-name>
```

If ISSUE instead: heading `### Current branch`, then its own fence:

```
<current-branch-name>
```

&nbsp;

then heading `### Suggested branch`, then its own fence:

```
<branch-name>
```

`---`, then heading `# 📝 Commits (<N>)`.

If Step 2 excluded any files as likely secrets, add one plain line right after (omit entirely if none): `Excluded (possible secrets — review manually): <file1>, <file2>`

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

After the last commit block, `---`, then the Merge Request section — **the same template Steps 10 and 13 reuse when they re-render this section later**.

Heading `# 🔀 Merge Request`.

Two separate lists, each with its own count and its own independent keycap-emoji numbering (both start at 1️⃣), each a **plain list — never fenced**. **Omit either list entirely if its count is 0**. **If both counts are 0** (nothing new to propose and nothing prior found), there's no actual merge request to describe — omit the entire `# 🔀 Merge Request` section instead, heading and all (Assumed target, Squash check, Title, Description included too) — a title/description for a non-existent PR isn't useful.

Heading `### 📝 New commits (<N>)`, then plain list:
1️⃣ <Title-1>
2️⃣ <Title-2>

&nbsp;

Heading `### 📝 Existing commits (<M>)`, then plain list:
1️⃣ <real commit subject line-1>
2️⃣ <real commit subject line-2>

**New commits** = this run's proposed commits (Steps 2-3), if any. `<N>` must match the commit count shown in `# 📝 Commits (<N>)` exactly, same counting-hygiene rule (count the list, don't estimate). Each line is the matching commit's **Title** (not the message subject, not the body). The label itself reflects what actually happened this run — one of two states: `New commits to be applied` (Step 9 not yet approved/declined) or `New commits applied` (Step 10 already applied them, re-renders with this).

**Existing commits** = Step 5's surviving prior commits (already committed before this run, not yet on the target), if any — completely independent count from `<N>` above, no cross-check between the two. Since these commits weren't authored by this run, don't invent a Title for them — show each one's **real commit subject line** (first line of its actual message) as-is.

&nbsp;

Heading `### Assumed target`, then its own fence:

```
<target-branch-name>
```

Right after the target code block, one plain parenthetical line — not a separate heading or label: `(squash check: <ran, detected / ran, not detected / skipped — HEAD was on a mainline branch>)`

If Step 4 needed a judgment-call tiebreak, add: `Note: also equidistant from feat/C — picked feat/A based on branch naming.` If Step 4's fork-point search found nothing shared, add: `Note: no shared history found with any other branch; defaulted to this branch as its own target.` If Step 4's verification disagreed and it fell back to the distance method, add: `Note: fork-point search couldn't be verified; fell back to distance-based candidate check.` If that fallback capped candidates at 30, add: `Note: repo has 214 branches — only the 30 most recently active were checked; specify via arguments if the real target is older.` If Step 4's freshness check excluded a stale target, add: `Note: <old-target> was determined as the target but no longer exists on the remote (likely deleted after merging) — <new-target> was used instead.` Omit any note that doesn't apply. **These five are the only notes that ever appear here — never invent a new one, even if some part of Step 4's computation seems unusual or worth explaining; if none of the five apply, show nothing.**

&nbsp;

Heading `### Title`, then its own fence:

```
<mr-title>
```

&nbsp;

Heading `### Description`, then its own fence — the whole Summary/Changes/Testing markdown goes inside this one block as literal text, not rendered as real headings:

```
<mr-description>
```

Title and Description cover the full change — all commits combined (many git hosts auto-populate the MR/PR description from only the first commit). See Step 6.

At the very end, after `---`: heading `# 👤 Committer` (real heading), then plain text, never fenced:

Name: <committer-name>
Email: <committer-email>

Copy directly from context — don't alter or guess.

- Render the full response in this exact order: Branch, Commits, Merge Request, Committer.
- **Rendering this output does not end the step — immediately continue to Step 9 in the same turn; never stop, pause, or wait after rendering.**

### Step 9 — Ask whether to apply the plan

- After rendering (Step 8), use `AskUserQuestion` to ask whether to create the commit(s) exactly as shown — same messages, same files, split files committed with only their split hunks — locally only, no push. If Branch status is ISSUE, mention that a new branch (the suggested name) will be created first. The decline option's own description should say that if they commit it themselves instead, re-running this command afterward will check whether syncing with the target is needed.
- If not approved, stop — nothing else happens, this stays advisory-only.
- If approved, continue immediately to Step 10 in the same turn — don't stop or wait after receiving the answer.

### Step 10 — Apply the plan (only if Step 9 was approved)

- **First, verify the working tree still matches the plan**: run `git status --untracked-files=all` and compare the set of changed files against Context's original repo status — same files changed/added/deleted, nothing more, nothing less (file identity only, not content). If they differ (a new file appeared, a planned file is gone, etc.), stop here — don't create anything, don't touch any branch — and report that the working tree changed since the plan was built; the user should re-run the command for an updated plan.
- **Then, normalize the starting state**: run a bare `git reset` (no flags) to unstage everything, regardless of whatever mix of staged/unstaged/untracked the files were already in. This only touches the index, never the working tree — nothing is lost. Do this before touching any branch or file, so every subsequent `git add`/`git apply --cached` starts from the same known, clean baseline instead of assuming nothing was pre-staged.
- **Branch, if Status was ISSUE**:
  - Caused (also) by Step 1's mainline check → check out the Assumed target first (if different from current HEAD), then create and switch to the suggested branch name from there.
  - Caused by Step 7's naming check, or by detached HEAD, or both (but **not** mainline) → create and switch to the suggested branch name from HEAD's current position — never from the target, that would strand any existing commits already on this branch. Detached HEAD uses this same path (git allows branching from a detached position directly).
  - If branch creation fails, stop immediately and report the error — don't attempt any commits.
- **Per commit, in order**:
  - Never `git add` a file Step 2 excluded as a likely secret, even if it would otherwise belong to this commit's concern — it was deliberately left out of every commit's file list.
  - Whole (unsplit) files: `git add <file>` (handles new/modified/deleted correctly). For a rename, `git add <old-path> <new-path>` in that same single call — both paths together, so the deletion and the addition are staged as one rename, not a stray delete plus an untracked add. **Exception — case-only rename** (old and new path are identical except for letter case, e.g. `Foo.txt` → `foo.txt`): on a case-insensitive filesystem (Windows, default macOS) the combined `git add <old-path> <new-path>` call can get confused since both paths resolve to the same physical file. Instead, `git rm --cached <old-path>` (index only — nothing to touch in the working tree anyway) then `git add <new-path>`.
  - Split files: apply just the relevant hunk(s) (file header + those `@@ ... @@` blocks only, copied verbatim from the diff) with a single `git apply --cached` call fed via a quoted heredoc — `git apply --cached <<'PATCH_EOF'` then the hunk content then `PATCH_EOF` — no temp file, git reads the patch straight from stdin. **The heredoc delimiter must be quoted** (`<<'PATCH_EOF'`, not `<<PATCH_EOF`), so the shell doesn't expand `$`, backticks, or other special characters that may appear inside the diff. Then verify with `git diff --cached <file>` that only the intended hunk(s) got staged. If it doesn't match, unstage, skip auto-committing that file, and note in the final report that it needs manual staging.
  - Commit with the exact message from the plan — subject via `-m`, body (if any) via a second `-m` — no Co-Authored-By trailer, no wording changes.
  - Before committing the next file that was split further down (later hunks of the same file), re-derive its remaining diff from the current state — the file has changed since the last commit.
- **Once all commits are made, verify nothing was left behind**: run one more `git status --untracked-files=all` and compare against what's expected to still show — Step 2's excluded-secret files, and any split file that failed hunk verification above. Anything else still staged/unstaged/untracked wasn't accounted for by the plan; note it in the final report as an unexpected leftover (don't stop, don't ask — just disclose it).
- **Re-render the `# 🔀 Merge Request` section in full**, using this template (same as Step 8's — repeated here so it's rendered right at this point, not recalled from a distant definition). Headings shown here as inline code (e.g. `### Title`) are **real markdown headings, never fenced**; only content inside an actual ``` block below gets a real fence in your output. **Spacing**: before every heading, insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly here, `&nbsp;` on its own line is what actually produces visible breathing room; never use `---`:

  Heading `# 🔀 Merge Request`.

  &nbsp;

  Both lists — heading `### 📝 New commits (<N>)` then plain list `1️⃣ <Title-1>` ...; heading `### 📝 Existing commits (<M>)` then plain list `1️⃣ <real commit subject line-1>` ... — own count and keycap numbering each, never fenced, omit either if its count is 0, omit the whole section if both are 0.

  Change the **New commits** label to `New commits applied (<N>)` instead of `New commits to be applied (<N>)` — confirms exactly what happened. The **Existing commits** list, if shown, is unaffected by this change.

  &nbsp;

  Heading `### Assumed target`, then its own fence:

  ```
  <target-branch-name>
  ```

  `(squash check: <ran, detected / ran, not detected / skipped — HEAD was on a mainline branch>)` — plus the same tiebreak/fallback/freshness notes as Step 8's render, if they applied there.

  &nbsp;

  Heading `### Title`, then its own fence:

  ```
  <mr-title>
  ```

  &nbsp;

  Heading `### Description`, then its own fence — the whole Summary/Changes/Testing markdown goes inside this one block as literal text, not rendered as real headings:

  ```
  <mr-description>
  ```

  Title and Description are unchanged from Step 8's render unless something here (e.g. a manual-staging fallback) actually changes what's being proposed.

  Follow the re-rendered section with each commit's short hash, the branch (if created), any file that needed manual staging, and any unexpected leftover files found above. Still never push.
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

**Build one combined plan** and show it:
- Normal-file resolutions.
- Semantic-impact fixes: **merge path** — list together (they all land in the one merge commit); **rebase path** — group under each affected commit's own heading, showing which fix(es) go into which commit.
- Lockfile regenerate preview (which packages changed) and binary comparison (sizes/paths) — shown here as information only; flag that each one still needs its own choice, asked below only if you choose to apply.

`AskUserQuestion`: how do you want to proceed?
- **Apply the plan**: continue below — one more round of questions for each lockfile/binary choice, then the real execution.
- **Start the sync, but leave conflicts for me**: run the real sync command (`git merge --no-commit --no-ff <target-remote>/<target>` or plain `git rebase <target-remote>/<target>`, whichever applies) and stop immediately — don't apply any resolution, don't touch the semantic fix, leave every conflict exactly as git reports it. Report that a rebase/merge is now in progress and needs manual resolution; re-running this command later will pick it up via the mid-rebase/merge guard.
- **Decline**: nothing was ever touched — no abort needed, nothing real ever ran. Stop.

**If "Apply the plan" was chosen**: ask the remaining per-file choices before doing anything else — one or more `AskUserQuestion` calls (up to 4 questions each, split across multiple calls if there are more), one question per lockfile ("use the regenerated result, or leave for manual?") and one per binary file ("keep ours, keep theirs, or leave for manual?"). Once every choice is made, continue to the real execution below.

**If reached from the mid-rebase/merge guard instead**: skip the preview above entirely — the sync command already ran (outside this run, or in an earlier run that stopped here) and is already conflicted for real; no semantic-impact finding is available in this case (Step 11 never ran). Build a smaller plan for just what's actually conflicted right now, the same way:

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

- **Re-render the `# 🔀 Merge Request` section in full**, once more, using this template (same as Step 8's — repeated here so it's rendered right at this point, not recalled from a distant definition). Headings shown here as inline code (e.g. `### Title`) are **real markdown headings, never fenced**; only content inside an actual ``` block below gets a real fence in your output. **Spacing**: before every heading, insert a blank line, then a line containing only `&nbsp;`, then another blank line — a plain blank line alone collapses/renders invisibly here, `&nbsp;` on its own line is what actually produces visible breathing room; never use `---`:

  Heading `# 🔀 Merge Request`.

  &nbsp;

  Both lists — heading `### 📝 New commits (<N>)` then plain list `1️⃣ <Title-1>` ...; heading `### 📝 Existing commits (<M>)` then plain list `1️⃣ <real commit subject line-1>` ... — own count and keycap numbering each, never fenced, omit either if its count is 0, omit the whole section if both are 0.

  Same content and labels as whichever version — `New commits to be applied`, `New commits applied`, or omitted — was last shown; don't relabel it here.

  &nbsp;

  Heading `### Assumed target`, then its own fence:

  ```
  <target-branch-name>
  ```

  `(squash check: <ran, detected / ran, not detected / skipped — HEAD was on a mainline branch>)` — plus the same tiebreak/fallback/freshness notes as before, if they applied.

  &nbsp;

  Heading `### Title`, then its own fence:

  ```
  <mr-title>
  ```

  &nbsp;

  Heading `### Description`, then its own fence — the whole Summary/Changes/Testing markdown goes inside this one block as literal text, not rendered as real headings:

  ```
  <mr-description>
  ```

  With lines appended for whatever actually happened: `Synced with <target>: <rebase/merge/fast-forward> completed.`, plus, if applicable, `Conflicts resolved: <N> file(s).` and, for semantic risk:
  - **Merge path, fixed**: `Semantic risk fixed: <N> instance(s), included in the merge commit.`
  - **Rebase path, fixed**: `Semantic risk fixed: <N> instance(s):` followed by one line per affected commit — `- <short-hash> "<commit title>" — <short description of the fix>`.
  - **Either path, couldn't be applied**: `Semantic risk found but couldn't be auto-applied — see above, resolve manually.`
- Never push, regardless of outcome or which path ran.
- **Rendering this does not end the step — immediately continue to Step 14 in the same turn; never stop, pause, or wait after rendering.**

### Step 14 — Stop

- Never push, never offer to push, no matter what happened above.
