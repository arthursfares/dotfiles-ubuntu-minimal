#!/usr/bin/env bash

bt_powered() {
    bluetoothctl show | grep -q "Powered: yes"
}

bt_connected_name() {
    # Find the MAC of any currently-connected device
    local mac name
    mac=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2; exit}')

    # Fallback for older bluetoothctl versions that lack "devices Connected"
    if [ -z "$mac" ]; then
        for m in $(bluetoothctl devices | awk '{print $2}'); do
            if bluetoothctl info "$m" 2>/dev/null | grep -q "Connected: yes"; then
                mac="$m"
                break
            fi
        done
    fi

    [ -z "$mac" ] && return 1
    name=$(bluetoothctl info "$mac" | awk -F': ' '/^\s*Name:/ {print $2; exit}')
    echo "$name"
}

case "$BLOCK_BUTTON" in
    1)  # left click — open bluetui in a terminal
        "${TERMINAL:-kitty}" -e bluetui &
        ;;
    2)  # middle click — toggle power
        if bt_powered; then
            bluetoothctl power off >/dev/null
        else
            bluetoothctl power on >/dev/null
        fi
        ;;
    3)  # right click — choose a paired device to connect
        if ! bt_powered; then
            notify-send "Bluetooth" "Power is off" 2>/dev/null
        else
            chosen=$(bluetoothctl devices | sed 's/^Device //' | dmenu -i -p "Connect:")
            if [ -n "$chosen" ]; then
                mac=${chosen%% *}
                bluetoothctl connect "$mac" >/dev/null &
            fi
        fi
        ;;
esac

# Status line
if ! bt_powered; then
    echo "BT off"
elif name=$(bt_connected_name); then
    echo "BT $name"
else
    echo "BT on"
fi
