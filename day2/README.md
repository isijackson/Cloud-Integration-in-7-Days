# Day 2. Ship every Tuesday

Book chapter: **Day 2: Ship every Tuesday**. One lab in the afternoon.

| Book part | Folder | What it does |
|---|---|---|
| Afternoon: the lab, Steps 0 to 17 | [`github-actions-azure-webapp/`](github-actions-azure-webapp/README.md) | An Express app in a GitHub repository, deployed to an Azure Web App on every push by a GitHub Actions workflow that Azure's Deployment Center writes |
| The same build on the other clouds, On Google Cloud | [`github-actions-azure-webapp/cloud-run.yml`](github-actions-azure-webapp/README.md#the-google-cloud-twin-cloud-runyml) | The same app deployed to Cloud Run with a keyless GitHub Actions workflow (documented, not run in class) |

Nothing from Day 1 is needed.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day2/github-actions-azure-webapp
```

If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files).

## Accounts for today

An Azure subscription with App Service quota for Free F1 in at least one region, and a GitHub account. Google Cloud only for the optional twin.

## Cost

F1 is free and GitHub Actions minutes are free for public repositories. If your region has no F1 quota and you fall back to B1, it is about 13 dollars a month (October 2026), so delete the resource group the same day.

## When something fails

Read the "If it fails" lines under each step, the chapter's field notes, the lab's "Troubleshoot with an AI assistant" subsection, and Appendix C, "Day 2", of the book.
