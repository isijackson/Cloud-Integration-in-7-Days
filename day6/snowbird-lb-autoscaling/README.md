# Day 6 labs: the Snowbird launch

Book: **Day 6: The eight a.m. launch**, Afternoon, part one: survive the launch (Steps 1 to 16) and Afternoon, part two: prove it scales (Steps 1 to 8). Script comments call these "Week 6 Lab 6.2" and "Lab 6.3".

A season-pass store that must survive its eight a.m. launch. Part one builds a managed instance group of two web VMs behind `lb-vm`, an HAProxy balancer with health checks and a stats page, puts a CDN in front, and proves that the store keeps selling with one server stopped. Part two turns on the autoscaler, builds a Locust load generator and a dashboard, and watches the group grow under 2,000 users and shrink afterwards.

## Files

| File | What it does |
|---|---|
| `config/web-startup.sh` | Startup script for every web VM: NGINX serves the store page and a cacheable `static.txt`, and proxies `/buy` to a small Python checkout service that does real CPU work, so a load test gives the autoscaler something to react to. Read by `web-template` (Step 1). |
| `config/lb-startup.sh` | Startup script for `lb-vm`: HAProxy with round-robin balancing, health checks, a stats page on port 8404, and the cron job. |
| `config/refresh-backends.sh` | Run by cron on `lb-vm` every minute: rewrites the `web_pool` backends from the instance group, so autoscaled VMs get traffic. Goes into the `refresh-script` metadata key (Step 5). |
| `config/locustfile.py` | One pass buyer: the home page, `static.txt` and `/buy`, weighted 5:1:4 (part two, Step 3). |
| `config/dashboard.yaml` | The *Snowbird launch test* dashboard (part two, Step 4), printed in the book. |
| `config/dashboard.json` | The same dashboard as JSON, read by `deploy-lab6-2.sh`. |
| `scripts/deploy-lab6-1.sh <PROJECT_ID>` | Part one, Steps 1 to 8 and 15 to 16: template, group, firewall rules, Compute Viewer grant, `lb-vm`, the alternation proof and the failure drill. Prints the IP to use for option A. |
| `scripts/deploy-lab6-cdn.sh <PROJECT_ID>` | Part one, option B (Steps 11 to 13): a global external Application Load Balancer with Cloud CDN in front of `web-group`, and HTTPS from a Google-managed certificate on `<ip>.nip.io`. Run after `deploy-lab6-1.sh`. |
| `scripts/deploy-lab6-2.sh <PROJECT_ID>` | Part two, Steps 1 to 7: autoscaling (2 to 6, 60 percent CPU, 90 s cool-down), `locust-vm`, the dashboard, two headless runs. `RUN_MINUTES` sets each run's length (default 5). |
| `scripts/rollback-lab6.sh <PROJECT_ID> [-n] [-y]` | Both parts: the CDN balancer, `locust-vm`, `lb-vm`, `web-group`, `web-template`, the four firewall rules, the dashboard and the Compute Viewer grant. |

Option A (Cloudflare, Steps 9 and 10) is console only; there is no script for it.

## Prerequisites

- **Accounts.** A Google Cloud project with billing. A school sandbox cannot create firewall rules, so `allow-web-80` fails at Step 3 there; use your own project. Option A also needs a free Cloudflare account and a domain you own; option B needs neither.
- **Tools** (Day 0): `gcloud` and `curl`, nothing else, for both parts. Cloud Shell works as well as a laptop; clone this repository there with the `git clone` line from the top-level README.
- **Check:**

```bash
cd ~/Cloud-Integration-in-7-Days/day6/snowbird-lb-autoscaling
gcloud auth login
gcloud config set project seven-day-cloud
curl -s https://checkip.amazonaws.com
```

Skip `gcloud auth login` in Cloud Shell. The last line prints the address that `allow-stats` (Step 6) and part two's `allow-locust-ui` open to.

## Mac and Windows, laptop and Cloud Shell

A Mac and Ubuntu on Windows behave the same today: both print your home's public address, which is the one your browser uses. The difference that matters is **laptop against Cloud Shell**. Cloud Shell prints its own address in Google's network, so a rule opened to it keeps your browser out of the HAProxy stats page and the Locust UI. In Cloud Shell, run the `curl` line on your laptop instead and set `MYIP` by hand (`MYIP=203.0.113.7`, with your address) in place of the `MYIP=$(curl ...)` lines. The deploy scripts look the address up themselves, so run from Cloud Shell they open `allow-stats` to Cloud Shell; put it right afterwards with:

```bash
gcloud compute firewall-rules update allow-stats --source-ranges=$MYIP/32
```

## Values to edit first

| Item | Book value | Override with (scripts) |
|---|---|---|
| Project | `seven-day-cloud` | the `<PROJECT_ID>` argument |
| Zone | `us-west1-b` (the course and the scripts default to `us-central1-a`) | `ZONE=us-west1-b` in front of every script, rollback included |
| Your laptop's address | `<YOUR_PUBLIC_IP>` | `MYIP` |
| Option A name | `passes.<your-domain>` | the Cloudflare console |
| Run length | 5 minutes | `RUN_MINUTES` |

## Run order

### Part one: survive the launch

**By hand (do this first).** Steps 1 to 8 build the web tier and the balancer; then **one** of option A (Steps 9 and 10, Cloudflare) or option B (Steps 11 to 14, Cloud CDN); then the drill, Steps 15 and 16. About two and a half hours through the console.

**Scripted** (Steps 1 to 8 and 15 to 16 in under three minutes), then option B (about forty seconds, plus 15 to 30 minutes for the certificate to become Active, which you need not wait for):

```bash
ZONE=us-west1-b bash scripts/deploy-lab6-1.sh seven-day-cloud
ZONE=us-west1-b bash scripts/deploy-lab6-cdn.sh seven-day-cloud
```

**Expected:** refreshing the balancer's address alternates between the two web VMs' hostnames; the stats page at `http://<LB_IP>:8404` shows both servers UP; a repeated request for `static.txt` through the CDN shows a cache hit; and with one server stopped the store keeps answering while the stats page marks it DOWN.

### Part two: prove it scales

Needs part one's `web-group`, `lb-vm` and `allow-web-80`. Neither CDN option is used: Locust must point at the balancer's own address.

**By hand:** Steps 1 to 8 (autoscaler, Locust VM and its port, install Locust and copy the locustfile, the dashboard **before** any load, 200 users, 2,000 users, scale-in, verify). The dashboard and the locustfile, from this folder:

```bash
gcloud monitoring dashboards create \
    --config-from-file=config/dashboard.yaml
gcloud compute scp config/locustfile.py locust-vm:~ --zone=us-west1-b
```

**Scripted** (Steps 1 to 7 with five-minute runs, about 24 minutes):

```bash
ZONE=us-west1-b bash scripts/deploy-lab6-2.sh seven-day-cloud
```

**Expected:** the group grows during each run (the book's reference run: 2 to 3 at 200 users, 2 to 6 at 2,000 users) and shrinks back to two by itself several minutes after the load stops, because the autoscaler looks back over a 10-minute window; the dashboard shows CPU, group size and bytes on one time axis; Locust's CSV files give the request counts, failure rates and medians for the chapter's table. During run 2 the `server` lines in `haproxy.cfg` on `lb-vm` should keep up with the group size.

## Clean up

One script does the Google Cloud side of both parts. Pass the same `ZONE`, or it looks in `us-central1-a` and reports nothing to delete:

```bash
bash scripts/rollback-lab6.sh seven-day-cloud -n   # list only
ZONE=us-west1-b bash scripts/rollback-lab6.sh seven-day-cloud -y
```

Then check that `gcloud compute instances list` shows none of the lab's VMs and `gcloud compute instance-groups managed list` is empty. The Cloudflare record (option A) is deleted in the Cloudflare console. The order by hand, if you prefer the console, is in the chapter's Clean up section: forwarding rules, proxies, certificate, URL map, backend service, health check and global address; the two VMs; the group, then the template; the four firewall rules; the dashboard and the Compute Viewer grant.

## Cost

Two e2-small web VMs and an e2-medium balancer for an afternoon cost well under a dollar. At its maximum of six the group is about 90 dollars a month, the two e2-medium VMs about 50 more, and option B's global forwarding rules about 18 (October 2026). The autoscaler shrinks the group back to two by itself, but nothing deletes the VMs except you.

## When something fails

See the chapter's "If it fails" lines and field notes (the cron PATH that kept the refresh from running, the dashboard filter that left the charts empty), the "Troubleshoot with an AI assistant" subsection of each part, and Appendix C, "Day 6".
