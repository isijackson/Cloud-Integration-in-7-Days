#!/usr/bin/env bash
# Removes the federation pool (and its provider) and, with --repo, the GitHub repository.
#   rollback-lab5-keyless-ci.sh <PROJECT_ID> <owner/repo> [-y] [--repo]
set -uo pipefail
PROJECT="${1:?usage: $0 <PROJECT_ID> <owner/repo> [-y] [--repo]}"; REPO="${2:?}"; shift 2; YES=0; RM=0
for a in "$@"; do case "$a" in -y) YES=1;; --repo) RM=1;; esac; done
g() { gcloud "$@" --project="$PROJECT" --quiet 2>/dev/null; }
P=$(g iam workload-identity-pools describe github --location=global --format="value(name)")
echo "Keyless CI resources:"; printf '  pool: %s\n  repo: %s\n' "${P:-none}" "$([ "$RM" = 1 ] && echo "$REPO" || echo '(kept; pass --repo)')"
[ -z "$P" ] && [ "$RM" = 0 ] && { echo "Nothing to delete."; exit 0; }
if [ "$YES" != 1 ]; then read -r -p "Delete? [y/N] " ans; [ "$ans" = y ] || exit 1; fi
[ -n "$P" ] && g iam workload-identity-pools delete github --location=global && echo "pool deleted (soft-deleted for 30 days by Google)"
[ "$RM" = 1 ] && gh repo delete "$REPO" --yes && echo "repo deleted"
echo "LAB5_KEYLESS_CI_ROLLBACK_DONE"
