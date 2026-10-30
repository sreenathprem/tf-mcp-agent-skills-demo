# Every taggable AWS resource must carry the mandatory tags. tags_all is
# checked, so tags applied through provider default_tags count.

policy {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

input "required_tags" {
  type    = list(string)
  default = ["owner", "cost-center", "data-classification"]
}

resource_policy "*" "mandatory_tags" {
  filter = core::try(attrs.tags_all, null) != null

  locals {
    tag_keys     = core::keys(core::try(attrs.tags_all, {}))
    missing_tags = [for tag in input.required_tags : tag if !core::contains(local.tag_keys, tag)]
  }

  enforce {
    condition     = core::length(local.missing_tags) == 0
    error_message = "Missing mandatory tags: ${core::join(", ", local.missing_tags)}. Set them in the provider default_tags block."
  }
}
