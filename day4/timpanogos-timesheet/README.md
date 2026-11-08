# Day 4 labs: the Timpanogos timesheet

Book: **Day 4: A real application, locked down**, Afternoon parts one, two and three. Script comments call these "Week 4 Lab 4.3", "Lab 4.4" and "Lab 4.5".

A home-health agency's visit timesheet: a React form (frontend) and an Express API with an in-memory list (backend). Part one runs it on a laptop in two containers; part two puts it on GKE with only the frontend public; part three puts Identity-Aware Proxy in front so only staff granted an IAM role get in, and the refusal shows in the audit log.

This folder is also what you push to your own repository in part one, Step 6.

## Files

| File | What it does |
|---|---|
| `backend/index.js` | The whole API: three routes (`/api/health`, and GET and POST `/api/timesheet`) and an in-memory list. |
| `backend/package.json`, `backend/package-lock.json` | The API's dependencies, Express and cors, with pinned versions. |
| `backend/Dockerfile`, `backend/.dockerignore` | The seven-line backend image; keeps local `node_modules` and `dist` out of the build. |
| `frontend/src/App.jsx`, `frontend/src/main.jsx`, `frontend/index.html` | The form and the list, with the relative `fetch('/api/timesheet')`; the mount point; the page Vite builds around it. |
| `frontend/vite.config.js` | The dev server on port 3000 with the `/api` proxy to port 5000. |
| `frontend/nginx.conf` | The production web server: static files, and `/api/` proxied to `backend:5000` with a two-second timeout. |
| `frontend/Dockerfile`, `frontend/.dockerignore` | The two-stage build: Node builds the app, NGINX serves it. |
| `frontend/package.json`, `frontend/package-lock.json` | React, Vite and the `dev` and `build` scripts. |
| `k8s/backend.yaml` | The backend Deployment (readiness probe on `/api/health`) and its `ClusterIP` Service. Placeholder `IMAGE_BACKEND`. |
| `k8s/frontend.yaml` | The frontend Deployment (2 replicas) and its `LoadBalancer` Service, with the NEG annotation part three needs. Placeholder `IMAGE_FRONTEND`. |
| `k8s/iap.yaml` | Part three: the BackendConfig with IAP on, the ManagedCertificate and the Ingress. Placeholder `HOSTNAME`. |
| `mcp/server.js`, `mcp/test.js`, `mcp/package.json`, `mcp/package-lock.json` | Add-on from the DevOps section: an MCP server that wraps the API in three tools for an AI agent, and a test that drives it as a client would. |
| `scripts/deploy-lab4-1.sh` | Part one, Steps 3 to 5: build both images, run them on a shared network, submit three visits, stop the backend. `TAG` optional (default `1.0`). |
| `scripts/deploy-lab4-2.sh <PROJECT_ID>` | Part two: push both images, create or reuse the cluster, apply the manifests, wait for the external IP, submit a visit, prove the backend is private. |
| `scripts/deploy-lab4-3.sh <PROJECT_ID> [member ...]` | Part three, Steps 1 and 6 to 9, once the console steps are done. Needs `CLIENT_ID` and `CLIENT_SECRET` in the environment. |
| `scripts/rollback-lab4-1.sh [-n] [-y]` | Removes the containers, the network and the local images. |
| `scripts/rollback-lab4-2.sh <PROJECT_ID> [-n] [-y] [--keep-cluster]` | Removes the workloads, the Services (releasing the load balancer IP), the cluster and the registry images. |
| `scripts/rollback-lab4-3.sh <PROJECT_ID> [-n] [-y]` | Removes the Ingress, certificate, BackendConfig, secret and the static IP. |

The manifests carry placeholders so that no project name is ever in the repository. Part two, Step 2 and part three, Step 7 write filled-in copies to `k8s/rendered/`, and `kubectl` applies those.

## Prerequisites

| Part | Accounts | Tools (Day 0) |
|---|---|---|
| One | GitHub for Step 6 (or use the website) | Docker Desktop running, Node.js 20 or newer, `git`, `gh` |
| Two | A Google Cloud project with billing | `gcloud` with the GKE auth plugin, `kubectl`, Docker Desktop |
| Three | The same project, plus a second Google account that holds no role in it (the departed nurse) | The same `gcloud` and `kubectl`, and a browser for the console steps |

Part one cannot run in Cloud Shell; it needs Docker on the laptop.

```bash
cd ~/Cloud-Integration-in-7-Days/day4/timpanogos-timesheet
node --version
docker info --format '{{.ServerVersion}}'
gh auth status
gcloud auth login                         # parts two and three
gcloud config set project seven-day-cloud
kubectl version --client
```

## Mac and Windows

- **Mac.** Port 5000 belongs to AirPlay Receiver, so the backend publishes on host port **5001**: `-p 5001:5000` in Step 3, and in Step 1 `PORT=5001 node index.js` with the `vite.config.js` proxy changed to 5001 (Step 1's "If it fails" line), or switch AirPlay Receiver off for the afternoon. On Apple Silicon, part two's `--platform linux/amd64` flag is essential: the cluster's nodes are x86.
- **Windows (WSL Ubuntu).** Port 5000 is free; use 5000 as printed. Run `npm` and `docker` in the Ubuntu terminal, keep the folder in the Linux home, and open http://localhost:3000 in the Windows browser or with `explorer.exe http://localhost:3000`. An apt-installed `gcloud` refuses `gcloud components install kubectl`; Day 0's apt line already installed `kubectl` and the plugin.

## Values to edit first

| Item | Book value | Override with (scripts) |
|---|---|---|
| Project | `seven-day-cloud` | the `<PROJECT_ID>` argument |
| Region and zone | `us-east1`, `us-east1-b` (the course and the scripts default to `us-central1-a`) | `export ZONE=us-east1-b REGION=us-east1` |
| Registry prefix | `us-east1-docker.pkg.dev/seven-day-cloud/timesheet` | `PFX` in part two, Step 1; `REGISTRY=<dockerhub user>` makes the script push to Docker Hub instead |
| Cluster | `timpanogos`, Standard, one e2-medium node | `CLUSTER` |
| OAuth client | `timesheet-iap` | `CLIENT_ID`, `CLIENT_SECRET` (from the console, part three Step 4) |
| Hostname | `<your-ip-with-dashes>.nip.io` on the static address `timesheet-ip` | `HOST` in part three, Step 7 |
| Granted account | `nurse@example.com` | the `user:<email>` argument to `deploy-lab4-3.sh` |

## Run order

### Part one: build and containerize

By hand (do this first): Step 1 runs the API with `cd backend && npm install && node index.js`, Step 2 the UI with `cd frontend && npm install && npm run dev`. Step 3 builds and runs the containers:

```bash
docker network create timesheet
docker build -t timesheet-backend:1.0 ./backend
docker build -t timesheet-frontend:1.0 ./frontend
docker run -d --name backend --network timesheet \
    -p 5000:5000 timesheet-backend:1.0          # 5001:5000 on a Mac
docker run -d --name frontend --network timesheet \
    -p 3000:3000 timesheet-frontend:1.0
```

Open http://localhost:3000 and submit three visits (Step 4); stop the backend and watch the page fail fast (Step 5); push the repository and let a teammate run it cold (Step 6). Scripted, Steps 3 to 5 in one minute:

```bash
bash scripts/deploy-lab4-1.sh
```

**Expected:** three saved visits listed through port 3000, and with the backend stopped the page fails fast instead of hanging (`nginx.conf` gives the backend two seconds to connect).

### Part two: Kubernetes with a private backend

By hand: Steps 1 to 8 in the chapter (push both images with `--platform linux/amd64`, render the manifests into `k8s/rendered/`, create the cluster, apply, wait for the external IP, open it on a phone, prove the backend is private, scale the frontend). Scripted, about seven and a half minutes:

```bash
export ZONE=us-east1-b REGION=us-east1
bash scripts/deploy-lab4-2.sh seven-day-cloud
```

**Expected:** `backend` 1/1 behind a `ClusterIP` Service, `frontend` 2/2 behind a `LoadBalancer` Service with an external IP, a visit saved through that IP, and the backend unreachable from outside the cluster. The script prints `EXTERNAL_IP=`.

### Part three: staff-only access with IAP

Steps 2 to 5 are console only (consent screen, test users, the OAuth client, its redirect URI). Then, by hand, Steps 6 to 12, or scripted for Steps 1 and 6 to 9:

```bash
CLIENT_ID=... CLIENT_SECRET=... bash scripts/deploy-lab4-3.sh seven-day-cloud user:nurse@example.com
```

A leading space on an `export CLIENT_ID=... CLIENT_SECRET=...` line keeps the secret out of the shell history. Waiting for the Google-managed certificate is the long part: eighteen minutes in the book's run.

**Expected:** the granted account signs in and reaches the app at `https://<your-hostname>`; once Step 11 removes the grant, the same account is refused before any app content loads; `gcloud logging read` shows the `AuthorizeUser` entries for both. Enable the IAP Data Access audit logs (Step 1) **before** you test, or there is nothing to read.

## Add-on: the MCP server

From the DevOps section, against the part one backend container (port 5001 on a Mac):

```bash
cd mcp && npm install && TIMESHEET_API=http://localhost:5001 npm test
```

It prints `add_visit with a patient NAME: rejected by the schema (good)`.

## Clean up

Part three first, then part two, then the laptop:

```bash
bash scripts/rollback-lab4-3.sh seven-day-cloud -y
bash scripts/rollback-lab4-2.sh seven-day-cloud -y
bash scripts/rollback-lab4-1.sh -y
```

Export the same `ZONE` and `REGION` you deployed with first. By hand: `kubectl delete -f k8s/rendered/iap.yaml` and `gcloud compute addresses delete timesheet-ip --global`; then `kubectl delete -f k8s/rendered/`, `gcloud container clusters delete timpanogos --zone=us-east1-b` and `gcloud artifacts repositories delete timesheet --location=us-east1`; then `docker rm -f backend frontend && docker network rm timesheet`. Final check:

```bash
gcloud container clusters list
gcloud compute addresses list --global
gcloud artifacts repositories list --location=us-east1
```

Each should print `Listed 0 items.` The OAuth client and consent screen cost nothing and can stay.

## Cost

Part one: nothing. Part two: one e2-medium node and the GKE control plane, about 100 dollars a month, plus a few dollars for the load balancer. Part three: the global HTTPS load balancer, about 18 dollars a month, plus the reserved address (October 2026). The author's two days of runs came to under three dollars; left running, about 120 dollars a month. The cluster is the one you must not forget.

## When something fails

See the chapter's "If it fails" lines and field notes, the "Troubleshoot with an AI assistant" subsection of each part, and Appendix C, "Day 4".
