#!/usr/bin/env bash
# Week 4 Lab 4.3 rollback: containers, network and local images.   rollback-lab4-1.sh [-n] [-y]
set -uo pipefail; DRY=0; YES=0
for a in "$@"; do case "$a" in -n) DRY=1;; -y) YES=1;; *) echo "usage: $0 [-n] [-y]"; exit 2;; esac; done
C=$(docker ps -a --format '{{.Names}}' | grep -E '^(backend|frontend)$' | tr '\n' ' '); N=$(docker network ls --format '{{.Name}}' | grep -x timesheet)
I=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'timesheet-(backend|frontend)' | tr '\n' ' ')
echo "Lab 4.3 resources on this machine:"; printf '  containers: %s\n  network: %s\n  images: %s\n' "${C:-none}" "${N:-none}" "${I:-none}"
[ -z "$C$N$I" ] && { echo "Nothing to delete."; exit 0; }; [ "$DRY" = 1 ] && exit 0
if [ "$YES" != 1 ]; then read -r -p "Delete all of the above? [y/N] " ans; [ "$ans" = y ] || { echo "Aborted."; exit 1; }; fi
[ -n "$C" ] && docker rm -f $C >/dev/null && echo "removed containers"; [ -n "$N" ] && docker network rm timesheet >/dev/null && echo "removed network"
[ -n "$I" ] && docker rmi -f $I >/dev/null 2>&1 && echo "removed images"; echo "LAB4_1_ROLLBACK_DONE"
