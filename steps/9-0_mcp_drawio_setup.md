# Step 9: draw.io MCP でデータ全体像を可視化

## 概要

draw.io MCP（Tool Server）を Cortex Code CLI に接続し、ハンズオン全体のデータ構造をER図として可視化する。

**所要時間**: 20分  
**使用機能**: `cortex mcp add`、draw.io MCP（Tool Server）、ER図生成  
**パッケージ**: `@drawio/mcp`（公式: [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp)）  
**挙動**: ブラウザの新規タブで draw.io エディタが開き、ER図が表示される

---

## 前提条件

Node.js（v18以上）がインストール済みであること。  
※ CoCo CLI をインストール済みであれば Node.js は入っている可能性が高い。

```bash
node --version   # v18.0.0 以上
```

未インストールの場合:
- Mac: `brew install node`
- Windows: https://nodejs.org/ からダウンロード

---

## 9-1: draw.io MCPの接続

### MCP 一覧の確認

CoCo 内で:
```
/mcp
```

または ターミナルで:
```bash
cortex mcp list
```

### draw.io MCP（Tool Server）を追加

```bash
cortex mcp add drawio -- npx -y @drawio/mcp
```

### 接続確認

```bash
cortex mcp list
```

`drawio` が表示されれば接続完了。

---

## 9-2: ER図の作成

### プロンプト

```
#EC_DATA #RETAIL_DATA #PRODUCT_MASTER #MART_SALES #CUSTOMER_REVIEWS #SNOW_RETAIL_DOCUMENTS
draw.io MCPを使って、これらのテーブルの関係をER図として可視化して
```

### 挙動

1. CoCo が各テーブルのスキーマ情報を自動取得
2. draw.io XML を生成
3. **ブラウザの新規タブで `app.diagrams.net` が開き、ER図が表示される**
4. draw.io エディタ上でそのまま編集・PNG/SVG エクスポート・保存が可能

---

## mcp.json での設定（参考）

`.cortex/mcp.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@drawio/mcp"]
    }
  }
}
```

---

## Tool Server vs App Server の違い

| | Tool Server（採用） | App Server |
|---|---|---|
| 表示先 | **ブラウザの新規タブ**（draw.io エディタ） | チャット内インライン（iframe） |
| 編集 | ✅ draw.io で直接編集可能 | △ iframe 内で限定的 |
| インストール | Node.js 必要 | 不要（URL のみ） |
| パッケージ | `npx @drawio/mcp` | `https://mcp.draw.io/mcp` |

**ハンズオンでは Tool Server を採用**: ブラウザで大きく表示され、参加者が図を編集・保存できるため体験が豊か。

---

## トラブルシューティング

| 症状 | 対処法 |
|------|--------|
| `cortex mcp list` に drawio が表示されない | `cortex mcp add drawio -- npx -y @drawio/mcp` を再実行 |
| `node: command not found` | Node.js をインストール |
| ブラウザが開かない | ターミナルの権限設定を確認。手動で URL をコピーして開く |
| ER図が不正確 | `#テーブル名` でテーブルを明示的に指定 |

---

## 講師ポイント

- **MCPとは**: Model Context Protocol。CoCo が外部ツールと連携するための標準プロトコル
- **体験のポイント**: 「プロンプト1つでブラウザに ER 図が出る」瞬間がハイライト
- **draw.io 以外の MCP**: GitHub・Jira・Slack など様々なツールと連携可能
- **活用価値**: データ全体像のドキュメント化がコマンド1つで完了
