# Hermes Safe Backup

## What is backed up:
- `config.yaml` - Hermes configuration (no secrets)
- `MEMORY.md` - Persistent memory notes
- `USER.md` - User profile
- `SOUL.md` - Personality file
- `skills/` - All installed skills
- `memories/` - Memory directory

## What is NOT backed up (sensitive):
- `.env` - API keys and tokens
- `auth.json` - Authentication tokens
- `gateway_state.json` - Gateway credentials
- `auth.lock` - Auth lock file
- `state.db*` - Runtime state databases
- `sessions/` - Session transcripts

## To restore:
1. Copy files back to `~/.hermes/`
2. Re-add your `.env` API keys manually
