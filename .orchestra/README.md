# Orchestra Plugin - Document-Driven & Test-Driven Development

Welcome to the Orchestra Plugin Documentation-Driven and Test-Driven Development system!

## Overview

This system helps teams maintain high-quality software by enforcing:

1. **Documentation-Driven Development** - Requirements, architecture, and design must be documented before implementation
2. **Test-Driven Development** - Tests must be written before code
3. **Automated Quality Gates** - Linting, formatting, and sync validation are automatic
4. **Continuous Synchronization** - Documentation, tests, and code are kept in sync

## Directory Structure

```
.orchestra/
├── config.json                          # Workflow configuration
├── sync-state.json                      # Current sync state and metrics
├── specs/
│   ├── requirements/                    # Feature requirements and stories
│   │   ├── TEMPLATE.md
│   │   └── [SYSTEM-001-feature.md]
│   ├── architecture/                    # Architecture Decision Records
│   │   ├── TEMPLATE-ADR.md
│   │   └── [ADR-001-design.md]
│   ├── data-models/                     # Data model and schema docs
│   │   ├── TEMPLATE.md
│   │   └── [entity-schema.md]
│   ├── business-logic/                  # Business logic documentation
│   │   ├── TEMPLATE.md
│   │   └── [feature-logic.md]
│   └── security/                        # Security documentation
│       └── [threat-model.md]
├── scripts/
│   ├── sync-validator.ts                # Synchronization validator
│   ├── init-memory-bank.sh              # Memory Bank initialization
│   ├── sync-to-memory-bank.sh           # Document synchronization
│   ├── record-milestone.sh              # Milestone recording
│   ├── test-memory-bank-init.sh         # Init tests
│   ├── test-sync-to-memory-bank.sh      # Sync tests
│   └── test-milestone-recording.sh      # Milestone tests
├── cache/
│   └── sync-history.json                # Document sync history
├── logs/
│   └── milestone-recording.log          # Milestone recording logs
└── reports/
    ├── sync-report-YYYY-MM-DD.md        # Auto-generated sync reports
    └── quality-metrics.json             # Quality metrics

```

## Quick Start

### 1. Create a New Requirement

Create a new requirement document in `.orchestra/specs/requirements/`:

```bash
cp .orchestra/specs/requirements/TEMPLATE.md .orchestra/specs/requirements/AUTH-001-user-login.md
```

Edit the file with:
- Unique ID (e.g., `AUTH-001`)
- Feature title
- Requirements and acceptance criteria
- Related implementation files

### 2. Create an Architecture Decision

Create a new ADR in `.orchestra/specs/architecture/`:

```bash
cp .orchestra/specs/architecture/TEMPLATE-ADR.md .orchestra/specs/architecture/ADR-001-design-decision.md
```

### 3. Write Tests First (TDD)

```bash
# Create test file following TDD principles
# tests/auth/login.test.ts
```

Example test file:
```typescript
describe('User Login', () => {
  it('should authenticate user with valid credentials', () => {
    // Given
    const credentials = { email: 'user@example.com', password: 'secret' };

    // When
    const result = login(credentials);

    // Then
    expect(result.success).toBe(true);
    expect(result.user).toBeDefined();
  });
});
```

### 4. Implement the Feature

Create implementation file corresponding to the test:
```bash
# src/auth/login.ts
```

### 5. Link Documentation to Code

Update the requirement document with implementation file references:
```markdown
### Related Files
- Implementation: `src/auth/login.ts`
- Tests: `tests/auth/login.test.ts`
- Related Architecture: `ADR-001-design-decision.md`
```

### 6. Verify Sync State

Run the sync validator to check synchronization:
```bash
# Automatically runs on commit (if enabled)
# Or manually:
npx ts-node .orchestra/scripts/sync-validator.ts
```

## Configuration

### config.json Options

**Workflow Mode:**
- `"mode": "strict"` - Enforces all rules, blocks non-compliant commits
- `"mode": "lenient"` - Warns about violations but allows commits (recommended for MVP)

**Features:**
- `enforceTestFirst` - Require tests before code changes
- `autoLint` - Run linting checks automatically
- `autoFixLint` - Automatically fix lint issues
- `syncThreshold` - Minimum sync score (0-100)
- `validateOnCommit` - Run sync validation before commits

Example lenient configuration:
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

## Workflows

### Documentation → Code Flow

```
1. Create Requirement Document
   ↓
2. Create Architecture Decision (if needed)
   ↓
3. Create Data Model (if needed)
   ↓
4. Write Tests
   ↓
5. Implement Code
   ↓
6. Run Linting & Formatting
   ↓
7. Commit (with automatic validation)
```

### Sync Validation

The system automatically validates:

- **Documentation Completeness** - All implemented features have corresponding documentation
- **Test Coverage** - Features have associated tests
- **Code-Test-Doc Synchronization** - These three elements reference each other
- **Architecture Adherence** - Code follows documented architecture decisions
- **Data Model Consistency** - Database schemas match documented models

## Git Hooks Integration

The following hooks are automatically run:

### Before Code Write
- Checks if test file exists for feature (advisory only in lenient mode)

### After Code Write
- Runs ESLint and Prettier automatically
- Fixes formatting issues

### Before Commit
- Validates sync score against configured threshold
- Generates sync report if issues detected

## Quality Metrics

The `sync-state.json` file tracks:

```json
{
  "syncScore": 85,
  "status": "valid",
  "requirements": [
    {
      "id": "AUTH-001",
      "status": "implemented",
      "linkedTests": ["tests/auth/login.test.ts"],
      "linkedCode": ["src/auth/login.ts"],
      "coverage": 92
    }
  ],
  "tests": {
    "total": 156,
    "passing": 156,
    "failing": 0,
    "coverage": 87
  },
  "lint": {
    "errors": 0,
    "warnings": 2
  }
}
```

### Sync Score Calculation

- 40% - Requirements with corresponding tests
- 30% - Implemented requirements with corresponding code
- 20% - Test pass rate
- 10% - Architecture-code alignment

**Score Interpretation:**
- 90-100: Excellent synchronization
- 70-89: Good synchronization with minor issues
- 50-69: Moderate sync issues, recommend review
- 0-49: Major sync issues, review required

## Common Workflows

### Adding a New Feature

```bash
# 1. Create requirement
cp .orchestra/specs/requirements/TEMPLATE.md \
   .orchestra/specs/requirements/FEATURE-001-new-feature.md

# 2. Edit requirement (add title, criteria, etc.)
vim .orchestra/specs/requirements/FEATURE-001-new-feature.md

# 3. Create test file
mkdir -p tests/features
touch tests/features/new-feature.test.ts

# 4. Write failing tests (Red)
# ... implement test code ...

# 5. Run tests (should fail)
npm test tests/features/new-feature.test.ts

# 6. Implement code (Green)
mkdir -p src/features
touch src/features/new-feature.ts
# ... implement code ...

# 7. Run tests (should pass)
npm test tests/features/new-feature.test.ts

# 8. Refactor if needed
# ... improve code quality ...

# 9. Link documentation
# Edit requirement file to add Related Files section

# 10. Commit
git add .
git commit -m "feat: Add FEATURE-001-new-feature"
```

## Troubleshooting

### Sync Score is Low

Check `.orchestra/reports/sync-report-YYYY-MM-DD.md` for details about what's missing:

```bash
# View latest report
cat .orchestra/reports/sync-report-*.md | tail -1
```

### Tests Not Found

Make sure test files follow the naming convention:
- Implementation: `src/module/feature.ts`
- Tests: `tests/module/feature.test.ts`

### Linting Issues

Auto-fix enabled lint issues:
```bash
npm run lint:fix
```

## Agent Roles

The Orchestra Plugin coordinates these specialist agents:

- **Riley** - Requirements clarification
- **Kai** - Architecture decisions
- **Finn** - Test strategy and coverage
- **Skye** - Code implementation
- **Iris** - Security review
- **Nova** - UI/UX validation
- **Eden** - Documentation

Reference agents in requirement comments:
```markdown
<!-- @Riley: Please clarify acceptance criteria -->
<!-- @Kai: Architecture review needed -->
<!-- @Finn: Test coverage strategy -->
```

## Next Steps

1. **Copy this document** to your project's main documentation
2. **Configure workflows** in `config.json` based on your team's needs
3. **Create your first requirement** using the template
4. **Write tests first** following the TDD cycle
5. **Run sync validation** to track progress

## Memory Bank Integration

Orchestra Plugin integrates with **Memory Bank** for persistent project knowledge across Claude Code sessions.

### Memory Bank Scripts

The `.orchestra/scripts/` directory contains automation scripts for Memory Bank:

#### 1. init-memory-bank.sh

**Purpose**: Initialize Memory Bank directory structure and template files

**Usage**:
```bash
bash .orchestra/scripts/init-memory-bank.sh
```

**What it does**:
- Creates `~/memory-bank/orchestra/` directory
- Generates 5 template files (project-overview, tech-stack, decisions, progress, next-steps)
- Protects existing projects from overwrite
- Sets file permissions (644)

**Safety features**:
- Checks for existing files before overwriting
- Non-destructive operation
- Graceful error handling

**Automatic execution**: Called by setup.sh (Step 4.5)

---

#### 2. sync-to-memory-bank.sh

**Purpose**: Sync `.orchestra/specs/` documents to Memory Bank

**Usage**:
```bash
# Normal sync (only changed files)
bash .orchestra/scripts/sync-to-memory-bank.sh

# Preview without making changes
bash .orchestra/scripts/sync-to-memory-bank.sh --dry-run

# Force overwrite all files
bash .orchestra/scripts/sync-to-memory-bank.sh --force

# Verbose output
bash .orchestra/scripts/sync-to-memory-bank.sh --verbose
```

**What it does**:
- Discovers files matching sync patterns in config.json
- Checks file checksums to detect changes
- Syncs only changed files (incremental sync)
- Excludes template files and large files (>1MB)
- Records sync history in `.orchestra/cache/sync-history.json`

**Configuration**: Via `.orchestra/config.json`:
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
        "**/*TEMPLATE*.md"
      ]
    }
  }
}
```

**Automatic execution**: Triggered by `hooks/after_deploy.sh`

---

#### 3. record-milestone.sh

**Purpose**: Record project milestones in Memory Bank progress.md

**Usage**:
```bash
bash .orchestra/scripts/record-milestone.sh \
  "Milestone Name" \
  "Description" \
  "tag" \
  "Contributor (optional)"
```

**Example**:
```bash
bash .orchestra/scripts/record-milestone.sh \
  "Memory Bank Integration" \
  "Completed initialization and sync scripts" \
  "feature" \
  "Skye"
```

**Tags**: feature, bugfix, refactor, docs, test, perf, chore

**What it does**:
- Reads current progress.md from Memory Bank
- Adds new milestone entry to table
- Updates milestone count
- Sets UTC timestamp
- Prevents duplicate entries
- Logs to `.orchestra/logs/milestone-recording.log`

**Output format** (in progress.md):
```markdown
| Date | Milestone | Description | Tag | Contributor |
|------|-----------|-------------|-----|-------------|
| 2025-11-03 15:30:00 UTC | Memory Bank Integration | Completed scripts | `feature` | Skye |
```

---

### Memory Bank Cache and Logs

#### .orchestra/cache/sync-history.json

**Purpose**: Track document synchronization history

**Structure**:
```json
{
  "syncs": [
    {
      "file": "requirements/REQ-001.md",
      "checksum": "a1b2c3d4e5f6",
      "timestamp": "2025-11-03T10:30:00Z",
      "action": "sync"
    }
  ]
}
```

**Used by**: `sync-to-memory-bank.sh` for incremental sync

---

#### .orchestra/logs/milestone-recording.log

**Purpose**: Log all milestone recording operations

**Format**:
```
[2025-11-03 10:30:00 UTC] Recording milestone: Memory Bank Integration
[2025-11-03 10:30:00 UTC] Description: Completed initialization and sync scripts
[2025-11-03 10:30:00 UTC] Tag: feature
[2025-11-03 10:30:00 UTC] Contributor: Skye
[2025-11-03 10:30:00 UTC] ✅ Milestone recorded successfully
```

**Used for**: Debugging and audit trail

---

### Memory Bank Test Scripts

The `.orchestra/scripts/` directory includes comprehensive test suites:

1. **test-memory-bank-init.sh** (296 lines)
   - Tests initialization script functionality
   - Validates directory structure, template files, permissions
   - Tests existing project protection
   - 8 test cases, 100% pass rate

2. **test-sync-to-memory-bank.sh** (390 lines)
   - Tests document synchronization
   - Validates incremental sync, dry-run, force modes
   - Tests exclude patterns and large file filtering
   - 7 test cases, 100% pass rate

3. **test-milestone-recording.sh** (393 lines)
   - Tests milestone recording
   - Validates tag validation, duplicate prevention
   - Tests timestamp and contributor tracking
   - 6 test cases, 100% pass rate

**Run tests**:
```bash
# Test initialization
bash .orchestra/scripts/test-memory-bank-init.sh

# Test synchronization
bash .orchestra/scripts/test-sync-to-memory-bank.sh

# Test milestone recording
bash .orchestra/scripts/test-milestone-recording.sh
```

---

### Learn More

For complete Memory Bank documentation, see:
- [MEMORY_BANK_GUIDE.md](../MEMORY_BANK_GUIDE.md) - Comprehensive usage guide
- [MEMORY-BANK-IMPLEMENTATION-COMPLETE.md](../MEMORY-BANK-IMPLEMENTATION-COMPLETE.md) - Implementation details

---

## Support

For issues or questions about the Orchestra Plugin, check:
- `.orchestra/README.md` (this file)
- `.orchestra/specs/` (examples and templates)
- `config.json` (configuration options)
- [MEMORY_BANK_GUIDE.md](../MEMORY_BANK_GUIDE.md) (Memory Bank documentation)
