#!/usr/bin/env bash
# block_dangerous_bash.sh
# ----------------------------------------------------------------------
# PreToolUse hook for `Bash` tool.
# ローカル環境を破壊しうる Bash コマンドをブロックする。
#
# 入力 (stdin):
#   {
#     "tool_name": "Bash",
#     "tool_input": { "command": "..." }
#   }
#
# 出力 / 終了コード:
#   通過: exit 0, {"decision":"allow"}
#   ブロック: exit 2, {"decision":"block","reason":"..."}
# ----------------------------------------------------------------------
set -u

INPUT="$(cat)"

extract_cmd() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '.tool_input.command // ""'
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input",{}).get("command") or "")
except Exception:
    print("")'
  else
    printf ''
  fi
}

CMD="$(extract_cmd)"

if [ -z "$CMD" ]; then
  printf '%s\n' '{"decision":"allow","systemMessage":"[hook] bash command empty, skipped"}'
  exit 0
fi

# ブロックパターン（破壊的コマンド）
PATTERNS=(
  'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f?[[:space:]]+/'
  'rm[[:space:]]+-rf?[[:space:]]+~'
  ':\(\)\{ *: *\| *: *& *\} *;:'      # フォーク爆弾
  'mkfs\.'
  'dd[[:space:]]+if=.*of=/dev/'
  '>[[:space:]]*/dev/sd[a-z]'
  'sudo[[:space:]]+rm'
  'shutdown[[:space:]]'
  'reboot[[:space:]]*$'
  'curl[[:space:]]+.*\|[[:space:]]*sh'
  'wget[[:space:]]+.*\|[[:space:]]*sh'
)

for pat in "${PATTERNS[@]}"; do
  if printf '%s' "$CMD" | grep -E -q "$pat"; then
    REASON="破壊的なシェルコマンドが検出されたため、Hooks によりブロックされました。pattern=${pat}"
    ESCAPED_REASON="${REASON//\"/\\\"}"
    printf '%s\n' "{\"decision\":\"block\",\"reason\":\"${ESCAPED_REASON}\"}"
    exit 2
  fi
done

printf '%s\n' '{"decision":"allow"}'
exit 0
