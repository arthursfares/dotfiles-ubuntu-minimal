#!/usr/bin/env bash
# ============================================================================
#  i3blocks: power menu
# ----------------------------------------------------------------------------
#  Left-click the block to open a dmenu with:
#    * logout    -> exit i3 session (back to tty)
#    * reboot    -> systemctl reboot
#    * shutdown  -> systemctl poweroff
# ============================================================================

icon="${USER^^} "

case "$BLOCK_BUTTON" in
    1)  # left click — open the menu
        choice=$(printf '%s\n' logout reboot shutdown \
            | dmenu -i -p "Power:")
        case "$choice" in
            logout)   i3-msg exit ;;
            reboot)   systemctl reboot ;;
            shutdown) systemctl poweroff ;;
        esac
        ;;
esac

# Status line — just the icon
echo "$icon"
