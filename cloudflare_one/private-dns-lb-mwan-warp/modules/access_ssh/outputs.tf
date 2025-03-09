output "ssh_pub_key" {
    value = "${cloudflare_zero_trust_access_short_lived_certificate.ssh_short_lived.public_key}"
}