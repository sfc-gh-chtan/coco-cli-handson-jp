USE ROLE ACCOUNTADMIN;

-- Git連携のため、API統合を作成する
CREATE OR REPLACE API INTEGRATION git_api_coco_hands_on_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-chtan/', 'https://github.com/snow-jp-handson-org/')
  ENABLED = TRUE;

-- Cortex Codeハンズオン参加者ロールに必要な権限を付与
GRANT USAGE ON INTEGRATION git_api_coco_hands_on_integration TO ROLE <Cortex Codeハンズオン参加者ロール>;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE <Cortex Codeハンズオン参加者ロール>;
