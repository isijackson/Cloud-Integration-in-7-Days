#!/usr/bin/env bash
# Week 6 rollback (both labs): locust-vm, lb-vm, web-group, web-template, the four firewall rules,
# the Cloud CDN balancer (deploy-lab6-cdn.sh), the dashboard and the Compute Viewer grant. Cloudflare record: delete in the Cloudflare console.
#   rollback-lab6.sh <PROJECT_ID> [-n] [-y]
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> [-n] [-y]}"; shift; DRY=0; YES=0
for a in "$@"; do case "$a" in -n) DRY=1;; -y) YES=1;; *) echo "usage"; exit 2;; esac; done
ZONE="${ZONE:-us-central1-a}"; g() { gcloud "$@" --project="$PROJECT" --quiet 2>/dev/null; }
VMS=$(g compute instances list --filter="name=(locust-vm lb-vm)" --format="value(name)" | tr '\n' ' ')
MIG=$(g compute instance-groups managed list --filter="name=web-group" --format="value(name)"); TPL=$(g compute instance-templates list --filter="name=web-template" --format="value(name)")
FW=$(g compute firewall-rules list --filter="name=(allow-web-80 allow-stats allow-locust-ui allow-health-checks)" --format="value(name)" | tr '\n' ' ')
LBR=$(g compute forwarding-rules list --global --filter="name=(web-http-rule web-https-rule)" --format="value(name)" | tr "\n" " ")
# the rest of the Cloud CDN balancer is looked up on its own: deploy-lab6-cdn.sh can stop after creating web-backend (which uses
# web-group) and before the forwarding rules, and web-group cannot be deleted while a backend service still references it
CDNX=$( { g compute target-https-proxies list --filter="name=web-https-proxy" --format="value(name)"; g compute target-http-proxies list --filter="name=web-http-proxy" --format="value(name)"
  g compute ssl-certificates list --filter="name=web-cert" --format="value(name)"; g compute url-maps list --filter="name=web-map" --format="value(name)"
  g compute backend-services list --filter="name=web-backend" --format="value(name)"; g compute health-checks list --filter="name=web-hc" --format="value(name)"
  g compute addresses list --filter="name=web-cdn-ip" --format="value(name)"; } | tr "\n" " "); CDNALL="$LBR$CDNX"
DB=$(g monitoring dashboards list --filter="displayName='Snowbird launch test'" --format="value(name)")
echo "Week 6 resources in $PROJECT:"; printf '  VMs: %s\n  MIG: %s\n  template: %s\n  firewall: %s\n  CDN balancer: %s\n  dashboard: %s\n' "${VMS:-none}" "${MIG:-none}" "${TPL:-none}" "${FW:-none}" "${CDNALL:-none}" "${DB:-none}"
[ -z "$VMS$MIG$TPL$FW$LBR$CDNX$DB" ] && { echo "Nothing to delete."; exit 0; }; [ "$DRY" = 1 ] && exit 0
if [ "$YES" != 1 ]; then read -r -p "Delete all of the above? [y/N] " ans; [ "$ans" = y ] || { echo "Aborted."; exit 1; }; fi
if [ -n "$LBR$CDNX" ]; then   # each delete is skipped quietly if that object does not exist
  for r in $LBR; do g compute forwarding-rules delete "$r" --global; done; g compute target-https-proxies delete web-https-proxy --global; g compute target-http-proxies delete web-http-proxy --global
  g compute ssl-certificates delete web-cert --global; g compute url-maps delete web-map --global; g compute backend-services delete web-backend --global
  g compute health-checks delete web-hc --global; g compute addresses delete web-cdn-ip --global; echo "deleted the Cloud CDN balancer"
fi
# delete each VM and the group in the zone it is really in, not only $ZONE
for v in $VMS; do z=$(g compute instances list --filter="name=$v" --format="value(zone.basename())"); g compute instances delete "$v" --zone="${z:-$ZONE}" && echo "deleted $v"; done
MZ=$(g compute instance-groups managed list --filter="name=web-group" --format="value(zone.basename())")
[ -n "$MIG" ] && g compute instance-groups managed delete web-group --zone="${MZ:-$ZONE}" && echo "deleted web-group"
[ -n "$TPL" ] && g compute instance-templates delete web-template && echo "deleted web-template"
for f in $FW; do g compute firewall-rules delete "$f" && echo "deleted rule $f"; done
[ -n "$DB" ] && g monitoring dashboards delete "$DB" && echo "deleted dashboard"
SA=$(g iam service-accounts list --filter="displayName:'Compute Engine default service account'" --format="value(email)")
[ -n "$SA" ] && g projects remove-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA" --role=roles/compute.viewer --condition=None >/dev/null && echo "removed Compute Viewer grant"
echo "LAB6_ROLLBACK_DONE"
