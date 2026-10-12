#!/usr/bin/env bash

set -u

get_battery() {
    local capacity

    for file in /sys/class/power_supply/BAT*/capacity; do
        if [[ -r "$file" ]]; then
            read -r capacity < "$file"
            printf '%s\n' "$capacity"
            return
        fi
    done

    printf 'N/A\n'
}

get_wifi() {
    local state
    state=$(nmcli -t -f WIFI radio 2>/dev/null) || state="disabled"
    printf '%s\n' "${state:-disabled}"
}

get_bluetooth() {
    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
        printf 'yes\n'
    else
        printf 'no\n'
    fi
}

case "${1:-status}" in
    status)
        get_battery
        get_wifi
        get_bluetooth
        ;;

    wifi)
        if [[ "$(get_wifi)" == "enabled" ]]; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        ;;

    bluetooth)
        if [[ "$(get_bluetooth)" == "yes" ]]; then
            bluetoothctl power off
        else
            bluetoothctl power on
        fi
        ;;

    *)
        printf 'Unknown action: %s\n' "$1" >&2
        exit 1
        ;;
esac
