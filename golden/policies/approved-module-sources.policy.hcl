# Registry modules must come from the organization's private registry, so
# teams build on the platform team's approved modules. Local modules
# (./ and ../ paths) are allowed.

input "approved_namespace" {
  type    = string
  default = "app.terraform.io/<your-org>/"
}

module_policy "*" "approved_module_sources" {
  filter = meta.source != null && !core::startswith(meta.source, "./") && !core::startswith(meta.source, "../")

  enforce {
    condition     = core::startswith(meta.source, input.approved_namespace)
    error_message = "Module source '${meta.source}' is not approved. Use a module from ${input.approved_namespace} or request one from the platform team."
  }
}
