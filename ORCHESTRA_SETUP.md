# Orchestra Plugin Setup Guide

This guide helps you set up the Document-Driven and Test-Driven Development workflow in your project.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Usage](#usage)

## Prerequisites

- Node.js 14+ and npm
- TypeScript support (already in Orchestra)
- Git (for hooks integration)

### Optional Tools (for full functionality)

- ESLint (for TypeScript/JavaScript linting)
- Prettier (for code formatting)
- Black (for Python formatting, if using Python)
- Pylint (for Python linting, if using Python)

## Installation

### 1. Verify `.orchestra` Directory Structure

The structure should be created automatically:

```bash
$ ls -la .orchestra/
├── config.json              # Main configuration
├── sync-state.json          # Sync metrics
├── README.md                # Documentation
├── specs/
│   ├── requirements/        # Feature requirements
│   ├── architecture/        # ADRs (Architecture Decision Records)
│   ├── data-models/         # Data schemas
│   ├── business-logic/      # Business logic docs
│   └── security/            # Security docs
├── scripts/
│   └── sync-validator.ts    # Validation script
└── reports/                 # Auto-generated reports
```

### 2. Install Required npm Packages

```bash
# Install TypeScript and ts-node
npm install --save-dev typescript ts-node @types/node

# Install linting tools
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin prettier

# Optional: Install other formatters
npm install --save-dev black isort pylint
```

### 3. Verify Configuration

Check that `.orchestra/config.json` exists and matches your team's preferences:

```bash
cat .orchestra/config.json
```

The default configuration is set to **lenient mode**, which:
- ✅ Warns about violations
- ✅ Enables auto-linting and auto-fixing
- ✅ Does NOT block commits on violations
- ✅ Validates sync state on commit (advisory)

### 4. Memory Bank Initialization

**Memory Bank** provides persistent project knowledge that survives Claude Code session restarts.

#### Automatic Initialization (Recommended)

If you ran `./setup.sh` from the Orchestra repository root, Memory Bank was **automatically initialized** in Step 4.5.

**What was created:**

```
~/memory-bank/orchestra/
├── project-overview.md    # Project overview and current state
├── tech-stack.md         # Technology stack and dependencies
├── decisions.md          # Important decisions log
├── progress.md           # Detailed progress tracking
└── next-steps.md         # Immediate action items
```

**Verify installation:**

```bash
# Check if Memory Bank directory exists
ls -la ~/memory-bank/orchestra/

# List Memory Bank files
ls -la ~/memory-bank/orchestra/*.md
```

You should see 5 Markdown files with default content and timestamps.

#### Manual Initialization

If Memory Bank was not initialized automatically (e.g., if setup.sh failed at Step 4.5), you can run the initialization script manually:

```bash
# From Orchestra repository root
bash .orchestra/scripts/init-memory-bank.sh
```

**Expected output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎼 Orchestra Plugin - Memory Bank Initialization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Creating Memory Bank directory structure...
✓ Directory created: /Users/your-username/memory-bank/orchestra
✓ Created: project-overview.md
✓ Created: tech-stack.md
✓ Created: decisions.md
✓ Created: progress.md
✓ Created: next-steps.md
✓ File permissions set (644 for documentation)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Memory Bank Initialization Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Understanding Memory Bank Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| **project-overview.md** | High-level project overview and current state | Weekly or at major milestones |
| **tech-stack.md** | Technology stack, dependencies, architecture | When dependencies change |
| **decisions.md** | Important decisions and rationale (lightweight ADR) | Per significant decision |
| **progress.md** | Detailed progress tracking and milestones | Daily or automatically |
| **next-steps.md** | Immediate action items and roadmap | Daily for high-priority items |

#### How Orchestra Agents Use Memory Bank

- **Alex (PM)**: Reads project-overview.md and next-steps.md for task planning
- **Riley (Requirements)**: Updates decisions.md with clarifications
- **Skye (Implementation)**: References tech-stack.md for architecture patterns
- **Kai (Architecture)**: Maintains decisions.md with ADRs
- **Eden (Documentation)**: Updates all files to keep documentation current

**Complete guide**: See [MEMORY_BANK_GUIDE.md](MEMORY_BANK_GUIDE.md) for detailed usage instructions, synchronization, and troubleshooting.

### 5. Update Git Hooks

Create git hook symlinks (if not already done):

```bash
# Note: This depends on how your project manages git hooks
# If using husky, add to .husky:
# npx husky add .husky/pre-commit "bash hooks/pre_commit_sync_validator.sh"
# npx husky add .husky/post-commit "bash hooks/post_code_write.sh"
```

Or configure manually in `.git/hooks/` if not using husky.

## Configuration

### Workflow Modes

**Lenient Mode (Recommended for MVP)**
```json
{
  "workflow": {
    "enabled": true,
    "mode": "lenient",
    "enforceTestFirst": false,
    "autoLint": true,
    "autoFixLint": true,
    "syncThreshold": 70,
    "validateOnCommit": true
  }
}
```

**Strict Mode (For mature projects)**
```json
{
  "workflow": {
    "enabled": true,
    "mode": "strict",
    "enforceTestFirst": true,
    "autoLint": true,
    "autoFixLint": true,
    "syncThreshold": 90,
    "validateOnCommit": true
  },
  "quality": {
    "blockCommitOnFailure": true
  }
}
```

### Customizing Configuration

Edit `.orchestra/config.json`:

```bash
# Enable test-first enforcement
jq '.workflow.enforceTestFirst = true' .orchestra/config.json > temp.json && mv temp.json .orchestra/config.json

# Increase sync threshold
jq '.workflow.syncThreshold = 80' .orchestra/config.json > temp.json && mv temp.json .orchestra/config.json
```

## Verification

### 1. Check Installation

```bash
# Verify directories exist
ls -la .orchestra/

# Verify config files
cat .orchestra/config.json
cat .orchestra/sync-state.json

# Verify Memory Bank files
ls -la ~/memory-bank/orchestra/

# Verify ESLint config
cat .eslintrc.json

# Verify Prettier config
cat .prettierrc.json
```

### 2. Run Initial Sync Validation

```bash
# Run the sync validator
npx ts-node .orchestra/scripts/sync-validator.ts

# Check output
cat .orchestra/sync-state.json
```

Expected output should show:
- No requirements yet (empty project)
- No architecture decisions yet
- Sync score should initialize to 100 or high value

### 3. Test Linting

```bash
# Check for lint issues in src/ directory
npx eslint src/ || echo "Linting check complete"

# Auto-format code
npx prettier --write src/

# Check TypeScript
npx tsc --noEmit
```

## Usage

### Create Your First Requirement

```bash
# Copy template
cp .orchestra/specs/requirements/TEMPLATE.md \
   .orchestra/specs/requirements/AUTH-001-user-login.md

# Edit with your editor
vim .orchestra/specs/requirements/AUTH-001-user-login.md
```

Fill in:
- ID: `AUTH-001`
- Title: `User Login System`
- Status: `reviewed`
- Requirements with acceptance criteria
- Test cases
- Related Files section

### Write Tests First (TDD)

```bash
# Create test file
mkdir -p tests/auth
touch tests/auth/login.test.ts

# Write failing test
cat > tests/auth/login.test.ts << 'EOF'
import { login } from '../../src/auth/login';

describe('login', () => {
  it('should authenticate valid credentials', () => {
    const result = login({ email: 'test@example.com', password: 'secret' });
    expect(result.success).toBe(true);
  });
});
EOF

# Run test (should fail - Red)
npm test tests/auth/login.test.ts
```

### Implement the Feature

```bash
# Create implementation
mkdir -p src/auth
touch src/auth/login.ts

# Implement to pass tests
cat > src/auth/login.ts << 'EOF'
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResult {
  success: boolean;
  user?: { id: string; email: string };
}

export function login(req: LoginRequest): LoginResult {
  // Implementation here
  return { success: true, user: { id: '1', email: req.email } };
}
EOF

# Run test (should pass - Green)
npm test tests/auth/login.test.ts

# Auto-format code
npm run lint:fix
```

### Update Requirement with Links

```bash
# Add to .orchestra/specs/requirements/AUTH-001-user-login.md:
# ### Related Files
# - Implementation: `src/auth/login.ts`
# - Tests: `tests/auth/login.test.ts`
# - Related Architecture: `ADR-001-authentication.md`
```

### Commit Changes

```bash
# Stage changes
git add .

# Commit (automatically validates sync)
git commit -m "feat(AUTH-001): Implement user login system"

# Expected output:
# 🔍 Running Sync Validation...
# 📊 Sync Score: 75 / 100 (Threshold: 70)
# ✅ Sync validation passed
```

### Check Sync State

```bash
# View current sync metrics
cat .orchestra/sync-state.json | jq '.'

# View latest sync report
cat .orchestra/reports/sync-report-*.md | tail -1
```

## npm Scripts

Add these to your `package.json`:

```json
{
  "scripts": {
    "lint": "eslint src tests",
    "lint:fix": "eslint --fix src tests && prettier --write src tests",
    "format": "prettier --write src tests",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "sync-validate": "ts-node .orchestra/scripts/sync-validator.ts",
    "sync-report": "cat .orchestra/reports/sync-report-*.md | tail -1"
  }
}
```

Then use:
```bash
npm run lint
npm run lint:fix
npm run sync-validate
npm run sync-report
```

## Workflow Integration with Agent Roles

When creating requirements, you can tag agents for specific tasks:

```markdown
# AUTH-001: User Login

## Requirements

- **REQ-1:** System must authenticate users
  <!-- @Riley: Can you clarify the MFA requirement? -->

## Architecture

<!-- @Kai: Should we use JWT or session-based auth? -->

## Testing

<!-- @Finn: What's the coverage target for auth tests? -->

## Implementation Notes

<!-- @Skye: Ready for implementation when tests are written -->
```

These comments help coordinate with Orchestra's specialist agents when using agent-routing features.

## Troubleshooting

### Issue: Sync Validator Not Found

```bash
# Make sure TypeScript and ts-node are installed
npm install --save-dev typescript ts-node
```

### Issue: ESLint Errors

```bash
# Fix automatically
npm run lint:fix

# Or check specific file
npx eslint src/file.ts --fix
```

### Issue: Git Hooks Not Running

If hooks aren't executing:

1. Verify hook files are executable:
   ```bash
   chmod +x hooks/*.sh
   ```

2. Check git hooks directory:
   ```bash
   ls -la .git/hooks/
   ```

3. For husky integration:
   ```bash
   npx husky install
   ```

---

### Issue: Memory Bank Not Initialized

**Symptoms:**
- `~/memory-bank/orchestra/` directory doesn't exist
- Template files are missing

**Solutions:**

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

**See also**: [MEMORY_BANK_GUIDE.md](MEMORY_BANK_GUIDE.md#troubleshooting) for comprehensive Memory Bank troubleshooting

### Issue: Low Sync Score

Run validation to see detailed issues:
```bash
npm run sync-validate

# Check report
cat .orchestra/reports/sync-report-*.md
```

Common causes:
- Missing test files for implemented features
- Incomplete requirement documentation
- Unlinked implementation files

## Next Steps

1. **Customize configuration** in `.orchestra/config.json` for your team
2. **Create first requirement** in `.orchestra/specs/requirements/`
3. **Write tests first** following TDD principles
4. **Integrate with CI/CD** to enforce quality gates
5. **Monitor sync scores** to maintain documentation-code synchronization

## Support & Learning

- Read `.orchestra/README.md` for detailed workflow documentation
- Check `.orchestra/specs/*/TEMPLATE.md` for documentation examples
- Review `.orchestra/config.json` for all available options
- Inspect `.orchestra/sync-state.json` for current metrics

## Additional Resources

### Orchestra Documentation

- [MEMORY_BANK_GUIDE.md](MEMORY_BANK_GUIDE.md) - Complete Memory Bank usage guide
- [README.md](README.md) - Orchestra Plugin overview
- [.orchestra/README.md](.orchestra/README.md) - Document-Driven Development guide

### External Resources

- [Test-Driven Development (TDD)](https://en.wikipedia.org/wiki/Test-driven_development)
- [Architecture Decision Records](https://adr.github.io/)
- [Documentation as Code](https://www.writethedocs.org/)
- [ESLint Documentation](https://eslint.org/)
- [Prettier Documentation](https://prettier.io/)
