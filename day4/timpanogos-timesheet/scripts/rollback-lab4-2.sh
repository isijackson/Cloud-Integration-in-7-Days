#!/usr/bin/env bash
# Week 4 Lab 4.4 rollback: workloads, services (releases the LB IP), the cluster, the registry images.
#   rollback-lab4-2.sh <PROJECT_ID> [-n] [-y] [--keep-cluster]
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> [-n] [-y] [--keep-cluster]}"; shift; DRY=0; YES=0; KEEP=0
for a in "$@"; do case "$a" in -n) DRY=1;; -y) YES=1;; --keep-cluster) KEEP=1;; *) echo "usage"; exit 2;; esac; done
ZONE="${ZONE:-us-central1-a}"; REGION="${REGION:-us-central1}"; CLUSTER="${CLUSTER:-timpanogos}"; CLUSTER_LOC="${CLUSTER_LOC:-$ZONE}"
g() { gcloud "$@" --project="$PROJECT" --quiet 2>/dev/null; }
C=$(g container clusters list --filter="name=$CLUSTER" --format="value(name,location)")
# use the zone the cluster is really in, and its region for the registry
L=$(awk 'NR==1{print $2}' <<<"$C")
if [ -n "$L" ]; then CLUSTER_LOC="$L"; case "$L" in *-[a-z]) REGION="${L%-*}";; *) REGION="$L";; esac; fi
AR=$(g artifacts repositories list --location="$REGION" --filter="name~timesheet" --format="value(name)")
echo "Lab 4.4 resources in $PROJECT:"; printf '  cluster: %s\n  artifact repo: %s\n' "${C:-none}" "${AR:-none}"
[ -z "$C$AR" ] && { echo "Nothing to delete."; exit 0; }; [ "$DRY" = 1 ] && exit 0
if [ "$YES" != 1 ]; then read -r -p "Delete all of the above? [y/N] " ans; [ "$ans" = y ] || { echo "Aborted."; exit 1; }; fi
if [ -n "$C" ] && g container clusters get-credentials "$CLUSTER" --location="$CLUSTER_LOC" >/dev/null; then
  kubectl delete ingress timesheet-ingress --ignore-not-found; kubectl delete -f "$(dirname "$0")/../k8s/rendered/" --ignore-not-found 2>/dev/null || kubectl delete deploy,svc backend frontend --ignore-not-found
  echo "workloads and services deleted"; sleep 20
  [ "$KEEP" = 1 ] && echo "cluster kept" || { g container clusters delete "$CLUSTER" --location="$CLUSTER_LOC" && echo "deleted cluster $CLUSTER"; }
fi
[ -n "$AR" ] && g artifacts repositories delete "${AR##*/}" --location="$REGION" && echo "deleted artifact repo"
echo "LAB4_2_ROLLBACK_DONE"
