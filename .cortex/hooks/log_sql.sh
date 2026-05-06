#!/usr/bin/env bash
# log_sql.sh
# ----------------------------------------------------------------------
# PostToolUse hook for `snowflake_sql_execute`.
# 実行された SQL を監査ログとして追記する（決してブロックはしない）。
#
# 入力 (stdin):
#   {
#     "tool_name": "snowflake_sql_execute",
#     "tool_input": { "sql": "...", "description": "..." },
#     "tool_response": { ... }
#   }
#
# 出力:
#   常に exit 0
#   stdout には何も返さない（PostToolUse は decision を要求しない）
# ----------------------------------------------------------------------
set -u

LOG_DIR="${CORTEX_PROJECT_DIR:-.}/.cortex/logs"
LOG_FILE="${LOG_DIR}/sql_audit.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

INPUT="$(cat)"

extract_field() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$path // \"\""
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    keys = '$path'.replace('.tool_input.','').replace('.tool_name','tool_name').split('.')
    cur = d
    for k in keys:
        if not k: continue
        cur = cur.get(k, '') if isinstance(cur, dict) else ''
    print(cur if isinstance(cur, str) else str(cur))
except Exception:
    print('')
"
  fi
}

SQL=$(extract_field '.tool_input.sql')
DESC=$(extract_field '.tool_input.description')
TS=$(date '+%Y-%m-%dT%H:%M:%S%z')

# ログ追記（フォーマット: ISO8601 | description | sql 1行化）
{
  printf '[%s] desc=%q\n' "$TS" "${DESC:-}"
  printf '       sql=%s\n' "$(printf '%s' "${SQL:-}" | tr '\n' ' ' | tr -s ' ')"
  printf '\n'
} >> "$LOG_FILE" 2>/dev/null || true

# PostToolUse はブロック不可なので必ず exit 0
exit 0
