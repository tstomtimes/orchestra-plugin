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

To use the Orchestra plugin in other projects, you have several options:

#### Option 1: Environment Variable Setup (Recommended for Development)

Set the `ORCHESTRA_ROOT` environment variable to point to your Orchestra installation:

```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
export ORCHESTRA_ROOT="/path/to/orchestra"

# Then run Claude from your project
cd /path/to/your-project
claude
```

#### Option 2: Symlink Setup (Recommended for Production)

Create a symbolic link from your project's `.claude` directory to the Orchestra plugin:

```bash
cd /path/to/your-project
mkdir -p .claude/hooks
ln -s /path/to/orchestra/.claude/settings.json .claude/settings.json
ln -s /path/to/orchestra/.claude/hooks /path/to/your-project/.claude/orchestra-hooks
```

Then in your `.claude/settings.json`, update hook commands to reference the symlink:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/orchestra-hooks/hook-loader.sh session-start"
          }
        ]
      }
    ]
  }
}
```

#### Option 3: Direct Copy (Standalone)

Copy the Orchestra `.claude` directory structure to your project:

```bash
cp -r /path/to/orchestra/.claude /path/to/your-project/.claude
cp -r /path/to/orchestra/hooks /path/to/your-project/hooks
```

---

## Installation Methods

### Method 1: NPM/PNPM Package (Future)

Once published as a package, you'll be able to install via:

```bash
npm install @orchestra/plugin
# or
pnpm add @orchestra/plugin
```

### Method 2: Git Submodule

Add Orchestra as a submodule to your project:

```bash
git submodule add https://github.com/anthropics/orchestra.git ./orchestra-plugin
export ORCHESTRA_ROOT="./orchestra-plugin"
```

### Method 3: Manual Installation

Clone the Orchestra repository:

```bash
git clone https://github.com/anthropics/orchestra.git
export ORCHESTRA_ROOT="/path/to/orchestra"
```

---

## Configuration

### Using ORCHESTRA_ROOT Environment Variable

The hook-loader script checks for the `ORCHESTRA_ROOT` environment variable:

```bash
# Set environment variable
export ORCHESTRA_ROOT="/path/to/orchestra"

# Run Claude (hooks will be loaded correctly)
claude
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
