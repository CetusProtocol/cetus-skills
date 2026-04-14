#!/usr/bin/env bash
# PreToolUse hook: blocks obviously unsafe shell patterns.
#
# Checks:
# - --private-key flag anywhere in the command
# - common direct secret injection patterns (PRIVATE_KEY=0x..., MNEMONIC=...)
# - suspicious 64-byte hex literals unless in common safe hash contexts
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

if echo "$COMMAND" | grep -qF -- "--private-key"; then
  echo '{"decision":"block","reason":"BLOCKED: --private-key detected. Use a secure signer flow instead of passing raw keys on CLI."}'
  exit 0
fi

if echo "$COMMAND" | grep -qiE '(PRIVATE_KEY|MNEMONIC|SEED_PHRASE)[[:space:]]*='; then
  echo '{"decision":"block","reason":"BLOCKED: direct secret assignment detected in shell command."}'
  exit 0
fi

if echo "$COMMAND" | grep -qE '0x[0-9a-fA-F]{64}'; then
  if echo "$COMMAND" | grep -qiE '(tx|transaction|hash|receipt|block)'; then
    : # likely a hash reference
  elif echo "$COMMAND" | grep -qE '--(data|calldata|payload)[[:space:]]'; then
    : # likely explicit calldata/payload
  else
    echo '{"decision":"block","reason":"BLOCKED: 64-byte hex literal detected. Possible private key exposure."}'
    exit 0
  fi
fi

exit 0
