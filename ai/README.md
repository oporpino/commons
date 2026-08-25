# WeHive AI Rules

This directory contains AI rules organized by tech stack and shared skills for AI assistants like Claude Code and Codex.

## Structure

```
.commons/ai/
├── all.md                    # All rules (all tech stacks) - use only for multi-stack projects
├── ruby.md                   # Entry point for Ruby projects
├── react.md                  # Entry point for React projects
├── django.md                 # Entry point for Django projects
├── terraform.md              # Entry point for Terraform projects
├── shared/                   # Provider-neutral skills, commands, and plugin rules
├── providers/                # Provider-specific plugin packaging
└── rules/
    ├── shared/               # Rules shared across all tech stacks
    │   ├── main.md           # General rules (code style, practices)
    │   ├── git.md            # Git workflow rules
    │   └── testing.md        # General testing principles
    ├── ruby/                 # Ruby-specific rules
    │   ├── main.md           # Ruby general rules
    │   └── testing.md        # Ruby testing (RSpec/Minitest)
    ├── react/                # React-specific rules
    │   ├── main.md           # React general rules
    │   └── testing.md        # React testing (Jest/RTL)
    ├── django/               # Django-specific rules
    │   ├── main.md           # Django general rules
    │   └── testing.md        # Django testing
    └── terraform/            # Terraform-specific rules
        └── main.md           # Terraform rules (structure, modules)
```

## Usage

### In Your Project's AI Instructions

Reference the appropriate entry point based on your project's tech stack:

**Ruby projects:**
```markdown
**IMPORTANT**: This project follows specific rules defined in `.commons/ai/ruby.md`.
```

**React projects:**
```markdown
**IMPORTANT**: This project follows specific rules defined in `.commons/ai/react.md`.
```

**Django projects:**
```markdown
**IMPORTANT**: This project follows specific rules defined in `.commons/ai/django.md`.
```

**Terraform projects:**
```markdown
**IMPORTANT**: This project follows specific rules defined in `.commons/ai/terraform.md`.
```

**Multi-stack projects (only if needed):**
```markdown
**IMPORTANT**: This project follows specific rules defined in `.commons/ai/all.md`.
```

## How It Works

Each entry point file (ruby.md, react.md, etc.) contains only imports that pull in:
1. Shared rules (git, testing principles, general practices)
2. Tech-specific rules (framework conventions, testing tools)

This structure ensures:
- ✅ No duplication of shared rules
- ✅ Clear separation by tech stack
- ✅ Easy to add new tech stacks
- ✅ Projects only load relevant rules

## Adding a New Tech Stack

1. Create directory: `mkdir rules/new-stack`
2. Create main rules: `rules/new-stack/main.md`
3. Create testing rules: `rules/new-stack/testing.md`
4. Create entry point: `new-stack.md` with imports
5. Update `all.md` to include the new entry point
6. Document usage in this README

## File Organization

**Entry point files** (ruby.md, react.md, etc.):
- Contains only `@` imports
- No actual rules content
- Acts as composition layer

**Rules files** (rules/{stack}/main.md, etc.):
- Contains actual rules in groups: `[group_name]`
- Follow format: `- category: rule description`
- Use priority ordering (top = higher priority)
