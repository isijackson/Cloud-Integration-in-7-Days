#!/usr/bin/env bash
# Week 6 Lab 6.3 deploy: autoscaling on web-group (min 2, max 6, 60% CPU), a Locust VM, the Cloud
# Monitoring dashboard, then two headless Locust runs (200 users, 2000 users) with instance counts recorded.
#   deploy-lab6-2.sh <PROJECT_ID>        RUN_MINUTES (default 5) controls each run's length
set -euo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID>}"; ZONE="${ZONE:-us-central1-a}"; D=$(cd "$(dirname "$0")/.." && pwd); RUN_MINUTES="${RUN_MINUTES:-5}"
g() { gcloud "$@" --project="$PROJECT" --quiet; }
echo "== Part 1: autoscaling"
g compute instance-groups managed set-autoscaling web-group --zone="$ZONE" --min-num-replicas=2 --max-num-replicas=6 --target-cpu-utilization=0.6 --cool-down-period=90 >/dev/null
g compute instance-groups managed describe web-group --zone="$ZONE" --format='yaml(autoscaler.autoscalingPolicy)'
LB=$(g compute instances describe lb-vm --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
echo "== Part 2: locust-vm"
g compute instances describe locust-vm --zone="$ZONE" >/dev/null 2>&1 || g compute instances create locust-vm --zone="$ZONE" --machine-type=e2-medium --image-family=debian-12 --image-project=debian-cloud --tags=locust
MYIP=$(curl -s https://checkip.amazonaws.com); g compute firewall-rules describe allow-locust-ui >/dev/null 2>&1 || g compute firewall-rules create allow-locust-ui --allow=tcp:8089 --target-tags=locust --source-ranges="$MYIP/32"
SSHF=""; sshvm() { gcloud compute ssh locust-vm --project="$PROJECT" --zone="$ZONE" --quiet $SSHF --command="$*" 2>/dev/null; }
for i in $(seq 1 12); do sshvm true && break; SSHF="--tunnel-through-iap"; sshvm true && break; SSHF=""; sleep 10; done
gcloud compute scp "$D/config/locustfile.py" locust-vm:~/locustfile.py --project="$PROJECT" --zone="$ZONE" --quiet $SSHF 2>/dev/null
sshvm 'sudo apt-get update -qq >/dev/null; sudo apt-get install -y -qq python3-venv >/dev/null; [ -d ~/lt ] || python3 -m venv ~/lt; ~/lt/bin/pip install -q locust; ~/lt/bin/locust --version'
echo "== Part 3: dashboard"
g monitoring dashboards list --filter="displayName='Snowbird launch test'" --format="value(name)" | grep -q . || g monitoring dashboards create --config-from-file="$D/config/dashboard.json" >/dev/null
echo "dashboard: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT"
count() { g compute instance-groups managed list-instances web-group --zone="$ZONE" --format="value(name)" | grep -c .; }
run() { local users=$1 rate=$2; echo "-- Locust run: $users users, spawn $rate, ${RUN_MINUTES}m against http://$LB"
  sshvm "cd ~ && ~/lt/bin/locust -f locustfile.py --host=http://$LB --headless -u $users -r $rate --run-time ${RUN_MINUTES}m --csv=run_$users --only-summary 2>&1 | tail -8"
  echo "instances in web-group after the run: $(count)"; }
echo "== Part 4: two runs"; echo "instances before: $(count)"
run 200 20
run 2000 100
echo "== scale-in: waiting up to 15 minutes for the group to return to 2"
for i in $(seq 1 30); do c=$(count); echo "$(date +%T) instances=$c"; [ "$c" -le 2 ] && break; sleep 30; done
echo "LAB6_2_DEPLOY_DONE"
