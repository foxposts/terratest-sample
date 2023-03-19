locals {
  settings-name_prefix = "terraform-with-terratest-staging"
}

module "web_host" {
  source                 = "../module/web_host"
  web_host_waf_arn = module.security.web_host_waf_arn
  settings-name_prefix   = "${local.settings-name_prefix}"
  allowed_cors_origins   = ["https://s3-example.hashicorp.com"]
  web_host_html_list = { "index_document" = "index.html"}
}

module "security" {
  source                 = "../module/security"
  web_acl_default_action = "allow"
  web_acl_name           = "example"
  web_acl_description    = "example web acl"
  web_acl_managed_rules  = {
    "managed_rule1" = {
      rule_name         = "AWSManagedRulesCommonRuleSet"
      priority          = 10
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
      statement = {
        rule_action_override = ["SizeRestrictions_QUERYSTRING", "NoUserAgent_HEADER"]
      }
    }
    "managed_rule2" = {
      rule_name         = "AWSManagedRulesLinuxRuleSet"
      priority          = 20
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesLinuxRuleSet"
        sampled_requests_enabled   = true
      }
      statement = {
        rule_action_override = []
      }
    }
  }
  web_acl_cloudwatch_metrics_enabled = true
  web_acl_metric_name                = "sample_metric"
  web_acl_sampled_requests_enabled   = true
}