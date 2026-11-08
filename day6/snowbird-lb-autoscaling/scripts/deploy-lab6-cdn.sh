#!/usr/bin/env bash
# Week 6 Lab 6.2 Part 3, option B: a Google Cloud global external Application Load Balancer (EXTERNAL_MANAGED, not the
# classic one) with Cloud CDN
# in front of web-group. No domain and no Cloudflare account needed: the balancer gets a global IP, and
# HTTPS comes from a Google-managed certificate on the <ip>.nip.io name. Run after deploy-lab6-1.sh Part 1
# (the group must exist). Option A (Cloudflare) stays a console step for teams that own a domain.
#   deploy-lab6-cdn.sh <PROJECT_ID>        ZONE (default us-central1-a) must match the group's zone
set -euo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID>}"; ZONE="${ZONE:-us-central1-a}"
g() { gcloud "$@" --project="$PROJECT" --quiet; }
echo "== Part 3B.1: named port, health-check firewall rule, health check"
g compute instance-groups managed set-named-ports web-group --zone="$ZONE" --named-ports=http:80
g compute firewall-rules describe allow-health-checks >/dev/null 2>&1 || g compute firewall-rules create allow-health-checks \
  --allow=tcp:80 --target-tags=web --source-ranges=130.211.0.0/22,35.191.0.0/16   # Google's health-check and proxy ranges
g compute health-checks describe web-hc >/dev/null 2>&1 || g compute health-checks create http web-hc --port=80 --request-path=/static.txt --check-interval=10s --timeout=5s
echo "== Part 3B.2: backend service with Cloud CDN, the group as its backend"
g compute backend-services describe web-backend --global >/dev/null 2>&1 || g compute backend-services create web-backend --global --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP --port-name=http --health-checks=web-hc --enable-cdn --cache-mode=CACHE_ALL_STATIC --default-ttl=3600 --enable-logging --logging-sample-rate=1
g compute backend-services describe web-backend --global --format='value(backends[].group)' | grep -q web-group || \
  g compute backend-services add-backend web-backend --global --instance-group=web-group --instance-group-zone="$ZONE" --balancing-mode=UTILIZATION --max-utilization=0.8
echo "== Part 3B.3: URL map, HTTP proxy, global IP, forwarding rule"
g compute url-maps describe web-map >/dev/null 2>&1 || g compute url-maps create web-map --default-service=web-backend
g compute target-http-proxies describe web-http-proxy >/dev/null 2>&1 || g compute target-http-proxies create web-http-proxy --url-map=web-map
g compute addresses describe web-cdn-ip --global >/dev/null 2>&1 || g compute addresses create web-cdn-ip --global
CDN=$(g compute addresses describe web-cdn-ip --global --format='value(address)'); HOST="${CDN//./-}.nip.io"; echo "CDN_IP=$CDN  HOSTNAME=$HOST"
g compute forwarding-rules describe web-http-rule --global >/dev/null 2>&1 || g compute forwarding-rules create web-http-rule --global --load-balancing-scheme=EXTERNAL_MANAGED --address=web-cdn-ip --target-http-proxy=web-http-proxy --ports=80
echo "== Part 3B.4: HTTPS with a Google-managed certificate on $HOST (Active after 15 to 30 minutes; HTTP works meanwhile)"
g compute ssl-certificates describe web-cert --global >/dev/null 2>&1 || g compute ssl-certificates create web-cert --global --domains="$HOST"
g compute target-https-proxies describe web-https-proxy >/dev/null 2>&1 || g compute target-https-proxies create web-https-proxy --url-map=web-map --ssl-certificates=web-cert
g compute forwarding-rules describe web-https-rule --global >/dev/null 2>&1 || g compute forwarding-rules create web-https-rule --global --load-balancing-scheme=EXTERNAL_MANAGED --address=web-cdn-ip --target-https-proxy=web-https-proxy --ports=443
echo "== checkpoint: the balancer answers (programming takes 3 to 5 minutes), the HTML stays dynamic, static.txt is served from the cache"
# while the balancer is still being programmed some requests get Google's own 404 page, so wait for five answers in a row from a backend
ok=0; for i in $(seq 1 90); do if curl -s -m 5 "http://$CDN/" | grep -q "served by"; then ok=$((ok+1)); [ $ok -ge 5 ] && break; else ok=0; fi; sleep 5; done
for i in 1 2 3 4 5 6; do curl -s -m 5 "http://$CDN/" | grep -o "served by [a-z0-9-]*" || echo "(not from a backend yet)"; done
echo "-- static.txt three times with GET (a HEAD request, curl -I, never fills the cache): the first is a MISS (no age header), the next ones a HIT (age counts up)"
for i in 1 2 3; do curl -s -m 8 -o /dev/null -D - "http://$CDN/static.txt" | grep -i -E "^(HTTP/|age:|cache-control:|via:)" || echo "(no answer yet)"; echo; sleep 2; done
echo "-- the balancer's own log says the same (cacheHit true/false; allow a minute for entries to appear)"
sleep 60; g logging read 'resource.type="http_load_balancer" httpRequest.requestUrl:"static.txt"' --limit=5 --format='table(timestamp,httpRequest.requestUrl,httpRequest.cacheLookup,httpRequest.cacheHit,httpRequest.status)' || true
g compute ssl-certificates describe web-cert --global --format='value(managed.status)' | sed 's/^/certificate: /'
echo "HTTPS test once the certificate is ACTIVE:  curl -s -o /dev/null -D - https://$HOST/static.txt | grep -i -E '^(HTTP/|age:)'"
echo "LAB6_CDN_DEPLOY_DONE"
