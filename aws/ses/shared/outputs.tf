output "identity_arn" {
  description = "SES v2 apex domain identity ARN. Referenced by string in the aws/identity/<env> send grants."
  value       = aws_sesv2_email_identity.this.arn
}

output "identity_name" {
  description = "The verified SES sending domain (apex)."
  value       = aws_sesv2_email_identity.this.email_identity
}

output "dkim_tokens" {
  description = "Easy DKIM tokens. Publish each as <token>._domainkey.mojerodos.pl CNAME -> <token>.dkim.amazonses.com in the cloudflare/dns follow-up PR."
  value       = aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens
}

output "mail_from_domain" {
  description = "Custom MAIL FROM subdomain — needs an MX and an SPF TXT record (cloudflare/dns follow-up PR)."
  value       = aws_sesv2_email_identity_mail_from_attributes.this.mail_from_domain
}

output "mail_from_mx_value" {
  description = "Region-specific MX target for the MAIL FROM subdomain."
  value       = "feedback-smtp.eu-central-1.amazonses.com"
}
