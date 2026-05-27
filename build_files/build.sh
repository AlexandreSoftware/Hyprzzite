#!/bin/bash

set -ouex pipefail

### ── Enable Hyprland COPR (not yet in official Fedora repos) ────────────────
dnf5 -y copr enable solopasha/hyprland

### ── Hyprland compositor and core ecosystem ──────────────────────────────────
dnf5 install -y --skip-unavailable \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    wlogout \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk

### ── Status bar ──────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable waybar

### ── App launcher ────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable wofi

### ── Clipboard (cliphist lives in the solopasha COPR) ───────────────────────
dnf5 install -y --skip-unavailable wl-clipboard cliphist

### ── Disable COPR so it is not active on the final image ────────────────────
dnf5 -y copr disable solopasha/hyprland

### ── Notifications ───────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable dunst libnotify

### ── Terminal emulator ───────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable kitty

### ── Screenshot tools ────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable grim slurp swappy

### ── Display / brightness / media controls ───────────────────────────────────
dnf5 install -y --skip-unavailable \
    brightnessctl \
    playerctl \
    pavucontrol \
    pamixer

### ── Polkit authentication agent ─────────────────────────────────────────────
dnf5 install -y --skip-unavailable polkit-gnome

### ── Qt and GTK Wayland support ──────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    qt5-qtwayland \
    qt6-qtwayland \
    nwg-look

### ── Fonts ────────────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    nerd-fonts \
    fontawesome-fonts \
    fontawesome-fonts-web

### ── Network / Bluetooth applets ─────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    network-manager-applet \
    blueman

### ── File manager ────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    thunar \
    thunar-volman \
    thunar-archive-plugin

### ── Theming ──────────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    adw-gtk3-theme \
    papirus-icon-theme

### ── XDG user dirs ───────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable xdg-user-dirs xdg-user-dirs-gtk

### ── Communication ────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable discord

### ── Misc utilities used by common Hyprland configs ──────────────────────────
dnf5 install -y --skip-unavailable \
    jq \
    socat \
    imagemagick

### ── Install helper scripts ──────────────────────────────────────────────────
install -Dm755 /ctx/scripts/setup-player2  /usr/local/bin/setup-player2
install -Dm755 /ctx/scripts/dualscope      /usr/local/bin/dualscope
install -Dm755 /ctx/scripts/hypr-help      /usr/local/bin/hypr-help
install -Dm755 /ctx/scripts/hypr-wallpaper /usr/local/bin/hypr-wallpaper

### ── Clean up SDDM session list ─────────────────────────────────────────────
# Keep only: Plasma, Steam Gaming Mode, Hyprland
rm -f /usr/share/wayland-sessions/gamescope-session.desktop
rm -f /usr/share/wayland-sessions/plasma-steamos-wayland-oneshot.desktop
rm -f /usr/share/xsessions/plasma-steamos-oneshot.desktop

### ── Install default configs into /etc/skel ──────────────────────────────────
install -d /etc/skel/.config
cp -r /ctx/config/* /etc/skel/.config/
install -d /etc/skel/Pictures/Screenshots
install -d /etc/skel/Pictures/Wallpapers

### ── Enable system units ─────────────────────────────────────────────────────
systemctl enable bluetooth.service
systemctl enable podman.socket
