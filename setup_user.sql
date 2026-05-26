-- ロールの指定
USE ROLE COCO_CLI_HANDSON_ROLE;

USE WAREHOUSE COCO_CLI_HANDSON_WH;

-- ユーザ名を動的に取得してデータベース名を設定
SET DB_NAME = 'SNOWRETAIL_DB_' || CURRENT_USER();
SET SCHEMA_NAME = $DB_NAME || '.SNOWRETAIL_SCHEMA';
SET STAGE_NAME = $DB_NAME || '.SNOWRETAIL_SCHEMA.FILE';

// Step2: 各種オブジェクトの作成 //

-- データベースの作成
CREATE OR REPLACE DATABASE IDENTIFIER($DB_NAME);
-- スキーマの作成
CREATE OR REPLACE SCHEMA IDENTIFIER($SCHEMA_NAME);
-- スキーマの指定
USE SCHEMA IDENTIFIER($SCHEMA_NAME);

-- ステージの作成
CREATE OR REPLACE STAGE IDENTIFIER($STAGE_NAME) encryption = (type = 'snowflake_sse') DIRECTORY = (ENABLE = TRUE);


// Step3: 公開されているGitからデータとスクリプトを取得 //
  
-- GITリポジトリの作成
CREATE OR REPLACE GIT REPOSITORY GIT_INTEGRATION_FOR_COCO_CLI_HANDSON
  API_INTEGRATION = git_api_coco_hands_on_integration
  ORIGIN = 'https://github.com/sfc-gh-chtan/coco-cli-handson-jp.git';

-- チェックする   
ls @GIT_INTEGRATION_FOR_COCO_CLI_HANDSON/branches/main;

-- Githubからファイルを持ってくる
COPY FILES INTO @IDENTIFIER($STAGE_NAME) FROM @GIT_INTEGRATION_FOR_COCO_CLI_HANDSON/branches/main/data/ PATTERN ='.*\\.csv$';

-- ============================================================
-- 1. データの準備
-- この章では外部にある4種類のCSVファイルをSnowflake テーブルとして投入する
-- ============================================================

-- データベースの作成, スキーマの準備
USE SCHEMA IDENTIFIER($SCHEMA_NAME);

-- ファイルを確認
ls @file;

-- データの投入
-- Step1: テーブル作成
create or replace TABLE EC_DATA (
	TRANSACTION_ID VARCHAR(16777216),
	TRANSACTION_DATE DATE,
	PRODUCT_ID VARCHAR(16777216),
	PRODUCT_NAME VARCHAR(16777216),
	QUANTITY NUMBER(38,0),
	UNIT_PRICE NUMBER(38,0),
	TOTAL_PRICE NUMBER(38,0)
);

create or replace TABLE RETAIL_DATA (
	TRANSACTION_ID VARCHAR(16777216),
	TRANSACTION_DATE DATE,
	PRODUCT_ID VARCHAR(16777216),
	PRODUCT_NAME VARCHAR(16777216),
	QUANTITY NUMBER(38,0),
	UNIT_PRICE NUMBER(38,0),
	TOTAL_PRICE NUMBER(38,0)
);

create or replace TABLE PRODUCT_MASTER (
 	PRODUCT_ID VARCHAR(16777216),
	PRODUCT_NAME VARCHAR(16777216),
	UNIT_PRICE NUMBER(38,0)
);

create or replace TABLE SNOW_RETAIL_DOCUMENTS (
	DOCUMENT_ID VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	CONTENT VARCHAR(16777216),
	DOCUMENT_TYPE VARCHAR(16777216),
	DEPARTMENT VARCHAR(16777216),
	CREATED_AT TIMESTAMP_NTZ(9),
	UPDATED_AT TIMESTAMP_NTZ(9),
	VERSION NUMBER(38,1)
);

create or replace TABLE CUSTOMER_REVIEWS (
	REVIEW_ID VARCHAR(16777216),
	PRODUCT_ID VARCHAR(16777216),
	CUSTOMER_ID VARCHAR(16777216),
	RATING NUMBER(38,1),
	REVIEW_TEXT VARCHAR(16777216),
	REVIEW_DATE TIMESTAMP_NTZ(9),
	PURCHASE_CHANNEL VARCHAR(16777216),
	HELPFUL_VOTES NUMBER(38,0)
);

-- Step2: データロード
create or replace temp file format temp_ff
    type = csv
    skip_header = 1
; 

create or replace temp file format temp_ff_2
	TYPE=CSV
    SKIP_HEADER=1
    FIELD_OPTIONALLY_ENCLOSED_BY='"'
; 

copy into EC_DATA
from @FILE
file_format = (format_name = temp_ff)
files = ('ec_data.csv');

copy into PRODUCT_MASTER
from @FILE
file_format = (format_name = temp_ff)
files = ('product_master.csv');

copy into RETAIL_DATA
from @FILE
file_format = (format_name = temp_ff)
files = ('retail_data.csv');

copy into CUSTOMER_REVIEWS
from @FILE
file_format = (format_name = temp_ff)
files = ('customer_reviews.csv');

copy into SNOW_RETAIL_DOCUMENTS
from @FILE
file_format = (format_name = temp_ff_2)
files = ('snow_retail_documents.csv');
