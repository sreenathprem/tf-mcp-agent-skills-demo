provider "aws" {
  region = var.region

  # The approved platform modules do not expose a tags input, so mandatory
  # tags are applied to every resource through provider default_tags.
  default_tags {
    tags = local.common_tags
  }
}
