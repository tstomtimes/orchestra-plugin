# Hooks Guide for Orchestra Plugin

## What are Hooks?

Hooks are automation scripts that run at specific points in your development workflow. Orchestra Plugin uses hooks to provide quality gates, security checks, and automated approvals.

## Automatic Activation

**Good news: Hooks activate automatically when you install the plugin!**

### Installation Process

1. Install the plugin:
   ```
   /plugin marketplace add tstomtimes/orchestra-plugin
   /plugin install orchestra-plugin
   ```

2. Restart Claude Code

3. Hooks are now active! ✅

No additional configuration needed.

## Available Hooks

Orchestra Plugin includes these hooks:

### 1. UserPromptSubmit Hook

**File**: `hooks/user-prompt-submit.sh`

**When it runs**: Every time you submit a prompt to Claude Code

**What it does**:
- Auto-approves safe operations
- **Blocks dangerous operations** like:
  - `rm -rf /` (file deletion)
  - `git push --force` (destructive git operations)
  - `sudo shutdown` (system modifications)
  - `DROP DATABASE` (database operations)
  - Modifications to critical system files

**Benefit**: Seamless workflow without constant approval prompts, while staying safe

### 2. PreToolUse Hooks

**Files**:
- `hooks/before_pr.sh` - Runs before creating pull requests
- `hooks/before_merge.sh` - Runs before merging code
- `hooks/before_deploy.sh` - Runs before deployments

**What they do**:
- **before_pr.sh**: Linting, type checking, tests, secret scanning
- **before_merge.sh**: E2E tests, performance checks
- **before_deploy.sh**: Environment validation, migration checks

**Benefit**: Quality gates ensure code quality before critical operations

### 3. PostToolUse Hooks

**File**: `hooks/after_deploy.sh`

**When it runs**: After deployment completes

**What it does**:
- Smoke tests
- Deployment notifications
- Health checks

**Benefit**: Immediate validation of deployments

### 4. SessionStart Hook

**File**: `hooks/before_task.sh`

**When it runs**: At the start of each Claude Code session

**What it does**:
- Environment setup validation
- Task context initialization
- Project health check

**Benefit**: Consistent starting state for each session

## How to Verify Hooks are Active

### Method 1: Check Settings

```bash
cat .claude/settings.json | jq '.hooks | keys'
```

Expected output:
```json
[
  "PostToolUse",
  "PreToolUse",
  "SessionStart",
  "UserPromptSubmit"
]
```

### Method 2: Test Auto-Approval

Try a safe operation:
```
You: "List files in the current directory"
```

If hooks are working:
- Operation executes immediately without approval prompt
- No manual confirmation needed

Try a dangerous operation (will be blocked):
```
You: "Run 'rm -rf /tmp/test' command"
```

If hooks are working:
- Operation is **automatically blocked**
- You'll see: `🛑 BLOCKED: Dangerous command detected`

### Method 3: Check Hook Execution Permissions

```bash
ls -la hooks/
```

All `.sh` files should have execute permission (`-rwxr-xr-x`).

## Customizing Hook Behavior

### Disable All Hooks

If you want to disable automation temporarily:

1. Edit `.claude/settings.json`
2. Add:
   ```json
   {
     "disableAllHooks": true
   }
   ```
3. Restart Claude Code

### Disable Only Auto-Approval

Keep quality gates but disable auto-approval:

1. Edit `.claude/settings.json`
2. Remove the `UserPromptSubmit` section
3. Restart Claude Code

### Add Custom Hook Patterns

To block additional patterns:

1. Edit `hooks/user-prompt-submit.sh`
2. Add to the `DANGEROUS_PATTERNS` array:
   ```bash
   DANGEROUS_PATTERNS=(
       # Existing patterns...
       "your-custom-pattern"
   )
   ```
3. Save and test

## Troubleshooting

### Hooks Not Running

**Symptom**: Operations require manual approval every time

**Solutions**:

1. **Check if hooks are enabled**:
   ```bash
   cat .claude/settings.json | jq '.disableAllHooks'
   ```
   Should be `false` or `null` (not present)

2. **Verify hook scripts have execute permission**:
   ```bash
   chmod +x hooks/*.sh
   ```

3. **Check for syntax errors**:
   ```bash
   bash -n hooks/user-prompt-submit.sh
   ```

4. **Restart Claude Code**:
   Settings changes require restart

### Hooks Blocking Too Much

**Symptom**: Safe operations are being blocked

**Solutions**:

1. **Check the blocked pattern**:
   Look for `🛑 BLOCKED:` message

2. **Review `DANGEROUS_PATTERNS`**:
   ```bash
   cat hooks/user-prompt-submit.sh | grep -A 20 "DANGEROUS_PATTERNS"
   ```

3. **Adjust patterns if needed**:
   Edit `hooks/user-prompt-submit.sh` to refine blocking rules

### Hook Timeouts

**Symptom**: Hook execution takes too long

**Solutions**:

1. **Increase timeout in settings**:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": "gh pr create",
         "hooks": [{
           "type": "command",
           "command": "./hooks/before_pr.sh",
           "timeout": 600  // 10 minutes
         }]
       }]
     }
   }
   ```

2. **Optimize hook scripts**:
   Remove unnecessary checks or parallelize operations

## Security Best Practices

1. **Review hooks before enabling**: Read all `.sh` files
2. **Use version control**: Track hook changes with git
3. **Test in safe environment**: Try hooks on non-production projects first
4. **Regular audits**: Review hook execution logs periodically
5. **Principle of least privilege**: Only block what's necessary

## Advanced: Hook Development

### Creating a Custom Hook

1. Create a new script in `hooks/`:
   ```bash
   touch hooks/my-custom-hook.sh
   chmod +x hooks/my-custom-hook.sh
   ```

2. Add hook logic:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   # Your hook logic here
   echo "Running custom validation..."

   # Exit 0 to approve, Exit 1 to block
   exit 0
   ```

3. Register in `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": "your-pattern",
         "hooks": [{
           "type": "command",
           "command": "./hooks/my-custom-hook.sh"
         }]
       }]
     }
   }
   ```

### Hook Environment Variables

Hooks have access to:
- `$TOOL_NAME` - Name of the tool being used
- `$TOOL_PARAMS` - JSON parameters passed to the tool
- All user environment variables

### Testing Hooks

```bash
# Set test environment
export TOOL_NAME="Bash"
export TOOL_PARAMS='{"command":"ls -la"}'

# Run hook manually
./hooks/user-prompt-submit.sh
echo "Exit code: $?"
```

## Resources

- [Claude Code Hooks Documentation](https://docs.claude.com/claude-code/hooks)
- [Security Guide](SECURITY.md)
- [GitHub Issues](https://github.com/tstomtimes/orchestra-plugin/issues)

---

**Remember**: Hooks are powerful automation tools. They work seamlessly when trusted, but always stay aware of what they're doing.
