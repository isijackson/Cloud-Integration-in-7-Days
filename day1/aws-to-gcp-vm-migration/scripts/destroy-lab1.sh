#!/usr/bin/env bash
# One-shot teardown for Week 1 Lab 1. Runs the AWS and GCP cleanup scripts, skipping any cloud
# whose CLI is not logged in. Usage: destroy-lab1.sh <GCP_PROJECT_ID> [-n] [-y] [--route-b]
# --route-b (AWS only) also deletes Route B's import role ROLE (default vmimport-$USER); see 05-cleanup-aws.sh.
# In the Vocareum setup the AWS CLI lives in the Vocareum terminal and gcloud in Cloud Shell,
# so run 05-cleanup-aws.sh and 06-cleanup-gcp.sh separately there; this wrapper is for a
# machine that has both CLIs configured.
set -uo pipefail
export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-2}}"; export AWS_DEFAULT_REGION="$AWS_REGION"
PROJECT="${1:?usage: $0 <GCP_PROJECT_ID> [-n] [-y] [--route-b]}"; shift
D=$(cd "$(dirname "$0")" && pwd); GCP_ARGS=()
for a in "$@"; do [ "$a" = --route-b ] || GCP_ARGS+=("$a"); done   # the GCP side has no import role
if aws sts get-caller-identity >/dev/null 2>&1; then bash "$D/05-cleanup-aws.sh" "$@"; else echo "AWS CLI not logged in: skipping AWS (run 05-cleanup-aws.sh -y in AWS CloudShell)"; fi
if gcloud auth print-access-token >/dev/null 2>&1; then bash "$D/06-cleanup-gcp.sh" "$PROJECT" ${GCP_ARGS[@]+"${GCP_ARGS[@]}"}; else echo "gcloud not logged in: skipping GCP (run 06-cleanup-gcp.sh in Cloud Shell)"; fi
