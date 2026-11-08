# Cloud Integration in 7 Days: lab scripts

The scripts and lab files for the book *Cloud Integration in 7 Days: Move it, ship it, lock it down and make it scale on AWS, Azure and Google Cloud* by Jackson I. Isiko, Ph.D.

Each chapter of the book walks through its labs by hand: console clicks, commands and the output to expect. The scripts here run the same commands in order. Use them to check your work, to rebuild a lab quickly, or to clean up when you are done. The book's text is the guide; these files are its companion.

| Book chapter | Folder | What it builds |
|---|---|---|
| Day 1. Move it, then automate it | `day1/aws-to-gcp-vm-migration`, `day1/azure-to-gcp-vm-migration`, `day1/lab1-migration-workflow` | An Apache VM migrated from AWS or Azure to Google Cloud as a disk image |
| | `day1/multi-cloud-ansible-deployment`, `day1/cross-cloud-iac` | One Ansible controller configuring NGINX on Google Cloud and Azure; OpenTofu definitions of the VMs |
| Day 2. Ship every Tuesday | `day2/github-actions-azure-webapp` | A GitHub Actions pipeline deploying an Express app to an Azure Web App |
| Day 3. Containers and the orchestra | `day3/gke-helm-networkpolicy`, `day3/jenkins-docker-pipeline` | GKE Autopilot with Helm and a NetworkPolicy; a Jenkins pipeline that builds and pushes a Docker image |
| Day 4. A real application, locked down | `day4/timpanogos-timesheet` | A two-container app on GKE behind Identity-Aware Proxy |
| Day 5. Identity is the perimeter | `day5/service-accounts-bigquery` | Least-privilege service accounts and keyless CI to BigQuery |
| Day 6. The eight a.m. launch | `day6/snowbird-lb-autoscaling` | A load-balanced, autoscaled web tier with a CDN and a load test |

Day 0 (setting up accounts) and Day 7 (the leadership review) have no scripts. Script comments use the course's numbering: Week 4 and Lab 4.4 in a script mean Day 4 in the book.

## How to run a lab

Every lab folder has a `scripts/` folder with three kinds of script:

```bash
bash scripts/deploy-<lab>.sh <PROJECT_ID>      # build the lab and print each checkpoint
bash scripts/verify-<lab>.sh <PROJECT_ID>      # where present: check what exists and what answers
bash scripts/rollback-<lab>.sh <PROJECT_ID>    # list the lab's resources, ask once, delete them
```

Add `-n` to a rollback script to only list, or `-y` to skip the question. The book uses the project ID `seven-day-cloud`; use your own. Read each script's first lines for its arguments and the tools it needs (the Google Cloud CLI, the Azure CLI, the AWS CLI, `doctl`, `gh`, `kubectl`, `helm`, Docker, Ansible or OpenTofu, depending on the lab).

## Before you run anything

- These scripts create billable resources on your own cloud accounts. Each chapter's Clean up section, and each `rollback-*.sh`, removes them. Set a budget alert first (Day 0).
- Run them in a project or subscription you use only for learning.
- The clouds change. If a command or flag no longer works, the book's errata address is in its front matter.

## License

Shared for readers of the book to learn with. Copyright © 2026 Jackson I. Isiko.
