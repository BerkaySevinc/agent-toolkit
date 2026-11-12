# agent-toolkit

An AI coding toolkit, kept in sync across machines with a single script.

<br>

---

<br>

## ✨ Features

- **One-command install** — a single script mirrors everything into `%USERPROFILE%\.claude`, no manual copying required
- **Manual install also works** — running the script is optional, copying only the files you want by hand works just as well
- **Safe by default** — a file that already exists and differs prompts before overwriting; nothing is silently replaced, and nothing is backed up either (git is your history)
- **Clear feedback** — a colored, categorized summary shows exactly what was installed, updated, skipped, or already up to date

<br>

---

<br>

## 🚀 Quick Start

<br>

### 📥 1. Clone or download this repository

Clone it, or just download it as a ZIP — anywhere on your machine, the installer works out of any location.

<br>

### ▶️ 2. Run `install.bat`

Double-click it, or run it from a terminal. It mirrors everything in this repo into `%USERPROFILE%\.claude`.

> ℹ️ The script is just a convenience — nothing requires it. You can just as well copy only the specific files you want (e.g. a single skill from `skills/`) into `%USERPROFILE%\.claude` yourself.

<br>

### ✅ 3. Resolve conflicts _(if any)_

If a file already exists locally and differs from this repo's version, you'll be asked whether to overwrite it or skip it — file by file.

<br>

### 🔁 4. Re-run anytime

Pull (or re-download) the latest version and run `install.bat` again — only new or changed files trigger a prompt; everything else is left untouched.

<br>

---

<br>

## 📦 What's Inside

- **`install.bat`** — the installer
- **`CLAUDE.md`** — master prompt, detailed below
- **`skills/`** — custom slash commands (Skills), detailed below
- **`agents/`** — sub-agent definitions used by skills (today: the `/decide` council, the `/bug-review` reviewers and the `/vuln-review` reviewers)

> **Maintenance note:** the `bug-review-*` and `vuln-review-*` agents are deliberate copies of one skeleton. When you change a shared part, change it in both. Shared: in the selector, the scope finding, base-branch detection, measuring and slicing; in the lead, the stage flow, the router procedure, merging and the handling of cut-off reports; in the sweeper and the verifier, the short output format and the re-ask rule. Different on purpose: the angles, the finder record fields, the verification criteria, the severity scale, the report sections and the plan-screen texts.

<br>

### 🧠 Prompts

| Prompt | What it does |
|--------|---------------|
| `CLAUDE.md` | Master prompt — global instructions loaded into every project, defining how the agent should work with you |

<br>

### ⚡ Skills

| Skill | What it does |
|---------|---------------|
| `/merge-pilot` | Turns your uncommitted changes into clean commits with a PR/MR description, then syncs, pushes and opens the PR/MR through your existing GitHub, GitLab or Azure DevOps login, each step only after your approval. Never force-pushes |
| `/my-skills` | Lists only your own skills and commands (user, project, added directories), grouped by category — built-in, plugin, and synced skills left out |
| `/decide` | Stress-tests a decision with a council of independent sub-agents: you approve a neutral brief, advisors answer anonymously, reviewers and a challenger attack the result, and a chairman recommends. It recommends, you decide. On request only, 13–23 sub-agent calls (ask for a lighter run in your own words) |
| `/decide-light` | The lighter, faster `/decide`: fewer advisors, no challenge stage, about 10–12 sub-agent calls |
| `/double-check` | A quick, general double check of your latest changes before you commit or publish: bugs, secrets, forgotten things, anything that should not (or need not) be in a public repo. Scope comes from the conversation or your own words. Reports and asks whether to fix; say so in your own words and it fixes first. No sub-agents, never commits or pushes; for a deep review use `/bug-review` or `/vuln-review` |
| `/double-check-fix` | The fixing `/double-check`: fixes what it safely can first, then reports what was fixed and what still needs you |
| `/bug-review` | Reviews your changes (or a scope you name) for bugs with independent sub-agents that read the code from different angles; every finding is verified. Then assesses the findings against your project (fix now, leave for later, no fix needed, needs your decision) and acts only after you approve. No security audit (see `/vuln-review`). On request only, about 9–20 sub-agent calls (name a model in your own words to run it on that model); big scopes are sliced and reviewed one slice at a time |
| `/bug-review-light` | The lighter, faster `/bug-review`: a quick scan with two angles and no sweep, about 6–9 sub-agent calls |
| `/bug-review-branch` | `/bug-review` on everything the current branch added versus its base branch, like a PR; the base is found from the shared history and shown for you to confirm |
| `/bug-review-project` | `/bug-review` on the whole project instead of a change; works outside a git repository too, and big projects can be sliced |
| `/vuln-review` | Reviews your changes (or a scope you name) for security vulnerabilities with independent sub-agents that read the code from different angles (injection, access control, secrets, cryptography and more); every finding is checked as a concrete attack. Then assesses the findings against your project (fix now, leave for later, no fix needed, needs your decision) and acts only after you approve. Separate from the built-in `/security-review`; no ordinary bug hunt (see `/bug-review`). On request only, about 10–21 sub-agent calls (name a model in your own words to run it on that model); big scopes are sliced and reviewed one slice at a time |
| `/vuln-review-light` | The lighter, faster `/vuln-review`: a quick scan with the three core angles and no sweep, about 7–10 sub-agent calls |
| `/vuln-review-branch` | `/vuln-review` on everything the current branch added versus its base branch, like a PR; the base is found from the shared history and shown for you to confirm |
| `/vuln-review-project` | `/vuln-review` on the whole project instead of a change, old weaknesses included; works outside a git repository too, and big projects can be sliced |

<br>

---

<br>

## ➕ Adding Your Own Content

Drop any file or folder into this repo — whenever you run `install.bat` next, it gets picked up automatically, no changes to the script needed.
