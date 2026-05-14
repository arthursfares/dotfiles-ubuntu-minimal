#!/usr/bin/env bash
# ============================================================================
#  i3blocks: NordVPN status
# ----------------------------------------------------------------------------
#  Shows one of three states:
#    * logged out    -> red    "VPN logged out"
#    * disconnected  -> yellow "VPN disconnected"
#    * connected     -> green  "VPN <City>, <Country>"
#
#  Left-click toggles connect/disconnect (no-op when logged out).
# ============================================================================
set -u

# nordvpn not installed yet -> render nothing
command -v nordvpn >/dev/null 2>&1 || exit 0

# Grab status. `timeout` guards against a hung daemon.
# Strip ANSI color codes and the leading "- " bullets nordvpn prints.
status_raw=$(timeout 2 nordvpn status 2>/dev/null \
    | sed -e 's/\x1b\[[0-9;]*[mGKHF]//g' \
          -e 's/^[[:space:]]*-[[:space:]]*//')

is_logged_out() { echo "$status_raw" | grep -qi 'not logged in'; }
is_connected()  { echo "$status_raw" | grep -qi '^Status:[[:space:]]*Connected'; }

# Left-click: toggle (only if logged in)
if [[ "${BLOCK_BUTTON:-0}" == "1" ]] && ! is_logged_out; then
    if is_connected; then
        nordvpn disconnect >/dev/null 2>&1 &
    else
        nordvpn connect    >/dev/null 2>&1 &
    fi
fi

icon="VPN"

if is_logged_out; then
    text="$icon logged out"
    color="#ff5555"
elif is_connected; then
    country=$(echo "$status_raw" | awk -F': *' '/^Country:/ {print $2; exit}')
    city=$(echo "$status_raw"    | awk -F': *' '/^City:/    {print $2; exit}')
    if [[ -n "$city" && -n "$country" ]]; then
        loc="$city, $country"
    else
        loc="${city}${country}"
    fi
    text="$icon ${loc:-connected}"
    color="#50fa7b"
else
    text="$icon disconnected"
    color="#f1fa8c"
fi

# i3blocks output: full_text / short_text / color
echo "$text"
echo "$text"
echo "$color"
