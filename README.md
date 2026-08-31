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

> ℹ️ The script is just a convenience — nothing requires it. You can just as well copy only the specific files you want (e.g. a single command from `commands/`) into `%USERPROFILE%\.claude` yourself.

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
- **`commands/`** — custom slash commands, detailed below

<br>

### 🧠 Prompts

| Prompt | What it does |
|--------|---------------|
| `CLAUDE.md` | Master prompt — global instructions loaded into every project, defining how the agent should work with you |

<br>

### ⚡ Commands

| Command | What it does |
|---------|---------------|
| `/merge-pilot` | Proposes how to organize your uncommitted changes into clean commits, then creates them once you approve — complete with a ready-to-use PR description. Can then optionally sync the branch with its target, resolving conflicts along the way. Never pushes |

<br>

---

<br>

## ➕ Adding Your Own Content

Drop any file or folder into this repo — whenever you run `install.bat` next, it gets picked up automatically, no changes to the script needed.
