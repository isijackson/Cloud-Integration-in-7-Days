#!/usr/bin/env bash
# Week 4 Lab 4.5 rollback: Ingress, certificate, BackendConfig, secret, static IP.  rollback-lab4-3.sh <PROJECT_ID> [-n] [-y]
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> [-n] [-y]}"; shift; DRY=0; YES=0
for a in "$@"; do case "$a" in -n) DRY=1;; -y) YES=1;; *) echo "usage"; exit 2;; esac; done
g() { gcloud "$@" --project="$PROJECT" --quiet 2>/dev/null; }
ING=$(kubectl get ingress timesheet-ingress -o name 2>/dev/null); IPR=$(g compute addresses list --global --filter="name=timesheet-ip" --format="value(name,address)")
echo "Lab 4.5 resources:"; printf '  ingress: %s\n  static IP: %s\n' "${ING:-none}" "${IPR:-none}"
[ -z "$ING$IPR" ] && { echo "Nothing to delete."; exit 0; }; [ "$DRY" = 1 ] && exit 0
if [ "$YES" != 1 ]; then read -r -p "Delete all of the above? [y/N] " ans; [ "$ans" = y ] || { echo "Aborted."; exit 1; }; fi
kubectl delete ingress timesheet-ingress --ignore-not-found; kubectl delete managedcertificate timesheet-cert --ignore-not-found; kubectl delete backendconfig iap-config --ignore-not-found; kubectl delete secret iap-oauth --ignore-not-found
kubectl annotate service frontend cloud.google.com/backend-config- 2>/dev/null; sleep 30
[ -n "$IPR" ] && g compute addresses delete timesheet-ip --global && echo "released static IP"
echo "LAB4_3_ROLLBACK_DONE"
