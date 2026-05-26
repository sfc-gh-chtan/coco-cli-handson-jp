-- ============================================================
-- cleanup.sql
-- ハンズオン環境の全削除
-- 実行: snow sql -f cleanup.sql
-- ============================================================

-- ロールの指定
USE ROLE COCO_CLI_HANDSON_ROLE;

-- ユーザ名を動的に取得してデータベース名を設定
SET DB_NAME = 'SNOWRETAIL_DB_' || CURRENT_USER();
SET SCHEMA_NAME = $DB_NAME || '.SNOWRETAIL_SCHEMA';
SET STAGE_NAME = $DB_NAME || '.SNOWRETAIL_SCHEMA.FILE';
SET CORTEX_AGENT_NAME = $SCHEMA_NAME || '.HANDSON_DOCS_SEARCH';

-- Cortex Agent
DROP CORTEX SEARCH SERVICE IF EXISTS IDENTIFIER($CORTEX_AGENT_NAME);

-- Database ごと全オブジェクト削除
-- (テーブル, Dynamic Table, Semantic View, Stage, Git Repository 等すべて含む)
DROP DATABASE IF EXISTS IDENTIFIER($DB_NAME);
