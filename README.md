# Terraform MCP Server + Agent Skills demo

A 40-minute live demo. An AI agent moves a legacy AWS stack onto approved
private-registry modules, adds tests and policies, and plans it in HCP
Terraform, using:

- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server): live
  registry, private registry, and HCP Terraform workspace/run data
- [HashiCorp Agent Skills](https://github.com/hashicorp/agent-skills):
  `terraform-style-guide`, `refactor-module`, `terraform-test`, `terraform-policy`

**Walkthrough:** [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md)

**Before you start:** replace `<your-org>` in `CLAUDE.md`, `scripts/` and
`golden/` with your own HCP Terraform organization. It needs `vpc`,
`ecs-cluster` and `nginx-ecs` AWS modules in its private registry.

## Layout

| Path | Purpose |
|---|---|
| `legacy/main.tf` | The "before": monolithic, hardcoded, insecure stack |
| `sentinel/` | An existing Sentinel policy to convert in Act 4 |
| `CLAUDE.md` | Project rules for the agent (private registry first, never apply) |
| `.mcp.json` | Terraform MCP server with the `registry`, `registry-private` and `terraform` toolsets |
| `golden/` | Verified answers for every act, used as fallbacks |
| `scripts/preflight.sh` | Pre-demo checks, then verifies the golden answers |
| `scripts/verify-golden.sh` | fmt, validate, `terraform test`, `tfpolicy validate/test` on `golden/` |
| `scripts/reset.sh` | Removes generated `claims-portal/` and `policies/` |

Generated during the demo (removed by `reset.sh`): `claims-portal/`, `policies/`.

## Prerequisites

- Terraform 1.16+ (`brew upgrade hashicorp/tap/terraform`)
- `tfpolicy` CLI 0.5.0 from <https://releases.hashicorp.com/tfpolicy/>
  (the Homebrew tap only has 0.1.0)
- Podman with a running machine (runs the MCP server container)
- `TFE_TOKEN` exported in `~/.zshrc` (read by the MCP server) **and** `terraform login`
  (used by the CLI to download private modules)
- Agent skills in `~/.claude/skills`: `npx skills add hashicorp/agent-skills`

## Quick start

```bash
./scripts/reset.sh
./scripts/preflight.sh
```
