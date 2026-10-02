#!/bin/bash
# launchd (every 180s): quit Claude app + CLI when 5h or 7d usage >= LIMIT.
LIMIT=95
d="$HOME/.claude/usage-kill"
export PATH="$HOME/.local/bin:$PATH"  # launchd has a minimal PATH; claude lives here
# refresh the token via the CLI's own login flow when it expires within 30 min (haiku, 1 turn, cheap)
exp=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.expiresAt // 0')
[ $(( exp / 1000 - $(date +%s) )) -lt 1800 ] && claude -p "ok" --model haiku --max-turns 1 </dev/null >/dev/null 2>&1
T=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
r=$(curl -sf -m 10 https://api.anthropic.com/api/oauth/usage -H "Authorization: Bearer $T" -H "anthropic-beta: oauth-2025-04-20")
if [ -z "$r" ]; then
  # fetch failed (often just a transient 429 from polling every 180s) — stay quiet
  # unless it's been failing for 10+ minutes straight, then something's actually wrong
  touch "$d/.failing_since" 2>/dev/null
  [ -f "$d/.last_ok" ] && [ -z "$(find "$d/.last_ok" -mmin -10 2>/dev/null)" ] && \
    { [ -n "$(find "$d/.warned" -mmin -60 2>/dev/null)" ] || { touch "$d/.warned"; osascript -e 'display notification "使用率を10分以上取得できません。ターミナルで claude を一度起動してください" with title "usage-kill: 監視停止中" sound name "Basso"'; }; }
  exit 0
fi
touch "$d/.last_ok"; rm -f "$d/.warned"
echo "$(date '+%F %T') $(echo "$r" | jq -c '[.five_hour.utilization, .seven_day.utilization]')" > "$d/last.log"
if [ "$(echo "$r" | jq --argjson l "$LIMIT" '[.five_hour.utilization, .seven_day.utilization] | map(. // 0) | max >= $l')" = true ]; then
  osascript -e 'display notification "使用率が上限に近いため Claude を終了しました" with title "usage-kill" sound name "Basso"'
  osascript -e 'quit app "Claude"'; pkill -x claude
  sleep 5; pkill -f /Applications/Claude.app/Contents/MacOS/Claude
fi
