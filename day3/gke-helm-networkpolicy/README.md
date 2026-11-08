# Day 3, part two: the credit union's cluster

Book: **Day 3: Containers and the orchestra**, Afternoon, part two: the credit union's cluster, Steps 1 to 12. Script comments call this "Week 3 Lab 3.2".

A GKE Autopilot cluster runs NGINX three ways: as a `kubectl` Deployment that heals itself when you delete a pod, as a Helm release you upgrade and roll back, and behind a NetworkPolicy that lets only pods labelled `role=frontend` in. The Helm chart itself is made with `helm create` during the lab, so it is not in this folder.

## Files

| File | What it does |
|---|---|
| `k8s/nginx-deployment.yaml` | The `loan-calc` Deployment, 3 replicas of `nginx:1.27` (Step 4). |
| `k8s/network-policy.yaml` | `loan-calc-frontend-only`: ingress to the app only from pods labelled `role=frontend` (Step 10). |
| `k8s/cluster.tf` | Stretch: the same Autopilot cluster as OpenTofu (validated, not applied in class). |
| `scripts/deploy-lab3-1.sh <PROJECT_ID>` | Steps 2 to 11 with every validation printed; skips the optional Step 6 and the Step 12 verification. A second run uninstalls the existing `loan-calc` release first, so the history again reads revisions 1, 2 and 3. |
| `scripts/rollback-lab3-1.sh <PROJECT_ID> [-n] [-y] [--keep-cluster]` | Deletes the Helm release, the policy, the Deployment, then the cluster. |

## Prerequisites

- **Accounts.** A Google Cloud project with billing and the Kubernetes Engine API on (Step 1 enables it).
- **Tools** (Day 0): `gcloud` with the GKE auth plugin, `kubectl` and `helm`. Cloud Shell has all three, signed in; clone this repository there first with the `git clone` line from the top-level README.
- **Check:**

```bash
cd ~/Cloud-Integration-in-7-Days/day3/gke-helm-networkpolicy
gcloud auth login
gcloud config set project seven-day-cloud
gke-gcloud-auth-plugin --version
```

Skip `gcloud auth login` in Cloud Shell. The plugin line must print a version, or `kubectl` cannot talk to the cluster after Step 3.

## Mac and Windows

- **Mac.** Homebrew's `kubernetes-cli` and `helm` from Day 0 cover both tools.
- **Windows (WSL Ubuntu).** An apt-installed `gcloud` refuses `gcloud components install kubectl`; `kubectl` and the plugin come from Day 0's apt line and `helm` from snap. If one is missing: `sudo apt-get install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin`.

## Values to edit first

| Item | Book value | Override with (scripts) |
|---|---|---|
| Project | `seven-day-cloud` | the `<PROJECT_ID>` argument |
| Region | `us-east1` (the course says `us-central1`, the scripts' default) | `REGION` |
| Cluster | `silverlake-public`, Autopilot | `CLUSTER` |

Pick a region, write it down, and use it in every command.

## Run order

**By hand (do this first).** Steps 1 to 12 in the chapter, in Cloud Shell. The core commands, in order:

```bash
gcloud services enable container.googleapis.com
gcloud container clusters create-auto silverlake-public --region us-east1
gcloud container clusters get-credentials silverlake-public \
    --region us-east1
kubectl apply -f k8s/nginx-deployment.yaml
kubectl rollout status deployment/loan-calc
helm create loan-calc-chart
helm install loan-calc ./loan-calc-chart
helm upgrade loan-calc ./loan-calc-chart
helm rollback loan-calc 1
helm history loan-calc
kubectl apply -f k8s/network-policy.yaml
```

The chapter has the `sed` edits to the chart's `values.yaml` between these, the pod deletion of Step 5, the optional public Service of Step 6, and the two probes of Step 11.

**Scripted** (Cloud Shell or a laptop):

```bash
REGION=us-east1 bash scripts/deploy-lab3-1.sh seven-day-cloud
```

**Stretch, the cluster as code** (from a laptop with `tofu`):

```bash
cd k8s && tofu init
tofu apply -var project=seven-day-cloud -var region=us-east1
```

The `get_credentials` output prints the Step 3 command; `tofu destroy` is the clean-up.

## Expected result

The cluster `RUNNING`; three `loan-calc` pods, with a deleted pod replaced within seconds; `helm history loan-calc` showing revision 3 deployed and described as "Rollback to 1"; and the NetworkPolicy proven: the unlabelled probe times out, the `role=frontend` probe receives the NGINX page. About 90 minutes by hand, 15 of them waiting for the cluster.

## Clean up

```bash
helm uninstall loan-calc
kubectl delete -f k8s/network-policy.yaml -f k8s/nginx-deployment.yaml
kubectl delete svc loan-calc-public --ignore-not-found
gcloud container clusters delete silverlake-public --region us-east1 --quiet
gcloud container clusters list
```

Or in one go:

```bash
bash scripts/rollback-lab3-1.sh seven-day-cloud -n    # list only
REGION=us-east1 bash scripts/rollback-lab3-1.sh seven-day-cloud -y
```

`--keep-cluster` keeps the cluster; the book advises against it (a fresh cluster is seven minutes, a kept one about 73 dollars a month). On a free sandbox, end the lab session as well.

## Cost

An Autopilot cluster bills a control-plane fee of about 73 dollars a month (October 2026), roughly ten cents an hour, plus a few cents for the pods. Delete it the same evening.

## When something fails

See the chapter's "If it fails" lines and field notes (including the evening `us-central1` had no Autopilot capacity), the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 3".
