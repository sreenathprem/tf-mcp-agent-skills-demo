#!/usr/bin/env bash
# Removes everything the AI generated during a run-through so the next one starts clean.
# Does not touch legacy/, sentinel/, golden/, or anything in HCP Terraform.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for d in claims-portal policies; do
  if [[ -e "$ROOT/$d" ]]; then
    rm -rf "${ROOT:?}/$d"
    echo "removed $d/"
  fi
done

cat <<'EOF'

Local reset done. If you ran Act 5, also clean up HCP Terraform:
  - delete workspace "claims-portal-dev" in <your-org> (it has no resources: plan only)
EOF
