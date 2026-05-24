@echo off
REM Deploy routing-engine to cybertranspay via Cloud Build
REM Run from repo root: scripts\deploy-routing-engine.cmd

set PROJECT_ID=cybertranspay
set REGION=europe-west1

echo === CyberTransPay: routing-engine deploy ===
echo Project: %PROJECT_ID%
echo.

gcloud config set project %PROJECT_ID%
if errorlevel 1 goto :error

echo [1/2] Terraform apply (infra)...
cd /d "%~dp0..\terraform"
terraform init
terraform apply -var="project_id=%PROJECT_ID%" -var="region=%REGION%" -var="allow_public_routing_api=true"
if errorlevel 1 goto :error

echo.
echo [2/2] Cloud Build (docker + deploy)...
cd /d "%~dp0.."
gcloud builds submit --config=cloudbuild.yaml --project=%PROJECT_ID%
if errorlevel 1 goto :error

echo.
echo === Done ===
for /f "delims=" %%U in ('gcloud run services describe routing-engine --region=%REGION% --project=%PROJECT_ID% --format="value(status.url)"') do set URL=%%U
echo URL: %URL%
echo Health: %URL%/health
goto :eof

:error
echo FAILED. See docs/DEPLOY_ROUTING_ENGINE.md
exit /b 1
