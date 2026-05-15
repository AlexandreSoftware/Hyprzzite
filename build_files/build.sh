#!/bin/bash

set -ouex pipefail

### ── Enable Hyprland COPR (not yet in official Fedora repos) ────────────────
dnf5 -y copr enable solopasha/hyprland
dnf5 -y copr enable erikreider/SwayNotificationCenter

### ── Hyprland compositor and core ecosystem ──────────────────────────────────
dnf5 install -y \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk

### ── Status bar ──────────────────────────────────────────────────────────────
dnf5 install -y waybar

### ── App launcher ────────────────────────────────────────────────────────────
dnf5 install -y wofi

### ── Disable COPRs so they are not active on the final image ─────────────────
dnf5 -y copr disable solopasha/hyprland
dnf5 -y copr disable erikreider/SwayNotificationCenter

### ── Notifications ───────────────────────────────────────────────────────────
dnf5 install -y dunst libnotify

### ── Terminal emulator ───────────────────────────────────────────────────────
dnf5 install -y kitty

### ── Screenshot tools ────────────────────────────────────────────────────────
dnf5 install -y grim slurp swappy

### ── Clipboard ───────────────────────────────────────────────────────────────
dnf5 install -y wl-clipboard cliphist

### ── Display / brightness / media controls ───────────────────────────────────
dnf5 install -y \
    brightnessctl \
    playerctl \
    pavucontrol \
    pamixer

### ── Polkit authentication agent ─────────────────────────────────────────────
dnf5 install -y polkit-gnome

### ── Qt and GTK Wayland support ──────────────────────────────────────────────
dnf5 install -y \
    qt5-qtwayland \
    qt6-qtwayland \
    nwg-look

### ── Fonts ────────────────────────────────────────────────────────────────────
dnf5 install -y \
    nerd-fonts \
    fontawesome-fonts \
    fontawesome-fonts-web

### ── Network / Bluetooth applets ─────────────────────────────────────────────
dnf5 install -y \
    network-manager-applet \
    blueman

### ── File manager ────────────────────────────────────────────────────────────
dnf5 install -y \
    thunar \
    thunar-volman \
    thunar-archive-plugin

### ── Theming ──────────────────────────────────────────────────────────────────
dnf5 install -y \
    adw-gtk3-theme \
    papirus-icon-theme

### ── XDG user dirs ───────────────────────────────────────────────────────────
dnf5 install -y xdg-user-dirs xdg-user-dirs-gtk

### ── Communication ────────────────────────────────────────────────────────────
dnf5 install -y discord

### ── Misc utilities used by common Hyprland configs ──────────────────────────
dnf5 install -y \
    jq \
    socat \
    imagemagick

### ── Install default configs into /etc/skel ──────────────────────────────────
# New users automatically get these configs copied to their home directory.
install -d /etc/skel/.config
cp -r /ctx/config/* /etc/skel/.config/
install -d /etc/skel/Pictures/Screenshots

### ── Enable system units ─────────────────────────────────────────────────────
# Bazzite-dx ships SDDM — Hyprland will appear as a selectable session at login.
systemctl enable bluetooth.service
systemctl enable podman.socket
