@echo off
REM One-command update: git pull + Cloud Build (build, push, update Cloud Run)
REM Run from repo root: scripts\update-routing-engine.cmd

set PROJECT_ID=cybertranspay
set REGION=europe-west1

cd /d "%~dp0.."
echo === CyberTransPay routing-engine update ===

echo [1/2] git pull...
git pull origin main
if errorlevel 1 goto :error

echo [2/2] Cloud Build...
gcloud builds submit --config=cloudbuild.yaml --project=%PROJECT_ID%
if errorlevel 1 goto :error

echo.
echo === SUCCESS ===
for /f "delims=" %%U in ('gcloud run services describe routing-engine --region=%REGION% --project=%PROJECT_ID% --format="value(status.url)"') do set URL=%%U
echo Cloud Run URL: %URL%
echo.
echo Test locally (keep proxy window open):
echo   gcloud run services proxy routing-engine --region=%REGION% --project=%PROJECT_ID% --port=8080
echo   curl http://127.0.0.1:8080/health
goto :eof

:error
echo FAILED.
exit /b 1
