#!/usr/bin/env bash
# Single entry point for local / agent runs. For CI, see .github/workflows/test.yml
#
# Usage:
#   ./scripts/test-all.sh            # static + mac (if Darwin) + docker (if docker)
#   ./scripts/test-all.sh static     # test-static.sh only
#   ./scripts/test-all.sh mac        # tests/run_tests.zsh + scripts/test.sh
#   ./scripts/test-all.sh docker     # Ubuntu 24.04 + bootstrap-linux.sh
#   ./scripts/test-all.sh full       # static + mac + docker
#
# Env: SKIP_DOCKER=1  SKIP_MAC=1

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

mode="${1:-default}"

run_static() {
  ./scripts/test-static.sh
}

run_mac() {
  if [[ "${SKIP_MAC:-0}" == "1" ]]; then
    echo "==> mac: SKIP_MAC=1"
    return 0
  fi
  ZSH_BIN=""
  for z in /opt/homebrew/bin/zsh /usr/local/bin/zsh /bin/zsh; do
    if [[ -x "$z" ]]; then ZSH_BIN="$z"; break; fi
  done
  if [[ -z "$ZSH_BIN" ]]; then
    echo "==> mac: no zsh found" >&2
    return 1
  fi
  echo "==> mac: $ZSH_BIN tests/run_tests.zsh"
  "$ZSH_BIN" tests/run_tests.zsh
  echo "==> mac: scripts/test.sh (shellcheck + file checks; uses bash in shebang)"
  "$ZSH_BIN" scripts/test.sh
}

run_docker() {
  if [[ "${SKIP_DOCKER:-0}" == "1" ]]; then
    echo "==> docker: SKIP_DOCKER=1"
    return 0
  fi
  REPO_DIR="$REPO_DIR" ./scripts/test-linux-docker.sh
}

case "$mode" in
  static) run_static ;;
  mac) run_mac ;;
  docker) run_docker ;;
  full)
    run_static
    if [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
      run_mac
    else
      echo "==> full: skip mac (not on Darwin; run mac job on a Mac or CI)"
    fi
    run_docker
    ;;
  default)
    run_static
    if [[ "$(uname -s 2>/dev/null)" == "Darwin" ]] && [[ "${SKIP_MAC:-0}" != "1" ]]; then
      run_mac
    fi
    if command -v docker &>/dev/null && [[ "${SKIP_DOCKER:-0}" != "1" ]]; then
      run_docker
    else
      echo "==> default: skip docker (install Docker or run: $0 docker)"
    fi
    ;;
  *)
    echo "Usage: $0 [static|mac|docker|full|default]" >&2
    exit 2
    ;;
esac

echo "==> test-all: done"
