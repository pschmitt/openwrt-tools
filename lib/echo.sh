# vim: set ft=sh:
# shellcheck shell=bash

CRON="${CRON:-}"
NO_COLOR="${NO_COLOR:-}"
DEBUG="${DEBUG:-}"
VERBOSE="${VERBOSE:-}"

echo_fancy() {
  local prefix="$1"
  local color="$2"
  shift 2

  if [[ -n "$NO_COLOR" || -n "$CRON" ]]
  then
    echo "$prefix $*" >&2
    return 0
  fi

  echo -e "${color}${prefix}\e[0m $*" >&2
}

echo_info() {
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
