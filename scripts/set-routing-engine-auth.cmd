@echo off
REM Enable API key auth on Cloud Run routing-engine
REM Generates a key if ROUTING_API_KEY is not set.

set PROJECT_ID=cybertranspay
set REGION=europe-west1
set SERVICE=routing-engine
set KEY_FILE=%~dp0..\.routing-api-key.txt

if "%ROUTING_API_KEY%"=="" (
  for /f "delims=" %%K in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "ROUTING_API_KEY=%%K"
)

if "%ROUTING_API_KEY%"=="" (
  echo FAILED: could not generate API key.
  exit /b 1
)

echo.
echo ========================================
echo   API KEY: %ROUTING_API_KEY%
echo ========================================
echo SAVE THIS KEY.
echo.

echo %ROUTING_API_KEY%> "%KEY_FILE%"
echo Key also saved to: %KEY_FILE%
echo.

echo Updating Cloud Run env: AUTH_REQUIRED=true ...
call :update_service
if errorlevel 1 goto :error

echo.
echo === Auth enabled ===
echo API KEY: %ROUTING_API_KEY%
echo.
echo Test via proxy:
echo   gcloud run services proxy %SERVICE% --region=%REGION% --project=%PROJECT_ID% --port=8080
echo.
echo Quote (PowerShell):
echo   curl -Method POST http://127.0.0.1:8080/v1/routes/quote -ContentType "application/json" -Headers @{"X-API-Key"="%ROUTING_API_KEY%"} -Body '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'
goto :eof

:update_service
gcloud run services update %SERVICE% ^
  --region=%REGION% ^
  --project=%PROJECT_ID% ^
  --set-env-vars=AUTH_REQUIRED=true,AUTH_API_KEYS=%ROUTING_API_KEY%,RUST_LOG=info ^
  --quiet
exit /b %ERRORLEVEL%

:error
echo FAILED.
exit /b 1
