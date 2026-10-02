#!/bin/sh
# Desktop notifications for Claude Code, delivered by Ghostty itself via OSC 777
# and tunneled through tmux's passthrough escape.
#
# Chosen over `osascript -e 'display notification'` because macOS 26 attributes an
# osascript notification to Script Editor rather than the terminal, so it is dropped
# silently (exit 0, no hook error) unless Script Editor is separately authorized.
# OSC 777 posts under Ghostty's own bundle ID, which is already authorized.
#
# Note: Ghostty suppresses its own notifications while the window is focused. That is
# the desired behavior here, since these only matter when you are looking elsewhere.
#
# Requires `set -g allow-passthrough on` in ~/.tmux.conf.
#
# Usage: notify-ghostty.sh stop|notification   (hook JSON on stdin)

JSON="$(cat)"
SID="$(printf '%s' "$JSON" | jq -r '.session_id // ""' 2>/dev/null)"
[ -n "$SID" ] || exit 0

SESS="$(jq -rs --arg sid "$SID" 'map(select(.sessionId == $sid)) | .[0] // empty' \
        "$HOME"/.claude/sessions/*.json 2>/dev/null)"
[ -n "$SESS" ] || exit 0

NAME="$(printf '%s' "$SESS" | jq -r '.name // "Claude"' 2>/dev/null)"
[ -n "$NAME" ] || NAME="Claude"

case "$1" in
  notification)
    MSG="$(printf '%s' "$JSON" | jq -r '.message // ""' 2>/dev/null)"
    printf '%s' "$MSG" | grep -qiE 'permission|approval|needs your' || exit 0
    BODY="[$NAME] $MSG"
    ;;
  *)
    BODY="$NAME is waiting"
    ;;
esac

# OSC 777 is ';'-delimited, so strip separators and control bytes, and keep it short.
BODY="$(printf '%s' "$BODY" | tr -d ';\033\007\r\n' | cut -c1-120)"
[ -n "$BODY" ] || exit 0

# Resolve the tty of the client attached to THIS session's tmux pane, so the escape
# lands on the right window when several Claude sessions run side by side.
PANE="$(printf '%s' "$SESS" | jq -r '.tmux // ""' 2>/dev/null | sed 's/.*\.//')"
if [ -n "$PANE" ]; then
  TTY="$(tmux display-message -p -t "$PANE" '#{client_tty}' 2>/dev/null)"
  if [ -n "$TTY" ] && [ -w "$TTY" ]; then
    printf '\033Ptmux;\033\033]777;notify;Claude Code;%s\007\033\\' "$BODY" > "$TTY"
    exit 0
  fi
fi

# Not under tmux: talk to Ghostty directly, no passthrough wrapper.
if [ -w /dev/tty ]; then
  printf '\033]777;notify;Claude Code;%s\007' "$BODY" > /dev/tty
fi
exit 0
