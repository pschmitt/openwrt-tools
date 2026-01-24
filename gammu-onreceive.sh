#!/usr/bin/env bash

cd "$(dirname "$(readlink -f -- "$0")")" || return 9
# shellcheck source=lib/echo.sh
source lib/echo.sh || exit 2

load_mmsms_defaults() {
  local config_path="${MMSMS_CONFIG:-/etc/mmsms.conf}"

  if [[ ! -f "$config_path" ]]
  then
    echo_warn "missing config file: $config_path"
    return 1
  fi

  # shellcheck disable=SC1090,SC1091 # Optional runtime config; resolved on target system.
  source "$config_path"
}

get_modem_device() {
  local gammu_config="${GAMMU_CONFIG:-/var/gammu-default.conf}"

  if [[ ! -f "$gammu_config" ]]
  then
    return 1
  fi

  awk -F ' *= *' '/^device *= */ { print $2; exit }' "$gammu_config"
}

get_own_phone_number() {
  local modem_device
  modem_device="$(get_modem_device || true)"

  if [[ -z "$modem_device" ]]
  then
    return 0
  fi

  local attempt response number
  for (( attempt=1; attempt<=3; attempt++ ))
  do
    response=$(printf 'AT+CNUM\r\n' | socat -t 1 - "${modem_device},crnl")

    number=$(grep -E '^\+CNUM' <<< "$response" | \
      sed -nr 's/.*"(\+\d+)".*/\1/p'
    )

    if [[ -n "$number" ]]
    then
      printf '%s\n' "$number"
      return 0
    fi

    sleep 1
  done
}

read_sms_text_from_id() {
  local sms_id="$1"
  local inbox_path="${GAMMU_INBOX_PATH:-/var/sms/inbox}"
  local sms_file=""

  if [[ -z "$sms_id" ]]
  then
    return 0
  fi

  if [[ -f "$sms_id" ]]
  then
    sms_file="$sms_id"
  elif [[ -f "$inbox_path/$sms_id" ]]
  then
    sms_file="$inbox_path/$sms_id"
  fi

  if [[ -n "$sms_file" ]]
  then
    cat "$sms_file"
  fi
}

post_webhook() {
  local recipient="$1"
  local sender="$2"
  local text="$3"
  local date_value="$4"
  local payload resp rc code body log_body

  payload="$(jq -n \
    --arg recipient "$recipient" \
    --arg sender "$sender" \
    --arg text "$text" \
    --arg date "$date_value" \
    --argjson ignore false \
    '{recipient:$recipient, sender:$sender, text:$text, date:$date, ignore:$ignore}')"

  resp="$(curl -sS -m 10 -H 'Content-Type: application/json' -w $'\n%{http_code}' \
    -X POST -d "$payload" "$WEBHOOK_URL" 2>&1)"
  rc=$?
  if (( rc != 0 ))
  then
    echo_warn "webhook delivery error rc='$rc' output='${resp:0:200}'"
    return "$rc"
  fi

  code="${resp##*$'\n'}"
  body="${resp%$'\n'*}"
  log_body="${body:0:200}"
  if [[ "$code" =~ ^2 ]]
  then
    echo_info "webhook response code='$code' body='$log_body'"
  else
    echo_warn "webhook response code='$code' body='$log_body'"
  fi
}

main() {
  local sms_ids=("$@")
  local sms_count="${SMS_MESSAGES:-1}"
  local idx
  local recipient
  local sender
  local text
  local date_value

  if ! load_mmsms_defaults
  then
    return 1
  fi

  if [[ ! "$sms_count" =~ ^[0-9]+$ ]]
  then
    sms_count=1
  fi

  recipient="$(get_own_phone_number || true)"

  if [[ -z "${WEBHOOK_URL:-}" ]]
  then
    echo_warn "WEBHOOK_URL is not set"
    return 1
  fi

  for (( idx=1; idx<=sms_count; idx++ ))
  do
    local sender_var="SMS_${idx}_NUMBER"
    local text_var="SMS_${idx}_TEXT"
    local decoded_text_var="DECODED_${idx}_TEXT"
    local sms_id="${sms_ids[$((idx-1))]:-}"

    sender="${!sender_var:-}"
    text="${!text_var:-}"
    if [[ -z "$text" ]]
    then
      text="${!decoded_text_var:-}"
    fi
    if [[ -z "$text" ]]
    then
      text="$(read_sms_text_from_id "$sms_id")"
    fi

    date_value="$(date -Iseconds)"

    echo_info "forwarding sms from '${sender:-unknown}' to webhook"
    post_webhook "$recipient" "$sender" "$text" "$date_value"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  set -eo pipefail

  main "$@"
fi
