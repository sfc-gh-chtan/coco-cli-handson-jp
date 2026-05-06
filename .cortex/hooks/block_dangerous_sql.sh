#!/usr/bin/env bash
# =============================================================================
# block_dangerous_sql.sh
#   PreToolUse hook: 危険な SQL (DROP/DELETE/INSERT/UPDATE 等) をブロックする。
#
# Cortex Code CLI からの呼ばれ方:
#   stdin に JSON が渡されてくる。例:
#     {
#       "hook_event_name": "PreToolUse",
#       "tool_name": "snowflake_sql_execute",
#       "tool_input": { "sql": "DROP TABLE FOO" }
#     }
#
#   stdout に JSON を返すと CoCo がそれを解釈する。
#     - 通過させる: {"decision":"allow"}    + exit 0
#     - 阻止する  : {"decision":"block","reason":"..."}  + exit 2
# =============================================================================

# stdin (JSON) を変数に読み込む
INPUT="$(cat)"

# JSON から tool_name と sql を取り出す。jq があればそれを使う。
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
SQL=$(echo "$INPUT" | jq -r '.tool_input.sql // .tool_input.query // ""')

# このフックは SQL 実行ツール (tool_name に "sql" or "snowflake" を含む) のみ対象。
# 他のツール呼び出し (Bash, Read など) は素通りさせる。
if [[ "$TOOL_NAME" != *sql* && "$TOOL_NAME" != *snowflake* ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# SQL を大文字化してキーワード検索しやすくする
SQL_UPPER=$(echo "$SQL" | tr '[:lower:]' '[:upper:]')

# ブロック対象キーワード一覧 (本番テーブル破壊や書き込みを意図する SQL)
DANGEROUS_KEYWORDS=(
  "DROP TABLE"
  "DROP DATABASE"
  "DROP SCHEMA"
  "TRUNCATE"
  "DELETE FROM"
  "UPDATE "
  "INSERT INTO"
  "MERGE INTO"
  "ALTER TABLE"
  "GRANT "
  "REVOKE "
)

# キーワードが見つかったら block して exit 2
for keyword in "${DANGEROUS_KEYWORDS[@]}"; do
  if [[ "$SQL_UPPER" == *"$keyword"* ]]; then
    echo "{\"decision\":\"block\",\"reason\":\"危険な SQL '${keyword}' が検出されたためブロックしました。SELECT のみ許可されています。\"}"
    exit 2
  fi
done

# 危険キーワードなし → 通過
echo '{"decision":"allow"}'
exit 0
