# Cache rule configuring cache settings and defining custom cache keys
resource "cloudflare_ruleset" "cache_everything" {
  zone_id     = var.cloudflare_zone_id
  name        = var.rule_name
  description = var.rule_desc
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules {
    ref         = var.rule_name
    description = var.rule_desc
    expression  = true
    action      = "set_cache_settings"
    action_parameters {
      cache = true
      respect_strong_etags = true
      edge_ttl {
        mode = "override_origin"
        default = "7"
      }
      browser_ttl {
        mode = "override_origin"
        default = "2678400" #31 days or 1 month in seconds
      }
    }
  }
  
}