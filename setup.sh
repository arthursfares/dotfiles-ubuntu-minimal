#!/usr/bin/env bash
# ============================================================================
#  Ubuntu Server Minimal -> i3 personal desktop, automated setup
# ----------------------------------------------------------------------------
#  Run as your normal user (NOT root). sudo will be invoked when needed.
#    chmod +x setup.sh && ./setup.sh
# ============================================================================

set -euo pipefail

# ---------- helpers ---------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

append_once() {
    local line="$1" file="$2"
    touch "$file"
    grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# ---------- config ----------------------------------------------------------
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/arthursfares/dotfiles-ubuntu-minimal.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles-ubuntu-minimal}"
KITTY_THEME="${KITTY_THEME:-ENCOM}"

# ---------- pre-flight ------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "Run this script as your normal user (it will call sudo when needed)."
    exit 1
fi

sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ---------- 1. system update & base packages --------------------------------
log "Updating system and installing base packages"
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    xorg i3 i3blocks \
    kitty wget vim git unzip curl

# ---------- 2. auto-startx on tty1 ------------------------------------------
log "Configuring .xinitrc and auto-startx on tty1"
echo "exec i3" > "$HOME/.xinitrc"

if ! grep -q 'exec startx' "$HOME/.profile" 2>/dev/null; then
    cat >> "$HOME/.profile" <<'EOF'

# Auto-start X on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
  exec startx
fi
EOF
fi

# ---------- 3. i3 config from dotfiles repo ---------------------------------
log "Fetching i3 config from $DOTFILES_REPO"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

mkdir -p "$HOME/.config/i3"
I3_CONFIG="$HOME/.config/i3/config"

# If a real file (not a symlink) is already there, back it up.
if [[ -e "$I3_CONFIG" && ! -L "$I3_CONFIG" ]]; then
    mv "$I3_CONFIG" "$I3_CONFIG.bak.$(date +%s)"
    warn "Existing i3 config backed up next to it"
fi

ln -sfn "$DOTFILES_DIR/i3/config" "$I3_CONFIG"

# ---------- 4. kitty as default x-terminal-emulator -------------------------
log "Registering kitty as the default x-terminal-emulator"
KITTY_BIN="$(command -v kitty)"
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_BIN" 50
sudo update-alternatives --set x-terminal-emulator "$KITTY_BIN"

# ---------- 5. Google Chrome ------------------------------------------------
log "Installing Google Chrome"
if ! command -v google-chrome >/dev/null; then
    CHROME_TMP="$(mktemp -d)"
    wget -O "$CHROME_TMP/chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y "$CHROME_TMP/chrome.deb"
    rm -rf "$CHROME_TMP"
fi

# ---------- 6. JetBrainsMono Nerd Font --------------------------------------
log "Installing JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! fc-list | grep -qi 'JetBrainsMono Nerd'; then
    wget -P "$FONT_DIR" \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    ( cd "$FONT_DIR" && unzip -o JetBrainsMono.zip && rm JetBrainsMono.zip )
    fc-cache -fv
fi

# ---------- 7. kitty config + theme -----------------------------------------
log "Writing kitty.conf and fetching '$KITTY_THEME' theme"
mkdir -p "$HOME/.config/kitty"

if ! wget -q -O "$HOME/.config/kitty/current-theme.conf" \
        "https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/themes/${KITTY_THEME}.conf"; then
    warn "Couldn't fetch kitty theme '$KITTY_THEME'; run \`kitten themes\` later."
    : > "$HOME/.config/kitty/current-theme.conf"
fi

cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
# Font
font_family JetBrainsMono Nerd Font
font_size   12.0

# Padding
window_padding_width 4

# Theme (swap by overwriting current-theme.conf or via `kitten themes`)
include current-theme.conf
EOF

# ---------- 8. timezone -----------------------------------------------------
log "Setting timezone to America/Sao_Paulo"
sudo timedatectl set-timezone America/Sao_Paulo

# ---------- 9. audio (PipeWire) + bluetooth ---------------------------------
log "Installing PipeWire audio stack and Bluetooth"
sudo apt install -y \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack \
    pipewire-audio-client-libraries libspa-0.2-bluetooth \
    wireplumber pulseaudio-utils alsa-utils pavucontrol \
    bluez

systemctl --user enable --now pipewire pipewire-pulse wireplumber || \
    warn "Couldn't start PipeWire user services now; they'll start on next login."
sudo systemctl enable --now bluetooth
sudo usermod -aG audio "$USER"

# Wireplumber Bluetooth quality tweaks
log "Configuring wireplumber for Bluetooth"
mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"
cat > "$HOME/.config/wireplumber/wireplumber.conf.d/51-bluez.conf" <<'EOF'
monitor.bluez.properties = {
  bluez5.enable-sbc-xq     = true
  bluez5.enable-msbc       = true
  bluez5.enable-hw-volume  = true
  bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hsp_hs hsp_ag hfp_hf hfp_ag ]
}
EOF
systemctl --user restart wireplumber 2>/dev/null || true

# ---------- 10. bluetui (cargo) ---------------------------------------------
log "Installing bluetui via cargo (may take a few minutes)"
sudo apt install -y cargo libdbus-1-dev pkg-config
append_once 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.bashrc"
export PATH="$HOME/.cargo/bin:$PATH"

if ! command -v bluetui >/dev/null; then
    cargo install bluetui
fi

# ---------- 11. GitHub CLI --------------------------------------------------
log "Installing GitHub CLI"
if ! command -v gh >/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi

# ---------- done ------------------------------------------------------------
cat <<EOF

============================================================
  All done. A few things still need to be done by hand:
------------------------------------------------------------
  1. REBOOT (or at least log out & back in) so:
       * \`audio\` group membership takes effect
       * PipeWire user services start under the new session
  2. \`gh auth login\`            -> authenticate GitHub CLI
  3. \`bluetui\`                  -> pair Bluetooth devices
  4. Optional: \`kitten themes\`  -> pick a different kitty theme

  Your i3 config lives at:
    $DOTFILES_DIR/i3/config
  and is symlinked into ~/.config/i3/config. Edit it in the
  repo, \`git pull\` on new machines, then reload with Mod+Shift+R.
============================================================
EOF
