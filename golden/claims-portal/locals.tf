locals {
  name_prefix = "${var.application}-${var.environment}"

  common_tags = {
    application         = var.application
    environment         = var.environment
    owner               = var.owner
    cost-center         = var.cost_center
    data-classification = var.data_classification
    managed-by          = "terraform"
  }
}
