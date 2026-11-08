#!/usr/bin/env bash
# Week 4 Lab 4.5 deploy: IAP in front of the frontend Service through a GKE Ingress with a BackendConfig
# and a Google-managed certificate on a nip.io hostname. Needs an OAuth client (consent screen done in
# the console) passed as CLIENT_ID and CLIENT_SECRET, and Lab 4.4 running on GKE.
#   CLIENT_ID=... CLIENT_SECRET=... deploy-lab4-3.sh <PROJECT_ID> [member-to-grant ...]
set -euo pipefail
PROJECT="${1:?usage: CLIENT_ID=.. CLIENT_SECRET=.. $0 <PROJECT_ID> [user:someone@example.com ...]}"; shift
: "${CLIENT_ID:?set CLIENT_ID}"; : "${CLIENT_SECRET:?set CLIENT_SECRET}"
D=$(cd "$(dirname "$0")/.." && pwd); g() { gcloud "$@" --project="$PROJECT" --quiet; }
echo "== Part 1: services"; g services enable iap.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com iam.googleapis.com >/dev/null
# IAP writes one audit entry per authorization decision only when Data Access logs are on for it (off by default); Part 5 reads them
P=$(mktemp); gcloud projects get-iam-policy "$PROJECT" --format=json > "$P"
python3 - "$P" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); ac = d.setdefault("auditConfigs", [])
if not any(c.get("service") == "iap.googleapis.com" for c in ac):
    ac.append({"service": "iap.googleapis.com", "auditLogConfigs": [{"logType": "ADMIN_READ"}, {"logType": "DATA_READ"}, {"logType": "DATA_WRITE"}]})
    json.dump(d, open(p, "w")); print("IAP data-access audit logs: enabled")
else: print("IAP data-access audit logs: already on")
PY
g projects set-iam-policy "$PROJECT" "$P" >/dev/null; rm -f "$P"
echo "== Part 2: OAuth pair as a Kubernetes secret"
kubectl create secret generic iap-oauth --from-literal=client_id="$CLIENT_ID" --from-literal=client_secret="$CLIENT_SECRET" --dry-run=client -o yaml | kubectl apply -f -
echo "== Part 3: static IP, hostname, Ingress + BackendConfig + ManagedCertificate"
g compute addresses describe timesheet-ip --global >/dev/null 2>&1 || g compute addresses create timesheet-ip --global
IP=$(g compute addresses describe timesheet-ip --global --format='value(address)'); HOST="${IP//./-}.nip.io"; echo "HOSTNAME=$HOST"
mkdir -p "$D/k8s/rendered"; sed "s|HOSTNAME|$HOST|g" "$D/k8s/iap.yaml" > "$D/k8s/rendered/iap.yaml"
kubectl annotate service frontend cloud.google.com/backend-config='{"default": "iap-config"}' --overwrite
kubectl apply -f "$D/k8s/rendered/iap.yaml"
echo "== Part 4: grant access by IAM role, never by code"
# the GKE ingress controller writes the backends annotation only after it has created the backend service, minutes after the apply
BS=""; if [ "$#" -gt 0 ]; then for i in $(seq 1 40); do
  BS=$(kubectl get ingress timesheet-ingress -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/backends}' 2>/dev/null | grep -o 'k8s[0-9a-z-]*frontend[0-9a-z-]*' | head -1 || true)
  [ -n "$BS" ] && break; echo "$(date +%T) waiting for the frontend backend service"; sleep 15; done; fi
for m in "$@"; do [ -n "$BS" ] && g iap web add-iam-policy-binding --resource-type=backend-services --service="$BS" --member="$m" --role=roles/iap.httpsResourceAccessor 2>/dev/null || echo "grant $m in Console → Security → Identity-Aware Proxy once the backend appears"; done
echo "== waiting for the managed certificate (15 to 30 minutes typical)"
for i in $(seq 1 60); do S=$(kubectl get managedcertificate timesheet-cert -o jsonpath='{.status.certificateStatus}' 2>/dev/null); echo "$(date +%T) cert=$S"; [ "$S" = Active ] && break; sleep 30; done
kubectl get ingress timesheet-ingress
echo "Open https://$HOST in a private window: Google sign-in first, then the app for granted accounts, 'You don't have access' for others."
echo "Then remove the plain-HTTP path from Lab 4.4: kubectl patch service frontend -p '{\"spec\":{\"type\":\"ClusterIP\"}}'  (kubectl get svc frontend: no EXTERNAL-IP)"
echo "Logs: gcloud logging read 'resource.type=\"iap_web\"' --limit=20 --project=$PROJECT --format='table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.status.message)'"
echo "LAB4_3_DEPLOY_DONE"
