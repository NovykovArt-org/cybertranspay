@echo off
REM Grant Cloud Build permissions for project cybertranspay (1079379369218)
REM Run once before: gcloud builds submit
REM Idempotent: safe to re-run (ignores "already exists" errors)

setlocal EnableExtensions
set PROJECT_ID=cybertranspay
set COMPUTE_SA=1079379369218-compute@developer.gserviceaccount.com
set CLOUDBUILD_SA=1079379369218@cloudbuild.gserviceaccount.com
set REGION=europe-west1

echo Creating Artifact Registry (ignore error if exists)...
call gcloud artifacts repositories create cybertranspay --repository-format=docker --location=%REGION% --project=%PROJECT_ID% 2>nul
if errorlevel 1 echo   (repository already exists — OK)

echo Granting IAM to Compute default SA...
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/artifactregistry.writer --quiet
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/run.admin --quiet
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/logging.logWriter --quiet
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/iam.serviceAccountUser --quiet

echo Granting IAM to Cloud Build SA...
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/artifactregistry.writer --quiet
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/run.admin --quiet

echo Granting Artifact Registry reader to Cloud Run service agent...
call gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:service-1079379369218@serverless-robot-prod.iam.gserviceaccount.com --role=roles/artifactregistry.reader --quiet

echo Granting Compute SA permission to act as itself (Cloud Run deploy)...
call gcloud iam service-accounts add-iam-policy-binding %COMPUTE_SA% --member=serviceAccount:%COMPUTE_SA% --role=roles/iam.serviceAccountUser --project=%PROJECT_ID% --quiet

echo Done. Update with: scripts\update-routing-engine.cmd
exit /b 0
