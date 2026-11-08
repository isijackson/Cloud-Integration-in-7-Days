#!/usr/bin/env bash
# Week 5 Lab 5.2 rollback: delete both VMs, the IAM binding and both service accounts.
#   rollback-lab5.sh <PROJECT_ID> [-n] [-y]     -n = dry run, -y = no confirmation prompt
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> [-n] [-y]}"; shift; DRY=0; YES=0
for a in "$@"; do case "$a" in -n) DRY=1;; -y) YES=1;; *) echo "usage: $0 <PROJECT_ID> [-n] [-y]"; exit 2;; esac; done
ZONE="${ZONE:-us-central1-a}"; SA="${SA:-names-report}"; SA_EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"
g() { gcloud "$@" --project="$PROJECT" --quiet 2>/dev/null; }
VMS=$(g compute instances list --filter="name=(report-vm control-vm)" --format="value(name,zone.basename())")
SAS=$(g iam service-accounts list --filter="email=($SA_EMAIL $SA-control@$PROJECT.iam.gserviceaccount.com)" --format="value(email)" | tr '\n' ' ')
echo "Lab 5 resources in $PROJECT:"; printf '  VMs (name zone): %s\n  service accounts: %s\n' "${VMS:-none}" "${SAS:-none}"
[ -z "$VMS$SAS" ] && { echo "Nothing to delete."; exit 0; }
[ "$DRY" = 1 ] && exit 0
if [ "$YES" != 1 ]; then read -r -p "Delete all of the above? [y/N] " ans; [ "$ans" = y ] || { echo "Aborted."; exit 1; }; fi
echo "$VMS" | while read -r name zone; do [ -n "$name" ] && g compute instances delete "$name" --zone="$zone" && echo "deleted VM $name"; done
for e in $SAS; do
  [ "$e" = "$SA_EMAIL" ] && g projects remove-iam-policy-binding "$PROJECT" --member="serviceAccount:$e" --role="roles/bigquery.user" --condition=None >/dev/null && echo "removed BigQuery User binding"
  g iam service-accounts delete "$e" && echo "deleted service account $e"
done
echo "Remaining lab VMs: $(g compute instances list --filter="name=(report-vm control-vm)" --format="value(name)" | grep -c .)"
echo "LAB5_ROLLBACK_DONE"
