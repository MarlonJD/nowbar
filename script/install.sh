#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Nowbar"
BUNDLE_ID="com.marlonjd.Nowbar"
LEGACY_APP_NAME="ListeningNowStatusBar"
LEGACY_BUNDLE_ID="com.marlonjd.ListeningNowStatusBar"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
DEST_APP="/Applications/$APP_NAME.app"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$BUNDLE_ID.plist"
LEGACY_PLIST_PATH="$LAUNCH_AGENTS_DIR/$LEGACY_BUNDLE_ID.plist"
GUI_DOMAIN="gui/$(id -u)"

"$ROOT_DIR/script/build_and_run.sh" --build-only >/dev/null

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -x "$LEGACY_APP_NAME" >/dev/null 2>&1 || true
launchctl bootout "$GUI_DOMAIN" "$LEGACY_PLIST_PATH" >/dev/null 2>&1 || true
rm -f "$LEGACY_PLIST_PATH"
rm -rf "/Applications/$LEGACY_APP_NAME.app"
rm -rf "$DEST_APP"
ditto "$SOURCE_APP" "$DEST_APP"

mkdir -p "$LAUNCH_AGENTS_DIR"
cat >"$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$BUNDLE_ID</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-n</string>
    <string>$DEST_APP</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

launchctl bootout "$GUI_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "$GUI_DOMAIN" "$PLIST_PATH"
launchctl kickstart -k "$GUI_DOMAIN/$BUNDLE_ID"

echo "Installed $DEST_APP"
echo "Enabled login launch agent $PLIST_PATH"
