# Agent Voice Notifications with ElevenLabs

Orchestra Plugin supports voice notifications for agent task completions using ElevenLabs Text-to-Speech API. Each agent has their own unique voice and personality, making the development experience more immersive and human-like.

## Quick Start

### 1. Enable Voice Notifications

Edit your `.env` file:

```bash
# Enable voice
VOICE_ENABLED=true

# Add your ElevenLabs API key
ELEVENLABS_API_KEY=your_api_key_here
```

Get your API key from: https://elevenlabs.io/

### 2. Test Voice Notification

```bash
echo '{"command":"announce_task_complete","params":{"agent_name":"alex","task_description":"code review"}}' | python3 orchestra/mcp-servers/elevenlabs-server.py
```

## Agent Voices & Personalities

Each agent has a distinct personality and voice:

| Agent | Voice | Personality | Short Phrases |
|-------|-------|-------------|---------------|
| **Alex** | Rachel (Calm, measured) | Strategic PM who ensures clarity | "Task complete.", "All set.", "Scoped and ready." |
| **Eden** | Bella (Precise, methodical) | Meticulous QA specialist | "Tests pass.", "QA complete.", "All checks good." |
| **Iris** | Adam (Serious, authoritative) | Security-focused guardian | "Security checked.", "No vulnerabilities.", "Safe to proceed." |
| **Mina** | Dorothy (Enthusiastic, creative) | Design-focused frontend specialist | "UI ready.", "Design complete.", "Looks great." |
| **Theo** | Sam (Calm, reliable) | Operations specialist | "Deployment successful.", "System stable.", "All metrics green." |

## Token-Optimized Design

To minimize ElevenLabs token usage, voice messages are intentionally short (2-6 words). The system uses two types of messages:

- **Voice Message**: Short phrase spoken by the agent (e.g., "Task complete.")
- **Text Message**: Detailed message displayed in the console (e.g., "✅ Alex: Code review complete.")

This approach provides rich context in text while keeping voice costs low.

## Voice Configuration

Agent voices and settings are configured in [`agents/voice-config.json`](../agents/voice-config.json):

```json
{
  "agents": {
    "alex": {
      "voice_id": "21m00Tcm4TlvDq8ikWAM",
      "voice_name": "Rachel",
      "voice_settings": {
        "stability": 0.75,
        "similarity_boost": 0.75,
        "style": 0.5
      },
      "speaking_style": {
        "tone": "Calm, measured, and thoughtful",
        "pace": "Moderate"
      }
    }
  },
  "short_phrases": {
    "alex": [
      "Task complete.",
      "All set.",
      "Ready to proceed."
    ]
  }
}
```

## Available Commands

### 1. Announce Task Completion

```bash
echo '{
  "command": "announce_task_complete",
  "params": {
    "agent_name": "alex",
    "task_description": "code review"
  }
}' | python3 elevenlabs-server.py
```

**Response:**
```json
{
  "success": true,
  "data": {
    "agent": "alex",
    "voice_name": "Rachel",
    "voice_message": "Task complete.",
    "text_message": "✅ Alex: code review complete.",
    "audio_base64": "..."
  }
}
```

### 2. Announce Task Handoff

```bash
echo '{
  "command": "announce_handoff",
  "params": {
    "from_agent": "alex",
    "to_agent": "mina",
    "task_description": "UI implementation"
  }
}' | python3 elevenlabs-server.py
```

### 3. Get Agent Personality

```bash
echo '{
  "command": "get_agent_personality",
  "params": {
    "agent_name": "eden"
  }
}' | python3 elevenlabs-server.py
```

**Response:**
```json
{
  "success": true,
  "data": {
    "name": "Eden",
    "personality": "Meticulous QA specialist with an eye for detail and edge cases",
    "voice_name": "Bella",
    "speaking_style": {
      "tone": "Precise, methodical, slightly perfectionist",
      "pace": "Steady and deliberate"
    },
    "voice_enabled": true
  }
}
```

### 4. Custom Text-to-Speech

```bash
echo '{
  "command": "speak_as_agent",
  "params": {
    "agent_name": "iris",
    "message": "Security check passed."
  }
}' | python3 elevenlabs-server.py
```

## Cost Optimization Tips

1. **Keep Messages Short**: Default phrases are 2-6 words (saves ~80% tokens vs full sentences)

2. **Disable When Not Needed**: Set `VOICE_ENABLED=false` in `.env` when focusing on development

3. **Use Text Notifications**: The system always displays text messages, even when voice is disabled

4. **Monitor Usage**: Check your ElevenLabs dashboard for usage stats

## Customizing Voices

### Change Agent Voice

Edit `agents/voice-config.json`:

```json
{
  "agents": {
    "alex": {
      "voice_id": "your_preferred_voice_id",
      "voice_name": "Custom Voice Name"
    }
  }
}
```

### Get Available Voices

```bash
echo '{"command":"get_voices","params":{}}' | python3 elevenlabs-server.py
```

### Add Custom Short Phrases

Edit `short_phrases` in `voice-config.json`:

```json
{
  "short_phrases": {
    "alex": [
      "Done.",
      "Complete.",
      "Finished.",
      "All good."
    ]
  }
}
```

## Integration with Hooks

Voice notifications can be integrated into hooks for automated feedback:

```bash
# In after_deploy.sh
if [ "$VOICE_ENABLED" = "true" ]; then
  echo '{"command":"announce_task_complete","params":{"agent_name":"theo","task_description":"deployment"}}' | \
    python3 orchestra/mcp-servers/elevenlabs-server.py
fi
```

## Troubleshooting

### "Voice is disabled" Error

**Solution**: Set `VOICE_ENABLED=true` in your `.env` file

### "ELEVENLABS_API_KEY not configured" Error

**Solution**: Add your API key to `.env`:
```bash
ELEVENLABS_API_KEY=your_key_here
```

### Audio Not Playing

The server returns base64-encoded audio. To play it:

1. Save the audio to a file:
```bash
# Response contains audio_base64
echo "BASE64_STRING" | base64 --decode > output.mp3
afplay output.mp3  # macOS
# or
mpg123 output.mp3  # Linux
```

2. Or use the `save_to_file` parameter:
```bash
echo '{
  "command": "speak_as_agent",
  "params": {
    "agent_name": "alex",
    "message": "Hello",
    "save_to_file": "/tmp/alex-hello.mp3"
  }
}' | python3 elevenlabs-server.py
```

### Rate Limits

ElevenLabs has usage limits based on your plan. If you hit limits:
- Reduce notification frequency
- Use shorter messages
- Upgrade your ElevenLabs plan

## Best Practices

1. **Test with Voice Disabled First**: Develop with `VOICE_ENABLED=false`, enable only when demoing or for important milestones

2. **Use for Key Events**: Enable voice for:
   - Deployment completions
   - Critical test failures
   - Security alerts
   - Major milestones

3. **Respect Your Budget**: Monitor ElevenLabs usage and adjust notification frequency accordingly

4. **Customize for Your Team**: Adjust agent personalities and phrases to match your team's culture

## Example Workflow

```bash
# 1. Enable voice for important deployment
export VOICE_ENABLED=true

# 2. Run deployment
./hooks/before_deploy.sh

# 3. On success, Theo announces:
# Voice: "Deployment successful."
# Text: "✅ Theo: Production deployment complete."

# 4. Disable voice for routine work
export VOICE_ENABLED=false
```

## License & Credits

- Orchestra Plugin: MIT License
- ElevenLabs: Commercial TTS service (separate license and pricing)
- Voice actors: Provided by ElevenLabs

---

For issues or questions about voice notifications, see the main [README](../../README.md) or [MCP Servers documentation](README.md).
