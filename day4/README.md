# Day 4. A real application, locked down

Book chapter: **Day 4: A real application, locked down**. One application, three parts, all from one folder.

| Book part | Course lab | Scripts | What it does |
|---|---|---|---|
| Afternoon, part one: build and containerize (Steps 1 to 6) | Lab 4.3 | `deploy-lab4-1.sh`, `rollback-lab4-1.sh` | The timesheet API and UI run plain, then as two containers on one Docker network |
| Afternoon, part two: deploy to Kubernetes with a private backend (Steps 1 to 8) | Lab 4.4 | `deploy-lab4-2.sh`, `rollback-lab4-2.sh` | Both images in Artifact Registry, a GKE cluster, a public frontend and a private backend |
| Afternoon, part three: staff-only access with Identity-Aware Proxy (Steps 1 to 12) | Lab 4.5 | `deploy-lab4-3.sh`, `rollback-lab4-3.sh` | An HTTPS Ingress with IAP in front of the frontend, access granted by IAM role, and the refusal in the audit log |

All three parts use [`timpanogos-timesheet/`](timpanogos-timesheet/README.md). Part two needs part one's files (not its running containers); part three needs part two running. Nothing from Days 1 to 3 is required.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day4/timpanogos-timesheet
```

If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files).

## Cost

Part one never leaves the laptop. Part two's cluster (one e2-medium node plus the GKE control plane) is about 100 dollars a month and part three's global HTTPS load balancer about 18 (October 2026); for an afternoon, under three dollars in the author's runs. Delete the cluster the same day.

## When something fails

Read the "If it fails" lines under each step, the chapter's field notes, each part's "Troubleshoot with an AI assistant" subsection, and Appendix C, "Day 4", of the book.
