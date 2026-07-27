# aws/ses/dev — dev SES configuration set

The dev environment's native SES sending configuration for `mojerodos.pl`. The verified apex
domain identity + DKIM + MAIL FROM live in the account-global `aws/ses/shared` root; this leaf
owns only the **dev-specific** config set and its event routing.

**Creates:**

- `mojerodos-dev-ses` — a configuration set with TLS **REQUIRE** on delivery, reputation
  metrics enabled, sending enabled, and bounce+complaint **suppression**.
- `mojerodos-dev-ses-cw` — a CloudWatch event destination
  (send / delivery / bounce / complaint / reject).

## Why these choices

- **Config set, not another identity.** dev and prod share the one apex identity in
  `aws/ses/shared` (an SES identity is unique per account+region). The env boundary is this
  config set plus the IAM grant that pins the dev principal to it.
- **CloudWatch, not SNS, for dev.** No extra topic/subscription/IAM, and the suppression lists
  already auto-drop bad addresses. SNS is the prod upgrade, when the app has a real
  bounce/complaint consumer to feed.
- **TLS REQUIRE + suppression** — in-transit encryption and per-env auto-suppression of
  addresses that bounce or complain.

## Deliberately NOT here

- **The apex identity, DKIM, MAIL FROM, account suppression** — `aws/ses/shared`.
- **The `ses:SendEmail` grant + boundary widening** — `aws/identity/dev` (attaches to the
  `mojerodos-dev-app` principal; scopes it to this config set).
- **DNS records** — `cloudflare/dns`.

## Apply

Via the normal repo flow: PR → CI `plan` → merge → prod-gated `apply`. No local apply. This
leaf and `aws/ses/shared` apply independently (a config set does not reference the identity in
Terraform), so leaf ordering does not matter.

## Post-apply

The dev app sends with `ConfigurationSetName = mojerodos-dev-ses` using the `mojerodos-dev-app`
credentials. While the account is in SES sandbox (dev's normal state), send only to verified
recipient addresses; confirm the CloudWatch SES metrics register the events.
