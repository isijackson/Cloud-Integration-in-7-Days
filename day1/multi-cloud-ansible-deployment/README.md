# Day 1, Lab 2: one Ansible controller, two clouds

Book: **Day 1: Move it, then automate it**, Afternoon, part two: configuration automation, Steps 1 to 14 (Step 1A builds the controller on EC2 if DigitalOcean is not an option). Script comments call this "Week 1 Lab 2".

A controller droplet on DigitalOcean runs Ansible. It reaches a Google Cloud VM and an Azure VM with a fleet key it generated itself, and one playbook installs and starts NGINX on both. A second run of the idempotent playbook reports `changed=0`.

## Files

| File | Where it runs | What it does |
|---|---|---|
| `ansible/nginx.yml` | Controller, `~/lab2` | The Step 8 playbook: update APT, install NGINX, start and enable it. Use it if the heredoc in Step 8 goes wrong. |
| `ansible/nginx-idempotent.yml` | Controller, `~/lab2` | The Step 11 version with `cache_valid_time`, so a second run reports `changed=0`. |
| `ansible/ansible.cfg` | Controller, next to `inventory.ini` | Optional; quiets the "discovered Python interpreter" warning and skips the host-key prompt for new VMs. |
| `ansible/inventory.example.ini` | Reference | The shape of the `inventory.ini` that Step 7 writes: `[azure]` and `[gcp]` groups with `ansible_user=ubuntu`. Replace the IPs with your clients' public IPs. |
| `ansible/eda/rulebook.yml` | Controller, `~/lab2/eda` | Stretch, not run in class: Event-Driven Ansible that reruns `nginx-idempotent.yml` when a webhook on port 5000 receives `{"event": "nginx-down"}`. |
| `scripts/01-controller-bootstrap.sh` | **On the controller**, as root, right after first login | Steps 2 and 3 as one script: installs Ansible from its PPA and generates the fleet key `~/.ssh/id_rsa`, then prints the public line to paste into each client. |
| `scripts/deploy-lab2.sh <PROJECT_ID>` | Laptop with `doctl`, `gcloud` and `az` signed in | The whole lab end to end: controller, both clients, passwordless SSH, inventory, ping, the playbook twice, both pages. Writes `~/lab2-state.env`. |
| `scripts/verify-lab2.sh [<PROJECT_ID>]` | Same | The three VMs exist, the ping, the idempotent playbook and both curls in one go. |
| `scripts/02-destroy-lab2-do.sh [-n] [-y]` | Laptop with `doctl` | Deletes the controller droplet (`DO_KEY_NAME=<name>` also deletes that uploaded key). |
| `scripts/03-destroy-lab2-gcp.sh <PROJECT_ID> [-n] [-y]` | Where `gcloud` is signed in | Deletes `ansible-client-gcp` and the `allow-ssh-ansible` rule. |
| `scripts/04-destroy-lab2-azure.sh [RESOURCE_GROUP] [-n] [-y]` | Where `az` is signed in (Cloud Shell on the sandbox) | Deletes the Azure client and what `az vm create` made for it; in your own subscription the group `ansible-lab-rg` goes whole. |
| `scripts/destroy-lab2.sh <PROJECT_ID> [-n] [-y]` | Laptop | Runs the three clean-up scripts, skipping a cloud whose CLI is not signed in. |
| `scripts/rollback-lab2.sh <PROJECT_ID> [-n] [-y]` | Laptop | The same as `destroy-lab2.sh`. |

## Prerequisites

- **Accounts.** DigitalOcean (or the AWS account, for Step 1A), the Google Cloud project, the Azure subscription.
- **Tools** (Day 0): `doctl`, `gcloud`, `az` and `ssh` on the laptop. Ansible is **not** needed on the laptop; Step 2 installs it on the controller.
- **A laptop key.** `ssh-keygen -t ed25519` if `~/.ssh/id_ed25519.pub` does not exist, and its `.pub` uploaded to DigitalOcean for the one-command path.
- **Sign in** before Step 1; all three must answer for the scripts:

```bash
cd ~/Cloud-Integration-in-7-Days/day1/multi-cloud-ansible-deployment
doctl auth init
doctl account get
gcloud auth login
gcloud config set project seven-day-cloud
az login --use-device-code
ls ~/.ssh/id_ed25519.pub
```

The DigitalOcean API token needs write scope, or the droplet create fails with a 403.

## Mac and Windows

- **Mac.** Nothing extra.
- **Windows (WSL Ubuntu).** The key is the one in the Ubuntu home (`~/.ssh/id_ed25519`), not one under `C:\Users`; create it inside Ubuntu and upload that `.pub` to DigitalOcean. If `doctl` came from snap and cannot read the key, run `sudo snap connect doctl:ssh-keys :ssh-keys`.

## Values to edit first

| Item | Book value | Override with (deploy script) |
|---|---|---|
| Your DigitalOcean key name | `it360-lab-mac` | `DO_SSH_KEY_NAME` |
| Its private key on the laptop | `~/.ssh/id_ed25519` | `LOCAL_KEY` |
| Controller | `ansible-controller`, nyc1, s-1vcpu-1gb | `DO_REGION`, `DO_SIZE` |
| Google Cloud client | `ansible-client-gcp`, us-central1-a, e2-micro | `ZONE` |
| Azure client | `ansible-client-azure`, `ansible-lab-rg`, eastus, Standard_B1s | `AZ_RG`, `AZ_LOCATION`, `AZ_SIZE` |
| Inventory IPs | your two client IPs | edit `inventory.ini` on the controller (Step 7) |

## Run order

**By hand (do this first).** Steps 1 to 14 in the chapter. `$` lines run on the laptop, `controller$` lines on the controller over SSH. The Ansible files go into `~/lab2` on the controller next to the `inventory.ini` that Step 7 writes; type them from the chapter, or clone this repository on the controller and copy them:

```bash
controller$ mkdir -p ~/lab2 && cd ~/lab2
controller$ ansible all -i inventory.ini -m ping                      # Step 9
controller$ ansible-playbook -i inventory.ini nginx.yml               # Step 10
controller$ ansible-playbook -i inventory.ini nginx.yml               # Step 11: the second run
controller$ sed 's/update_cache: yes/&\n        cache_valid_time: 3600/' \
    nginx.yml > nginx-idempotent.yml
controller$ ansible-playbook -i inventory.ini nginx-idempotent.yml
controller$ ansible-playbook -i inventory.ini nginx.yml --syntax-check   # Step 14
```

The `sed` line writes the same file as `ansible/nginx-idempotent.yml`; if you copied that file in, skip the `sed`.

**Scripted, from the laptop:**

```bash
bash scripts/deploy-lab2.sh seven-day-cloud
bash scripts/verify-lab2.sh seven-day-cloud
```

If your DigitalOcean key has another name:

```bash
DO_SSH_KEY_NAME=<your key's name> LOCAL_KEY=<its private key file> bash scripts/deploy-lab2.sh seven-day-cloud
```

## Expected result

`SUCCESS` with `"ping": "pong"` from both hosts, a PLAY RECAP with `changed=2`, `failed=0` and `unreachable=0` on the first run, `changed=1` on the plain second run (refreshing the package index counts as a change) and `changed=0` on `nginx-idempotent.yml`, and the NGINX welcome page at both client IPs side by side. The scripted run took 8 minutes; budget 90 minutes by hand.

## Clean up

Clients first, then the controller (the chapter's "Lab 2, clients first, then the controller"):

```bash
gcloud compute instances delete ansible-client-gcp --zone=us-central1-a --quiet
gcloud compute firewall-rules delete allow-ssh-ansible --quiet
az group delete -n ansible-lab-rg --yes
doctl compute droplet delete ansible-controller --force
gcloud compute instances list --filter=name=ansible-client-gcp
az vm list -o table; doctl compute droplet list
```

Or in one go:

```bash
bash scripts/rollback-lab2.sh seven-day-cloud -n    # list only
bash scripts/rollback-lab2.sh seven-day-cloud -y
```

On a school Azure sandbox the Azure CLI only works in the portal's Cloud Shell, so run `bash scripts/04-destroy-lab2-azure.sh` there. For an EC2 controller (Step 1A), delete the instance, its security group and the key pair `ansible-controller-key` as the chapter says.

## Cost

The droplet is six dollars a month (about two cents for the lab), the e2-micro is in Google's free tier, and the B1s is about 7.59 dollars a month (October 2026). All three bill until destroyed; a powered-off droplet still bills.

## Safety

The fleet key never leaves the controller; only its `.pub` is copied to the clients. Destroying the controller destroys the fleet private key, as it should.

## When something fails

See the chapter's "If it fails" lines (an `UNREACHABLE` line means the IP, user or key in the inventory is wrong), its field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 1, Lab 2 (Ansible)".
