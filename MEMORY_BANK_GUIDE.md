# Memory Bank Integration Guide

**Orchestra Plugin for Claude Code**

---

## Table of Contents

1. [What is Memory Bank?](#what-is-memory-bank)
2. [Automatic Initialization](#automatic-initialization)
3. [Memory Bank File Structure](#memory-bank-file-structure)
4. [File Purposes and Usage](#file-purposes-and-usage)
5. [Working with Memory Bank](#working-with-memory-bank)
6. [Document Synchronization](#document-synchronization)
7. [Milestone Recording](#milestone-recording)
8. [Manual Operations](#manual-operations)
9. [FAQ](#faq)
10. [Troubleshooting](#troubleshooting)

---

## What is Memory Bank?

**Memory Bank** is a persistent knowledge storage system that preserves project context across Claude Code sessions. Unlike session-based context (which is lost when Claude Code restarts), Memory Bank maintains:

- Project overview and current state
- Technology stack and dependencies
- Important decisions and their rationale
- Progress tracking and milestones
- Next steps and action items

### Key Benefits

- **Session Persistence** - Project knowledge survives Claude Code restarts
- **Reduced Context Re-explanation** - No need to repeatedly describe your project
- **Agent Knowledge Sharing** - All Orchestra agents access the same project knowledge
- **Structured Documentation** - Consistent format ensures completeness
- **Automatic Updates** - Hooks keep Memory Bank synchronized with code changes

### How It Works

Memory Bank stores structured Markdown files in `~/memory-bank/orchestra/`:

```
~/memory-bank/orchestra/
├── project-overview.md    # High-level project overview
├── tech-stack.md         # Technology stack and architecture
├── decisions.md          # Important decisions log
├── progress.md           # Detailed progress tracking
└── next-steps.md         # Immediate action items
```

Claude Code's Memory Bank MCP server provides tools to read, write, and update these files programmatically during conversations.

---

## Automatic Initialization

The Orchestra Plugin **automatically initializes Memory Bank** during setup. You don't need to manually configure anything.

### When Initialization Happens

Memory Bank initialization occurs automatically when you run:

```bash
./setup.sh
```

Or from within Claude Code:

```
/orchestra-setup
```

### What Gets Created

The initialization script creates:

1. **Directory structure**: `~/memory-bank/orchestra/`
2. **5 template files** (see [Memory Bank File Structure](#memory-bank-file-structure))
3. **Timestamps** for tracking when files were created
4. **Default content** with project-specific information

### Safety Features

- **Existing project protection**: Won't overwrite if files already exist
- **Non-blocking**: If initialization fails, setup continues (Memory Bank is optional)
- **Idempotent**: Safe to run multiple times

---

## Memory Bank File Structure

Memory Bank uses 5 core template files to organize project knowledge:

### 1. project-overview.md

**Purpose**: High-level project overview and current state

**Contents**:
- Project purpose and goals
- Current implementation status
- Repository structure
- Key features summary
- Recent changes log
- Short/medium/long-term goals

**Update frequency**: Weekly or when major milestones are reached

**Example use case**:
```markdown
## Current State

### Implementation Status
- ✅ Core plugin architecture with 12 agents
- ✅ Git hook system
- ✅ MCP servers (Browser, Memory Bank, ElevenLabs)
- 🚧 Memory Bank integration (in progress)
```

---

### 2. tech-stack.md

**Purpose**: Technology stack, dependencies, and system architecture

**Contents**:
- Languages and runtime environments
- Frameworks and libraries
- MCP server implementations
- Development tools
- Architecture patterns
- Configuration files
- External services and APIs
- System requirements

**Update frequency**: When dependencies or architecture changes

**Example use case**:
```markdown
## Core Technologies

### Languages
- **TypeScript** - Primary language for plugin logic
- **Bash** - Shell scripting for setup and hooks
- **Python** - MCP server implementation (ElevenLabs)
```

---

### 3. decisions.md

**Purpose**: Important decisions and their rationale (lightweight ADR)

**Contents**:
- Decision log with unique IDs
- Context for each decision
- Alternatives considered
- Rationale and reasoning
- Consequences and trade-offs
- Decision status (Proposed/Implemented/Rejected/Revised)

**Update frequency**: When significant architectural or technical decisions are made

**Example use case**:
```markdown
### D-003: Memory Bank Integration
**Date:** 2025-11
**Status:** ✅ Implemented
**Context:** Need for persistent project knowledge across sessions

**Alternatives Considered:**
1. Session-based context only
2. File-based project documentation
3. Memory Bank MCP server integration

**Decision:** Integrate Memory Bank MCP server

**Rationale:**
- Persists key information across sessions
- Reduces need to re-explain context
- Enables knowledge sharing between agents
```

---

### 4. progress.md

**Purpose**: Detailed progress tracking, milestones, and metrics

**Contents**:
- Current sprint status
- Completed/in-progress/blocked tasks
- Phase-based milestones
- Feature implementation status
- Code quality metrics
- Known issues and risk register
- Weekly updates
- **Automated milestone entries**

**Update frequency**: Daily or weekly; automatically updated by hooks

**Example use case**:
```markdown
## Milestones

### Phase 1: Core Infrastructure ✅
**Completed:** 2025-11
- [x] Project setup and repository structure
- [x] 12 specialized agent definitions
- [x] Git hook system implementation

### Phase 2: MCP Server Integration 🚧
**In Progress - 85% Complete**
- [x] Browser MCP server
- [ ] Memory Bank initialization automation
```

**Automatic Updates**:
The `record-milestone.sh` script automatically adds milestone entries:

| Date | Milestone | Description | Tag | Contributor |
|------|-----------|-------------|-----|-------------|
| 2025-11-03 | Feature XYZ | Implemented core functionality | `feature` | John Doe |

---

### 5. next-steps.md

**Purpose**: Immediate action items and future roadmap

**Contents**:
- Immediate high-priority actions (this week)
- Short-term goals (next 2 weeks)
- Medium-term goals (next month)
- Long-term vision (next quarter)
- Dependencies and blockers
- Quick wins (< 1 hour tasks)
- Ideas and backlog

**Update frequency**: Daily for immediate actions; weekly for short-term goals

**Example use case**:
```markdown
## Immediate Actions (This Week)

### High Priority 🔴
1. **Complete Memory Bank initialization script**
   - **Owner:** Skye
   - **Status:** In Progress
   - **Deadline:** 2025-11-05

### Medium Priority 🟡
1. **Update Orchestra documentation**
   - Add Memory Bank usage guide
```

---

## File Purposes and Usage

### When to Update Each File

| File | Update Trigger | Frequency | Owner |
|------|---------------|-----------|-------|
| **project-overview.md** | Major milestones, architecture changes | Weekly | Alex, Eden |
| **tech-stack.md** | New dependencies, framework changes | As needed | Kai, Skye |
| **decisions.md** | Significant technical decisions | Per decision | Kai, Alex |
| **progress.md** | Task completion, milestones | Daily/Auto | All agents |
| **next-steps.md** | Planning sessions, sprint updates | Daily | Alex, Riley |

### Reading Memory Bank Files

Orchestra agents automatically read relevant Memory Bank files when needed. You can also manually read them:

**Via MCP tools in Claude Code**:
```
Use mcp__memory-bank__memory_bank_read with:
- projectName: "orchestra"
- fileName: "project-overview.md"
```

**Via direct file access**:
```bash
cat ~/memory-bank/orchestra/project-overview.md
```

### Updating Memory Bank Files

**Via MCP tools in Claude Code**:
```
Use mcp__memory-bank__memory_bank_update with:
- projectName: "orchestra"
- fileName: "progress.md"
- content: "Updated content here..."
```

**Via direct file editing**:
```bash
vim ~/memory-bank/orchestra/next-steps.md
```

---

## Working with Memory Bank

### For Developers

Memory Bank provides persistent context for your development sessions:

1. **Session Start**: Claude loads Memory Bank files to understand project state
2. **Development**: Work naturally; changes are tracked automatically
3. **Session End**: Updates are written back to Memory Bank
4. **Next Session**: Context is restored automatically

### For Orchestra Agents

Agents use Memory Bank to:

- **Alex (PM)**: Read project overview and next-steps for task planning
- **Riley (Requirements)**: Update decisions.md with clarifications
- **Skye (Implementation)**: Reference tech-stack.md for architecture patterns
- **Kai (Architecture)**: Maintain decisions.md with ADRs
- **Eden (Documentation)**: Update all files to keep documentation current

### Best Practices

1. **Keep files concise**: Focus on essential information
2. **Update regularly**: Don't let documentation drift from code
3. **Use consistent formatting**: Follow template structure
4. **Link between files**: Cross-reference related sections
5. **Date your updates**: Include timestamps for tracking

---

## Document Synchronization

The Orchestra Plugin includes automatic synchronization between `.orchestra/specs/` and Memory Bank.

### Automatic Sync Features

**Sync script**: `.orchestra/scripts/sync-to-memory-bank.sh`

**What gets synced**:
- Requirements documents (`.orchestra/specs/requirements/*.md`)
- Architecture decisions (`.orchestra/specs/architecture/*.md`)
- Data models (`.orchestra/specs/data-models/*.md`)
- Business logic docs (`.orchestra/specs/business-logic/*.md`)

**When sync happens**:
- Manually: Run sync script
- After deploy: `hooks/after_deploy.sh` triggers sync
- On demand: Via Orchestra agents

### Manual Synchronization

**Run sync script**:
```bash
# Dry-run to see what would be synced
bash .orchestra/scripts/sync-to-memory-bank.sh --dry-run

# Actual sync
bash .orchestra/scripts/sync-to-memory-bank.sh

# Force sync (overwrite unchanged files)
bash .orchestra/scripts/sync-to-memory-bank.sh --force

# Verbose output
bash .orchestra/scripts/sync-to-memory-bank.sh --verbose
```

### Sync Options Reference

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be synced without making changes |
| `--force` | Force overwrite existing files even if unchanged |
| `--verbose`, `-v` | Show detailed output |
| `--help`, `-h` | Show usage information |

### Sync Configuration

Edit `.orchestra/config.json` to control sync behavior:

```json
{
  "integrations": {
    "memoryBank": {
      "enabled": true,
      "project": "orchestra",
      "syncPatterns": [
        ".orchestra/specs/requirements/*.md",
        ".orchestra/specs/architecture/*.md"
      ],
      "excludePatterns": [
        "**/*TEMPLATE*.md",
        "**/*.draft.md"
      ]
    }
  }
}
```

**Configuration options**:

- `enabled`: Enable/disable Memory Bank integration
- `project`: Memory Bank project name
- `syncPatterns`: Glob patterns for files to sync
- `excludePatterns`: Glob patterns for files to exclude

### Sync History

Sync operations are tracked in `.orchestra/cache/sync-history.json`:

```json
{
  "syncs": [
    {
      "file": "requirements/REQ-001.md",
      "checksum": "a1b2c3d4",
      "timestamp": "2025-11-03T10:30:00Z",
      "action": "sync"
    }
  ]
}
```

This prevents unnecessary re-syncing of unchanged files.

---

## Milestone Recording

The Orchestra Plugin provides automatic milestone recording to track project progress.

### Automatic Milestone Recording

**Script**: `.orchestra/scripts/record-milestone.sh`

**Usage**:
```bash
bash .orchestra/scripts/record-milestone.sh \
  "Milestone Name" \
  "Brief description" \
  "tag" \
  "Contributor Name (optional)"
```

**Example**:
```bash
bash .orchestra/scripts/record-milestone.sh \
  "Memory Bank Integration" \
  "Completed Memory Bank initialization and sync scripts" \
  "feature" \
  "Skye"
```

### Milestone Tags

| Tag | Purpose |
|-----|---------|
| `feature` | New feature implementation |
| `bugfix` | Bug fix |
| `refactor` | Code refactoring |
| `docs` | Documentation update |
| `test` | Test implementation |
| `perf` | Performance optimization |
| `chore` | Maintenance task |

### What Gets Recorded

Milestones are automatically added to `progress.md` in this format:

```markdown
## Milestone Updates

| Date | Milestone | Description | Tag | Contributor |
|------|-----------|-------------|-----|-------------|
| 2025-11-03 15:30:00 UTC | Memory Bank Integration | Completed initialization scripts | `feature` | Skye |
```

**Automatic updates**:
- Timestamp in UTC
- Total milestone count
- Last updated timestamp
- Prevents duplicate entries

### Integration with Hooks

Milestones can be recorded automatically by hooks:

```bash
# In hooks/after_deploy.sh
if [ deployment successful ]; then
  bash .orchestra/scripts/record-milestone.sh \
    "Deployment to Production" \
    "Deployed version $VERSION successfully" \
    "chore" \
    "$(git config user.name)"
fi
```

---

## Manual Operations

### Reinitializing Memory Bank

If you need to recreate Memory Bank files:

1. **Backup existing files** (if any):
   ```bash
   cp -r ~/memory-bank/orchestra ~/memory-bank/orchestra-backup-$(date +%Y%m%d)
   ```

2. **Remove existing project**:
   ```bash
   rm -rf ~/memory-bank/orchestra
   ```

3. **Run initialization script**:
   ```bash
   bash .orchestra/scripts/init-memory-bank.sh
   ```

### Listing Memory Bank Projects

**Via MCP tools**:
```
Use mcp__memory-bank__list_projects
```

**Via direct access**:
```bash
ls -la ~/memory-bank/
```

### Listing Project Files

**Via MCP tools**:
```
Use mcp__memory-bank__list_project_files with projectName: "orchestra"
```

**Via direct access**:
```bash
ls -la ~/memory-bank/orchestra/
```

### Manually Editing Files

You can directly edit Memory Bank files with any text editor:

```bash
# Edit in vim
vim ~/memory-bank/orchestra/next-steps.md

# Edit in VSCode
code ~/memory-bank/orchestra/progress.md

# Edit with nano
nano ~/memory-bank/orchestra/decisions.md
```

Changes will be available in the next Claude Code session.

---

## FAQ

### General Questions

**Q: Do I need to manually create Memory Bank files?**
A: No. Memory Bank is automatically initialized by `setup.sh`. Template files are created for you.

**Q: What happens if Memory Bank initialization fails?**
A: Setup continues normally. Memory Bank is optional and non-blocking. You can run the initialization script manually later.

**Q: Can I use Memory Bank with multiple projects?**
A: Yes. Each project gets its own directory under `~/memory-bank/PROJECT_NAME/`.

**Q: How do Orchestra agents access Memory Bank?**
A: Agents use Claude Code's Memory Bank MCP tools to read and write files programmatically during conversations.

**Q: Do Memory Bank files count against my Claude Code context window?**
A: No. Memory Bank files are loaded on-demand and managed separately from conversation context.

### Technical Questions

**Q: Where are Memory Bank files stored?**
A: In `~/memory-bank/orchestra/` on your local filesystem.

**Q: Can I version control Memory Bank files?**
A: Yes. You can add `~/memory-bank/` to a git repository if desired, but it's not required.

**Q: What format are Memory Bank files?**
A: Markdown (.md) for human readability and easy editing.

**Q: How often should I update Memory Bank files?**
A: Update as project evolves. Aim for weekly reviews at minimum. Use the sync script to automate updates from `.orchestra/specs/`.

**Q: Can I customize Memory Bank templates?**
A: Yes. Edit the template generation functions in `.orchestra/scripts/init-memory-bank.sh` before running setup.

**Q: What if I accidentally delete Memory Bank files?**
A: Re-run the initialization script: `bash .orchestra/scripts/init-memory-bank.sh`

### Sync Questions

**Q: How do I know if files are in sync?**
A: Check `.orchestra/cache/sync-history.json` for sync timestamps and checksums.

**Q: What if sync script fails?**
A: Check logs in `.orchestra/logs/`. Common issues: missing `jq`, invalid config.json, or filesystem permissions.

**Q: Can I exclude certain files from sync?**
A: Yes. Add glob patterns to `excludePatterns` in `.orchestra/config.json`.

**Q: Does sync overwrite existing Memory Bank files?**
A: Only if files have changed (detected via checksum). Use `--force` to override.

---

## Troubleshooting

### Issue: Memory Bank Not Initialized

**Symptoms**:
- `~/memory-bank/orchestra/` directory doesn't exist
- Template files are missing

**Solutions**:
1. Run initialization script manually:
   ```bash
   bash .orchestra/scripts/init-memory-bank.sh
   ```

2. Check if script is executable:
   ```bash
   chmod +x .orchestra/scripts/init-memory-bank.sh
   ```

3. Check script output for errors:
   ```bash
   bash .orchestra/scripts/init-memory-bank.sh 2>&1 | tee init-debug.log
   ```

---

### Issue: Sync Script Fails

**Symptoms**:
- Error messages when running sync script
- Files not appearing in Memory Bank

**Solutions**:

1. **Check if `jq` is installed**:
   ```bash
   which jq
   # If not installed: brew install jq (macOS) or apt install jq (Linux)
   ```

2. **Verify config.json syntax**:
   ```bash
   jq . .orchestra/config.json
   ```

3. **Run with verbose output**:
   ```bash
   bash .orchestra/scripts/sync-to-memory-bank.sh --verbose
   ```

4. **Check file permissions**:
   ```bash
   ls -la .orchestra/specs/
   ```

---

### Issue: Milestone Recording Fails

**Symptoms**:
- Milestone not added to progress.md
- Error messages from record-milestone.sh

**Solutions**:

1. **Check if progress.md exists**:
   ```bash
   ls -la ~/memory-bank/orchestra/progress.md
   ```

2. **Verify arguments**:
   ```bash
   bash .orchestra/scripts/record-milestone.sh \
     "Test Milestone" \
     "Test description" \
     "feature"
   ```

3. **Check logs**:
   ```bash
   cat .orchestra/logs/milestone-recording.log
   ```

4. **Ensure valid tag** (feature/bugfix/refactor/docs/test/perf/chore)

---

### Issue: Files Not Syncing Automatically

**Symptoms**:
- Changes in `.orchestra/specs/` don't appear in Memory Bank
- Hooks don't trigger sync

**Solutions**:

1. **Check if Memory Bank integration is enabled**:
   ```bash
   jq '.integrations.memoryBank.enabled' .orchestra/config.json
   ```

2. **Manually trigger sync**:
   ```bash
   bash .orchestra/scripts/sync-to-memory-bank.sh
   ```

3. **Verify sync patterns**:
   ```bash
   jq '.integrations.memoryBank.syncPatterns' .orchestra/config.json
   ```

4. **Check hook configuration**:
   ```bash
   cat hooks/after_deploy.sh | grep sync-to-memory-bank
   ```

---

### Issue: Large Files Not Syncing

**Symptoms**:
- Warning: "Skipping large file (>1MB)"
- Some specification files missing from Memory Bank

**Solutions**:

1. **Check file size**:
   ```bash
   ls -lh .orchestra/specs/requirements/*.md
   ```

2. **Split large files** into smaller documents

3. **Modify size limit** in sync script (advanced):
   Edit `.orchestra/scripts/sync-to-memory-bank.sh` and adjust the 1MB limit

---

### Issue: Permission Denied Errors

**Symptoms**:
- "Permission denied" when accessing Memory Bank
- Cannot write to `~/memory-bank/`

**Solutions**:

1. **Check directory permissions**:
   ```bash
   ls -la ~/memory-bank/
   ```

2. **Fix ownership**:
   ```bash
   sudo chown -R $(whoami) ~/memory-bank/
   ```

3. **Verify write permissions**:
   ```bash
   touch ~/memory-bank/test-file && rm ~/memory-bank/test-file
   ```

---

### Issue: Outdated Information in Memory Bank

**Symptoms**:
- Memory Bank files contain old or incorrect information
- Recent changes not reflected

**Solutions**:

1. **Manually update files**:
   ```bash
   vim ~/memory-bank/orchestra/project-overview.md
   ```

2. **Force sync from specs**:
   ```bash
   bash .orchestra/scripts/sync-to-memory-bank.sh --force
   ```

3. **Set up reminder** to review files weekly:
   ```bash
   # Add to crontab for weekly reminders
   crontab -e
   # Add: 0 9 * * MON echo "Review Memory Bank files" | mail -s "Weekly Reminder" you@example.com
   ```

---

### Getting Help

If you encounter issues not covered here:

1. **Check logs**:
   ```bash
   ls -la .orchestra/logs/
   cat .orchestra/logs/milestone-recording.log
   ```

2. **Run tests**:
   ```bash
   bash .orchestra/scripts/test-memory-bank-init.sh
   bash .orchestra/scripts/test-sync-to-memory-bank.sh
   bash .orchestra/scripts/test-milestone-recording.sh
   ```

3. **Review documentation**:
   - [README.md](README.md) - General Orchestra overview
   - [ORCHESTRA_SETUP.md](ORCHESTRA_SETUP.md) - Setup instructions
   - [.orchestra/README.md](.orchestra/README.md) - Document-Driven Development

4. **Open an issue**:
   - GitHub: [https://github.com/tstomtimes/orchestra/issues](https://github.com/tstomtimes/orchestra/issues)

---

## Summary

Memory Bank provides **persistent project knowledge** that survives Claude Code session restarts. Key features:

- **5 structured files** (overview, tech-stack, decisions, progress, next-steps)
- **Automatic initialization** via setup.sh
- **Document synchronization** from .orchestra/specs/
- **Milestone recording** for progress tracking
- **MCP tool integration** for programmatic access
- **Non-blocking and optional** (won't break your workflow)

**Quick Start**:
1. Run `./setup.sh` (Memory Bank is auto-initialized)
2. Review files in `~/memory-bank/orchestra/`
3. Update as project evolves
4. Use sync script to keep docs current

Memory Bank makes Orchestra Plugin smarter by preserving context across sessions, enabling more productive and context-aware development workflows.

---

**Last Updated**: 2025-11-03
