#!/usr/bin/env bash
# block_dangerous_sql.sh
# ----------------------------------------------------------------------
# PreToolUse hook for `snowflake_sql_execute`.
# 危険な書き込み系 SQL（DROP / TRUNCATE / DELETE / UPDATE / INSERT / MERGE / ALTER）
# をブロックして、本番データを保護する。
#
# 入力 (stdin): Cortex Code CLI が JSON で送信
#   {
#     "session_id": "...",
#     "tool_name": "snowflake_sql_execute",
#     "tool_input": { "sql": "..." }
#   }
#
# 出力 (stdout): JSON 1 行
#   許可: {"decision":"allow"}
#   ブロック: {"decision":"block","reason":"..."}
#
# 終了コード:
#   0 = 通過
#   2 = ブロック
# ----------------------------------------------------------------------
set -u

# stdin を全部読み込む
INPUT="$(cat)"

# tool_input.sql を抽出（Python が無くても動くよう、まず jq → Python の順で試行）
extract_sql() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '.tool_input.sql // .tool_input.query // ""'
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {})
    print(ti.get("sql") or ti.get("query") or "")
except Exception:
    print("")'
  else
    # フォールバック: 取り出せなかった場合は通過
    printf ''
  fi
}

SQL="$(extract_sql)"

# SQL が空なら通過（解析不能）
if [ -z "$SQL" ]; then
  printf '%s\n' '{"decision":"allow","systemMessage":"[hook] sql empty, skipped"}'
  exit 0
fi

# 大文字化して比較
SQL_UPPER="$(printf '%s' "$SQL" | tr '[:lower:]' '[:upper:]')"

# ブロック対象のキーワード（単語境界 \b で囲む）
PATTERNS=(
  '\bDROP[[:space:]]+TABLE\b'
  '\bDROP[[:space:]]+DATABASE\b'
  '\bDROP[[:space:]]+SCHEMA\b'
  '\bDROP[[:space:]]+WAREHOUSE\b'
  '\bTRUNCATE[[:space:]]+TABLE\b'
  '\bTRUNCATE\b[[:space:]]+'
  '\bDELETE[[:space:]]+FROM\b'
  '\bUPDATE\b[[:space:]]+'
  '\bINSERT[[:space:]]+INTO\b'
  '\bMERGE[[:space:]]+INTO\b'
  '\bALTER[[:space:]]+TABLE\b'
  '\bGRANT\b'
  '\bREVOKE\b'
)

for pat in "${PATTERNS[@]}"; do
  if printf '%s' "$SQL_UPPER" | grep -E -q "$pat"; then
    REASON="本番データ保護のため、書き込み系 SQL '${pat//\\b/}' は Hooks によりブロックされました。AGENTS.md 禁止事項に該当します。SELECT のみ許可されています。"
    # JSON 文字列としてエスケープ（簡易）
    ESCAPED_REASON="${REASON//\"/\\\"}"
    printf '%s\n' "{\"decision\":\"block\",\"reason\":\"${ESCAPED_REASON}\"}"
    exit 2
  fi
done

# 通過
printf '%s\n' '{"decision":"allow"}'
exit 0
