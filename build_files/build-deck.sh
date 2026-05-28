#!/bin/bash
# build-deck.sh — Steam Deck-only additions (runs after build-common.sh)

set -ouex pipefail

### ── Deck-specific packages ──────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    iio-sensor-proxy \
    gamemode \
    mangohud \
    gamescope

### ── Deck Hyprland config overlay ───────────────────────────────────────────
# hyprland-deck.conf is in /etc/skel/.config/hypr/ via build-common.sh
# autostart.conf detects eDP-1 and sources it automatically
install -Dm644 /ctx/config/hypr/hyprland-deck.conf \
    /etc/skel/.config/hypr/hyprland-deck.conf

### ── Deck-specific waybar config ────────────────────────────────────────────
install -Dm644 /ctx/config/waybar/config-deck.jsonc \
    /etc/skel/.config/waybar/config-deck.jsonc

### ── SDDM: autologin to Hyprland ─────────────────────────────────────────────
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zz-steamos-autologin.conf << 'EOF'
[Autologin]
Session=hyprland.desktop
EOF

### ── Deck-specific SDDM: no session cleanup (keep Steam Deck Game Mode) ─────
# Do NOT remove gamescope-session.desktop on Deck — it's the primary session
