# Day 1, Lab 1: migrate a VM from AWS to Google Cloud

Book: **Day 1: Move it, then automate it**, Afternoon, part one: the migration, Steps 1 to 18 (Route B and Route C are optional and console or command steps only; they use no file here). Script comments call this "Week 1 Lab 1 (AWS variant)".

You build an Ubuntu 22.04 EC2 instance running Apache, make its OS cloud-neutral, capture the root disk as a compressed qcow2, move it to Cloud Storage, create a Compute Engine image from it and launch a VM that serves the same page.

## Files

| File | Where it runs | What it does |
|---|---|---|
| `scripts/00-aws-all-in-one.sh` | AWS CloudShell, or a laptop with AWS credentials | Steps 1 to 8 in one run: key pair, security group (SSH from your IP only, HTTP from all), the instance, Apache, the 10 GB scratch volume, OS preparation, capture, and the image published at `http://<PUBLIC_IP>/disk.qcow2`. The book's AWS CloudShell commands are taken from this script. |
| `scripts/01-aws-build-apache.sh` | Where the AWS CLI is configured | Steps 1 to 4 only: launch, open SSH and HTTP, install and verify Apache. Defaults to the school sandbox key pair (`KEY_NAME=vockey`, `KEY_FILE=~/.ssh/labsuser.pem`); set both for your own account. |
| `scripts/02-aws-attach-scratch-volume.sh <INSTANCE_ID>` | Same | Step 5: a 10 GB gp3 volume `apacheserver1-scratch` attached as `/dev/sdf`. |
| `scripts/03-ec2-make-image.sh` | **On the EC2 instance**, in the SSH session | Steps 6 to 8: make the OS cloud-neutral, mount the scratch volume, take a frozen raw copy of the root disk, check it, compress it to qcow2 and publish it. |
| `scripts/04-gcp-import-and-launch.sh <PROJECT_ID> <EC2_PUBLIC_IP>` | Google Cloud Shell, or a laptop with `gcloud`, `qemu-img` and GNU tar | Steps 9 to 17: download, convert to the Compute Engine raw format, upload, create the image, launch the VM, open HTTP and validate. |
| `scripts/05-cleanup-aws.sh [-n] [-y]` | Where the AWS CLI is configured | Clean up the AWS side, found by name. |
| `scripts/06-cleanup-gcp.sh <PROJECT_ID> [-n] [-y]` | Where `gcloud` is signed in | Clean up the Google Cloud side (the `-aws` VM, image, bucket and firewall rules). |
| `scripts/deploy-lab1.sh <PROJECT_ID>` | A laptop with AWS credentials and `gcloud` | The whole lab end to end. |
| `scripts/verify-lab1.sh <PROJECT_ID>` | Same | What exists on each side and whether both web servers answer. |
| `scripts/destroy-lab1.sh <PROJECT_ID> [-n] [-y]` | Same | Runs both clean-up scripts, skipping a cloud whose CLI is not signed in. |
| `scripts/rollback-lab1.sh <PROJECT_ID> [-n] [-y]` | Same | The same as `destroy-lab1.sh`. |

## Prerequisites

- **Accounts.** An AWS account that can launch EC2 and attach a volume; a Google Cloud project with billing where you can create buckets, images, VMs and firewall rules (a sandbox lab role cannot create firewall rules and fails at Step 16).
- **Tools** (Day 0, "Set up your laptop"): `aws`, `gcloud`, `ssh` and `curl`. `qemu-img` and GNU tar are only needed if the Google Cloud half runs on your laptop; Google Cloud Shell has `gcloud` and GNU tar and installs `qemu-img` in Step 12, and the AWS half can run in AWS CloudShell.
- **Sign in** before Step 1:

```bash
cd ~/Cloud-Integration-in-7-Days/day1/aws-to-gcp-vm-migration
aws sts get-caller-identity
gcloud auth login
gcloud config set project seven-day-cloud
```

AWS CloudShell needs no sign-in. For a laptop AWS session, Day 0's "Signing in" shows `aws configure` with a named profile and region us-east-2.

## Mac and Windows

- **Mac.** Step 1's `mv ~/Downloads/apacheserver1-key.pem ~/.ssh/` works as printed. GNU tar comes from `brew install gnu-tar`, and `qemu-img` from `brew install qemu`.
- **Windows (WSL Ubuntu).** The browser saves the key to the Windows Downloads folder, so move it into the Linux home first: `mkdir -p ~/.ssh && mv /mnt/c/Users/<you>/Downloads/apacheserver1-key.pem ~/.ssh/`. `chmod 400` only works once the file is in the Linux home. Ubuntu's `tar` is already GNU tar.

## Values to edit first

The book's values; write yours next to them before you start (the chapter's "Before you start" table).

| Item | Book value | Override with |
|---|---|---|
| AWS region | us-east-2 | `export AWS_DEFAULT_REGION=us-east-2` (do this in a CloudShell opened outside Ohio) |
| Instance name, type | `apacheserver1`, t3.micro | `NAME`, `TYPE` |
| Google Cloud project, zone | `seven-day-cloud`, us-central1-a | the `<PROJECT_ID>` argument, `ZONE` |
| Bucket | `<PROJECT_ID>-apache-migration-aws` | `BUCKET` |
| Image, VM | `apacheserver-image-aws`, `apacheserver-gcp-aws` | `IMAGE`, `GCP_VM` |

On the free AWS sandbox the region is us-east-1, the key pair `vockey` (`labsuser.pem`) and the type t2.micro.

## Run order

**By hand (do this first).** Follow Steps 1 to 18 in the chapter. Steps 1 to 8 run in AWS (console or AWS CloudShell, then the SSH session on the instance), Steps 9 to 15 in Google Cloud Shell, Steps 16 to 18 validate.

**Scripted, AWS side in CloudShell, Google Cloud side in Cloud Shell or a laptop** (the route for an account with no laptop AWS credentials):

```bash
# 1. In AWS CloudShell, after cloning the repository there
cd ~/Cloud-Integration-in-7-Days/day1/aws-to-gcp-vm-migration
export AWS_DEFAULT_REGION=us-east-2
bash scripts/00-aws-all-in-one.sh            # prints the image URL http://<EC2_IP>/disk.qcow2

# 2. In Google Cloud Shell or on the laptop
bash scripts/04-gcp-import-and-launch.sh seven-day-cloud <EC2_IP>

# 3. Back in AWS CloudShell: Step 11, take the public download link down
ssh -i ~/.ssh/apacheserver1-key.pem ubuntu@<EC2_IP> 'sudo rm -f /var/www/html/disk.qcow2'
```

**Scripted, step by step** (the same steps in smaller pieces, if you want to stop between them): `01-aws-build-apache.sh`, then `02-aws-attach-scratch-volume.sh <INSTANCE_ID>`, then copy `03-ec2-make-image.sh` to the instance and run it there in the SSH session, then `04-gcp-import-and-launch.sh <PROJECT_ID> <EC2_PUBLIC_IP>`.

**Scripted, one laptop with both CLIs signed in:**

```bash
bash scripts/deploy-lab1.sh seven-day-cloud
bash scripts/verify-lab1.sh seven-day-cloud
```

## Expected result

Both pages answer side by side: `http://<EC2_IP>/` on AWS and `http://<GCE_IP>/` on Compute Engine, with the marker file from Step 6 present on the migrated VM and the serial console showing a clean boot. The six gates are in the chapter's phase table: HTTP 200 on the source, the marker file, `live=N copy=N` and the md5 written down, the md5 matching after download, the image `READY` and VM `RUNNING`, then HTTP 200 on Google Cloud with the link removed. The book's run took 17 minutes end to end on a fast link; budget two hours for a first pass by hand.

## Clean up

The chapter's Clean up section ("Lab 1 on AWS" and "Lab 1 on Google Cloud") has the console path and these commands:

```bash
# AWS
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
aws ec2 wait instance-terminated --instance-ids <INSTANCE_ID>
aws ec2 delete-volume --volume-id <SCRATCH_VOLUME_ID>
aws ec2 delete-security-group --group-id <SG_ID>
aws ec2 delete-key-pair --key-name apacheserver1-key

# Google Cloud
gcloud compute instances delete apacheserver-gcp-aws --zone=us-central1-a --quiet
gcloud compute images delete apacheserver-image-aws --quiet
gcloud storage rm -r gs://seven-day-cloud-apache-migration-aws
gcloud compute firewall-rules delete allow-http --quiet
gcloud compute firewall-rules delete allow-ssh-admin --quiet   # if Step 18 made it
```

Or the one-command version, which finds everything by name, lists it and asks once:

```bash
bash scripts/rollback-lab1.sh seven-day-cloud -n    # list only
bash scripts/rollback-lab1.sh seven-day-cloud -y
```

Keep `allow-http` while the Azure variant's VM is still running. Without laptop AWS credentials, run `bash scripts/05-cleanup-aws.sh -y` in AWS CloudShell and `bash scripts/06-cleanup-gcp.sh seven-day-cloud -y` in Google Cloud Shell. Route B adds an AMI, its snapshot, an S3 bucket and the `vmimport` role; Route C adds an IAM user and its access key; delete those as the chapter says.

## Cost

The t3.micro is free-tier eligible and the e2-micro is on Google's always-free list in us-central1 (October 2026); the scratch volume, the bucket and the custom image are cents for an afternoon. An e2-micro left running for a month is about seven dollars, and a custom image bills for storage until you delete it. Delete everything once your screenshots are taken.

## Safety

SSH is open to your IP only, never to 0.0.0.0/0. The public `disk.qcow2` link comes down as soon as the download is done (Step 11).

## When something fails

See the "If it fails" lines in the chapter, its field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 1, Lab 1 (migration)".
