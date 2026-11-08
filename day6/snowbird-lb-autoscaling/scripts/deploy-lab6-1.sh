#!/usr/bin/env bash
# Week 6 Lab 6.2 deploy: web tier as a managed instance group (2 x e2-small, NGINX, hostname page),
# an HAProxy load-balancer VM with health checks and a stats page, firewall rules, alternation proof
# and the failure drill. Cloudflare DNS/CDN is a console step (see README); the script prints the IP to use.
#   deploy-lab6-1.sh <PROJECT_ID>
set -euo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID>}"; ZONE="${ZONE:-us-central1-a}"; D=$(cd "$(dirname "$0")/.." && pwd)
g() { gcloud "$@" --project="$PROJECT" --quiet; }
echo "== Part 1: template, group of 2, firewall"
g compute instance-templates describe web-template >/dev/null 2>&1 || g compute instance-templates create web-template --machine-type=e2-small \
  --image-family=debian-12 --image-project=debian-cloud --tags=web --metadata-from-file=startup-script="$D/config/web-startup.sh"
g compute instance-groups managed describe web-group --zone="$ZONE" >/dev/null 2>&1 || g compute instance-groups managed create web-group --template=web-template --size=2 --zone="$ZONE"
g compute firewall-rules describe allow-web-80 >/dev/null 2>&1 || g compute firewall-rules create allow-web-80 --allow=tcp:80 --target-tags=web,lb
g compute instance-groups managed wait-until web-group --stable --zone="$ZONE" --timeout=300
g compute instances list --filter='name~^web-group' --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,status)"
echo "== Part 2: lb-vm with HAProxy (startup script) and the Compute Viewer role so it can list the group"
SA=$(g iam service-accounts list --filter="displayName:'Compute Engine default service account'" --format="value(email)")
g projects add-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA" --role=roles/compute.viewer --condition=None >/dev/null
g compute instances describe lb-vm --zone="$ZONE" >/dev/null 2>&1 || g compute instances create lb-vm --zone="$ZONE" --machine-type=e2-medium --image-family=debian-12 --image-project=debian-cloud --tags=lb \
  --scopes=https://www.googleapis.com/auth/cloud-platform --metadata-from-file=startup-script="$D/config/lb-startup.sh",refresh-script="$D/config/refresh-backends.sh"
MYIP=$(curl -s https://checkip.amazonaws.com); g compute firewall-rules describe allow-stats >/dev/null 2>&1 || g compute firewall-rules create allow-stats --allow=tcp:8404 --target-tags=lb --source-ranges="$MYIP/32"
LB=$(g compute instances describe lb-vm --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs[0].natIP)'); echo "LB_IP=$LB"
echo "== checkpoint: the balancer alternates between both backends"
for i in $(seq 1 60); do curl -sf -m 5 "http://$LB/" >/dev/null && break; sleep 5; done
for i in 1 2 3 4 5 6; do curl -s -m 5 "http://$LB/" | grep -o "served by [a-z0-9-]*"; done; curl -s -m 10 "http://$LB/buy"; echo
curl -sI "http://$LB/static.txt" | head -1
set +e
echo "== Part 4: failure drill: stop one web instance, the domain (balancer) keeps answering"
V1=$(g compute instances list --filter='name~^web-group' --format='value(name)' | head -1)
g compute instances stop "$V1" --zone="$ZONE" >/dev/null; echo "stopped $V1; polling the balancer for 30 s"
for i in $(seq 1 10); do curl -s -m 5 "http://$LB/" | grep -o 'served by [a-z0-9-]*'; sleep 3; done | sort | uniq -c
curl -s -m 5 "http://$LB:8404/;csv" 2>/dev/null | awk -F, '$1=="web_pool" && $2!="BACKEND"{print "  haproxy:", $2, $18}' || true
for i in 1 2 3 4 5 6; do g compute instances start "$V1" --zone="$ZONE" >/dev/null 2>&1 && { echo "started $V1 again (the MIG may also have recreated it)"; break; }; sleep 10; done
echo "Cloudflare: add an A record 'passes' -> $LB, Proxied (orange cloud); then curl -sI https://passes.<DOMAIN> | grep -i cf-cache-status"
echo "LAB6_1_DEPLOY_DONE"
