# Day 3. Containers and the orchestra

Book chapter: **Day 3: Containers and the orchestra**. Two labs in the afternoon.

| Book part | Folder | Scripts | What it does |
|---|---|---|---|
| Afternoon, part one: the brewery's pipeline (Steps 1 to 12) | [`jenkins-docker-pipeline/`](jenkins-docker-pipeline/README.md) | `deploy-lab3-2.sh`, `rollback-lab3-2.sh` | Jenkins in Docker builds, smoke-tests, tags and pushes a menu-board image |
| Afternoon, part two: the credit union's cluster (Steps 1 to 12) | [`gke-helm-networkpolicy/`](gke-helm-networkpolicy/README.md) | `deploy-lab3-1.sh`, `rollback-lab3-1.sh` | A GKE Autopilot cluster, NGINX by `kubectl` and by Helm with upgrade and rollback, and a NetworkPolicy proven with two probes |

**Mind the numbering.** The script names come from the course, where the cluster was Lab 3.2 and the pipeline Lab 3.3. In the book the pipeline is part one and the cluster part two, so `deploy-lab3-2.sh` belongs to part one and `deploy-lab3-1.sh` to part two.

The two labs are independent, and nothing from Days 1 and 2 is used.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day3
```

If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files).

## What you need today

- Part one: Docker Desktop running on a laptop (no cloud account, no Cloud Shell); a Docker Hub account with an access token only if you push to Docker Hub.
- Part two: a Google Cloud project with billing and the Kubernetes Engine API; `gcloud`, `kubectl` and `helm` (Cloud Shell has all three).

## Cost

Part one costs nothing but about 4 GB of disk. Part two's Autopilot cluster bills a control-plane fee of about 73 dollars a month (October 2026), roughly ten cents an hour, plus a few cents for the pods. Delete the cluster the same evening.

## When something fails

Read the "If it fails" lines under each step, the chapter's field notes, each lab's "Troubleshoot with an AI assistant" subsection, and Appendix C, "Day 3", of the book.
