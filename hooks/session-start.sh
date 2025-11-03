#!/usr/bin/env bash
# Session Start Hook
# Provides context about Orchestra Plugin to Claude

set -euo pipefail

# Create welcome message as context for Claude
CONTEXT=$(cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎭 ORCHESTRA PLUGIN LOADED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ Specialized agents are ready for coordination:

   🙂 Alex    - Project Conductor (ambiguous requests, scope definition)
   😎 Blake   - Release Manager (deployments, releases)
   🤓 Eden    - Documentation Lead (technical writing)
   😤 Finn    - QA & Testing (test coverage, validation)
   🤨 Iris    - Security Auditor (auth, secrets, vulnerabilities)
   🤔 Kai     - System Architect (design decisions, ADRs)
   😌 Leo     - Database Architect (schema, migrations)
   😊 Mina    - Integration Specialist (external APIs)
   😄 Nova    - UI/UX Specialist (interfaces, accessibility)
   🧐 Riley   - Requirements Clarifier (vague requests)
   😐 Skye    - Code Implementer (well-defined specs)
   😬 Theo    - Ops & Monitoring (reliability, incidents)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPORTANT: You should greet the user and inform them that Orchestra Plugin has been loaded.
List the available specialist agents and encourage them to ask for help with their tasks.

EOF
)

# Output JSON format for Claude's context
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(echo "$CONTEXT" | jq -Rs .)
  }
}
EOF

exit 0
