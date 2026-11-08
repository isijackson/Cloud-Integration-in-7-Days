# Cloud Integration in 7 Days: lab scripts

The scripts and lab files for the book *Cloud Integration in 7 Days: Move it, ship it, lock it down and make it scale on AWS, Azure and Google Cloud* by Jackson I. Isiko, Ph.D.

Each chapter of the book walks through its labs by hand: console clicks, commands and the output to expect. The scripts here run the same commands in order. Use them to check your work, to rebuild a lab quickly, or to clean up when you are done. The book's text is the guide; these files are its companion. Appendix F of the book prints every file the labs read, so the book also works offline.

## 1. Get the files

**With Git** (the route Day 0 uses). Clone into your home folder, on a Mac and in Ubuntu on Windows alike:

```bash
cd ~
git clone https://github.com/isijackson/Cloud-Integration-in-7-Days.git
cd Cloud-Integration-in-7-Days
ls
```

```
README.md  day1  day2  day3  day4  day5  day6
```

**Without Git.** On the GitHub page click **Code**, then **Download ZIP**, and unzip it. The folder unzips as `Cloud-Integration-in-7-Days-main`; rename it to `Cloud-Integration-in-7-Days` and move it to your home folder, so the `cd ~/Cloud-Integration-in-7-Days/...` lines in the book work as printed. On Windows, unzip it inside the Ubuntu home (for example `mv /mnt/c/Users/<you>/Downloads/Cloud-Integration-in-7-Days-main ~/Cloud-Integration-in-7-Days` in the Ubuntu terminal), not on the Windows drive.

**In a Cloud Shell** (AWS CloudShell, Azure Cloud Shell or Google Cloud Shell), run the same `git clone` line inside the shell. Each Cloud Shell has its own home folder, so clone once in each one you use.

## 2. Open the day you need

Every day folder has its own README with the labs in it, and every lab folder has a README with the files, the prerequisites, the run order, the clean-up and the cost.

| Book chapter | Folder | What it builds |
|---|---|---|
| [Day 1. Move it, then automate it](day1/README.md) | [`day1/aws-to-gcp-vm-migration`](day1/aws-to-gcp-vm-migration/README.md), [`day1/azure-to-gcp-vm-migration`](day1/azure-to-gcp-vm-migration/README.md), [`day1/lab1-migration-workflow`](day1/lab1-migration-workflow/README.md) | An Apache VM migrated from AWS or Azure to Google Cloud as a disk image |
| | [`day1/multi-cloud-ansible-deployment`](day1/multi-cloud-ansible-deployment/README.md), [`day1/cross-cloud-iac`](day1/cross-cloud-iac/README.md) | One Ansible controller configuring NGINX on Google Cloud and Azure; OpenTofu definitions of the VMs |
| [Day 2. Ship every Tuesday](day2/README.md) | [`day2/github-actions-azure-webapp`](day2/github-actions-azure-webapp/README.md) | A GitHub Actions pipeline deploying an Express app to an Azure Web App |
| [Day 3. Containers and the orchestra](day3/README.md) | [`day3/jenkins-docker-pipeline`](day3/jenkins-docker-pipeline/README.md), [`day3/gke-helm-networkpolicy`](day3/gke-helm-networkpolicy/README.md) | A Jenkins pipeline that builds and pushes a Docker image; GKE Autopilot with Helm and a NetworkPolicy |
| [Day 4. A real application, locked down](day4/README.md) | [`day4/timpanogos-timesheet`](day4/timpanogos-timesheet/README.md) | A two-container app on GKE behind Identity-Aware Proxy |
| [Day 5. Identity is the perimeter](day5/README.md) | [`day5/service-accounts-bigquery`](day5/service-accounts-bigquery/README.md) | Least-privilege service accounts and keyless CI to BigQuery |
| [Day 6. The eight a.m. launch](day6/README.md) | [`day6/snowbird-lb-autoscaling`](day6/snowbird-lb-autoscaling/README.md) | A load-balanced, autoscaled web tier with a CDN and a load test |

Day 0 (setting up accounts and tools) and Day 7 (the leadership review) have no files. Script comments use the course's numbering: Week 4 and Lab 4.4 in a script mean Day 4 in the book. Each lab README maps the script names to the book's parts.

## 3. Run a lab

Work from inside the lab folder; every command in the book starts with a `cd` into one, for example:

```bash
cd ~/Cloud-Integration-in-7-Days/day4/timpanogos-timesheet
```

Most lab folders have a `scripts/` folder with three kinds of script:

```bash
bash scripts/deploy-<lab>.sh <PROJECT_ID>      # build the lab and print each checkpoint
bash scripts/verify-<lab>.sh <PROJECT_ID>      # where present: check what exists and what answers
bash scripts/rollback-<lab>.sh <PROJECT_ID>    # list the lab's resources, ask once, delete them
```

Add `-n` to a rollback script to only list, or `-y` to skip the question. The book uses the project ID `seven-day-cloud`; use your own. Some scripts take other arguments (a team suffix, a GitHub repository) or read environment variables such as `ZONE`; each lab README lists them, and each script's first lines say the same.

Do each lab by hand once, following the chapter, before you let a script do it. The scripts are optional wrappers around the commands the chapter already prints.

## Before you run anything

- **Tools.** Day 0's "Set up your laptop: Mac and Windows" installs every tool the labs use (`aws`, `az`, `gcloud` with the GKE auth plugin, `doctl`, `gh`, `git`, `node`, `kubectl`, `helm`, Docker Desktop, `tofu`). Each lab README lists the ones that lab needs.
- **Mac.** Run the commands in Terminal. Tools come from Homebrew as Day 0 shows.
- **Windows.** Use WSL 2 with Ubuntu and run every command in the Ubuntu terminal, with the clone in the Ubuntu home (`~`), not under `/mnt/c`. Install Docker Desktop with the WSL 2 backend and turn on its WSL integration for Ubuntu. Do not install Windows-native copies of the same tools alongside.
- **Cost.** These scripts create billable resources on your own cloud accounts. Set a budget alert first (Day 0, Cost guards), run the labs in a project or subscription you use only for learning, and delete what you build at the end of each day: each chapter's Clean up section, or the lab's rollback script, removes it.
- **Secrets.** Nothing in this repository holds a key, a token or an account ID. Keep it that way in your own copies: tokens go into the tool that asks for them (Jenkins credentials, GitHub secrets), never into a file you commit.

## When something fails

- Each lab in the book has an "If it fails" line under the steps that commonly break, a "Field notes" section with what went wrong in the author's runs, and a "Troubleshoot with an AI assistant" subsection on using an AI assistant to work through an error in that lab.
- Appendix C of the book is a troubleshooting index by day.
- The clouds change. If a command or flag no longer works, or you find a mistake, write to isijackson@gmail.com with the day, the step, what you ran and what you saw (the book's Errata and feedback section).

## License

Shared for readers of the book to learn with. Copyright © 2026 Jackson I. Isiko.
