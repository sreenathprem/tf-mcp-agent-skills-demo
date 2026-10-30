#!/usr/bin/env bash
# Run 30 minutes before the demo. Checks every dependency and prints what to fix.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORG="<your-org>"
fail=0

ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; fail=1; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

echo "Tooling"
tf_version="$(terraform version -json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null)"
[[ -n "$tf_version" ]] && ok "terraform $tf_version" || bad "terraform not found"
command -v tfpolicy >/dev/null && ok "tfpolicy $(tfpolicy version)" || bad "tfpolicy not found (see README)"
command -v podman >/dev/null && ok "podman installed" || bad "podman not found"
if podman info >/dev/null 2>&1; then ok "podman machine running"; else bad "podman machine not running: podman machine start"; fi

echo "Agent skills (~/.claude/skills)"
for s in terraform-style-guide refactor-module terraform-test terraform-policy; do
  [[ -f "$HOME/.claude/skills/$s/SKILL.md" ]] && ok "$s" || bad "$s missing: npx skills add hashicorp/agent-skills"
done

echo "HCP Terraform"
eval "$(grep -E '^export TFE_(TOKEN|ADDRESS)=' ~/.zshrc 2>/dev/null)"
if [[ -z "${TFE_TOKEN:-}" ]]; then
  bad "TFE_TOKEN not exported in ~/.zshrc (the MCP server reads it from there)"
else
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TFE_TOKEN" \
    "${TFE_ADDRESS:-https://app.terraform.io}/api/v2/organizations/$ORG")"
  [[ "$code" == "200" ]] && ok "TFE_TOKEN can read organization $ORG" || bad "TFE_TOKEN rejected for $ORG (HTTP $code)"
fi

probe="$(mktemp -d)"
cat > "$probe/main.tf" <<EOF
module "probe" {
  source  = "app.terraform.io/$ORG/vpc/aws"
  version = "0.0.2"
}
EOF
if terraform -chdir="$probe" init -backend=false -input=false >/dev/null 2>&1; then
  ok "terraform CLI can download private modules"
else
  bad "terraform CLI cannot download private modules: run 'terraform login' (CLI token is separate from TFE_TOKEN)"
fi
rm -rf "$probe"

echo "Demo workspace"
for d in claims-portal policies; do
  [[ -e "$ROOT/$d" ]] && warn "$d/ already exists - run scripts/reset.sh for a clean start"
done
[[ -f "$ROOT/legacy/main.tf" ]] && ok "legacy/main.tf present" || bad "legacy/main.tf missing"

echo
if (( fail )); then
  echo "Fix the items marked ✘, then re-run."
  exit 1
fi

echo "All checks passed. Verifying golden answers..."
"$ROOT/scripts/verify-golden.sh"
