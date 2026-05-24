@echo off
REM Enable API key auth on Cloud Run routing-engine
REM Generates a key if ROUTING_API_KEY is not set.

set PROJECT_ID=cybertranspay
set REGION=europe-west1
set SERVICE=routing-engine

if "%ROUTING_API_KEY%"=="" (
  for /f "delims=" %%K in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set ROUTING_API_KEY=%%K
  echo Generated API key: %ROUTING_API_KEY%
  echo SAVE THIS KEY — it will not be shown again.
) else (
  echo Using ROUTING_API_KEY from environment.
)

echo.
echo Updating Cloud Run env: AUTH_REQUIRED=true ...
gcloud run services update %SERVICE% ^
  --region=%REGION% ^
  --project=%PROJECT_ID% ^
  --set-env-vars=AUTH_REQUIRED=true,AUTH_API_KEYS=%ROUTING_API_KEY%,RUST_LOG=info ^
  --quiet
if errorlevel 1 goto :error

echo.
echo === Auth enabled ===
echo Health (no key):  curl http://127.0.0.1:8080/health
echo Quote (with key): curl -H "X-API-Key: %ROUTING_API_KEY%" -X POST ...
echo.
echo Test via proxy:
echo   gcloud run services proxy %SERVICE% --region=%REGION% --project=%PROJECT_ID% --port=8080
goto :eof

:error
echo FAILED.
exit /b 1
