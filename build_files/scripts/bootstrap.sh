#!/bin/bash
# bootstrap.sh — run from the SETUP USB to inject secrets into a fresh Hyprzzite install
# Place this file at /SETUP/bootstrap.sh on the USB drive
set -euo pipefail

MOUNT="$(dirname "$(realpath "$0")")"
SECRETS_ARCHIVE="$MOUNT/secrets.age"
LITELLM_CFG="$HOME/.config/litellm/config.yaml"

if [ ! -f "$SECRETS_ARCHIVE" ]; then
    zenity --error --text="secrets.age not found on USB" 2>/dev/null || \
        echo "Error: secrets.age not found" && exit 1
fi

# ── Decrypt secrets ────────────────────────────────────────────────────────────
AGE_KEY=$(zenity --entry --hide-text \
    --title="Bootstrap USB" \
    --text="Enter age decryption passphrase:" \
    2>/dev/null)

[ -z "$AGE_KEY" ] && exit 0

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

age --decrypt --passphrase <(echo "$AGE_KEY") "$SECRETS_ARCHIVE" \
    | tar -xz -C "$TMPDIR" \
    || { notify-send -u critical "Bootstrap" "Decryption failed — wrong passphrase?"; exit 1; }

S="$TMPDIR"

# ── SSH keys ───────────────────────────────────────────────────────────────────
if [ -d "$S/ssh" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cp "$S/ssh/github_key"     "$HOME/.ssh/github_key"
    cp "$S/ssh/github_key.pub" "$HOME/.ssh/github_key.pub"
    chmod 600 "$HOME/.ssh/github_key"
    [ -f "$S/ssh_config" ] && cat "$S/ssh_config" >> "$HOME/.ssh/config"
fi

# ── Register SSH key with servers ─────────────────────────────────────────────
if [ -f "$S/servers.txt" ]; then
    while IFS= read -r host; do
        [ -z "$host" ] || [[ "$host" =~ ^# ]] && continue
        ssh-copy-id -i "$HOME/.ssh/github_key.pub" \
            -o PubkeyAuthentication=no \
            -o StrictHostKeyChecking=accept-new \
            "$host" 2>/dev/null || \
            notify-send "Bootstrap" "Could not register key with $host"
    done < "$S/servers.txt"
fi

# ── GitHub CLI auth ────────────────────────────────────────────────────────────
if [ -f "$S/github_token" ]; then
    gh auth login --with-token < "$S/github_token"
    gh ssh-key add "$HOME/.ssh/github_key.pub" --title "$(hostname)" 2>/dev/null || true
fi

# ── Tailscale ──────────────────────────────────────────────────────────────────
if [ -f "$S/tailscale_authkey" ]; then
    sudo tailscale up \
        --authkey="$(cat "$S/tailscale_authkey")" \
        --hostname="$(hostname)" \
        2>/dev/null &
fi

# ── AI keys → ~/.config/ai/keys ───────────────────────────────────────────────
mkdir -p "$HOME/.config/ai"
KEYS_FILE="$HOME/.config/ai/keys"
> "$KEYS_FILE"

[ -f "$S/anthropic_api_key" ] && \
    echo "ANTHROPIC_API_KEY=$(cat "$S/anthropic_api_key")" >> "$KEYS_FILE"

[ -f "$S/homelab_ollama_url" ] && \
    echo "HOMELAB_OLLAMA_URL=$(cat "$S/homelab_ollama_url")" >> "$KEYS_FILE"

[ -f "$S/vikunja_token" ] && \
    echo "VIKUNJA_TOKEN=$(cat "$S/vikunja_token")" >> "$KEYS_FILE"

[ -f "$S/vikunja_url" ] && \
    echo "VIKUNJA_URL=$(cat "$S/vikunja_url")" >> "$KEYS_FILE"

[ -f "$S/caldav_url" ] && \
    echo "CAL_URL=$(cat "$S/caldav_url")" >> "$KEYS_FILE"

[ -f "$S/caldav_user" ] && \
    echo "CAL_USER=$(cat "$S/caldav_user")" >> "$KEYS_FILE"

[ -f "$S/caldav_pass" ] && \
    echo "CAL_PASS=$(cat "$S/caldav_pass")" >> "$KEYS_FILE"

# ── Patch LiteLLM config with homelab URL ─────────────────────────────────────
if [ -f "$S/homelab_ollama_url" ] && [ -f "$LITELLM_CFG" ]; then
    python3 - "$(cat "$S/homelab_ollama_url")" <<'PY'
import sys, pathlib
try:
    import yaml
except ImportError:
    import subprocess, sys as _s
    subprocess.check_call([_s.executable, '-m', 'pip', 'install', 'pyyaml', '-q'])
    import yaml
cfg = pathlib.Path.home() / ".config/litellm/config.yaml"
data = yaml.safe_load(cfg.read_text())
names = [m.get('model_name','') for m in data.get('model_list',[])]
if 'homelab/default' not in names:
    data.setdefault('model_list',[]).append({
        'model_name': 'homelab/default',
        'litellm_params': {'model': 'openai/default', 'api_base': sys.argv[1]}
    })
    cfg.write_text(yaml.dump(data, default_flow_style=False))
PY
fi

# Restart LiteLLM with new keys
systemctl --user restart litellm.service 2>/dev/null || true

# ── Git config ─────────────────────────────────────────────────────────────────
[ -f "$S/gitconfig" ] && cp "$S/gitconfig" "$HOME/.gitconfig"

# ── KeePass database ───────────────────────────────────────────────────────────
if [ -f "$S/keepass.kdbx" ]; then
    mkdir -p "$HOME/Documents"
    cp "$S/keepass.kdbx" "$HOME/Documents/"
fi

# ── App sessions (Spotify, Vesktop) ───────────────────────────────────────────
if [ -d "$S/app-sessions/spotify" ]; then
    mkdir -p "$HOME/.var/app/com.spotify.Client"
    cp -r "$S/app-sessions/spotify/." "$HOME/.var/app/com.spotify.Client/"
fi

if [ -d "$S/app-sessions/vesktop" ]; then
    mkdir -p "$HOME/.var/app/dev.vencord.Vesktop"
    cp -r "$S/app-sessions/vesktop/." "$HOME/.var/app/dev.vencord.Vesktop/"
fi

notify-send "Bootstrap USB" "Bootstrap complete! Check settings panel for any remaining config."
