# Day 6. The eight a.m. launch

Book chapter: **Day 6: The eight a.m. launch**. Two parts in the afternoon, both from one folder.

| Book part | Course lab | Scripts | What it does |
|---|---|---|---|
| Afternoon, part one: survive the launch (Steps 1 to 16) | Lab 6.2 | `deploy-lab6-1.sh`, `deploy-lab6-cdn.sh` | A managed group of two web VMs behind an HAProxy balancer VM, a CDN in front (option A Cloudflare, option B Google Cloud CDN), and a failure drill |
| Afternoon, part two: prove it scales (Steps 1 to 8) | Lab 6.3 | `deploy-lab6-2.sh` | The autoscaler, a Locust VM, a Cloud Monitoring dashboard, and two load tests (200 and 2,000 users) |
| Clean up (both parts) | | `rollback-lab6.sh` | Removes everything both parts built |

Both parts use [`snowbird-lb-autoscaling/`](snowbird-lb-autoscaling/README.md). Part two needs part one's web tier and balancer running. Nothing from Days 1 to 5 is used.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day6/snowbird-lb-autoscaling
```

Every command in the chapter runs from inside this folder, so `config/web-startup.sh` resolves. If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files).

## Cost

An afternoon is pennies to well under a dollar. Forgotten, the group at its maximum of six is about 90 dollars a month, the two e2-medium VMs about 50 more, and option B's global forwarding rules about 18 (October 2026). Run the rollback script the same day.

## When something fails

Read the "If it fails" lines under each step, the chapter's field notes, each part's "Troubleshoot with an AI assistant" subsection, and Appendix C, "Day 6", of the book.
