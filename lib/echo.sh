# vim: set ft=sh:
# shellcheck shell=bash

CRON="${CRON:-}"
DEBUG="${DEBUG:-}"
NO_COLOR="${NO_COLOR:-}"
NO_WARNING="${NO_WARNING:-}"
VERBOSE="${VERBOSE:-}"
ECHO_SYSLOG="${ECHO_SYSLOG:-}"
QUIET="${QUIET:-}"

echo_fancy() {
  local prefix="$1"
  local color="$2"
  shift 2

  local line
  line="$prefix $*"

  if [[ -n "$NO_COLOR" || -n "$CRON" ]]
  then
    echo "$line" >&2
  else
    echo -e "${color}${prefix}\e[0m $*" >&2
  fi

  # Guard-clause: mirror to syslog only when enabled
  [[ -z "$ECHO_SYSLOG" ]] && return 0
  logger -t "$SCRIPT_NAME" "$line"
}

echo_info() {
  # Respect QUIET by suppressing info-level logs
  if [[ -n "$QUIET" ]]
  then
    return 0
  fi
  local prefix="INF"
  local color='\e[1m\e[34m'

  echo_fancy "$prefix" "$color" "$*"
}

# shellcheck disable=SC2317
echo_success() {
  local prefix="OK"
  local color='\e[1m\e[32m'

  echo_fancy "$prefix" "$color" "$*"
}

# shellcheck disable=SC2317
echo_warning() {
  [[ -n "$NO_WARNING" ]] && return 0
  local prefix="WRN"
  local color='\e[1m\e[33m'

  echo_fancy "$prefix" "$color" "$*"
}

# shellcheck disable=SC2317
echo_error() {
  local prefix="ERR"
  local color='\e[1m\e[31m'

  echo_fancy "$prefix" "$color" "$*"
}

# shellcheck disable=SC2317
echo_debug() {
  [[ -z "${DEBUG}${VERBOSE}" ]] && return 0
  local prefix="DBG"
  local color='\e[1m\e[35m'

  echo_fancy "$prefix" "$color" "$*"
}

# shellcheck disable=SC2317
echo_dryrun() {
  local prefix="DRY"
  local color='\e[1m\e[35m'

  echo_fancy "$prefix" "$color" "$*"
}

echo_confirm() {
  if [[ -n "$NOCONFIRM" ]]
  then
    return 0
  fi

  local msg_pre=$'\e[31mASK\e[0m'
  local msg="${1:-"Continue?"}"
  local yn
  read -r -n1 -p "${msg_pre} ${msg} [y/N] " yn
  [[ "$yn" =~ ^[yY] ]]
  local rc="$?"
  echo # append a NL
  return "$rc"
}
