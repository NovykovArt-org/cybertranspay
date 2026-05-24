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

echo Done. Now run: gcloud builds submit --config=cloudbuild.yaml --project=cybertranspay
