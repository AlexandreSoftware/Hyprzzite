#!/bin/bash
# build-common.sh — runs on both desktop and Steam Deck images

set -ouex pipefail

### ── Hyprland COPR ────────────────────────────────────────────────────────────
dnf5 -y copr enable solopasha/hyprland

### ── Hyprland ecosystem ───────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    hyprland \
    hyprland-qtutils \
    hyprpaper \
    hyprlock \
    hypridle \
    wlogout \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    waybar \
    wofi \
    wl-clipboard \
    cliphist \
    dunst \
    libnotify \
    kitty \
    grim \
    slurp \
    swappy \
    brightnessctl \
    playerctl \
    pavucontrol \
    pamixer \
    polkit-gnome \
    qt5-qtwayland \
    qt6-qtwayland \
    nwg-look \
    nwg-displays \
    wvkbd \
    nerd-fonts \
    fontawesome-fonts \
    fontawesome-fonts-web \
    network-manager-applet \
    blueman \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    adw-gtk3-theme \
    papirus-icon-theme \
    xdg-user-dirs \
    xdg-user-dirs-gtk \
    jq \
    socat \
    ImageMagick \
    zenity \
    python3-pyyaml \
    khal \
    vdirsyncer \
    libcec \
    cec-utils

dnf5 -y copr disable solopasha/hyprland

### ── Qt virtual keyboard (for SDDM) ─────────────────────────────────────────
dnf5 install -y --skip-unavailable qt5-qtvirtualkeyboard

### ── OBS Studio (native) ─────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable obs-studio

### ── Tailscale ────────────────────────────────────────────────────────────────
curl -fsSL "https://pkgs.tailscale.com/stable/fedora/39/tailscale.repo" \
    -o /etc/yum.repos.d/tailscale.repo
dnf5 install -y tailscale

### ── Ollama (AMD ROCm + Vulkan fallback) ─────────────────────────────────────
curl -fsSL https://ollama.com/install.sh | PATH=/usr/bin:/bin sh

### ── Dev tools ────────────────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable \
    neovim \
    tmux \
    fzf \
    ripgrep \
    fd-find \
    bat \
    zoxide \
    gh \
    age \
    eza \
    distrobox

### ── lazygit ──────────────────────────────────────────────────────────────────
LAZYGIT_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
curl -Lo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_Linux_x86_64.tar.gz"
tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
install -Dm755 /tmp/lazygit /usr/bin/lazygit

### ── mise (polyglot version manager) ────────────────────────────────────────
curl https://mise.run | MISE_INSTALL_PATH=/usr/bin/mise sh

### ── Discord (official RPM) ──────────────────────────────────────────────────
dnf5 install -y "https://discord.com/api/download?platform=linux&format=rpm"

### ── ProtonVPN ────────────────────────────────────────────────────────────────
dnf5 install -y \
    "https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
dnf5 install -y --setopt=tsflags=noscripts proton-vpn-gnome-desktop

### ── RustDesk ─────────────────────────────────────────────────────────────────
RUSTDESK_VER=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest \
    | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')
dnf5 install -y \
    "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VER}/rustdesk-${RUSTDESK_VER}-0.x86_64.rpm"

### ── EmuDeck dependencies ────────────────────────────────────────────────────
dnf5 install -y --skip-unavailable rsync unzip p7zip p7zip-plugins scrcpy

### ── Gaming sysctl tweaks ────────────────────────────────────────────────────
install -Dm644 /ctx/config/sysctl/gaming.conf /etc/sysctl.d/99-gaming.conf

### ── SDDM virtual keyboard config ───────────────────────────────────────────
install -Dm644 /ctx/config/sddm/virtualkeyboard.conf \
    /etc/sddm.conf.d/virtualkeyboard.conf

### ── KWin gaming env vars ────────────────────────────────────────────────────
install -Dm644 /ctx/config/environment.d/kwin-gaming.conf \
    /etc/environment.d/kwin-gaming.conf

### ── Install configs into /etc/skel ─────────────────────────────────────────
mkdir -p /etc/skel/.config
cp -r /ctx/config/hypr        /etc/skel/.config/
cp -r /ctx/config/waybar      /etc/skel/.config/
cp -r /ctx/config/dunst       /etc/skel/.config/
cp -r /ctx/config/kitty       /etc/skel/.config/
cp -r /ctx/config/wofi        /etc/skel/.config/
cp -r /ctx/config/wlogout     /etc/skel/.config/
cp -r /ctx/config/MangoHud    /etc/skel/.config/
cp -r /ctx/config/mise        /etc/skel/.config/
cp -r /ctx/config/litellm     /etc/skel/.config/
cp -r /ctx/config/wireplumber /etc/skel/.config/
cp -r /ctx/config/vdirsyncer  /etc/skel/.config/
cp -r /ctx/config/hyprzzite   /etc/skel/.config/

mkdir -p /etc/skel/.config/systemd/user
cp /ctx/config/systemd/*.service /etc/skel/.config/systemd/user/

mkdir -p /etc/skel/.config/ai
touch /etc/skel/.config/ai/keys

mkdir -p /etc/skel/.config/kde-displays
touch /etc/skel/.config/kde-displays/outputs.env

mkdir -p /etc/skel/Pictures/Screenshots
mkdir -p /etc/skel/Pictures/Wallpapers
mkdir -p /etc/skel/Applications

cp /ctx/config/EmuDeck.desktop /etc/skel/Desktop/EmuDeck.desktop 2>/dev/null || true

### ── Install scripts ─────────────────────────────────────────────────────────
install -Dm755 /ctx/scripts/setup-player2          /usr/bin/setup-player2
install -Dm755 /ctx/scripts/dualscope              /usr/bin/dualscope
install -Dm755 /ctx/scripts/hypr-help              /usr/bin/hypr-help
install -Dm755 /ctx/scripts/hypr-wallpaper         /usr/bin/hypr-wallpaper
install -Dm755 /ctx/scripts/hypr-primary-switch    /usr/bin/hypr-primary-switch
install -Dm755 /ctx/scripts/hyprzzite-setup        /usr/bin/hyprzzite-setup
install -Dm755 /ctx/scripts/hyprzzite-settings     /usr/bin/hyprzzite-settings
install -Dm755 /ctx/scripts/hyprzzite-alarm        /usr/bin/hyprzzite-alarm
install -Dm755 /ctx/scripts/install-sillytavern    /usr/bin/install-sillytavern
install -Dm755 /ctx/scripts/setup-waydroid         /usr/bin/setup-waydroid
install -Dm755 /ctx/scripts/apply-desktop-monitor-profile \
    /usr/bin/apply-desktop-monitor-profile

install -Dm755 /ctx/scripts/waybar/machine-stats.sh \
    /etc/skel/.config/waybar/scripts/machine-stats.sh
install -Dm755 /ctx/scripts/waybar/vikunja-due.sh \
    /etc/skel/.config/waybar/scripts/vikunja-due.sh

### ── ublue firstboot hooks ───────────────────────────────────────────────────
install -Dm755 /ctx/config/ublue-hooks/97-first-boot-wizard \
    /usr/share/ublue-os/user-setup.hooks.d/97-first-boot-wizard
install -Dm755 /ctx/config/ublue-hooks/98-ai-setup \
    /usr/share/ublue-os/user-setup.hooks.d/98-ai-setup
install -Dm755 /ctx/config/ublue-hooks/99-flatpaks \
    /usr/share/ublue-os/user-setup.hooks.d/99-flatpaks

### ── Enable system units ─────────────────────────────────────────────────────
systemctl enable bluetooth.service
systemctl enable podman.socket
systemctl enable ollama
systemctl enable tailscaled
# ProtonVPN: systemctl enable fails without running systemd; create symlink directly
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/me.proton.vpn.service \
    /etc/systemd/system/multi-user.target.wants/me.proton.vpn.service
