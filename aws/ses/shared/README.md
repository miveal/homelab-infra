# aws/ses/shared — native SES domain foundation (apex, account-global)

The account-wide native Amazon SES sending foundation for `mojerodos.pl`: the verified apex
domain identity, its Easy DKIM keypair, the custom MAIL FROM subdomain, and the account-level
suppression list. This root is **account-global** (`Environment=shared`, like `aws/billing`) —
an SES email identity is unique per account+region, so the domain is verified **once here**
and shared by every environment. Per-env behaviour (config set, event routing, IAM grant)
lives in `aws/ses/<env>/` and `aws/identity/<env>/`.

**Creates:**

- `mojerodos-ses` — the apex `mojerodos.pl` SES v2 domain identity with **Easy DKIM**
  (AWS-managed RSA-2048 keypair). No default configuration set is attached (see Why).
- Custom **MAIL FROM** `mail.mojerodos.pl` — disjoint from Resend's `send.mojerodos.pl`.
- Account+region **suppression list** (bounce + complaint).

## Why these choices

- **Shared apex identity, per-env config sets.** An `aws_sesv2_email_identity` is unique per
  account+region, so dev and a future prod cannot each own a `mojerodos.pl` identity in
  `eu-central-1`. Verifying once here and expressing "dev vs prod" through **configuration
  set + sandbox/production access + IAM scoping** is what lets prod onboard later by adding
  only new per-env leaves — this root stays untouched.
- **No default config set on the identity.** A default could point at only one env's set;
  instead each principal passes `ConfigurationSetName` explicitly (dev = `mojerodos-dev-ses`),
  authorized by the grant in `aws/identity/dev`.
- **`mail.mojerodos.pl` MAIL FROM (not `send.*`).** `send.mojerodos.pl` is Resend's envelope
  subdomain (`feedback-smtp.eu-west-1`). Keeping them disjoint lets native SES
  (`feedback-smtp.eu-central-1`) coexist with Resend during the migration, then retire Resend.

## Deliberately NOT here

- **The `ses:SendEmail` grant + permissions-boundary widening** — those attach to the app
  principal and live in `aws/identity/dev` (house rule: IAM principal grants live in
  `identity/`, and the CI leaf matrix can't order `ses` before `identity`).
- **The dev configuration set + event destination** — `aws/ses/dev`.
- **DKIM CNAMEs + MAIL FROM MX/SPF DNS records** — `cloudflare/dns` (separate provider/PR;
  uses this root's `dkim_tokens` / `mail_from_domain` outputs).
- **Production access (sandbox exit)** — a per-region manual AWS Support request, not
  Terraform-managed. See Post-apply.

## Apply

Via the normal repo flow: PR → CI `plan` → merge → prod-gated `apply`. No local apply.

## Post-apply manual steps (human)

1. **Publish DNS** (cloudflare PR): the 3 DKIM CNAMEs from `terraform output dkim_tokens`
   (`<token>._domainkey.mojerodos.pl → <token>.dkim.amazonses.com`), the MAIL FROM MX
   (`mail.mojerodos.pl → feedback-smtp.eu-central-1.amazonses.com`), and the MAIL FROM SPF
   TXT (`v=spf1 include:amazonses.com ~all`). Wait until the identity's DKIM status is
   `SUCCESS`.
2. **Sandbox**: the `eu-central-1` account starts in SES **sandbox** (send only to verified
   recipients, rate-capped) — the correct state for dev. Verify a couple of test recipients
   to exercise the send path.
3. **Production access** is a **prod-onboarding** step (console → SES → *Request production
   access*, or `PutAccountDetails`) — per-region, one-time, exits sandbox for the whole
   region. Do not request it just for dev.
