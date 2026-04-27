#!/usr/bin/env bash
# Run scripts/bootstrap-linux.sh inside Ubuntu 24.04 (Docker) to catch Linux-only
# regressions without a real droplet. Mirrors the CI job test-linux-bootstrap.
#
# Usage:
#   ./scripts/test-linux-docker.sh
#   REPO_DIR=/path/to/dotfiles ./scripts/test-linux-docker.sh
#
# Requires: Docker. Optional: RUN_BOOTSTRAP=0 to only print the plan.

set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${RUN_BOOTSTRAP:=1}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found; install Docker Desktop or the docker.io package." >&2
  exit 1
fi

if [[ ! -f "$REPO_DIR/scripts/bootstrap-linux.sh" ]]; then
  echo "Expected $REPO_DIR/scripts/bootstrap-linux.sh — is REPO_DIR correct?" >&2
  exit 1
fi

echo "Using repo: $REPO_DIR"

if [[ "$RUN_BOOTSTRAP" == "0" ]]; then
  echo "RUN_BOOTSTRAP=0; exiting without running container."
  exit 0
fi

# Ubuntu image + non-root user with passwordless sudo (matches typical cloud VM).
docker run --rm \
  -e NONINTERACTIVE=1 \
  -e CI=1 \
  -v "$REPO_DIR:/work:rw" \
  -w /work \
  ubuntu:24.04 \
  bash -euxc '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends sudo ca-certificates
    if ! id -u ci &>/dev/null; then
      useradd -mU -s /bin/bash -G sudo ci
    fi
    echo "ci ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ci
    chmod 0440 /etc/sudoers.d/ci
    chown -R ci:ci /work
    # Avoid sudo -E: it keeps HOME=/root from the parent shell so bootstrap runs as
    # ci but targets /root (mkdir fails with Permission denied).
    sudo -u ci bash -c "export NONINTERACTIVE=1 CI=1; cd /work && ./scripts/bootstrap-linux.sh"
    echo "✅ bootstrap-linux.sh completed in container"
  '

echo "✅ Linux Docker bootstrap test passed"
