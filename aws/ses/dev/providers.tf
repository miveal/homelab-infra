# Same region as aws/ses/shared — SES is regional and the dev config set must live alongside
# the apex identity it is used with (eu-central-1).
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.tags
  }
}
