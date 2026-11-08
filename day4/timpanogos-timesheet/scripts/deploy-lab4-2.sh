#!/usr/bin/env bash
# Week 4 Lab 4.4 deploy: push both images to a registry, create (or reuse) a GKE cluster, apply the
# manifests, wait for the frontend external IP, submit a visit, prove the backend is private.
#   deploy-lab4-2.sh <PROJECT_ID>
# Registry: REGISTRY=<dockerhub user> pushes to Docker Hub (docker login first). Default pushes to
# Artifact Registry in the project (no account needed): <REGION>-docker.pkg.dev/<PROJECT>/timesheet.
set -euo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID>}"; ZONE="${ZONE:-us-central1-a}"; REGION="${REGION:-us-central1}"
CLUSTER="${CLUSTER:-timpanogos}"; CLUSTER_LOC="${CLUSTER_LOC:-$ZONE}"; TAG="${TAG:-1.0}"
D=$(cd "$(dirname "$0")/.." && pwd); g() { gcloud "$@" --project="$PROJECT" --quiet; }
if [ -n "${REGISTRY:-}" ]; then PFX="$REGISTRY"; else
  PFX="$REGION-docker.pkg.dev/$PROJECT/timesheet"
  g services enable artifactregistry.googleapis.com container.googleapis.com >/dev/null
  g artifacts repositories describe timesheet --location="$REGION" >/dev/null 2>&1 || g artifacts repositories create timesheet --repository-format=docker --location="$REGION"
  gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet >/dev/null 2>&1
fi
echo "== Part 1: publish images to $PFX"
for s in backend frontend; do
  docker image inspect "timesheet-$s:$TAG" >/dev/null 2>&1 || docker build -q --platform linux/amd64 -t "timesheet-$s:$TAG" "$D/$s" >/dev/null
  docker build -q --platform linux/amd64 -t "$PFX/timesheet-$s:$TAG" "$D/$s" >/dev/null && docker push -q "$PFX/timesheet-$s:$TAG"; done
echo "== Part 3: cluster $CLUSTER"
if ! g container clusters describe "$CLUSTER" --location="$CLUSTER_LOC" --format="value(status)" 2>/dev/null | grep -q RUNNING; then
  g container clusters create "$CLUSTER" --num-nodes=1 --zone="$ZONE" --machine-type=e2-medium; fi
g container clusters get-credentials "$CLUSTER" --location="$CLUSTER_LOC"; kubectl get nodes
echo "== Part 2 and 4: manifests with the image names filled in, then deploy"
mkdir -p "$D/k8s/rendered"
sed "s|IMAGE_BACKEND|$PFX/timesheet-backend:$TAG|" "$D/k8s/backend.yaml" > "$D/k8s/rendered/backend.yaml"
sed "s|IMAGE_FRONTEND|$PFX/timesheet-frontend:$TAG|" "$D/k8s/frontend.yaml" > "$D/k8s/rendered/frontend.yaml"
kubectl apply -f "$D/k8s/rendered/backend.yaml" -f "$D/k8s/rendered/frontend.yaml"
kubectl rollout status deployment/backend --timeout=400s; kubectl rollout status deployment/frontend --timeout=400s
kubectl get deployments; kubectl get pods; 
for i in $(seq 1 40); do IP=$(kubectl get svc frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); [ -n "$IP" ] && break; sleep 10; done
kubectl get services; echo "EXTERNAL_IP=$IP"
for i in $(seq 1 30); do curl -sf -m 5 "http://$IP/api/health" >/dev/null && break; sleep 5; done
curl -s -X POST "http://$IP/api/timesheet" -H 'Content-Type: application/json' -d '{"nurseName":"R. Alder","patientCode":"P-1042","visitDate":"2026-11-10","hours":1.5}'; echo
curl -s "http://$IP/api/timesheet"; echo
echo "== Part 4, Validation 5: backend is private: port 5000 from the internet must fail, from inside the cluster must work"
curl -s -m 6 -o /dev/null -w "internet -> backend:5000  HTTP %{http_code} (000 = unreachable, correct)\n" "http://$IP:5000/api/timesheet" || true
kubectl run probe --rm -i --image=busybox:1.36 --restart=Never -- wget -qO- http://backend:5000/api/timesheet 2>/dev/null; echo
echo "== checkpoint: scale frontend to 3, external IP does not change"
kubectl scale deployment frontend --replicas=3 >/dev/null; sleep 5; kubectl get svc frontend
echo "Open http://$IP on a phone"; echo "LAB4_2_DEPLOY_DONE"
