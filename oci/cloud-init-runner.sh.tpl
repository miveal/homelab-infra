#!/bin/bash
set -e

# --- System deps ---
apt-get update
apt-get install -y curl jq git unzip

# --- Docker ---
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# --- GitHub Actions Runner ---
RUNNER_DIR=/home/ubuntu/actions-runner
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
  | jq -r .tag_name | sed 's/v//')

curl -fsSL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-arm64-$${RUNNER_VERSION}.tar.gz"

tar xzf runner.tar.gz
rm runner.tar.gz
chown -R ubuntu:ubuntu "$RUNNER_DIR"

# --- Rejestracja runnera ---
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${github_token}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${github_repo}/actions/runners/registration-token" \
  | jq -r .token)

sudo -u ubuntu "$RUNNER_DIR/config.sh" \
  --url "https://github.com/${github_repo}" \
  --token "$REG_TOKEN" \
  --name "${runner_name}" \
  --labels "self-hosted,Linux,ARM64,docker,oci,heavy" \
  --unattended \
  --replace

# --- Systemd service (auto-start po restarcie VM) ---
"$RUNNER_DIR/svc.sh" install ubuntu
"$RUNNER_DIR/svc.sh" start
