# Token Efficiency Skill

**Purpose**: Minimize unnecessary token usage while maintaining code quality and thoroughness.

## Core Principles

### 1. Targeted Search, Not Exploration

**Always prefer specific over general:**
- ✅ `Glob("**/auth/login.ts")` - Exact file
- ✅ `Grep("function handleAuth", type="ts")` - Specific pattern with file type
- ❌ `Glob("**/*.ts")` - Too broad
- ❌ Reading entire directories without filtering

### 2. Read Only What You Need

**Before reading a file, ask:**
- Do I need the entire file, or just specific sections?
- Can I use grep to find the relevant parts first?
- Has this file already been read in the conversation?

**Use Read with limits:**
```
Read(file_path, offset=100, limit=50)  # Only read 50 lines starting at line 100
```

### 3. Search Hierarchy (Most to Least Efficient)

1. **Known location**: Direct file read if path is known
2. **Pattern matching**: Glob with specific patterns
3. **Keyword search**: Grep for specific terms
4. **Contextual search**: Grep with -A/-B flags for context
5. **Agent search**: Task tool with Explore agent (last resort)

### 4. Incremental Discovery

**Don't gather everything upfront:**
```
Bad approach:
1. Read all files in src/
2. Read all test files
3. Read all config files
4. Then start implementation

Good approach:
1. Read the specific file to modify
2. Implement the change
3. Only read related files if needed during implementation
4. Read tests only when writing test updates
```

### 5. Scope Boundaries

**Set clear limits:**
- Maximum files to examine: 5-10 for most tasks
- Maximum file size to read fully: ~500 lines
- Large files: Use offset/limit or grep first
- Stop once you have sufficient information

### 6. Efficient Grep Usage

**Use appropriate output modes:**
- `files_with_matches`: Just need to know if pattern exists
- `count`: Just need to know how many matches
- `content`: Need to see actual matches (use head_limit)

**Add context only when needed:**
```
Grep("error handler", output_mode="content", -C=3, head_limit=10)
# Only 10 results with 3 lines of context each
```

### 7. Avoid Redundant Operations

**Check conversation history first:**
- Don't re-read files already examined
- Reference previous findings instead of re-searching
- Build on existing knowledge

### 8. Model Selection for Task Tool

**Choose the right model for the job:**
```
# Simple, well-defined task
Task(description="...", model="haiku", prompt="...")

# Default for most tasks (good balance)
Task(description="...", model="sonnet", prompt="...")

# Complex reasoning required (use sparingly)
Task(description="...", model="opus", prompt="...")
```

## Practical Examples

### Example 1: Adding a New Function

**Inefficient approach:**
```
1. Read entire src/ directory
2. Read all related files
3. Search for all similar patterns
4. Then implement
```

**Efficient approach:**
```
1. Grep for similar function names (files_with_matches)
2. Read ONE example file
3. Implement based on that pattern
4. Only read more if the first example is unclear
```

### Example 2: Bug Investigation

**Inefficient approach:**
```
1. Read all files that might be related
2. Search entire codebase for error messages
3. Check all test files
```

**Efficient approach:**
```
1. Grep for the specific error message
2. Read only the files containing that error
3. Check git blame if needed to understand context
4. Read tests only for files being modified
```

### Example 3: Code Review

**Inefficient approach:**
```
1. Read all files in the PR
2. Read all related test files
3. Read all documentation
4. Then provide feedback
```

**Efficient approach:**
```
1. Use git diff to see only changed lines
2. Read changed files with offset/limit to focus on modifications
3. Grep for test coverage of changed functions
4. Request summaries instead of reading full docs
```

## Token Budget Estimates

**Quick reference for delegation:**

| Task Type | Estimated Tokens | Recommended Model |
|-----------|------------------|-------------------|
| Simple bug fix | 2-5K | haiku |
| New feature (small) | 5-10K | haiku |
| New feature (medium) | 10-20K | sonnet |
| Architecture design | 20-30K | sonnet |
| Complex refactoring | 30-50K | sonnet |
| Full system review | Split into chunks | sonnet |

## Red Flags (Stop and Optimize)

**If you find yourself:**
- Reading more than 10 files for a single task
- Using Glob with `**/*` without file type filtering
- Reading entire large files (>1000 lines) without specific need
- Re-reading files already examined in the conversation
- Exploring code "just to understand better" without clear need

**Then:** Stop and refine your approach. Ask yourself:
1. What specific information do I need?
2. What's the minimum search required to get it?
3. Can I infer this from what I already know?

## Integration with Other Skills

This skill should be applied in conjunction with:
- **code-quality.md**: Maintain quality while being efficient
- **testing.md**: Test only what's necessary, focus on critical paths
- **security.md**: Targeted security checks, not exhaustive scans
- **documentation.md**: Document changes, not entire codebase

## Success Metrics

**You're doing it right when:**
- Tasks complete in <20K tokens for most features
- You find what you need in 1-3 search operations
- You reference previous reads instead of re-reading
- You can justify every file you read
- Subagents return focused, relevant results

**Review and improve** if token usage is consistently high without proportional complexity in the task.
