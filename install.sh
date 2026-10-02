#!/bin/bash
# Installs check.sh as a launchd agent (every 180s). Re-run safe.
set -euo pipefail
D="$HOME/.claude/usage-kill"; P="$HOME/Library/LaunchAgents/com.user.claude-usage-kill.plist"
mkdir -p "$D"; cp "$(dirname "$0")/check.sh" "$D/check.sh"; chmod +x "$D/check.sh"
cat > "$P" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.user.claude-usage-kill</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$D/check.sh</string></array>
  <key>StartInterval</key><integer>180</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardErrorPath</key><string>$D/err.log</string>
</dict></plist>
PLIST
launchctl bootout "gui/$(id -u)/com.user.claude-usage-kill" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$P"
echo "installed. status: cat $D/last.log   uninstall: launchctl bootout gui/$(id -u)/com.user.claude-usage-kill"
