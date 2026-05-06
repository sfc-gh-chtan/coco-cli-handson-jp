#!/usr/bin/env bash
# =============================================================================
# block_dangerous_bash.sh
#   PreToolUse hook: 破壊的な Bash コマンド (rm -rf, sudo, dd 等) をブロックする。
#
# Cortex Code CLI からの呼ばれ方:
#   stdin に JSON が渡されてくる。例:
#     {
#       "hook_event_name": "PreToolUse",
#       "tool_name": "bash",
#       "tool_input": { "command": "rm -rf /" }
#     }
#
#   stdout に JSON を返すと CoCo がそれを解釈する。
#     - 通過させる: {"decision":"allow"}    + exit 0
#     - 阻止する  : {"decision":"block","reason":"..."}  + exit 2
# =============================================================================

# stdin (JSON) を変数に読み込む
INPUT="$(cat)"

# JSON から tool_name と command を取り出す
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# このフックは bash ツールのみ対象。SQL 等の他ツールは素通り
if [[ "$TOOL_NAME" != "bash" && "$TOOL_NAME" != "Bash" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# ブロック対象パターン (システムを壊す可能性が高いコマンド)
DANGEROUS_PATTERNS=(
  "rm -rf /"          # ルート配下を丸ごと削除
  "rm -rf ~"          # ホームディレクトリを丸ごと削除
  "sudo rm"           # 管理者権限での削除
  "mkfs"              # ファイルシステム作成 (= ディスク初期化)
  "dd if="            # ディスクへの直接書き込み
  "shutdown"          # システム停止
  "reboot"            # 再起動
)

# パターンが見つかったら block して exit 2
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$CMD" == *"$pattern"* ]]; then
    echo "{\"decision\":\"block\",\"reason\":\"破壊的な Bash コマンド '${pattern}' が検出されたためブロックしました。\"}"
    exit 2
  fi
done

# 危険パターンなし → 通過
echo '{"decision":"allow"}'
exit 0
