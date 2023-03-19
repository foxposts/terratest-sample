provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

locals {
  acl_allow = var.web_acl_default_action == "allow" ? [true] : []
  acl_block = var.web_acl_default_action != "allow" ? [true] : []
}

resource "aws_wafv2_web_acl" "example" {
  name        = var.web_acl_name
  description = var.web_acl_description
  provider = aws.virginia
  scope       = "CLOUDFRONT"

  dynamic default_action {
    for_each = local.acl_allow
    content {
      allow {}
    }
  }
  dynamic default_action {
    for_each = local.acl_block
    content {
      block {}
    }
  }

  dynamic "rule" {
    for_each = var.web_acl_managed_rules
    content {
      name     = rule.value.rule_name
      priority = rule.value.priority
      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.rule_name
          vendor_name = "AWS"
          dynamic "rule_action_override" {
            for_each = toset(rule.value.statement.rule_action_override)
            content {
              action_to_use {
                count {}
              }
              name = rule_action_override.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name                = rule.value.visibility_config.metric_name
        sampled_requests_enabled   = rule.value.visibility_config.sampled_requests_enabled
      }

    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.web_acl_cloudwatch_metrics_enabled
    metric_name                = var.web_acl_metric_name
    sampled_requests_enabled   = var.web_acl_sampled_requests_enabled
  }
}


