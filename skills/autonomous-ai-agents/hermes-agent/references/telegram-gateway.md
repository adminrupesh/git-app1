# Telegram Gateway Configuration

Quick reference for Hermes Telegram gateway auth and connectivity issues.

## Authorization behavior

- `TELEGRAM_ALLOWED_USERS=`: blank = deny everyone. This is NOT open access.
- `GATEWAY_ALLOW_ALL_USERS=true`: required for open access across all platforms.
- `TELEGRAM_ALLOWED_USERS` accepts comma-separated **numeric user IDs** or **@usernames**.

## Diagnosing "Unauthorized user"

Check gateway logs for the real numeric ID:

```bash
tail -f ~/.hermes/logs/gateway.log | grep -i "unauthorized\|telegram"
```

Example log line:
```
WARNING gateway.run: Unauthorized user: 8612231951 (rupesh) on telegram
```

Add that ID to `.env`:
```bash
TELEGRAM_ALLOWED_USERS=8612231951,@tantrasys
```

Then restart:
```bash
hermes gateway restart
```

## Common pitfalls

1. **Username mismatch** — setting `TELEGRAM_ALLOWED_USERS=@someuser` without the numeric ID may still block if Telegram's user lookup doesn't resolve the handle. Always add the numeric ID from the log.
2. **Restart required** — `.env` changes do NOT take effect until gateway restart.
3. **Secret redaction** — if `security.redact_secrets` is enabled, tool outputs are scrubbed. Disable with `hermes config set security.redact_secrets false` if you need raw output.

## Verification

After restart, confirm in logs:
```
✓ telegram connected
```

And no new "Unauthorized user" lines when messaging the bot.
