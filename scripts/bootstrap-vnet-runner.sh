#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_REPOSITORY:?}" "${RUNNER_NAME:?}" "${RUNNER_REGISTRATION_TOKEN:?}"
[[ "$RUNNER_REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && "$RUNNER_NAME" =~ ^tinyjava-[a-z0-9]+$ ]]
repo_url="https://github.com/$RUNNER_REPOSITORY"
runner_home=/opt/actions-runner
runner_user=github-runner

if [[ ! -f "$runner_home/.runner" ]]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get -o Acquire::Retries=3 update
  apt-get -o Acquire::Retries=3 install -y ca-certificates curl git gnupg jq postgresql-client libicu70

  install -d -m 0755 /etc/apt/keyrings
  curl --fail --silent --show-error --location https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor --batch --yes -o /etc/apt/keyrings/azure-cli.gpg
  chmod 0644 /etc/apt/keyrings/azure-cli.gpg
  printf '%s\n' 'deb [arch=amd64 signed-by=/etc/apt/keyrings/azure-cli.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main' \
    > /etc/apt/sources.list.d/azure-cli.list
  apt-get -o Acquire::Retries=3 update
  apt-get -o Acquire::Retries=3 install -y azure-cli

  : "${RUNNER_VERSION:?}" "${RUNNER_SHA256:?}"
  [[ "$RUNNER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$RUNNER_SHA256" =~ ^[0-9a-f]{64}$ ]]
  archive=$(mktemp)
  trap 'rm -f -- "$archive"' EXIT
  curl --fail --silent --show-error --location --retry 3 \
    --output "$archive" "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  printf '%s  %s\n' "$RUNNER_SHA256" "$archive" | sha256sum --check

  if ! id "$runner_user" >/dev/null 2>&1; then
    useradd --system --create-home --shell /bin/bash "$runner_user"
  fi
  install -d -o "$runner_user" -g "$runner_user" -m 0750 "$runner_home"
  tar -xzf "$archive" -C "$runner_home"
  chown -R "$runner_user:$runner_user" "$runner_home"
  cd "$runner_home"
  runuser -u "$runner_user" -- ./config.sh --unattended --replace \
    --url "$repo_url" --name "$RUNNER_NAME" --labels "$RUNNER_NAME" --token "$RUNNER_REGISTRATION_TOKEN"
else
  cd "$runner_home"
  jq -e --arg url "$repo_url" --arg name "$RUNNER_NAME" \
    '.gitHubUrl == $url and .agentName == $name' .runner >/dev/null
fi

unset RUNNER_REGISTRATION_TOKEN
if [[ ! -f .service ]]; then
  ./svc.sh install "$runner_user"
fi
./svc.sh start
systemctl is-active --quiet "$(cat .service)"
