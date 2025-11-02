# Security Guide for Orchestra Plugin

## Hook Security Overview

The Orchestra Plugin uses hooks to provide automated quality gates and workflow automation. However, **hooks execute with your full user permissions** and require careful consideration.

### Security Warning

⚠️ **CRITICAL**: Hooks can:
- Execute arbitrary shell commands
- Read, modify, or delete any files your user can access
- Make network requests
- Install packages
- Modify system configuration

### Current Hook Configuration

The plugin includes the following hooks:

1. **UserPromptSubmit** (`user-prompt-submit.sh`)
   - Auto-approves safe operations
   - Blocks dangerous commands (file deletion, system modifications, force pushes)

2. **PreToolUse** hooks:
   - `before_pr.sh` - Runs before creating pull requests
   - `before_merge.sh` - Runs before merging code
   - `before_deploy.sh` - Runs before deployments

3. **PostToolUse** hooks:
   - `after_deploy.sh` - Runs after deployments

4. **SessionStart** hook:
   - `before_task.sh` - Runs at the start of each session

## Security Best Practices

### 1. Review Hook Scripts Before Enabling

Always review the hook scripts to understand what they do:

```bash
# Review all hooks
cat hooks/user-prompt-submit.sh
cat hooks/before_pr.sh
cat hooks/before_merge.sh
cat hooks/before_deploy.sh
cat hooks/after_deploy.sh
cat hooks/before_task.sh
```

### 2. Disable Auto-Approval (Recommended for Production)

If you want maximum control, you can disable the auto-approval hook:

**Option A: Disable all hooks**

Add to `.claude/settings.json`:
```json
{
  "disableAllHooks": true
}
```

**Option B: Remove specific hooks**

Edit `.claude/settings.json` and remove the `UserPromptSubmit` section:
```json
{
  "hooks": {
    "PreToolUse": [ /* keep these */ ],
    "PostToolUse": [ /* keep these */ ],
    "SessionStart": [ /* keep these */ ]
  }
}
```

### 3. Use Project-Level Settings for Teams

For team projects:
- Keep `.claude/settings.json` in version control
- Document all hooks in your README
- Require team review before adding new hooks
- Use git hooks to prevent accidental hook modifications

### 4. Dangerous Operations Protection

The `user-prompt-submit.sh` hook blocks these dangerous patterns:
- `rm -rf /` and similar destructive deletions
- Disk operations (`dd`, `mkfs`, `fdisk`)
- System shutdowns/reboots
- Force git pushes
- Database drops
- Permission changes to 777
- Modifications to critical system files

### 5. Hook Testing

Before enabling hooks in production:

```bash
# Test hooks in a safe directory
cd /tmp/test-project
cp -r /path/to/orchestra/.claude .
# Try operations and verify hook behavior
```

## Security Levels

### Level 1: Maximum Security (For Unfamiliar Codebases)
```json
{
  "disableAllHooks": true
}
```
- Manual approval for all operations
- No automated execution
- Best for unfamiliar codebases or untrusted environments

### Level 2: Selective Automation (Conservative)
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "gh pr create", "hooks": [{"type": "command", "command": "./hooks/before_pr.sh"}] }
    ],
    "PostToolUse": [
      { "matcher": "vercel deploy", "hooks": [{"type": "command", "command": "./hooks/after_deploy.sh"}] }
    ]
  }
}
```
- Critical operations automated
- Auto-approval disabled
- Good balance of safety and convenience

### Level 3: Full Automation (Recommended for Development)
```json
{
  "hooks": {
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "./hooks/user-prompt-submit.sh"}]}],
    "PreToolUse": [ /* all hooks */ ],
    "PostToolUse": [ /* all hooks */ ],
    "SessionStart": [ /* all hooks */ ]
  }
}
```
- ✅ **All operations automated with safety guards**
- ✅ **Dangerous operations are automatically blocked**
- ✅ **Best developer experience for trusted projects**
- Use for personal projects and trusted development environments

**Why Level 3 is safe for development:**
1. The `user-prompt-submit.sh` hook blocks all dangerous operations
2. System files are protected from modification
3. Destructive git operations (force push, hard reset) are prevented
4. You maintain full control - hooks are just automation, not autonomous AI

## Incident Response

If you suspect a hook has been compromised:

1. **Immediately disable hooks**:
   ```bash
   echo '{"disableAllHooks": true}' > .claude/settings.json
   ```

2. **Review recent changes**:
   ```bash
   git log -p -- hooks/
   git diff HEAD~5 -- hooks/
   ```

3. **Check for unauthorized modifications**:
   ```bash
   # Verify hook integrity
   sha256sum hooks/*.sh
   ```

4. **Restore from known-good state**:
   ```bash
   git checkout <trusted-commit> -- hooks/
   ```

## Reporting Security Issues

If you discover a security vulnerability in the Orchestra Plugin:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [your-security-email]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Regular Security Audits

Recommended schedule:
- **Weekly**: Review hook execution logs
- **Monthly**: Audit hook scripts for unnecessary permissions
- **Quarterly**: Review and update dangerous pattern blocklist
- **After incidents**: Immediate audit and remediation

## Additional Resources

- [Claude Code Hooks Documentation](https://docs.claude.com/claude-code/hooks)
- [OWASP Command Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)

---

**Remember**: Hooks are powerful tools. Use them responsibly and always maintain security awareness.
