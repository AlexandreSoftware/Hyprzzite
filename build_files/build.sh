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

### ── Communication (Discord RPM from official source, not in Fedora repos) ───
dnf5 install -y "https://discord.com/api/download?platform=linux&format=rpm"

### ── ProtonVPN (official Fedora repo) ────────────────────────────────────────
dnf5 install -y "https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
# --setopt=tsflags=noscripts skips %post/%posttrans scriptlets that try to
# run 'systemctl start' — which fails because there is no systemd in a container.
# The service is enabled manually below so it starts on first boot.
dnf5 install -y --setopt=tsflags=noscripts proton-vpn-gnome-desktop

### ── RustDesk (latest RPM from GitHub releases) ─────────────────────────────
RUSTDESK_VER=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')
dnf5 install -y "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VER}/rustdesk-${RUSTDESK_VER}-0.x86_64.rpm"

### ── Misc utilities used by common Hyprland configs ──────────────────────────
dnf5 install -y --skip-unavailable \
    jq \
    socat \
    ImageMagick

### ── Install helper scripts ──────────────────────────────────────────────────
# /usr/local is a dangling symlink in ostree images during build — use /usr/bin
install -Dm755 /ctx/scripts/setup-player2  /usr/bin/setup-player2
install -Dm755 /ctx/scripts/dualscope      /usr/bin/dualscope
install -Dm755 /ctx/scripts/hypr-help      /usr/bin/hypr-help
install -Dm755 /ctx/scripts/hypr-wallpaper /usr/bin/hypr-wallpaper

### ── Clean up SDDM session list ─────────────────────────────────────────────
# Keep only: Plasma, Steam Gaming Mode, Hyprland
rm -f /usr/share/wayland-sessions/gamescope-session.desktop
rm -f /usr/share/wayland-sessions/plasma-steamos-wayland-oneshot.desktop
rm -f /usr/share/xsessions/plasma-steamos-oneshot.desktop

### ── Install default configs into /etc/skel ──────────────────────────────────
mkdir -p /etc/skel/.config
cp -r /ctx/config/* /etc/skel/.config/
mkdir -p /etc/skel/Pictures/Screenshots
mkdir -p /etc/skel/Pictures/Wallpapers

### ── Enable system units ─────────────────────────────────────────────────────
systemctl enable bluetooth.service
systemctl enable podman.socket
# systemctl enable doesn't work without a running daemon; create the symlink directly
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/me.proton.vpn.service \
    /etc/systemd/system/multi-user.target.wants/me.proton.vpn.service
