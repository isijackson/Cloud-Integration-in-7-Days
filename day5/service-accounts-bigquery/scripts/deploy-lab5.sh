#!/usr/bin/env bash
# Week 5 Lab 5.2 deploy: service account with BigQuery User, a report VM that carries it, a control VM
# that does not, the query run from both, and the no-key-file evidence. Idempotent: safe to re-run.
#   deploy-lab5.sh <PROJECT_ID>        (ZONE, SA env vars optional)
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID>}"; ZONE="${ZONE:-us-central1-a}"; SA="${SA:-names-report}"
SA_EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"; D=$(cd "$(dirname "$0")/.." && pwd)
g() { gcloud "$@" --project="$PROJECT" --quiet; }
echo "== Part 1: APIs and identity"
g services enable compute.googleapis.com bigquery.googleapis.com iam.googleapis.com
g iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1 || g iam service-accounts create "$SA" --display-name="Nightly names report"
# the control VM gets its own identity with NO roles, so the negative test does not depend on what the
# project's default compute service account happens to hold (older projects grant it Editor)
CTL_EMAIL="$SA-control@$PROJECT.iam.gserviceaccount.com"
g iam service-accounts describe "$CTL_EMAIL" >/dev/null 2>&1 || g iam service-accounts create "$SA-control" --display-name="Control VM identity (no roles)"
for i in 1 2 3 4 5 6; do g projects add-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA_EMAIL" --role="roles/bigquery.user" --condition=None >/dev/null 2>&1 && break; sleep 10; done
echo "ROLES for $SA_EMAIL:"; g projects get-iam-policy "$PROJECT" --flatten="bindings[].members" --filter="bindings.members:$SA_EMAIL" --format="value(bindings.role)"
echo "== Part 2: two VMs"
g compute instances describe report-vm --zone="$ZONE" >/dev/null 2>&1 || g compute instances create report-vm --zone="$ZONE" --machine-type=e2-small \
  --image-family=debian-12 --image-project=debian-cloud --service-account="$SA_EMAIL" --scopes=https://www.googleapis.com/auth/cloud-platform
g compute instances describe control-vm --zone="$ZONE" >/dev/null 2>&1 || g compute instances create control-vm --zone="$ZONE" --machine-type=e2-micro \
  --image-family=debian-12 --image-project=debian-cloud --service-account="$CTL_EMAIL" --scopes=https://www.googleapis.com/auth/cloud-platform
g compute instances list --filter="name=(report-vm control-vm)" --format="table(name,zone.basename(),machineType.basename(),serviceAccounts[0].email,status)"
# ssh helper: plain first, IAP tunnel if port 22 is closed to the internet
SSHF=""
# probe: unfiltered, so its exit status is gcloud's (under pipefail a filtered pipe would report grep -v's status)
probe() { gcloud compute ssh "$1" --project="$PROJECT" --zone="$ZONE" --quiet $SSHF --command=true >/dev/null 2>&1; }
sshvm() { local vm=$1; shift; gcloud compute ssh "$vm" --project="$PROJECT" --zone="$ZONE" --quiet $SSHF --command="$*" 2>&1 | grep -v -E "^(WARNING|Warning|Updating|Existing|External IP|To increase|please see)"; }
for i in $(seq 1 12); do probe report-vm && break; SSHF="--tunnel-through-iap"; probe report-vm && break; SSHF=""; sleep 10; done
echo "SSH flags: '${SSHF:-direct}'"
echo "== Part 3: query from report-vm"
gcloud compute scp "$D/app/names.py" report-vm:~/names.py --project="$PROJECT" --zone="$ZONE" --quiet $SSHF 2>/dev/null
sshvm report-vm 'sudo apt-get update -qq >/dev/null; sudo apt-get install -y -qq python3-venv >/dev/null; python3 -m venv ~/bq && ~/bq/bin/pip install -q google-cloud-bigquery 2>/dev/null; ~/bq/bin/python -W ignore names.py TX 2>&1 | tail -6; ~/bq/bin/python -W ignore names.py UT 2>&1 | tail -6'
echo "== No-key-file evidence on report-vm"
sshvm report-vm 'ls -la ~ | grep -i json; echo "exit code $? (1 means no key file)"; env | grep -i GOOGLE_APPLICATION_CREDENTIALS; echo "exit code $? (1 means no credentials variable)"; curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email; echo'
echo "== Part 4: negative test on control-vm"
sshvm control-vm 'sudo apt-get update -qq >/dev/null; sudo apt-get install -y -qq python3-venv >/dev/null; python3 -m venv ~/bq && ~/bq/bin/pip install -q google-cloud-bigquery; printf "from google.cloud import bigquery\nfor row in bigquery.Client().query(\"SELECT 1\"): print(row)\n" > names.py; ~/bq/bin/python -W ignore names.py 2>&1 | grep -E "403|Forbidden|denied|Error" | head -2'
echo "LAB5_DEPLOY_DONE"
