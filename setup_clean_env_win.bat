@echo off
chcp 65001 >nul
setlocal

REM =============================================================================
REM setup_clean_env_win.bat  (Windows)
REM -----------------------------------------------------------------------------
REM Place this file at the root of the unzipped `coco-cli-handson-jp-main\`
REM and double-click it. The script starts cortex in a clean sandbox so that
REM the user's existing CoCo CLI settings are not affected.
REM
REM Mechanics:
REM   - The folder containing this batch is used as SANDBOX_HOME.
REM     * .cortex\        is read as project-scope settings
REM     * .snowflake\     is auto-created by cortex on first launch
REM   - USERPROFILE / HOME / SNOWFLAKE_HOME are temporarily redirected
REM     (setlocal restores them automatically when the batch exits)
REM   - --setting-sources project enables only project-scope settings
REM   - --no-mcp disables personal MCP integrations
REM   - Delete the unzipped folder afterwards to wipe everything.
REM =============================================================================

cd /d "%~dp0"
set "SANDBOX_HOME=%~dp0"
if "%SANDBOX_HOME:~-1%"=="\" set "SANDBOX_HOME=%SANDBOX_HOME:~0,-1%"

if not exist "%SANDBOX_HOME%\.cortex" (
    echo [ERROR] このバッチは coco-cli-handson-jp-main の直下に置いて実行してください。
    echo         current location: %SANDBOX_HOME%
    echo.
    pause
    exit /b 1
)

where cortex >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cortex command not found.
    echo         CoCo CLI をインストールして PATH を通してから再度実行してください。
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  クリーン環境で cortex を起動します (Windows)
echo ============================================================
echo   作業ディレクトリ / 一時 HOME : %SANDBOX_HOME%
echo.
echo   既存の %%USERPROFILE%%\.snowflake\cortex などには触れません。
echo   接続情報は初回起動時のセットアップウィザードで設定してください。
echo   (情報は %SANDBOX_HOME%\.snowflake\ 配下に保存されます)
echo.
echo   終了するには /exit と入力してください。
echo   ハンズオン後、解凍フォルダごと削除すれば設定・履歴も消去されます。
echo ============================================================
echo.

set "USERPROFILE=%SANDBOX_HOME%"
set "HOME=%SANDBOX_HOME%"
set "SNOWFLAKE_HOME=%SANDBOX_HOME%\.snowflake"

cortex ^
  -w "%SANDBOX_HOME%" ^
  --setting-sources project ^
  --no-mcp ^
  --no-auto-update ^
  -m "claude-sonnet-4-6"

echo.
echo cortex セッションを終了しました。
pause

endlocal
