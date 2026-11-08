#!/usr/bin/env bash
# Week 5 AI/automation extension: Workload Identity Federation so GitHub Actions can run the
# names report with NO service-account key. Creates the pool and provider, lets the repo's
# workflows impersonate names-report, pushes keyless-ci/ to a repository, and triggers the run.
#   deploy-lab5-keyless-ci.sh <PROJECT_ID> <github-owner/repo>     (gh signed in; repo is created if missing)
set -euo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> <owner/repo>}"; REPO="${2:?}"; SA="${SA:-names-report}"
SA_EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"; D=$(cd "$(dirname "$0")/.." && pwd)
g() { gcloud "$@" --project="$PROJECT" --quiet; }
PN=$(g projects describe "$PROJECT" --format='value(projectNumber)')
echo "== identity (same as Part 1) and the federation pool"
g iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1 || g iam service-accounts create "$SA" --display-name="Nightly names report"
for i in 1 2 3 4 5 6; do g projects add-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA_EMAIL" --role="roles/bigquery.user" --condition=None >/dev/null 2>&1 && break; sleep 10; done
g services enable iamcredentials.googleapis.com sts.googleapis.com >/dev/null
g iam workload-identity-pools describe github --location=global >/dev/null 2>&1 || g iam workload-identity-pools create github --location=global --display-name="GitHub Actions"
g iam workload-identity-pools providers describe github --location=global --workload-identity-pool=github >/dev/null 2>&1 || \
g iam workload-identity-pools providers create-oidc github --location=global --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='$REPO'"
PROVIDER="projects/$PN/locations/global/workloadIdentityPools/github/providers/github"
g iam service-accounts add-iam-policy-binding "$SA_EMAIL" --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/$PN/locations/global/workloadIdentityPools/github/attribute.repository/$REPO" >/dev/null
echo "WIF_PROVIDER=$PROVIDER"; echo "REPORT_SA=$SA_EMAIL"
echo "== repository and workflow"
W=$(mktemp -d); cp -r "$D/keyless-ci/." "$W/"; cd "$W"; git init -q -b main; git add -A; git commit -qm "Keyless nightly names report"
gh repo view "$REPO" >/dev/null 2>&1 || gh repo create "$REPO" --private --source=. --push >/dev/null
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$REPO.git"; git push -q -u origin main 2>/dev/null || true
gh variable set WIF_PROVIDER -R "$REPO" -b "$PROVIDER"; gh variable set REPORT_SA -R "$REPO" -b "$SA_EMAIL"
echo "waiting 90 s for the new IAM bindings to propagate (a run that starts earlier gets iam.serviceAccounts.getAccessToken denied)"; sleep 90
for attempt in 1 2; do
  gh workflow run nightly-names-report -R "$REPO"; sleep 20
  RID=$(gh run list -R "$REPO" --workflow nightly-names-report --limit 1 --json databaseId --jq '.[0].databaseId')
  if gh run watch -R "$REPO" "$RID" --exit-status >/dev/null; then echo "run $RID green"; break; else echo "run $RID failed (attempt $attempt)"; sleep 60; fi
done
gh run view -R "$REPO" "$RID" --log 2>/dev/null | grep -E "Top names|^\s*[A-Z][a-z]+: [0-9]+|credential source|no key file" | sed 's/.*\t//' | head -16
echo "LAB5_KEYLESS_CI_DONE"
