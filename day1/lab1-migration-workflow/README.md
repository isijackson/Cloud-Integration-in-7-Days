# Day 1, Lab 1: both migration variants from one command

Book: **Day 1: Move it, then automate it**, Afternoon, part one: the migration (the AWS route and The Azure variant), and "The timing tables". Day 0's "Get the companion files" notes that this folder's scripts sit at the top of the folder, not in a `scripts/` subfolder.

These three scripts call the scripts in the two sibling folders, [`../aws-to-gcp-vm-migration/scripts/`](../aws-to-gcp-vm-migration/README.md) and [`../azure-to-gcp-vm-migration/scripts/`](../azure-to-gcp-vm-migration/README.md), so keep the `day1/` folder whole.

## Files

| File | What it does |
|---|---|
| `deploy-lab1.sh <azure\|aws\|both> <PROJECT_ID>` | Runs one variant or both and prints the step-timing table. `both` runs Azure first, then AWS; `PARALLEL=1` runs them side by side (the two downloads then share bandwidth). Logs go to `~/lab1-azure-deploy.log` and `~/lab1-aws-deploy.log`. |
| `verify-lab1.sh <azure\|aws\|both> <PROJECT_ID>` | Checks what exists and whether the web servers answer. |
| `destroy-lab1.sh <azure\|aws\|both> <PROJECT_ID> [-n] [-y]` | Tears down one or both variants (the same as each variant's `rollback-lab1.sh`). |

## Prerequisites

- Everything in the two variant READMEs: `gcloud` signed in to a Google Cloud project with billing, `qemu-img` and GNU tar on the laptop.
- `azure`: `az login` done on the laptop.
- `aws`: AWS credentials on the laptop (a profile, region us-east-2). Without laptop credentials, run `00-aws-all-in-one.sh` in AWS CloudShell first and pass its IP as `EC2_IP`; the wrapper then runs only the Google Cloud import and reminds you of Step 11.

## Mac and Windows

- **Mac.** `brew install qemu gnu-tar`.
- **Windows (WSL Ubuntu).** Run in the Ubuntu terminal with the clone in the Linux home.

## Run order

```bash
cd ~/Cloud-Integration-in-7-Days/day1/lab1-migration-workflow
bash deploy-lab1.sh both seven-day-cloud
bash verify-lab1.sh both seven-day-cloud
```

AWS without laptop credentials:

```bash
EC2_IP=<ip printed by 00-aws-all-in-one.sh> bash deploy-lab1.sh aws seven-day-cloud
```

## Expected result

The timing table for each variant (the book's run: 17 minutes AWS to Compute Engine, 18 minutes Azure to Compute Engine) and the before and after URLs, each answering HTTP 200.

## Clean up

```bash
bash destroy-lab1.sh both seven-day-cloud -n    # list only
bash destroy-lab1.sh both seven-day-cloud -y
```

AWS side without laptop credentials: run `bash scripts/05-cleanup-aws.sh -y` in AWS CloudShell (us-east-2) from the `aws-to-gcp-vm-migration` folder; this wrapper then cleans the Google Cloud side only.

## Cost

The same as the two variants: cents for an afternoon if deleted the same day; an e2-micro left running is about seven dollars a month, and custom images bill for storage until deleted.

## When something fails

See the variant READMEs, the chapter's field notes, the "Troubleshoot with an AI assistant" subsection of the migration lab, and Appendix C, "Day 1, Lab 1 (migration)".
