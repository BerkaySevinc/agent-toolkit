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
- **`agents/`** — sub-agent definitions used by skills (today: the `/decide` council and the `/bug-review` reviewers)

<br>

### 🧠 Prompts

| Prompt | What it does |
|--------|---------------|
| `CLAUDE.md` | Master prompt — global instructions loaded into every project, defining how the agent should work with you |

<br>

### ⚡ Skills

| Skill | What it does |
|---------|---------------|
| `/merge-pilot` | Groups your uncommitted changes into clean commits with a ready-to-use PR/MR description, then — each step only after its own approval — syncs with the target, pushes, and opens the PR/MR via your existing GitHub, GitLab, or Azure DevOps login. Never force-pushes |
| `/my-skills` | Lists only your own skills and commands (user, project, added directories), grouped by category — built-in, plugin, and synced skills left out |
| `/decide` | Stress-tests a decision with a council of independent sub-agents: you approve a neutral brief, advisors with different reasoning methods answer anonymously, reviewers and a challenger attack the result, and a chairman gives a short recommendation (full details on request). It recommends; you decide. Runs only on request, 13–23 sub-agent calls. Ask for a lighter run in your own words for a faster, shorter version |
| `/decide-light` | The lighter, faster `/decide`: fewer advisors, no challenge stage, about 10–12 sub-agent calls |
| `/bug-review` | Reviews your changes (or any scope you name: a branch, a commit range, paths, the whole project) for bugs with independent sub-agents that read the code from different angles; every finding is verified before you see it, and you choose which to fix. Reads code only, no security audit. Runs only on request, about 9–20 sub-agent calls; big scopes can be sliced |
| `/bug-review-light` | The lighter, faster `/bug-review`: a quick scan with two angles and no sweep, about 6–9 sub-agent calls |
| `/bug-review-branch` | `/bug-review` on everything the current branch added compared with its base branch (commits and uncommitted changes together, like a PR); the base is found from the shared history and shown for you to confirm |
| `/bug-review-project` | `/bug-review` on the whole project instead of a change; works outside a git repository too, and big projects can be sliced |

<br>

---

<br>

## ➕ Adding Your Own Content

Drop any file or folder into this repo — whenever you run `install.bat` next, it gets picked up automatically, no changes to the script needed.
