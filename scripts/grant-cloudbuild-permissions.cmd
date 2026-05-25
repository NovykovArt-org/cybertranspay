@echo off
REM Grant Cloud Build permissions for project cybertranspay (1079379369218)
REM Run once before: gcloud builds submit

set PROJECT_ID=cybertranspay
set COMPUTE_SA=1079379369218-compute@developer.gserviceaccount.com
set CLOUDBUILD_SA=1079379369218@cloudbuild.gserviceaccount.com
set REGION=europe-west1

echo Creating Artifact Registry (ignore error if exists)...
gcloud artifacts repositories create cybertranspay --repository-format=docker --location=%REGION% --project=%PROJECT_ID% 2>nul

echo Granting IAM to Compute default SA (runs Cloud Build in this project)...
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/artifactregistry.writer
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/run.admin
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/logging.logWriter
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%COMPUTE_SA% --role=roles/iam.serviceAccountUser

echo Granting IAM to Cloud Build SA...
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/artifactregistry.writer
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/run.admin
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:%CLOUDBUILD_SA% --role=roles/logging.logWriter

echo Granting Artifact Registry reader to Cloud Run service agent...
gcloud projects add-iam-policy-binding %PROJECT_ID% --member=serviceAccount:service-1079379369218@serverless-robot-prod.iam.gserviceaccount.com --role=roles/artifactregistry.reader

echo Granting Compute SA permission to act as itself (Cloud Run deploy)...
gcloud iam service-accounts add-iam-policy-binding %COMPUTE_SA% --member=serviceAccount:%COMPUTE_SA% --role=roles/iam.serviceAccountUser --project=%PROJECT_ID%

echo Done. Update with: scripts\update-routing-engine.cmd
