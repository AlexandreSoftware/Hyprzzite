#!/bin/bash
# build-desktop.sh — desktop-only additions (runs after build-common.sh)

set -ouex pipefail

### ── Gaming tools ─────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    gamemode \
    mangohud \
    gamescope \
    protontricks

### ── Decky Loader service (pre-installed in Bazzite, ensure enabled) ─────────
systemctl enable plugin_loader.service 2>/dev/null || true

### ── arRPC (Discord Rich Presence daemon) ────────────────────────────────────
# Installed via npm; Vesktop detects it automatically
npm install -g arrpc 2>/dev/null || true

### ── Install desktop-specific scripts ───────────────────────────────────────
install -Dm755 /ctx/scripts/kde-primary-switch         /usr/bin/kde-primary-switch
install -Dm755 /ctx/scripts/kde-display-esports-desk   /usr/bin/kde-display-esports-desk
install -Dm755 /ctx/scripts/kde-display-tv-desk        /usr/bin/kde-display-tv-desk
install -Dm755 /ctx/scripts/kde-display-aoc-only       /usr/bin/kde-display-aoc-only
install -Dm755 /ctx/scripts/kde-display-tv-only        /usr/bin/kde-display-tv-only
install -Dm755 /ctx/scripts/gamescope-htpc-session     /usr/bin/gamescope-htpc-session
install -Dm755 /ctx/scripts/install-decky-plugins      /usr/bin/install-decky-plugins
install -Dm755 /ctx/scripts/setup-steam-shortcuts      /usr/bin/setup-steam-shortcuts

### ── Gamescope HTPC session file ─────────────────────────────────────────────
install -Dm644 /ctx/config/sessions/gamescope-htpc.desktop \
    /usr/share/wayland-sessions/gamescope-htpc.desktop

### ── Bootstrap + create-usb scripts ──────────────────────────────────────────
install -Dm755 /ctx/scripts/bootstrap.sh          /usr/bin/bootstrap-usb
install -Dm755 /ctx/scripts/create-bootstrap-usb  /usr/bin/create-bootstrap-usb

### ── Settings web UI ─────────────────────────────────────────────────────────
mkdir -p /etc/skel/.config/hyprzzite-settings
install -Dm644 /ctx/config/hyprzzite-settings/server.py \
    /etc/skel/.config/hyprzzite-settings/server.py

### ── KDE config skeleton ─────────────────────────────────────────────────────
mkdir -p /etc/skel/.config
cp -r /ctx/config/kde /etc/skel/.config/ 2>/dev/null || true

### ── KDE autostart entries ───────────────────────────────────────────────────
mkdir -p /etc/skel/.config/autostart
install -Dm644 /ctx/config/kde/autostart/steam.desktop \
    /etc/skel/.config/autostart/steam.desktop
install -Dm644 /ctx/config/kde/autostart/vesktop.desktop \
    /etc/skel/.config/autostart/vesktop.desktop
install -Dm644 /ctx/config/kde/autostart/easyeffects.desktop \
    /etc/skel/.config/autostart/easyeffects.desktop
install -Dm644 /ctx/config/kde/autostart/kdeconnect.desktop \
    /etc/skel/.config/autostart/kdeconnect.desktop
install -Dm644 /ctx/config/kde/autostart/arrpc.desktop \
    /etc/skel/.config/autostart/arrpc.desktop

### ── SDDM: autologin to Hyprland ─────────────────────────────────────────────
# Bazzite ships zz-steamos-autologin.conf which autologins to the KDE/Steam
# session — overwrite it so the desktop image boots straight into Hyprland.
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zz-steamos-autologin.conf << 'EOF'
[Autologin]
Session=hyprland.desktop
EOF

### ── Clean up SDDM session list ─────────────────────────────────────────────
# Remove Bazzite sessions we're not using (keep Plasma, Hyprland, Gamescope HTPC)
rm -f /usr/share/wayland-sessions/plasma-steamos-wayland-oneshot.desktop
rm -f /usr/share/xsessions/plasma-steamos-oneshot.desktop
