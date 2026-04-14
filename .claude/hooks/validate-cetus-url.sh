#!/usr/bin/env bash
# PreToolUse hook: validates open/xdg-open URLs.
# Only allows Cetus domains for automatic URL opening.
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

STRIPPED_COMMAND=$(echo "$COMMAND" | sed -E 's/^([A-Za-z_][A-Za-z_0-9]*=(["'"'"'][^"'"'"']*["'"'"']|[^ ]*) +)+//')
BINARY=$(echo "$STRIPPED_COMMAND" | awk '{print $1}')
BASE_BINARY=$(basename "$BINARY" 2>/dev/null || echo "$BINARY")

if [ "$BASE_BINARY" != "open" ] && [ "$BASE_BINARY" != "xdg-open" ]; then
  exit 0
fi

URL=$(echo "$COMMAND" | grep -oE 'https?://[^ "'"'"']+' | awk 'NR==1{print}')
if [ -z "$URL" ]; then
  echo '{"decision":"block","reason":"BLOCKED: no URL found in open command."}'
  exit 0
fi

if echo "$URL" | grep -qE '^https://([a-zA-Z0-9-]+\.)*cetus\.zone(/|$|\?)'; then
  exit 0
fi

echo '{"decision":"block","reason":"BLOCKED: only https://*.cetus.zone URLs can be opened automatically."}'
exit 0
