#!/bin/bash
# Reads the most recent Claude reply from this tab (Cmd+Shift+R, tmux prefix + R).
# Works in both profiles and while read-aloud is off, reads the whole reply, and
# opens it in ~/.local/bin/speakview-popup, which highlights each word as it is read.
#
#   speak-last.sh PANE_ID    PANE_ID is tmux's #{pane_id}, like %12
#
# Each running Claude writes sessions/<pid>.json with its session ID and a tmux
# field ending in its pane ID. That file is internal to Claude Code, so an update
# could change it. If it does, this shows a message instead of reading another tab.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIRS=("$HOME/.claude" "$HOME/.claude-perso")
pane="$1"

notify() {
  if [ -n "$TMUX" ]; then tmux display-message "$1"; else echo "$1"; fi
}

transcript=""
for dir in "${CONFIG_DIRS[@]}"; do
  session_file=$(grep -lE "\"tmux\":\"[^\"]*\\.$pane\"" "$dir"/sessions/*.json 2>/dev/null | head -n 1)
  [ -n "$session_file" ] || continue
  session_id=$(jq -r '.sessionId // empty' "$session_file")
  [ -n "$session_id" ] || continue
  transcript=$(ls -t "$dir"/projects/*/"$session_id".jsonl 2>/dev/null | head -n 1)
  [ -n "$transcript" ] && break
done

if [ -z "$transcript" ]; then
  notify "No Claude conversation in this tab"
  exit 0
fi

# Every text block Claude wrote since the last prompt you typed: a reply with tool
# calls in between is split over many transcript entries, not just the last one.
reply=$(tail -n 3000 "$transcript" | jq -Rrs '
  [split("\n")[] | fromjson? | select(.isSidechain | not)] as $e
  | ([$e | to_entries[]
      | select(.value.type == "user" and (.value.isMeta | not))
      | select(.value.message.content
          | (type == "string") or (type == "array" and all(.[]; .type != "tool_result")))
      | .key] | last // -1) as $u
  | [$e[$u + 1:][]
     | select(.type == "assistant")
     | [.message.content[]? | select(.type == "text") | .text]
     | join("\n")
     | select(length > 0)]
  | join("\n\n")')

# Check the raw reply, not the speakable text: an answer that is only code has
# nothing to say aloud but is still worth showing.
if [ -z "${reply//[[:space:]]/}" ]; then
  notify "No reply to read in this tab yet"
  exit 0
fi

# speakview renders the markdown itself and cleans it for the voice.
printf '%s' "$reply" | "$HOME/.local/bin/speakview-popup"
