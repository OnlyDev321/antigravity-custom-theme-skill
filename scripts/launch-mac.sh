#!/usr/bin/env bash
set -euo pipefail

# Choose the active Antigravity app name (defaults to Antigravity IDE if present)
APP_NAME="${1:-}"
if [ -z "$APP_NAME" ]; then
    if [ -d "/Applications/Antigravity IDE.app" ]; then
        APP_NAME="Antigravity IDE"
    else
        APP_NAME="Antigravity"
    fi
fi

echo "[launch-mac] Checking running instances of $APP_NAME..."

# If already running with remote-debugging-port, simply activate it
if pgrep -f "$APP_NAME.*--remote-debugging-port" >/dev/null 2>&1; then
    echo "[launch-mac] $APP_NAME is already running with remote debugging port enabled."
    open -a "$APP_NAME"
    exit 0
fi

# If running without debug port, quit cleanly first
if pgrep -x "$APP_NAME" >/dev/null 2>&1 || pgrep -f "/Applications/$APP_NAME.app" >/dev/null 2>&1; then
    echo "[launch-mac] Closing existing $APP_NAME instances without debug port..."
    osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
    for _ in {1..15}; do
        if ! pgrep -x "$APP_NAME" >/dev/null 2>&1 && ! pgrep -f "/Applications/$APP_NAME.app" >/dev/null 2>&1; then
            break
        fi
        sleep 0.2
    done
    killall "$APP_NAME" 2>/dev/null || true
    sleep 0.5
fi

# Clean stale port files
rm -f "$HOME/Library/Application Support/Antigravity/DevToolsActivePort" 2>/dev/null || true
rm -f "$HOME/Library/Application Support/Antigravity IDE/DevToolsActivePort" 2>/dev/null || true

echo "[launch-mac] Launching $APP_NAME with --remote-debugging-port=0..."
open -a "$APP_NAME" --args --remote-debugging-port=0

echo "[launch-mac] Done! Waiting for theme daemon to attach..."
