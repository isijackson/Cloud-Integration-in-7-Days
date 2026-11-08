#!/usr/bin/env bash
# Week 4 Lab 4.3 deploy: build both images, run them on a shared Docker network, submit three visits
# through the containerized frontend and prove they land in the containerized backend.
#   deploy-lab4-1.sh            (TAG env optional, default 1.0; images are local until Lab 4.4 pushes them)
set -euo pipefail
D=$(cd "$(dirname "$0")/.." && pwd); TAG="${TAG:-1.0}"; IMG="${IMG:-timesheet}"
echo "== Part 1 and 2: the app runs locally with node (backend) and vite (frontend) before any container"
( cd "$D/backend" && [ -f package-lock.json ] || npm install --silent >/dev/null 2>&1 ) ; ( cd "$D/frontend" && [ -f package-lock.json ] || npm install --silent >/dev/null 2>&1 )
echo "== Part 3: containers"
docker network inspect timesheet >/dev/null 2>&1 || docker network create timesheet >/dev/null
docker build -q -t "$IMG-backend:$TAG" "$D/backend" && docker build -q -t "$IMG-frontend:$TAG" "$D/frontend"
docker rm -f backend frontend >/dev/null 2>&1 || true
BP=5000; (lsof -nP -iTCP:5000 -sTCP:LISTEN >/dev/null 2>&1 || (command -v ss >/dev/null && ss -ltn | grep -q ':5000 ')) && { BP=5001; echo "host port 5000 is taken (macOS AirPlay Receiver); publishing the backend on $BP instead"; }
docker run -d --name backend --network timesheet -p $BP:5000 "$IMG-backend:$TAG" >/dev/null
docker run -d --name frontend --network timesheet -p 3000:3000 "$IMG-frontend:$TAG" >/dev/null
docker ps --filter name=backend --filter name=frontend --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
for i in $(seq 1 20); do curl -sf localhost:3000/api/health >/dev/null && break; sleep 1; done
echo "== three sample visits through the containerized frontend (nginx proxies /api to the backend container)"
for v in '{"nurseName":"R. Alder","patientCode":"P-1042","visitDate":"2026-11-10","hours":1.5}' \
         '{"nurseName":"M. Osei","patientCode":"P-2210","visitDate":"2026-11-10","hours":2}' \
         '{"nurseName":"R. Alder","patientCode":"P-3307","visitDate":"2026-11-11","hours":0.75}'; do
  curl -s -X POST localhost:3000/api/timesheet -H 'Content-Type: application/json' -d "$v"; echo; done
curl -s localhost:3000/api/timesheet | python3 -m json.tool
echo "== checkpoint: stop the backend, the UI must say 'Backend unreachable', not hang"
docker stop backend >/dev/null; curl -s -m 5 -o /dev/null -w "frontend /api with backend stopped -> HTTP %{http_code}\n" localhost:3000/api/timesheet; docker start backend >/dev/null
echo "Open http://localhost:3000 in a browser"
echo "LAB4_1_DEPLOY_DONE"
