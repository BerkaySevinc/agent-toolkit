---
description: Lists only your own custom skills and commands (user-level, the current project's including parent folders, and added directories), read straight from disk and grouped by category — never built-in, plugin, or claude.ai-synced ones.
disable-model-invocation: true
allowed-tools: Glob, Read
---

## Instructions

Read-only: never modify, create, or delete anything, and never run shell commands. Find every custom skill and command on disk, then display them.

### 1. Locate the folders to scan

Build a list of skills folders and commands folders, each tagged with a scope:

- **`user`**: this skill's own folder is `${CLAUDE_SKILL_DIR}` (`<config>/skills/my-skills`), so the skills folder is `${CLAUDE_SKILL_DIR}/..` and the commands folder is `${CLAUDE_SKILL_DIR}/../../commands`. If `${CLAUDE_SKILL_DIR}` did not resolve (it still appears literally) or those folders don't exist, use the `.claude` folder in the user's home directory instead.
- **`project`**: start at the current working directory and walk up through its parents; at every level, `<dir>/.claude/skills` and `<dir>/.claude/commands`. Stop after the first directory that is a git repository root; if none is found, keep walking up to the filesystem root (Claude Code loads parent folders' project skills even outside a repository). Find the repository root with `Read` on `<dir>/.git/HEAD` (a normal repository) and then `<dir>/.git` (a linked worktree's `.git` file) — "does not exist" means not a root; issue these reads for all levels in the same turn. Never use `Glob` for this check: it walks the whole tree and times out on large folders.
- **`added`**: for every additional working directory listed in your context ("Additional working directories", added with `/add-dir` or `--add-dir`), `<dir>/.claude/skills` and `<dir>/.claude/commands`. None listed means none.
- Skip any folder that is the same physical folder as one already in the list (e.g. the walk reaching the home directory lands on the user-level `.claude`). A folder that doesn't exist is skipped silently.

### 2. Enumerate with exactly these patterns

For every folder in the list above:

- **Skills**: `Glob` with pattern `**/SKILL.md` and `path` set to the skills folder, then keep only results that sit exactly one folder below it (`<skills folder>/<name>/SKILL.md`) and discard the rest — this is what keeps `synced/` (claude.ai-synced skills), `.trash/`, and any skill's supporting files out of the result. Never use `*/SKILL.md`: for a folder inside the working directory it silently returns nothing.
- **Commands**: `Glob` with pattern `*.md` and `path` set to the commands folder itself — never `commands/*.md` from its parent: a commands folder that is a junction or symlink is only followed when it is the `path` argument, and from the parent it silently returns nothing. Keep only files directly inside the folder; discard anything in a subfolder.
- Never list built-in, bundled, plugin, or claude.ai-synced skills — they don't live in these folders.

### 3. Read each file

One `Read` per file, all in the same turn, `limit` 20 — only the frontmatter (the block between the first two `---` lines) matters; ignore the body, except as noted below.

- **Name**: frontmatter `name:` if present, otherwise the skill's folder name / the command file's name without `.md`. Shown as `/name`.
- **Description**: the `description:` value, quotes stripped. If it is `>`, `|`, or empty, join the indented lines that follow. If there is none (or no frontmatter), use the first non-empty body line. Cut at the first sentence end, and at 120 characters with `…` if still longer. Escape any `|` as `\|`.
- **Manual only**: if the frontmatter has `disable-model-invocation: true`, append ` *(manual only)*` to the description.

### 4. Display

Group everything into logical categories by purpose — your own judgment, no predefined categories. Each skill or command appears in exactly one category. Same name at more than one scope or level: list every row.

Format each category as a table:

| Command | Scope | Description |
|---------|-------|-------------|
| `/name` | `user`, `project`, or `added` | one-line description |

**Output only the result.** Write no text while locating, enumerating, or reading — no progress updates, and no mention of resolved paths, skipped folders, or an empty project level. The first thing you write is the first category heading and the last is the total line; nothing before, between, or after. Category headings are in the user's language; descriptions are copied as written. End with a single line: `X skills total (user: A, project: B, added: C)`. If nothing was found, write a single line saying so, nothing else.
