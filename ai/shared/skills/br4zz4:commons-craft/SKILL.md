---
name: commons-craft
description: Use when creating, updating, or renaming a skill or command.
version: 1.1.0
---

# commons:commons-craft

> **TLDR**: The gain of one becomes the gain of all. Commons grows through every commit.

## Purpose

`.commons` exists to standardize projects and simplify the team's daily work. When one developer learns something or solves a problem that applies to everyone, that knowledge belongs in `.commons` — not locked in a single project.

The AI's role is to **actively facilitate this** — not wait to be asked.

## Core principle

> A solution that solves one project's problem is good.  
> A solution that solves all projects' problems is better.

Everything in `.commons` must be:
- **Agnostic** — no project-specific logic, names, or assumptions
- **Standardized** — consistent patterns that all projects follow
- **Complete** — complex internally, simple to use externally

## When to activate

Activate this skill when the user asks to:
- Create a new skill or command ("create a skill", "add a skill", "new command")
- Update, rename, or improve an existing skill ("update skill", "rename skill", "fix description")
- Understand where to put a skill or command ("where does this skill go?")
- Review skill naming or structure

Also activate **proactively** when:
- A conversation reveals new patterns, conventions, or decisions not yet captured in any skill
- An existing skill is found to be outdated, incomplete, or inconsistent with current practice
- A recurring task or workflow emerges that would benefit from a skill
- A Makefile target, script, or rule that would work in any project
- A pattern being repeated across multiple projects

## What does NOT belong in commons

- Anything with a project name, specific domain, or business logic
- Credentials, environment-specific values, or project URLs
- Workarounds for a single project's tech debt
- Experimental or unstable patterns not yet proven across projects

If in doubt: would this make sense in any wehive project, regardless of stack or domain? If yes → commons.

## Architecture

### Commons (shared across all projects)

Skills and commands live in a provider-neutral shared directory:

```
.commons/
  ai/
    shared/
      skills/
        <name>/           ← the DIRECTORY NAME governs the loaded name
          SKILL.md        ← name: <name>   (frontmatter is ignored by the loader)
      commands/
        <name>/
          <command>.md    ← commons:<name>:<command>
      rules/
        shared.md
    .project/
      specs/              ← shared planning records for commons
      ai/
        skills/           ← symlink to ai/shared/skills
        commands/         ← symlink to ai/shared/commands
```

`ai/` is the **marketplace root** for both providers, and `ai/shared/` is the
**plugin root** for both. Full layout:

```
ai/
  .claude-plugin/
    marketplace.json      ← registers "wehive" marketplace, source: "./shared"
  .agents/
    plugins/
      marketplace.json    ← same for codex, path: "./shared"
  shared/                  ← PLUGIN ROOT (both providers)
    .claude-plugin/
      plugin.json          ← plugin name: "commons" (no colons!)
    .codex-plugin/
      plugin.json          ← plugin name: "commons"
    hooks/
      hooks.json           ← SessionStart, reads ${CLAUDE_PLUGIN_ROOT}/rules/
    skills/  commands/  rules/    ← REAL directories, never symlinks
```

Claude installs the plugin via `claude plugin install commons@wehive`.
Codex registers the local marketplace with `codex plugin marketplace add`.
Codex CLI installs the plugin under `~/.codex/plugins/commons`.
It also receives one compatibility symlink at `~/.codex/skills/commons` because the prompt-visible loader in Codex CLI 0.128.0 reads that directory.
Both providers read the same canonical Markdown files from `ai/shared`.

**Key rule**: plugin name must NOT contain `:` — it breaks the cache path.

**`.commons` does NOT have project-specific `.workspace/` trees** — its `.project/`
is reserved for shared specs and AI mirrors.

### Distribution — never put a symlink inside the plugin root

`claude plugin install` copies the plugin tree into
`~/.claude/plugins/cache/wehive/commons/<version>/` and **does not follow symlinks**.
Any symlinked directory inside the plugin root is silently skipped — no error, no warning,
just missing skills.

This produced a 3.5-month outage nobody noticed:

| When | What happened |
|---|---|
| Apr 23 | installed while `skills/` was a **real directory** → cache got a real copy |
| May 4 | `skills/`, `commands/`, `rules/` converted to symlinks → every later reinstall would copy nothing |
| — | nobody reinstalled, so the Apr 23 copy just sat there being read as if current |
| Aug 6 | uninstall deleted that copy; reinstall produced a plugin with **zero skills** |
| Aug 6 | `ai/providers/` removed; `ai/shared/` became the plugin root of both providers, with real directories only |

Codex never hit this: it symlinks `~/.codex/plugins/commons` at the **live tree**, so it
reads through. Only Claude copies, so only Claude broke.

The structural fix is in place — there is no symlink left inside the plugin root, so
`claude plugin install` copies everything and no manual `cp -RL` step exists anymore.
**Keep it that way.** If you ever need to share a directory between providers, share it by
making the plugin root itself the shared directory, as it is now — never by symlinking into it.

After changing `ai/shared/`, a plain reinstall is enough:

```bash
claude plugin uninstall commons@wehive
claude plugin install commons@wehive
```

Then **verify**, do not assume:

```bash
diff -r $CACHE/skills $SRC/skills        # must be empty
claude plugin details commons@wehive     # skill count must match ls $SRC/skills | wc -l
```

The decisive check is a **new session or child agent** reporting the skills it actually
sees — filesystem inspection alone has been wrong here before.

**Never edit inside the cache.** An edit there is invisible to git and silently diverges
from the source; the `description: TEST - mudei aqui` left in `commands/machine/setup.md`
survived months that way. If a skill looks wrong, fix `ai/shared/` and redistribute.

### Project-specific

Skills and commands for a single project use **symlinks** in the project's
provider dirs:

```
<project>/
  .claude/
    skills  → symlink to ../.project/ai/skills
    commands → symlink to ../.project/ai/commands
  .codex/
    skills  → symlink to ../.project/ai/skills
    commands → symlink to ../.project/ai/commands
  .project/
    ai/
      skills/
        <name>/
          SKILL.md
      commands/
        <name>.md
```

Project skills appear as `<project-name>:<name>` (e.g. `checkout-api:deploy`).  
Commons skills and commands are provided by user-level provider configuration,
not by project-local symlinks.

For Make-related work, command behavior now lives in `make/commands/<name>.mk`,
project `run/*` files are the public command surface that commons loads (as
`make run.<name>` targets), and the entrypoint does not auto-discover stack files.

### Shell tasks: generic in commons + thin local wrapper

When a `tasks/*.sh` script mixes reusable mechanism with project-specific values
(role ARNs, ward paths, app names), split it:

- **Generic script → `.commons/shell/tasks/<domain>/<name>.sh`.** It takes ALL
  project specifics as flags or env vars, validates required ones, and contains no
  project name. Prefer named flags with a heroku-style `-a/--app` for the app
  (e.g. `db-tunnel.sh --app marketing.automation --env staging --db leads`), and
  derive conventions from it (namespace `<app-dashed>--<env>`, ward path
  `<app>.<env>.TF_VAR_<db>_db_*`).
- **Thin local wrapper → `<module>/tasks/<domain>/<name>.sh`.** It resolves
  `COMMONS_DIR` (exported by the shell profile; fall back to the wehive root's
  `.commons`) and calls the commons script with the app's values, keeping the
  positional interface that Make targets already use. Example: the local
  `tasks/db/tunnel.sh [env] [port]` just calls the commons `db-tunnel.sh --app
  marketing.automation --env "$ENV" --port "$PORT"`.

A sourced helper (like `aws-assume-role.sh`) becomes a wrapper that `export`s the
generic script's parameters (`ASSUME_ROLE_ARN`, `ASSUME_ROLE_SESSION`) then
`source`s the commons version — so anything that already sources the local helper
(run.sh, import scripts) picks up the commons path with no further change. Keep
genuinely single-project scripts (e.g. an app's one-shot state-import list, or an
app-only tool like n8n workflow deploy) local — generalize only when a second
project would reuse it.

## Naming conventions

| Type | Directory | Loaded name | Example |
|------|-----------|-------------|---------|
| Commons skill | `ai/shared/skills/<name>/` | `commons:<name>` | `commons:commit` |
| Commons command | `ai/shared/commands/<name>/<cmd>.md` | `commons:<name>:<cmd>` | `commons:machine:setup` |
| Project skill | `.project/ai/skills/<name>/` | `<project>:<name>` | `checkout-api:deploy` |

**The directory name governs the loaded skill name.** The plugin prefix (`commons:`)
comes from the plugin, and the rest comes from the directory — the `name:` field in
frontmatter is **not** what the loader reads. A directory named `wehive:docs` loads as
`commons:wehive:docs`, not `commons:docs`. Never put a prefix in the directory name.

- `description` must be **60 characters or less**
- Write in English
- Start content with `> **TLDR**`

## Creating a commons skill

1. Create `ai/shared/skills/<name>/SKILL.md` — bare `<name>`, no prefix
2. Set `name: <name>` in frontmatter, matching the directory
3. Reinstall the plugin so the cache picks it up (see **Distribution** below), then
   restart the provider session
4. Commit inside `.commons`

```markdown
---
name: <name>
description: Use when the user asks to X.
version: 1.1.0
---

> **TLDR**: One sentence summary.

## Rules / Steps
...
```

## Creating a project skill

1. Create `.project/ai/skills/<name>/SKILL.md`
2. Set `name: <project-name>:<name>` in frontmatter
3. Ensure `.claude/skills` and `.codex/skills` point to `../.project/ai/skills`
4. Commit to the project repo

**Never** create project-specific `.workspace/` trees inside `.commons`.

## Commit workflow

- Commons: commit inside `.commons`
- Project: commit directly to the project repo
