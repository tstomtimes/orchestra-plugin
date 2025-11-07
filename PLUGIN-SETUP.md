# Orchestra Plugin Setup Guide

## Overview

The Orchestra plugin provides specialized agents and automated hooks for Claude Code. This guide explains how to set up the plugin for use in your own projects.

## Table of Contents

1. [Quick Setup](#quick-setup)
2. [Installation Methods](#installation-methods)
3. [Configuration](#configuration)
4. [Troubleshooting](#troubleshooting)

---

## Quick Setup

### For Orchestra Project Itself

If you're working within the Orchestra project, the plugin is automatically available. Simply run:

```bash
cd /path/to/orchestra
claude
```

The hooks will be automatically loaded from the `.claude/` directory.

### For Other Projects

To use the Orchestra plugin in other projects, use the automated setup script:

```bash
# Run the setup script
bash /path/to/orchestra/setup-plugin.sh /path/to/your-project

# Then use Claude from your project
cd /path/to/your-project
claude
```

Or manually configure your project following the methods below:

---

## Installation Methods

### Method 1: Automated Setup (Recommended)

Use the included `setup-plugin.sh` script to automatically configure your project:

```bash
bash /path/to/orchestra/setup-plugin.sh /path/to/your-project
```

This creates:
- `.claude/settings.json` with absolute paths to the Orchestra hooks
- `.claude/hooks/hook-loader.sh` symlink (for reference)
- `.claude.json` with environment variable configuration

### Method 2: NPM/PNPM Package (Future)

Once published as a package, you'll be able to install via:

```bash
npm install @orchestra/plugin
# or
pnpm add @orchestra/plugin
```

### Method 3: Manual Configuration

If you prefer to set up manually:

1. Create `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/orchestra/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

2. Replace `/path/to/orchestra` with your actual Orchestra installation path

---

## Configuration

### Hook Path Resolution

The plugin uses **absolute paths** in `.claude/settings.json` to ensure hooks are found regardless of:
- The current working directory
- How Claude Code is invoked
- Where the Orchestra project is installed

Example hook command:
```bash
bash /Users/tstomtimes/Documents/GitHub/orchestra/hooks/session-start.sh
```

### Finding Your Orchestra Installation Path

```bash
# Get the absolute path to Orchestra
cd /path/to/orchestra
pwd

# Output will show the full path to use in settings.json
```

### Verifying Installation

To verify the plugin is correctly configured:

1. Run Claude from your project directory
2. Check that the Orchestra welcome message appears on startup
3. Verify that specialized agents are listed

Example output:
```
🎭 ORCHESTRA PLUGIN LOADED
✨ Specialized agents are ready for coordination:
   😎 Blake   - Release Manager
   🤓 Eden    - Documentation Lead
   ...
```

### Customizing Hooks

If you need to customize or disable specific hooks, you can:

1. Copy the settings.json to your project's `.claude/` directory
2. Modify the hooks configuration as needed
3. Keep the `hook-loader.sh` references intact

Example `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh session-start"
          }
        ]
      }
    ]
  }
}
```

---

## Troubleshooting

### Error: Hook not found

**Symptom:**
```
Plugin hook error: bash: ./.claude/hooks/hook-loader.sh: No such file or directory
```

**Solution:**
1. Verify the `hook-loader.sh` script exists in `.claude/hooks/`
2. Check that the path is correct relative to your project root
3. If using `ORCHESTRA_ROOT`, verify the environment variable is set:
   ```bash
   echo $ORCHESTRA_ROOT
   ```

### Error: Hook path resolution failed

**Symptom:**
```
Error: Hook 'session-start' not found at /path/to/hooks/session-start.sh
```

**Solution:**
1. Set `ORCHESTRA_ROOT` environment variable:
   ```bash
   export ORCHESTRA_ROOT="/path/to/orchestra"
   ```
2. Or use one of the symlink/copy methods above

### Hooks not loading when running from different directory

**Symptom:**
Hooks work when running `claude` from project root but fail from subdirectories.

**Solution:**
1. Use the `ORCHESTRA_ROOT` environment variable (recommended)
2. Or ensure all hook references use relative paths from `.claude/` directory

### Mixed hooks from different sources

**Symptom:**
Some hooks work but others fail with path resolution errors.

**Solution:**
Ensure all hooks in `.claude/settings.json` use the same loading mechanism:
- All use `hook-loader.sh` for consistency
- All use relative paths from project root
- Or all use absolute paths

---

## Development Setup

If you're developing the Orchestra plugin:

1. Clone the repository:
   ```bash
   git clone https://github.com/anthropics/orchestra.git
   cd orchestra
   ```

2. Run setup:
   ```bash
   ./setup.sh
   ```

3. Start developing:
   ```bash
   claude
   ```

---

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Agent-first policy and usage guide
- [.claude/settings.json](./.claude/settings.json) - Hook configurations

---

## Support

For issues or questions:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review the [CLAUDE.md](./CLAUDE.md) for agent usage
3. File an issue on GitHub: https://github.com/anthropics/orchestra/issues
