terraform {
  cloud {
    organization = "<your-org>"

    workspaces {
      name    = "claims-portal-dev"
      project = "aws"
    }
  }
}
