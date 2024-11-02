#!/usr/bin/env bash

DEST="${DEST:-/usr/bin}"
NETBIRD_REPO="netbirdio/netbird"
NETBIRD_ARCH="${NETBIRD_ARCH:-armv6}"

usage() {
  echo "Usage: $(basename "$0") REPO"
  echo
  echo "Examples:"
  echo "  $(basename "$0") $NETBIRD_REPO"
}

git_latest_version() {
  local gh_repo="$1"
  git ls-remote --tags "https://github.com/${gh_repo}" | \
    sed -rn 's|.*refs/tags/v?([^\^]+)(\^\{\})?|\1|p' | \
    sort -V | tail -1
}

netbird_version() {
  netbird version
}

netbird_latest_version() {
  git_latest_version "$NETBIRD_REPO"
}

netbird_is_up_to_date() {
  local latest_version
  latest_version="$(netbird_latest_version)"
  echo "$latest_version"  # to avoid another request, we "return" the version
  [[ "$(netbird_version)" == "$latest_version" ]]
}

fetze_netbird() {
  local latest_version
  if latest_version="$(netbird_is_up_to_date)"
  then
    echo "netbird is up-to-date ($latest_version)"
    return 0
  fi

  local url="https://github.com/${NETBIRD_REPO}/releases/download/v${latest_version}/netbird_${latest_version}_linux_${NETBIRD_ARCH}.tar.gz"
  wget -qO- "$url" | tar -xzvf - -C "$DEST" netbird
  /etc/init.d/netbird restart
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  set -e

  case "$1" in
    nb|netbird*)
      fetze_netbird
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
fi
