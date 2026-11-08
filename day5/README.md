# Day 5. Identity is the perimeter

Book chapter: **Day 5: Identity is the perimeter**. One lab and an add-on.

| Book part | Folder | Scripts | What it does |
|---|---|---|---|
| Afternoon: the lab, Steps 1 to 12 | [`service-accounts-bigquery/`](service-accounts-bigquery/README.md) | `deploy-lab5.sh`, `rollback-lab5.sh` | Two service accounts, one with exactly one role; a VM that carries it and can query BigQuery with no key file, and a control VM that is refused |
| The add-on: keyless CI with Workload Identity Federation, Add-on Steps 1 to 4 | [`service-accounts-bigquery/keyless-ci/`](service-accounts-bigquery/README.md#add-on-keyless-ci-with-workload-identity-federation) | `deploy-lab5-keyless-ci.sh`, `rollback-lab5-keyless-ci.sh` | The same report as a nightly GitHub Actions workflow that borrows the service account's identity with no key anywhere |

Nothing from Days 1 to 4 is needed.

## Get here

```bash
cd ~/Cloud-Integration-in-7-Days/day5/service-accounts-bigquery
```

If you do not have the folder yet, see [Get the files](../README.md#1-get-the-files).

## Cost

An e2-small and an e2-micro together are about two and a half cents an hour (October 2026); the query scans a few megabytes of a public table, inside the free terabyte. The whole lab is a few cents. The federation in the add-on costs nothing.

## Do not skip

No service-account key, at any step. The lab is the proof that you never needed one.

## When something fails

Read the "If it fails" lines under each step, the chapter's field notes, the lab's "Troubleshoot with an AI assistant" subsection, and Appendix C, "Day 5", of the book.
