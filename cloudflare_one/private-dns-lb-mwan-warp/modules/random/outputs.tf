output "argo_id" {
  value = tostring(random_id.tunnel_secret.b64_std)
}