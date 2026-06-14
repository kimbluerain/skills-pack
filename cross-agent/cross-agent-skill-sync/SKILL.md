---
name: cross-agent-skill-sync
description: Import skills from Reasonix, Claude Code, or other agents into Hermes format. Run the sync script, then convert each .md file to a proper Hermes skill with YAML frontmatter.
category: autonomous-ai-agents
tags: [skills, sync, migration, reasonix, claude-code, cross-agent]
---

# Cross-Agent Skill Sync

Import skills from Reasonix, Claude Code, or other agents so Hermes can use them.

## Overview

Other agents (Reasonix, Claude Code) store skills as flat `.md` files in specific directories. Hermes stores skills as `category/name/SKILL.md` files with YAML frontmatter. This skill documents the conversion process.

## Sync Workflow

### Step 1: Run the sync script

Reasonix has a sync script at `同步空间/reasonix/sync-skills/sync_skills.sh`:

```bash
cd $PROJECT_DIR && bash sync-skills/sync_skills.sh
```

This copies skills to:
- `~/.reasonix/skills/` (Reasonix global)
- `~/.claude/skills/` (Claude Code)

It does NOT copy to Hermes automatically.

### Step 2: Copy to Hermes (flat fallback)

```bash
SRC="~/.reasonix/skills"
HERMES_SKILLS="$HOME/.hermes/skills"
for f in "$SRC"/*.md; do
  base=$(basename "$f")
  [[ "$base" == "analysis-skill-downloaded.md" ]] && continue
  cp "$f" "$HERMES_SKILLS/reasonix-$base"
done
```

This creates flat files (e.g. `reasonix-memory-box.md`). Hermes does NOT recognize these — they lack the proper directory structure and frontmatter.

### Step 3: Convert to Hermes format

For each skill file:
1. Read the full content
2. Check if it has YAML frontmatter (starts with `---`)
3. If YES: extract `name` and `description` from frontmatter, then create a proper Hermes skill
4. If NO: write a new YAML frontmatter block with a descriptive `name` and `description`

Use `skill_manage(action='create', name='<name>', category='reasonix', content='...')` to register each skill.

### Step 4: Clean up

Remove the flat fallback files after conversion:

```bash
rm ~/.hermes/skills/reasonix-*.md
```

### Step 5: Verify

```bash
hermes skills list | grep reasonix
```

## Pitfalls

1. **Missing YAML frontmatter** — Hermes requires `name` and `description` in frontmatter. Plain markdown files are invisible to `hermes skills list`. Always convert via `skill_manage create`.
2. **Category matters** — Use `category: reasonix` to keep imported skills grouped and identifiable.
3. **00-SOP.md** — This file has no frontmatter at all. Manually write one with `name: reasonix-sop` and a clear description.
4. **Complex skills** — Some skills (like `ppt-master`) reference external scripts, templates, or directories. The SKILL.md can reference these but the actual support files won't auto-copy. Note this in the skill description.
5. **Name collisions** — Prefix with `reasonix-` to avoid colliding with existing Hermes skills of the same name.
6. **Session boundary** — After creating skills, they won't appear in the current session's skills list until `/reload-skills` or a new session. Use `skill_view('name')` directly to load in the current session.
