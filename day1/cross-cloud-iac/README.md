# Day 1 add-on: the same server as OpenTofu, on three clouds

Book: **Day 1: Move it, then automate it**, section "DevOps on each platform" (the cross-cloud layer), and the Stretch sections of both labs. The files are printed in Appendix F.

The same server (Ubuntu 22.04, NGINX, ports 22 and 80, a page that names its cloud) written once per provider. The resource names differ between the three `main.tf` files; the shape does not. OpenTofu is the Linux Foundation fork of Terraform with the same language; every file also runs under `terraform`.

**Status in the book:** the Google Cloud configuration was applied in the author's run (three resources: two firewall rules and the VM). The AWS and Azure configurations pass `tofu validate` and were **not** applied; say so when you hand them to a team.

## Files

| File | What it does |
|---|---|
| `gcp/main.tf` | Two firewall rules and an e2-micro VM in us-central1-a that installs NGINX at boot. Variables: `project` (required), `ssh_public_key` (required), `zone`, `name` (`it360-web`), `ssh_source_cidr`. Output: `public_ip`. |
| `aws/main.tf` | The same server on EC2: key pair, security group with 22 and 80, t2.micro, `user_data` that installs NGINX. Variables: `ssh_public_key` (required), `region` (`us-east-1`), `name`, `ssh_source_cidr`. |
| `azure/main.tf` | The same server on Azure, Standard_D2s_v4 in eastus. Variables: `ssh_public_key` (required), `location`, `name`, `ssh_source_cidr`, `resource_group` (empty creates one; set it to a pre-created sandbox group). |
| `scripts/apply.sh <aws\|azure\|gcp> [-var ...]` | `init` and `apply` in that cloud's folder, print the IP, wait for HTTP 200. |
| `scripts/destroy.sh <aws\|azure\|gcp> [-var ...]` | `destroy` in that cloud's folder. |
| `.gitignore` | Keeps OpenTofu's provider downloads and state files out of Git. |

## Prerequisites

- **Tools:** `tofu` (Day 0: `brew install opentofu` on a Mac; on Ubuntu, the script prints the OpenTofu installer line if `tofu` is missing). `terraform` works too.
- **Credentials:** the cloud's CLI signed in as Day 0 shows: `gcloud` for `gcp/`, `aws` for `aws/`, `az login` for `azure/`.
- **An SSH public key.** The book's run uses `~/.ssh/id_rsa.pub`.

## Mac and Windows

No differences: run in Terminal on a Mac or in the Ubuntu terminal on Windows, with the key in the Linux `~/.ssh`.

## Values to edit first

- `-var project=<your project ID>` for Google Cloud.
- `-var ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"` on every cloud.
- `ssh_source_cidr` defaults to `0.0.0.0/0`; narrow it to `<your public ip>/32` outside a sandbox.

## Run order

The Google Cloud one, as the book runs it:

```bash
cd ~/Cloud-Integration-in-7-Days/day1/cross-cloud-iac/gcp && tofu init
tofu apply -var project=seven-day-cloud \
    -var ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
tofu output public_ip
```

Or with the wrapper, from `day1/cross-cloud-iac`:

```bash
bash scripts/apply.sh gcp -var project=seven-day-cloud -var ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

The Ansible lab's stretch adds a third target with `aws/` (an EC2 instance with the controller's key) and appends its IP to the inventory under `[aws]`; nothing in the playbook changes.

## Expected result

`PUBLIC_IP=<address>` and a page at `http://<address>/` that answers "served from Google Cloud by it360-web".

## Clean up

Destroy with the same variables you applied with:

```bash
cd ~/Cloud-Integration-in-7-Days/day1/cross-cloud-iac/gcp
tofu destroy -var project=seven-day-cloud \
    -var ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

or `bash scripts/destroy.sh gcp -var project=seven-day-cloud -var ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"`. Keep the state files (ignored by Git) until the destroy has run; without them OpenTofu no longer knows what it built.

## Cost

The Google Cloud e2-micro is in the free tier in us-central1 (October 2026); the AWS t2.micro is free-tier eligible; the Azure Standard_D2s_v4 bills by the hour. Each bills until destroyed.

## When something fails

See the "Troubleshoot with an AI assistant" subsection of the Day 1 labs and Appendix C of the book.
