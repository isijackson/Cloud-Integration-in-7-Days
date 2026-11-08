# Day 1. Move it, then automate it

Book chapter: **Day 1: Move it, then automate it**. Two labs in the afternoon, plus an OpenTofu add-on.

| Book part | Folder | What it does |
|---|---|---|
| Afternoon, part one: the migration (AWS route, Steps 1 to 18) | [`aws-to-gcp-vm-migration/`](aws-to-gcp-vm-migration/README.md) | An Ubuntu VM running Apache on EC2, captured as a disk image and launched on Compute Engine |
| Afternoon, part one: the migration (The Azure variant, Azure Steps 1 to 16) | [`azure-to-gcp-vm-migration/`](azure-to-gcp-vm-migration/README.md) | The same migration with an Azure VM as the source |
| Afternoon, part one, both variants from one command | [`lab1-migration-workflow/`](lab1-migration-workflow/README.md) | Wrapper scripts that run the AWS variant, the Azure variant or both |
| Afternoon, part two: configuration automation (Steps 1 to 14) | [`multi-cloud-ansible-deployment/`](multi-cloud-ansible-deployment/README.md) | One Ansible controller on DigitalOcean configuring NGINX on a Google Cloud VM and an Azure VM |
| DevOps on each platform, and the Stretch sections | [`cross-cloud-iac/`](cross-cloud-iac/README.md) | The same NGINX server as OpenTofu code, once per cloud |

The two labs are independent: the Ansible lab needs nothing from the migration lab.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day1
```

If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files) in the top-level README.

## Accounts for today

- An AWS account that can launch EC2 and attach a volume (the AWS route).
- A Google Cloud project with billing, where you can create buckets, images, VMs and firewall rules. A school sandbox lab role cannot create firewall rules and fails at Step 16 of the migration, so use a personal project.
- An Azure subscription (the Azure variant and the Ansible lab).
- A DigitalOcean account for the Ansible controller, or the AWS account (Step 1A builds the controller on EC2 instead).

## Cost

Everything today is free tier or cents for an afternoon, as long as you delete it the same day. What costs money is forgetting: an e2-micro left running is about seven dollars a month, a custom image bills for its storage, a DigitalOcean droplet bills even when powered off, and a B1s on Azure is about 7.59 dollars a month (prices at the time of writing, October 2026). Each lab README has its clean-up commands, and the chapter's Clean up section has the console path.

## When something fails

Read the "If it fails" lines under each step, the chapter's "Field notes: what went wrong in my run", the "Troubleshoot with an AI assistant" subsection of each lab, and Appendix C (Day 1, Lab 1 and Day 1, Lab 2) of the book.
