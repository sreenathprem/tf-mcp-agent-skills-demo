# Walkthrough: Terraform MCP Server + HashiCorp Agent Skills

**Scenario:** an app team inherits the hand-written "claims portal" stack and moves it
onto the platform team's approved modules and HCP Terraform, using an AI agent
from start to finish.

**What it shows:** the MCP server gives the agent live facts, and skills give it
HashiCorp's know-how.

| | Terraform MCP Server | Agent Skills |
|---|---|---|
| What it is | A local server the agent calls for live data | Markdown playbooks the agent loads on demand |
| Answers | *What is true right now?* Latest versions, provider docs, **your private registry**, your workspaces and runs | *How should this be done?* Style guide, module refactoring, `terraform test`, Terraform Policy |
| Without it | Versions and arguments from training data; no idea your approved modules exist | Generic HCL; tests and policies in outdated or invented syntax |

**Length:** about 40 minutes. Every act stands alone, so you can skip acts.

| Act | Topic | Feature shown | Time |
|---|---|---|---|
| 0 | Setup and the "before" (optional baseline) | MCP off vs on | 3–5 min |
| 1 | What do we already have? | MCP: private + public registry | 5 min |
| 2 | Refactor onto approved modules | Skills: `refactor-module`, `terraform-style-guide` + MCP provider docs | 10 min |
| 3 | Prove it works without a cloud account | Skill: `terraform-test` | 7 min |
| 4 | Guardrails: Sentinel to Terraform Policy | Skill: `terraform-policy` | 8 min |
| 5 | Into HCP Terraform, plan only | MCP: `terraform` toolset | 7 min |

**Replace `<your-org>`** everywhere (prompts, `CLAUDE.md`, `scripts/`, `golden/`)
with your own HCP Terraform organization. That organization needs `vpc`,
`ecs-cluster` and `nginx-ecs` AWS modules in its private registry for Acts 1, 2
and 5.

---

## Setup

1. `podman machine start` (the MCP server runs in a container).
2. `terraform login` (the CLI needs its own app.terraform.io token to download
   private modules; this is separate from the `TFE_TOKEN` the MCP server uses).
3. `./scripts/reset.sh`, then `./scripts/preflight.sh`. Everything must be green,
   and the script ends by verifying all golden answers.
4. Open this folder in VS Code and start Claude Code. Approve the project MCP
   server from `.mcp.json` when prompted. It adds the `terraform` toolset
   (workspaces, runs, variable sets) to your existing registry toolsets.
   Check with `/mcp` that **terraform** is connected.
5. For Act 5: check the `AWS Credentials` variable set in `<your-org>`
   works for a plan in `eu-central-1` (it needs `ssm:GetParameter`,
   `ec2:DescribeAvailabilityZones`, and STS).

---

## Act 0: Setup and the "before" (3–5 min)

**Look at:**
- `legacy/main.tf`: one file, `aws ~> 4.0`, hardcoded AMI, `m5.2xlarge`, SSH open
  to the world, a **public-read bucket full of claim documents**, copy-pasted
  instances.
- `/mcp`: the Terraform MCP server is connected (local container, uses your token).
- `ls ~/.claude/skills`: skills from `github.com/hashicorp/agent-skills`, installed
  with `npx skills add hashicorp/agent-skills`.
- `CLAUDE.md`: the agent's project rules: private registry first, never apply.

**Optional baseline:** disable the terraform server in `/mcp`, then run the Act 1
prompt. Without MCP the agent cannot see `<your-org>`, so it suggests writing a
VPC from scratch or using a public module. Turn MCP back on, run `/clear`, and
continue.

---

## Act 1: "What do we already have?" (5 min)

**Prompt:**

```text
Read legacy/main.tf. Before changing anything, use the Terraform MCP server to
find out what our private registry in <your-org> already offers for this
stack, and get the latest AWS provider version. Give me a table mapping each
group of legacy resources to an approved module (with version) or "gap".
Don't write any code yet.
```

**Watch for:**
- `search_private_modules` → lists the modules in `<your-org>`
- `get_private_module_details` for `vpc`, `ecs-cluster`, `nginx-ecs` (inputs, outputs, resources)
- `get_latest_provider_version` → the current 6.x release (legacy is on 4.x)

**Expected result:**

| Legacy resources | Approved module |
|---|---|
| VPC, subnets, IGW, route table | `<your-org>/vpc/aws` 0.0.2 |
| ECS cluster, EC2 hosts, ALB, security groups | `<your-org>/ecs-cluster/aws` 0.0.6 |
| Task definition, service | `<your-org>/nginx-ecs/aws` 1.23.0 |
| S3 claim documents bucket | **gap**: no approved module |

---

## Act 2: Refactor onto approved modules (10 min)

**Prompt:**

```text
Refactor legacy/main.tf into a new root module in claims-portal/ using the
approved private modules. For the S3 gap, write a local module in
claims-portal/modules/secure-bucket; check the current AWS provider docs for
the S3 resources first.

Requirements:
- no hardcoded AMI: use the AWS-published ECS-optimised AMI SSM parameter
- mandatory tags owner, cost-center, data-classification on every resource
- instance types restricted to t3.micro/small/medium/large and m6i.large
- the legacy stack is already live in a workspace: add moved blocks so nothing
  is destroyed and recreated just because its address changed

Run fmt and validate when done.
```

**Watch for:**
- **Skills** `refactor-module` and `terraform-style-guide` load (shown in the transcript).
- **MCP** `search_providers` / `get_provider_details` for `s3_bucket_*` resources:
  current split resources, not the deprecated inline `acl` and `versioning` blocks.
- Standard file layout: `terraform.tf`, `providers.tf`, `variables.tf` (validated,
  alphabetical), `outputs.tf`, `locals.tf`.
- **Tags through provider `default_tags`**, because the approved modules have no
  `tags` input.
- `moved.tf` maps `aws_instance.ecs_node_1` → `module.ecs_cluster.aws_instance.ecs_instance[0]`
  and so on.
- Where the approved modules use different names (ALB, bucket), `moved` keeps
  state but the plan still shows replacements. The agent should say so.

**Fallback:** `rsync -a --exclude tests --exclude backend.tf --exclude .terraform golden/claims-portal/ claims-portal/`

---

## Act 3: Prove it works, no cloud account needed (7 min)

**Prompt:**

```text
Write Terraform tests for claims-portal and for the secure-bucket module.
Mock the AWS provider so no credentials are needed. Cover the security
defaults of the bucket and the input validation of the root module. Run them.
```

**Watch for:**
- **Skill** `terraform-test` loads.
- `mock_provider "aws"` with `mock_data` for `aws_availability_zones` (the vpc module
  indexes zone names, so random mock data would break it) and `aws_ssm_parameter`.
- `expect_failures = [var.instance_type]` style negative tests.
- Expected result: everything passes (golden: 6 root tests, 7 module tests).

**Try it:** open `claims-portal/modules/secure-bucket/main.tf`, change
`block_public_policy = true` to `false`, and re-run
`terraform -chdir=claims-portal/modules/secure-bucket test`. The public access
test fails. Change it back.

**Fallback:** `rsync -a --exclude backend.tf --exclude .terraform golden/claims-portal/ claims-portal/`

---

## Act 4: Guardrails, Sentinel to Terraform Policy (8 min)

**Prompt 4a (conversion):**

```text
sentinel/restrict-ec2-instance-type.sentinel is one of our existing Sentinel
policies. Convert it to Terraform Policy in policies/, with a policy test, and
run tfpolicy validate and tfpolicy test.
```

**Prompt 4b (new policies):**

```text
Add Terraform Policies in policies/ for:
1. mandatory tags owner, cost-center, data-classification on every AWS resource
   (default_tags must count)
2. S3 buckets must block public access and use KMS encryption
3. modules may only come from app.terraform.io/<your-org> (local modules OK)
Write policy tests that show the legacy bucket and the legacy m5.2xlarge
instances would be rejected. Run tfpolicy validate and tfpolicy test.
```

**Watch for:**
- **Skill** `terraform-policy` loads. It checks the installed `tfpolicy` version first.
- Sentinel `param` → `input` block; actions filter → `operations = ["create", "update"]`.
- `tags_all` (not `tags`), so provider `default_tags` count.
- The module-source policy only allows modules from the registry searched in Act 1.

**Known quirk:** the skill is written for `tfpolicy` 0.2/0.3, and the golden
answers were built with 0.5.0. Two differences showed up: `core::try()` does not
replace `null`, and `meta.provider_type` is not available in test mocks. If the
agent runs into either, let it read the error and fix it.

**Fallback:** `cp -R golden/policies policies`

---

## Act 5: Into HCP Terraform, plan only (7 min)

**Prompt:**

```text
Use the Terraform MCP server to create a workspace claims-portal-dev in the
"aws" project of <your-org>: Terraform 1.16.6, remote execution, tags
app:claims-portal and env:dev. Attach the "AWS Credentials" variable set to it.
Then add the cloud block to claims-portal and run a speculative terraform plan.
Finally, read the plan back from HCP Terraform through MCP and summarise it as
a change review: what gets created, what is risky, and what you would raise
with the platform team.
```

**Watch for:**
- `list_terraform_projects` → `create_workspace` → `list_variable_sets` →
  `attach_variable_set_to_workspaces`
- `terraform plan` streams from HCP Terraform. It's a **speculative plan, so it
  cannot be applied**.
- `list_runs` / `get_plan_logs` / `get_plan_json_output` → summary.
- Review findings to expect: the `ecs-cluster` module puts hosts in public
  subnets with public IPs, the ALB listens on HTTP only, and the module
  hardcodes 2 target-group attachments.
- Apply, discard, and delete tools (`action_run`, `delete_workspace_safely`, …)
  are not registered unless the server runs with `ENABLE_TF_OPERATIONS=true`.
  It is off here. You can restrict further with `--tools` to allowlist
  individual tools.

**Fallback:** create the workspace in the UI, `cp golden/claims-portal/backend.tf claims-portal/`,
then `terraform -chdir=claims-portal init && terraform -chdir=claims-portal plan`.

---

## Summary

- **Act 1:** reused 3 approved modules, found 1 gap. *(MCP private registry)*
- **Act 2:** current provider, style-guide layout, `moved` blocks. *(skills + MCP docs)*
- **Act 3:** 13 tests, no cloud credentials. *(skill)*
- **Act 4:** Sentinel converted, new guardrails with tests. *(skill)*
- **Act 5:** workspace, variable set and plan review, no apply possible. *(MCP TFE toolset)*

---

## FAQ

**What does the model see?** The files it reads, plus what MCP returns (module
metadata, plan logs and JSON). The MCP server runs locally in a container. The
token is only sent to HCP Terraform and is never shown to the model. Values
marked sensitive are redacted in plan output.

**What can the AI do in HCP Terraform?** Whatever the token can do, minus the
gated tools. Use a team token scoped to one project, keep `ENABLE_TF_OPERATIONS`
off, and use `--toolsets` / `--tools` to limit tools further.

**Does it work with Terraform Enterprise (self-hosted)?** Yes. Set `TFE_ADDRESS`.

**Are skills Claude-only?** No. They are plain Markdown (`SKILL.md`) in an open
format, and the MCP server is a standard protocol. Both work with other MCP- and
skills-capable agents.

**Can we write our own skills?** Yes. A skill is a folder with a `SKILL.md`.
Teams usually start with their module standards and naming conventions.

---

## Reset

```bash
./scripts/reset.sh            # removes claims-portal/ and policies/
# and delete workspace claims-portal-dev in <your-org> if Act 5 ran
```
