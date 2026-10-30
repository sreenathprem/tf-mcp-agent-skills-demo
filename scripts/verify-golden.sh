#!/usr/bin/env bash
# Proves the fallback ("golden") answers work: fmt, validate, terraform test, tfpolicy.
# Needs no AWS credentials. Needs a working app.terraform.io login for the private modules.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GOLDEN="$ROOT/golden"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "terraform fmt (check only)"
terraform fmt -recursive -check "$GOLDEN/claims-portal"

step "claims-portal: init (no backend), validate, test"
terraform -chdir="$GOLDEN/claims-portal" init -backend=false -input=false >/dev/null
terraform -chdir="$GOLDEN/claims-portal" validate
terraform -chdir="$GOLDEN/claims-portal" test

step "modules/secure-bucket: init, test"
terraform -chdir="$GOLDEN/claims-portal/modules/secure-bucket" init -input=false >/dev/null
terraform -chdir="$GOLDEN/claims-portal/modules/secure-bucket" test

step "policies: tfpolicy validate, test"
(cd "$GOLDEN/policies" && tfpolicy validate && tfpolicy test)

printf '\n\033[1;32mGolden answers verified.\033[0m\n'
