# Day 5 lab: service accounts, BigQuery and no keys

Book: **Day 5: Identity is the perimeter**, Afternoon: the lab, Steps 1 to 12, and "The add-on: keyless CI with Workload Identity Federation", Add-on Steps 1 to 4. Script comments call this "Week 5 Lab 5.2".

Two service accounts: `names-report` holds exactly one role, BigQuery User, and `names-report-control` holds none. `report-vm` runs as the first and prints the top baby names for Texas and Utah from a BigQuery public dataset, with no key file anywhere; the metadata server supplies the credential. `control-vm` runs the same script as the second and gets a 403, which you then find in the audit log.

## Files

| File | Where it runs | What it does |
|---|---|---|
| `app/names.py` | On `report-vm` and `control-vm` | The query script of Step 8: the top five names for a state (default `TX`). `bigquery.Client()` takes no arguments, so the credential comes from the environment. |
| `keyless-ci/names.py` | GitHub Actions | A copy of `app/names.py`, at the top of the folder the add-on pushes. |
| `keyless-ci/.github/workflows/names-report.yml` | GitHub Actions | The nightly keyless report: runs on a schedule and on the Run workflow button, gets a short-lived credential through Workload Identity Federation, and runs the report for both states. Reads the repository variables `WIF_PROVIDER` and `REPORT_SA`. |
| `scripts/deploy-lab5.sh <PROJECT_ID>` | Cloud Shell or a laptop with `gcloud` | Steps 1 to 10 end to end, every validation printed. Safe to run twice. |
| `scripts/rollback-lab5.sh <PROJECT_ID> [-n] [-y]` | Same | Both VMs, the IAM binding, both service accounts, in that order. |
| `scripts/deploy-lab5-keyless-ci.sh <PROJECT_ID> <owner/repo>` | Laptop with `gcloud` and `gh` | The add-on: the pool and provider, the impersonation grant, the repository (created private if missing) with `keyless-ci/` pushed, and the first run. |
| `scripts/rollback-lab5-keyless-ci.sh <PROJECT_ID> <owner/repo> [-y] [--repo]` | Same | Removes the federation pool and its provider, and with `--repo` the GitHub repository. |

## Prerequisites

- **Accounts.** A Google Cloud project with billing. The add-on also needs a GitHub account.
- **Tools** (Day 0): `gcloud` for Steps 1 to 12 (Cloud Shell has it signed in); `gh` as well for the add-on, which runs on the laptop.
- **Check:**

```bash
cd ~/Cloud-Integration-in-7-Days/day5/service-accounts-bigquery
gcloud auth login
gcloud config set project seven-day-cloud
gh auth status
```

Skip `gcloud auth login` in Cloud Shell, and `gh auth status` until the add-on. If you work in Cloud Shell, clone this repository there too, so Step 8's `gcloud compute scp app/names.py` finds the file. A school sandbox can do every step up to the add-on, because nothing here needs a firewall rule.

## Mac and Windows

Nothing differs between a Mac and Ubuntu on Windows: the `vm$` lines run on the VMs, and `gcloud compute ssh` from Ubuntu creates its key in the Linux `~/.ssh` as it does on a Mac.

## Values to edit first

Every service-account e-mail carries the project ID, so yours differ in every one.

| Item | Book value | Override with (scripts) |
|---|---|---|
| Project | `seven-day-cloud` | the `<PROJECT_ID>` argument |
| Zone | `us-central1-a` | `ZONE` |
| Report identity | `names-report@<PROJECT_ID>.iam.gserviceaccount.com` | `SA` |
| Control identity | `names-report-control@<PROJECT_ID>.iam.gserviceaccount.com` | |
| Add-on repository | `you/names-report-ci`, private | the `<owner/repo>` argument |

The lab's shell variables, set in Step 1 and Step 2:

```bash
gcloud config set project seven-day-cloud
export PROJECT_ID=$(gcloud config get-value project)
SA_EMAIL=names-report@$PROJECT_ID.iam.gserviceaccount.com
CTL_EMAIL=names-report-control@$PROJECT_ID.iam.gserviceaccount.com
```

## Run order

**By hand (do this first).** Steps 1 to 12 in the chapter: enable the APIs (1), create the two accounts (2), grant `names-report` BigQuery User only (3), create `report-vm` and `control-vm` (4, 5), read both identities back (6), install the client on `report-vm` (7), copy the script and run it (8), prove there is no key (9), run it on `control-vm` (10), find the refusal in the audit log (11), verify (12). Steps 7 and 8, the core of it:

```bash
gcloud compute ssh report-vm --zone=us-central1-a
vm$ sudo apt-get update && sudo apt-get install -y python3-venv
vm$ python3 -m venv ~/bq && source ~/bq/bin/activate
vm$ pip install google-cloud-bigquery
```

From a second terminal (Cloud Shell or the laptop, in this folder), copy the script over, then run it on the VM:

```bash
gcloud compute scp app/names.py report-vm:~/names.py --zone=us-central1-a
vm$ python names.py TX
vm$ python names.py UT
```

Add `--tunnel-through-iap` to `ssh` and `scp` if SSH needed it, or paste the script into `nano names.py` on the VM.

**Scripted** (about two minutes):

```bash
bash scripts/deploy-lab5.sh seven-day-cloud
```

## Expected result

`report-vm` prints the Texas and Utah top-five lists; `ls` and `env` find no key file and no `GOOGLE_APPLICATION_CREDENTIALS` (exit codes of 1); the metadata server names `names-report@...` as the credential; `control-vm` gets a 403 naming `bigquery.jobs.create`; and the audit log shows that refusal. `gcloud iam service-accounts keys list --managed-by=user` for `names-report` prints `Listed 0 items.`

## Add-on: keyless CI with Workload Identity Federation

Needs Steps 1 to 3 of the main lab (the project, the APIs and `names-report` with its role); the VMs are not needed. Every command runs in the laptop terminal where both `gcloud` and `gh` are signed in.

By hand: Add-on Steps 1 to 4 in the chapter (create the pool and the GitHub provider, let the repository impersonate `names-report`, push `keyless-ci/` and set the two repository variables `WIF_PROVIDER` and `REPORT_SA`, wait ninety seconds, then run it). Scripted:

```bash
bash scripts/deploy-lab5-keyless-ci.sh seven-day-cloud you/names-report-ci
```

Replace `you` with your GitHub user. **Expected:** a green `nightly-names-report` run whose log ends with the two state lists and the credential-source lines, including "no key file in the runner home either". Wait ninety seconds after the bindings before the first run; the chapter's field notes say what happens if you do not.

## Clean up

VMs first, then the binding, then the accounts:

```bash
gcloud compute instances delete report-vm control-vm \
    --zone=us-central1-a --quiet
SA_EMAIL=names-report@$PROJECT_ID.iam.gserviceaccount.com
CTL_EMAIL=names-report-control@$PROJECT_ID.iam.gserviceaccount.com
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" --role="roles/bigquery.user"
gcloud iam service-accounts delete $SA_EMAIL --quiet
gcloud iam service-accounts delete $CTL_EMAIL --quiet
```

Or `bash scripts/rollback-lab5.sh seven-day-cloud` (it lists, asks once, deletes; `-n` only lists, `-y` skips the prompt). If you ran the add-on:

```bash
bash scripts/rollback-lab5-keyless-ci.sh seven-day-cloud \
    you/names-report-ci -y --repo
```

`--repo` deletes the GitHub repository with `gh repo delete`, which needs the `delete_repo` scope. Google keeps a deleted pool for 30 days, so the name `github` cannot be reused until then. Afterwards, `gcloud compute instances list` and `gcloud iam service-accounts list` should show nothing from the lab.

## Cost

About two and a half cents an hour for the two VMs (October 2026), and the query is inside BigQuery's free terabyte. A forgotten e2-small is about twelve dollars a month. The federation itself costs nothing.

## Do not skip

No service-account key, at any step: not for a quick test, not for a screenshot. If a page offers a Keys tab, leave it alone.

## When something fails

See the chapter's "If it fails" lines and field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 5".
