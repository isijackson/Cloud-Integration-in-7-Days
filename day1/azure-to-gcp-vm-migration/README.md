# Day 1, Lab 1 (Azure variant): migrate a VM from Azure to Google Cloud

Book: **Day 1: Move it, then automate it**, Afternoon, part one: the migration, section "The Azure variant", Azure Steps 1 to 16. Script comments call this "Week 1 Lab 1 (Azure variant)".

The same migration as the AWS route with an Azure VM as the source: an Ubuntu 22.04 VM running Apache, made cloud-neutral, captured as a compressed qcow2, moved to Cloud Storage and launched on Compute Engine. The Google Cloud half is identical except for the names: bucket `seven-day-cloud-apache-migration`, image `apacheserver-image`, VM `apacheserver-gcp`.

## Files

| File | Where it runs | What it does |
|---|---|---|
| `scripts/00-azure-all-in-one.sh` | A laptop with `az login` done, or Azure Cloud Shell (Bash) | Azure Steps 1 to 6 in one run: resource group (or the existing one in `RG`), the VM with SSH open to your IP only and HTTP to all, Apache, the 10 GB scratch disk, capture, and the image published at `http://<PUBLIC_IP>/disk.qcow2`. The book's `az` commands are taken from this script. |
| `scripts/04-gcp-import-and-launch.sh <PROJECT_ID> <AZURE_PUBLIC_IP>` | Google Cloud Shell, or a laptop with `gcloud`, `qemu-img` and GNU tar | Azure Steps 7 to 15: download, convert, upload, image, VM, HTTP rule, validation. |
| `scripts/05-cleanup-azure.sh [-n] [-y]` | Where `az` is signed in (Cloud Shell on the sandbox) | Deletes the VM and everything `az vm create` made for it; deletes the group only if the lab created it (`apacheserver1-rg`). `RG=<group>` points it at an existing group. |
| `scripts/06-cleanup-gcp.sh <PROJECT_ID> [-n] [-y]` | Where `gcloud` is signed in | Deletes the Google Cloud VM, image, bucket and firewall rules of this variant. |
| `scripts/deploy-lab1.sh <PROJECT_ID>` | A laptop with `az` and `gcloud` signed in, `qemu-img` and GNU tar | The whole variant end to end, about 25 minutes, ending with the step-timing table. |
| `scripts/verify-lab1.sh <PROJECT_ID>` | Same | What exists on each side and whether both web servers answer. |
| `scripts/destroy-lab1.sh <PROJECT_ID> [-n] [-y]` | Same | Runs both clean-up scripts. |
| `scripts/rollback-lab1.sh <PROJECT_ID> [-n] [-y]` | Same | The same as `destroy-lab1.sh`. |

## Prerequisites

- **Accounts.** An Azure subscription with `az` signed in; a Google Cloud project with billing where you can create buckets, images, VMs and firewall rules.
- **Tools** (Day 0): `az`, `gcloud`, `ssh`, `curl`; `qemu-img` and GNU tar for a laptop run of the Google Cloud half (Cloud Shell has what it needs).
- **Sign in:**

```bash
cd ~/Cloud-Integration-in-7-Days/day1/azure-to-gcp-vm-migration
az login --use-device-code
gcloud auth login
gcloud config set project seven-day-cloud
```

On a school Azure sandbox that blocks the laptop CLI, use Azure Cloud Shell (the `>_` icon in the portal, Bash, No storage account required) and clone the repository there; the sandbox's resource group is pre-created, so pass it as `RG`.

## Mac and Windows

- **Mac.** `brew install qemu gnu-tar` if the Google Cloud half runs on the laptop.
- **Windows (WSL Ubuntu).** Run everything in the Ubuntu terminal; the key the script creates lives in the Linux `~/.ssh`. Ubuntu's `tar` is already GNU tar.

## Values to edit first

| Item | Book value | Override with |
|---|---|---|
| Resource group | `apacheserver1-rg` | `RG` (required on the sandbox) |
| Location, size, name | eastus, Standard_D2s_v4, `apacheserver1` | `LOCATION`, `SIZE`, `NAME` |
| Google Cloud project, zone | `seven-day-cloud`, us-central1-a | the `<PROJECT_ID>` argument, `ZONE` |
| Bucket | `<PROJECT_ID>-apache-migration` | `BUCKET` |

## Run order

**By hand (do this first).** Azure Steps 1 to 16 in the chapter.

**Scripted, Azure side in Cloud Shell:**

```bash
# Own subscription
bash scripts/00-azure-all-in-one.sh
# School sandbox: use its pre-created group
RG=$(az group list --query "[0].name" -o tsv) bash scripts/00-azure-all-in-one.sh
```

then, in Google Cloud Shell or on the laptop:

```bash
bash scripts/04-gcp-import-and-launch.sh seven-day-cloud <AZURE_PUBLIC_IP>
```

and remove the public download link (Azure Step 9) as the chapter shows.

**Scripted, one laptop with both CLIs:**

```bash
bash scripts/deploy-lab1.sh seven-day-cloud
bash scripts/verify-lab1.sh seven-day-cloud
```

The deploy script removes the download link itself and prints the timing table and both URLs.

## Expected result

`http://<AZURE_IP>/` (Azure `apacheserver1`) and `http://<GCE_IP>/` (Google Cloud `apacheserver-gcp`) serve the same page. The book's run took 18 minutes end to end; the first HTTP 200 on Google Cloud can take about two minutes after boot (Azure Step 15).

## Clean up

```bash
# Azure, own subscription
az group delete -n apacheserver1-rg --yes
# Azure, school sandbox (empties the pre-created group in the order Azure allows)
bash scripts/05-cleanup-azure.sh

# Google Cloud
gcloud compute instances delete apacheserver-gcp --zone=us-central1-a --quiet
gcloud compute images delete apacheserver-image --quiet
gcloud storage rm -r gs://seven-day-cloud-apache-migration
gcloud compute firewall-rules delete allow-http --quiet
```

Or in one go:

```bash
bash scripts/rollback-lab1.sh seven-day-cloud -n    # list only
bash scripts/rollback-lab1.sh seven-day-cloud -y
```

Keep `allow-http` if the AWS variant's VM is still running; the clean-up script checks for other `http-server` VMs first.

## Cost

Cents for an afternoon if deleted the same day. The Standard_D2s_v4 source VM, its disks and the custom image all bill until deleted. Delete everything once your screenshots are taken.

## When something fails

See the chapter's "If it fails" lines and field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 1, Lab 1 (migration)".
