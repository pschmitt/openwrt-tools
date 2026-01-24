#!/usr/bin/env bash

# Print usage information.
usage() {
  cat <<'EOF'
Usage: gammu-send-sms.sh <message>

Send an SMS using gammu-smsd-inject. The destination number and config file
can be overridden with GAMMU_DEST and MMSMS_CONFIG. DEFAULT_RECIPIENT_DE is
loaded from /etc/mmsms.conf by default.
EOF
}

# Load defaults from /etc/mmsms.conf.
load_mmsms_defaults() {
  local config_path="${MMSMS_CONFIG:-/etc/mmsms.conf}"

  if [[ ! -f "$config_path" ]]
  then
    printf 'Missing config file: %s\n' "$config_path" >&2
    return 1
  fi

  # shellcheck disable=SC1090,SC1091 # Optional runtime config; resolved on target system.
  source "$config_path"
}

# Send an SMS with gammu-smsd-inject.
send_sms() {
  local message="$1"
  local config_file="${GAMMU_CONFIG:-/var/gammu-default.conf}"
  local dest_number

  if ! load_mmsms_defaults
  then
    return 1
  fi

  dest_number="${GAMMU_DEST:-${DEFAULT_RECIPIENT_DE:-}}"
  if [[ -z "$dest_number" ]]
  then
    printf 'No recipient set. Define GAMMU_DEST or DEFAULT_RECIPIENT_DE in %s.\n' \
      "${MMSMS_CONFIG:-/etc/mmsms.conf}" >&2
    return 1
  fi

  gammu-smsd-inject -c "$config_file" TEXT "$dest_number" -unicode -text "$message"
}

# Entrypoint.
main() {
  if [[ "$#" -eq 0 ]]
  then
    usage
    return 1
  fi

  case "$1" in
    -h|--help)
      usage
      return 0
      ;;
  esac

  local message="$*"
  send_sms "$message"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
  main "$@"
fi
