# claude-usage-kill

Self-lock for Claude Code on macOS: when the 5-hour or weekly usage reaches 95%, quit the Claude desktop app and the `claude` CLI — so you never spill into paid "extra usage".

Works for the **desktop app too** (statusLine/hooks don't expose usage there), because it runs outside the app via launchd.

## How it works
- launchd runs `check.sh` every 180 s.
- It reads Claude Code's OAuth token from the macOS Keychain and queries `api.anthropic.com/api/oauth/usage`.
- `five_hour` or `seven_day` utilization ≥ `LIMIT` (default 95) → notification + quit the app and `pkill claude`. Relaunching gets killed again on the next tick.
- Token expiring within 30 min → one 1-turn `claude -p --model haiku` call so the CLI refreshes its own token (this script never touches the Keychain entry).
- Fetch failing for 10+ min → macOS notification (otherwise transient 429s are ignored).

## Install
```bash
claude /login   # once, so the Keychain entry exists
./install.sh
```
Tune `LIMIT` in `~/.claude/usage-kill/check.sh`. Status: `cat ~/.claude/usage-kill/last.log`.

## Caveats
- **Unofficial**: uses a private, undocumented endpoint; may break or be rate-limited (429) at any time. Not affiliated with Anthropic.
- Needs `jq`; macOS only; does not run while the Mac sleeps.
- Refresh-token expiry (~4 weeks) requires `claude /login` again.
- It cannot stop an in-flight request: keep a margin (95%, not 100%).
- A server-side spend limit set by your admin is the only hard guarantee; this is a seatbelt.
