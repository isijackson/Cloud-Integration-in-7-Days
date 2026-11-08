# Day 2 lab: a GitHub Actions pipeline to an Azure Web App

Book: **Day 2: Ship every Tuesday**, Afternoon: the lab, Steps 0 to 17. Script comments call this "Week 2 Lab 2.2".

A three-file Express app (the Canyon soccer club's schedule) goes into a GitHub repository. Azure's Deployment Center connects the Web App to the repository and writes a GitHub Actions workflow, so every push to `main` builds, tests and deploys the site. The live-change drill times a push from commit to live.

## Files

| File | What it does |
|---|---|
| `canyon-schedule/package.json` | The app's name, its `start` and `test` commands, and its one dependency, Express. |
| `canyon-schedule/index.js` | The Express server that answers `/` with the schedule page. Step 14 adds the Field 3 notice here. |
| `canyon-schedule/.gitignore` | Keeps `node_modules` out of the repository. |
| `scripts/deploy-lab2.sh <team>` | Steps 1 to 15 end to end: the `canyon-schedule` repository, the resource group `canyon-soccer-rg`, the Linux plan `canyon-asp` (Free F1, falling back to B1 when F1 quota is 0), the Web App `canyon-schedule-<team>` on the newest Node LTS, the GitHub Actions connection, and the timed live change. |
| `scripts/rollback-lab2.sh [-n] [-y] [--repo]` | Deletes the resource group, and the repository with `--repo`. |
| `cloud-run.yml` | The Google Cloud twin (see below). Not used by the Azure lab. |

The workflow file in your repository, `.github/workflows/main_canyon-schedule-<team>.yml`, is written by Azure in Step 9; it is not in this folder.

## Prerequisites

- **Accounts.** An Azure subscription with App Service quota for Free F1 in at least one region, and a GitHub account.
- **Tools** (Day 0): `git`, `node` (Node.js 22 or newer), `gh` and `az`, both signed in.
- **Check:**

```bash
cd ~/Cloud-Integration-in-7-Days/day2/github-actions-azure-webapp
node --version
gh auth status
az login --use-device-code
az account show --query name -o tsv
```

`gh auth status` must say Logged in to github.com; Step 5 walks through `gh auth login` if not. The scripts run on a laptop with both `gh` and `az` signed in, not in Cloud Shell.

**If your laptop Azure CLI is blocked** (a school sandbox with Conditional Access), every `az` command runs unchanged in Azure Cloud Shell in the portal (`>_`, Bash, No storage account required), and every console step works as written. Only Step 7, which needs a browser on your own machine, is laptop only.

## Mac and Windows

- **Mac.** The Terminal runs zsh, which reads a pasted `#` and `<team>` differently from bash; that is why Step 0 sets variables once and the command blocks carry no comments or angle brackets.
- **Windows (WSL Ubuntu).** `npm start` runs inside Ubuntu, and WSL 2 forwards `localhost`, so http://localhost:3000 opens in the Windows browser; `explorer.exe http://localhost:3000` from a second Ubuntu window opens it for you. Type the `LAB` path rather than dragging a folder.

## Values to edit first (Step 0)

Set these once in every terminal window you use; replace `yourteam` with a suffix of lowercase letters and digits (the Web App name must be unique across Azure) and `yourgithubuser` with your GitHub user:

```bash
TEAM=yourteam
GH_USER=yourgithubuser
LAB="$HOME/Cloud-Integration-in-7-Days/day2/github-actions-azure-webapp"
APP=canyon-schedule-$TEAM
echo $APP
```

For the script, the team suffix is the argument, and `LOCATION` picks the region (default eastus). The book's run is in West US 2, because its subscription had no F1 quota in eastus.

## Run order

**By hand (do this first).** Steps 0 to 17 in the chapter: create the Web App (Steps 1 to 4), sign in to GitHub and create the repository (Steps 5 and 6), copy the app in and run it (Step 7), push (Step 8), connect the Deployment Center (Step 9), watch the pipeline (Steps 10 to 13), make the live change (Steps 14 to 16) and verify (Step 17). Step 7, in your clone of your own repository:

```bash
cp -r "$LAB/canyon-schedule/." .
npm install
npm start
```

**Scripted** (does Steps 1 to 15 in about 8 minutes):

```bash
LOCATION=westus2 bash scripts/deploy-lab2.sh $TEAM
```

Drop `LOCATION=westus2` if your subscription has F1 quota in East US.

## Expected result

`https://canyon-schedule-<team>.azurewebsites.net` serves the schedule page; the Actions tab shows green runs with a build step (`npm install, build, and test`) and a deploy step (`Deploy to Azure Web App`); the repository holds one publish-profile secret; and after Step 14 the Field 3 notice is live within about a minute of the push (the book's drill: 0 min 46 s).

## Clean up

```bash
az group delete -n canyon-soccer-rg --yes --no-wait
```

or

```bash
bash scripts/rollback-lab2.sh -y
```

The repository can stay as your evidence; it costs nothing. If you keep it, delete the publish-profile secret, which points at an app that no longer exists:

```bash
SECRET=$(gh secret list -R "$GH_USER/canyon-schedule" \
    --json name --jq '.[].name' | grep PUBLISHPROFILE)
gh secret delete "$SECRET" -R "$GH_USER/canyon-schedule"
```

To delete the repository too, `bash scripts/rollback-lab2.sh -y --repo`; that needs the `delete_repo` scope (`gh auth refresh -h github.com -s delete_repo`), or use the repository's Settings, Danger Zone on GitHub.

## Cost

F1 is free; B1 is about 13 dollars a month (October 2026), about two cents for the hour the lab takes, if you delete the resource group afterwards. GitHub Actions minutes are free for public repositories.

## Do not skip

If you delete and recreate the Web App, the publish-profile secret is stale and every deploy fails with Unauthorized (401) while the build stays green. Reconnect the Deployment Center, or rerun the Step 9 command with `--force`.

## The Google Cloud twin: cloud-run.yml

Book: "The same build on the other clouds", On Google Cloud. The same app deployed to Cloud Run by GitHub Actions with Workload Identity Federation, so no key is stored anywhere. The book marks it **Vendor docs, not a class run**.

1. Follow the chapter's seven console steps (or the CLI equivalent it prints): a service account `canyon-deploy` with Cloud Run Admin, Artifact Registry Writer and Service Account User; a Workload Identity pool and GitHub provider limited to your repository; the five APIs.
2. Set three repository variables (not secrets): `WIF_PROVIDER`, `DEPLOY_SA`, `GCP_PROJECT`.
3. Copy the file into your own repository as `.github/workflows/cloud-run.yml`, push, and open the URL from the run summary (`LIVE_URL`).

Clean up (the chapter's commands):

```bash
gcloud run services delete canyon-schedule --region us-central1 --quiet
gcloud artifacts repositories delete cloud-run-source-deploy \
    --location us-central1 --quiet
gcloud iam workload-identity-pools delete github --location=global --quiet
gcloud iam service-accounts delete \
    canyon-deploy@seven-day-cloud.iam.gserviceaccount.com --quiet
```

Cloud Run at zero traffic costs nothing; the stored image costs cents a month.

## When something fails

See the chapter's "If it fails" lines (a green run with the Azure placeholder still showing means the `app-name` in the workflow does not match, or `package.json` lost its `start` line), its field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 2".
