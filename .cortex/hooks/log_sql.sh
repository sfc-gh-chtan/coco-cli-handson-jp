#!/usr/bin/env bash
# =============================================================================
# log_sql.sh
#   PostToolUse hook: 実行された SQL を監査ログとして追記する (ブロックはしない)。
#
# Cortex Code CLI からの呼ばれ方:
#   stdin に JSON が渡されてくる。例:
#     {
#       "hook_event_name": "PostToolUse",
#       "tool_name": "snowflake_sql_execute",
#       "tool_input": { "sql": "SELECT * FROM ...", "description": "..." }
#     }
#
#   PostToolUse はブロックできないので、常に exit 0 で返す。
# =============================================================================

# stdin (JSON) を変数に読み込む
INPUT="$(cat)"

# JSON から tool_name と sql と description を取り出す
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
SQL=$(echo "$INPUT" | jq -r '.tool_input.sql // ""')
DESC=$(echo "$INPUT" | jq -r '.tool_input.description // ""')

# このフックは SQL 実行ツールのみ対象。それ以外は何もせず終了
if [[ "$TOOL_NAME" != *sql* && "$TOOL_NAME" != *snowflake* ]]; then
  exit 0
fi

# ログ出力先 (プロジェクトルートからの相対)
LOG_DIR="${CORTEX_PROJECT_DIR:-.}/.cortex/logs"
LOG_FILE="${LOG_DIR}/sql_audit.log"

# ディレクトリが無ければ作る
mkdir -p "$LOG_DIR"

# ログに 1 件追記 (ISO8601タイムスタンプ + description + 実行SQL)
{
  echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $DESC"
  echo "  SQL: $SQL"
  echo ""
} >> "$LOG_FILE"

# PostToolUse はブロック不可なので必ず exit 0
exit 0
