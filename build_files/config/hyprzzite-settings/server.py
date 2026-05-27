#!/usr/bin/env python3
"""hyprzzite-settings — local web settings panel on port 9090"""
import os, re, subprocess, pathlib
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
import json

HOME = pathlib.Path.home()
KEYS_FILE = HOME / ".config/ai/keys"
LITELLM_CFG = HOME / ".config/litellm/config.yaml"
MONITOR_MAP = HOME / ".config/hyprzzite/monitor-audio-map.env"

def read_keys() -> dict:
    if not KEYS_FILE.exists():
        return {}
    out = {}
    for line in KEYS_FILE.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out

def write_keys(d: dict):
    KEYS_FILE.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"{k}={v}" for k, v in d.items() if v]
    KEYS_FILE.write_text("\n".join(lines) + "\n")

def get_monitors() -> list:
    try:
        result = subprocess.run(
            ["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=2)
        return json.loads(result.stdout)
    except Exception:
        return []

def get_sinks() -> list:
    try:
        result = subprocess.run(
            ["pactl", "list", "sinks", "short"], capture_output=True, text=True, timeout=2)
        sinks = []
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 2:
                sinks.append(parts[1])
        return sinks
    except Exception:
        return []

def read_monitor_map() -> dict:
    if not MONITOR_MAP.exists():
        return {}
    out = {}
    for line in MONITOR_MAP.read_text().splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out

def write_monitor_map(d: dict):
    MONITOR_MAP.parent.mkdir(parents=True, exist_ok=True)
    MONITOR_MAP.write_text("\n".join(f"{k}={v}" for k, v in d.items()) + "\n")

HTML = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Hyprzzite Settings</title>
<style>
  body {{ font-family: 'Segoe UI', sans-serif; background: #1b2027; color: #eff0f1; margin: 0; }}
  header {{ background: #24272c; padding: 16px 24px; font-size: 20px; font-weight: bold; color: #3daee9; }}
  .tabs {{ display: flex; background: #24272c; border-bottom: 1px solid #2d3139; }}
  .tab {{ padding: 10px 20px; cursor: pointer; color: #7f8c8d; border-bottom: 2px solid transparent; }}
  .tab.active {{ color: #3daee9; border-bottom-color: #3daee9; }}
  .panel {{ display: none; padding: 24px; }}
  .panel.active {{ display: block; }}
  label {{ display: block; margin-bottom: 4px; color: #bdc3c7; font-size: 13px; }}
  input[type=text], input[type=password], select {{
    width: 100%; max-width: 500px; padding: 8px 10px;
    background: #24272c; border: 1px solid #3a3f47; border-radius: 6px;
    color: #eff0f1; font-size: 14px; margin-bottom: 16px; box-sizing: border-box;
  }}
  button {{
    padding: 8px 18px; background: #3daee9; color: #1b2027;
    border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: bold;
  }}
  button:hover {{ background: #5bc0f7; }}
  button.danger {{ background: #da4453; color: white; }}
  .row {{ display: flex; gap: 12px; align-items: center; margin-bottom: 12px; flex-wrap: wrap; }}
  .note {{ color: #7f8c8d; font-size: 12px; margin-top: -12px; margin-bottom: 16px; }}
  h3 {{ color: #3daee9; margin-top: 24px; }}
  .success {{ color: #27ae60; padding: 8px; background: rgba(39,174,96,0.1); border-radius: 4px; margin-bottom: 12px; }}
  .error {{ color: #da4453; padding: 8px; background: rgba(218,68,83,0.1); border-radius: 4px; margin-bottom: 12px; }}
</style>
</head>
<body>
<header>⚙ Hyprzzite Settings</header>
<div class="tabs">
  <div class="tab active" onclick="show('ai')">AI Keys</div>
  <div class="tab" onclick="show('displays')">Displays</div>
  <div class="tab" onclick="show('apps')">Apps</div>
  <div class="tab" onclick="show('audio')">Audio</div>
</div>

<div id="ai" class="panel active">
  <h3>AI Backend Keys</h3>
  {msg_ai}
  <form method="POST" action="/save-keys">
    <label>Anthropic API Key</label>
    <input type="password" name="ANTHROPIC_API_KEY" value="{ANTHROPIC_API_KEY}" placeholder="sk-ant-...">
    <label>Homelab Ollama URL</label>
    <input type="text" name="HOMELAB_OLLAMA_URL" value="{HOMELAB_OLLAMA_URL}" placeholder="http://homeserver:11434">
    <label>Vikunja URL</label>
    <input type="text" name="VIKUNJA_URL" value="{VIKUNJA_URL}" placeholder="http://homeserver:3456">
    <label>Vikunja API Token</label>
    <input type="password" name="VIKUNJA_TOKEN" value="{VIKUNJA_TOKEN}" placeholder="token...">
    <label>CalDAV URL</label>
    <input type="text" name="CAL_URL" value="{CAL_URL}" placeholder="http://homeserver:5232">
    <label>CalDAV Username</label>
    <input type="text" name="CAL_USER" value="{CAL_USER}">
    <label>CalDAV Password</label>
    <input type="password" name="CAL_PASS" value="{CAL_PASS}">
    <button type="submit">Save &amp; Restart LiteLLM</button>
  </form>
</div>

<div id="displays" class="panel">
  <h3>Display Configuration</h3>
  <div class="row">
    <button onclick="fetch('/action/nwg-displays').then(()=>alert('nwg-displays launched'))">
      Launch nwg-displays
    </button>
    <button onclick="fetch('/action/apply-desktop-profile').then(()=>alert('Profile applied'))">
      Apply 3-Monitor Desktop Profile
    </button>
  </div>
  <h3>Monitor → Audio Mapping</h3>
  <p class="note">Maps each monitor to a PipeWire sink for auto audio switching.</p>
  {monitor_rows}
  <button onclick="saveMonitorMap()">Save Audio Map</button>
  <h3>CEC (Hisense TV Control)</h3>
  <div class="row">
    <button onclick="fetch('/action/cec-test').then(r=>r.text()).then(t=>alert(t))">Test CEC</button>
    <button onclick="fetch('/action/cec-wake')">Wake TV</button>
    <button onclick="fetch('/action/cec-standby')">Standby TV</button>
  </div>
</div>

<div id="apps" class="panel">
  <h3>Optional Apps</h3>
  <div class="row">
    <button onclick="fetch('/action/install-sillytavern').then(()=>alert('Installing SillyTavern...'))">
      Install SillyTavern
    </button>
    <button onclick="fetch('/action/setup-steam-shortcuts').then(()=>alert('Steam shortcuts added'))">
      Add Steam Shortcuts
    </button>
    <button onclick="fetch('/action/install-emudeck').then(()=>alert('Launching EmuDeck...'))">
      Install EmuDeck
    </button>
  </div>
  <h3>Default Browser</h3>
  <form method="POST" action="/save-browser">
    <select name="browser">
      <option value="firefox">Firefox</option>
      <option value="zen">Zen Browser</option>
      <option value="chromium">Ungoogled Chromium</option>
    </select>
    <button type="submit">Set Default</button>
  </form>
</div>

<div id="audio" class="panel">
  <h3>Audio Output</h3>
  <p class="note">Current PipeWire sinks:</p>
  {sink_list}
</div>

<script>
function show(id) {{
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  event.target.classList.add('active');
}}

function saveMonitorMap() {{
  const data = {{}};
  document.querySelectorAll('[data-monitor-sink]').forEach(el => {{
    data[el.dataset.monitorSink] = el.value;
  }});
  fetch('/save-monitor-map', {{
    method: 'POST',
    headers: {{'Content-Type': 'application/json'}},
    body: JSON.stringify(data)
  }}).then(() => alert('Saved'));
}}
</script>
</body>
</html>"""

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def send_html(self, body: str, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())

    def send_json(self, d: dict, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(d).encode())

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self.render_index()
        elif path.startswith("/action/"):
            self.handle_action(path[8:])
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode()
        parsed = urlparse(self.path)

        if parsed.path == "/save-keys":
            params = parse_qs(body)
            keys = read_keys()
            for k in ["ANTHROPIC_API_KEY","HOMELAB_OLLAMA_URL","VIKUNJA_URL",
                      "VIKUNJA_TOKEN","CAL_URL","CAL_USER","CAL_PASS"]:
                v = params.get(k, [""])[0].strip()
                if v:
                    keys[k] = v
                elif k in keys:
                    del keys[k]
            write_keys(keys)
            subprocess.Popen(["systemctl","--user","restart","litellm.service"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.send_response(302)
            self.send_header("Location", "/?msg=keys_saved")
            self.end_headers()

        elif parsed.path == "/save-browser":
            params = parse_qs(body)
            browser = params.get("browser", ["firefox"])[0]
            mapping = {
                "firefox":  "org.mozilla.firefox.desktop",
                "zen":      "app.zen_browser.zen.desktop",
                "chromium": "com.github.Eloston.UngoogledChromium.desktop",
            }
            if browser in mapping:
                subprocess.run(["xdg-settings","set","default-web-browser", mapping[browser]])
            self.send_response(302)
            self.send_header("Location", "/?msg=browser_saved")
            self.end_headers()

        elif parsed.path == "/save-monitor-map":
            data = json.loads(body)
            current = read_monitor_map()
            current.update({f"{k}_SINK": v for k, v in data.items() if v})
            write_monitor_map(current)
            self.send_json({"ok": True})

    def handle_action(self, action: str):
        scripts = {
            "nwg-displays":        ["nwg-displays"],
            "apply-desktop-profile": ["apply-desktop-monitor-profile"],
            "install-sillytavern": ["install-sillytavern"],
            "setup-steam-shortcuts": ["setup-steam-shortcuts"],
            "install-emudeck":     ["bash","-c",
                "curl -fsSL https://github.com/dragoonDorise/EmuDeck/releases/latest/download/emudeck.sh "
                "-o /tmp/emudeck.sh && bash /tmp/emudeck.sh"],
            "cec-test":   ["bash","-c","cec-client -l 2>&1 | head -20"],
            "cec-wake":   ["bash","-c","echo 'on 0' | cec-client -s -d 1"],
            "cec-standby":["bash","-c","echo 'standby 0' | cec-client -s -d 1"],
        }
        if action not in scripts:
            self.send_response(404)
            self.end_headers()
            return
        cmd = scripts[action]
        if action == "cec-test":
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write((result.stdout or result.stderr or "No output").encode())
        else:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.send_json({"ok": True})

    def render_index(self):
        params = parse_qs(urlparse(self.path).query)
        msg = params.get("msg", [""])[0]
        msg_ai = ""
        if msg == "keys_saved":
            msg_ai = '<div class="success">Keys saved. LiteLLM restarting…</div>'
        elif msg == "browser_saved":
            msg_ai = '<div class="success">Default browser updated.</div>'

        keys = read_keys()
        monitors = get_monitors()
        sinks = get_sinks()
        mmap = read_monitor_map()

        monitor_rows = ""
        for m in monitors:
            name = m.get("name","?")
            var = f"{name.replace('-','_')}_SINK"
            current_sink = mmap.get(var,"")
            opts = "<option value=''>-- None --</option>"
            for s in sinks:
                sel = "selected" if s == current_sink else ""
                opts += f"<option value='{s}' {sel}>{s}</option>"
            monitor_rows += (
                f'<div class="row"><label style="min-width:80px;margin:0">{name}</label>'
                f'<select data-monitor-sink="{name}">{opts}</select></div>'
            )

        sink_list = "".join(f"<div style='padding:4px 0;color:#bdc3c7'>{s}</div>" for s in sinks) or "<div>No sinks found</div>"

        body = HTML.format(
            msg_ai=msg_ai,
            ANTHROPIC_API_KEY=keys.get("ANTHROPIC_API_KEY",""),
            HOMELAB_OLLAMA_URL=keys.get("HOMELAB_OLLAMA_URL",""),
            VIKUNJA_URL=keys.get("VIKUNJA_URL",""),
            VIKUNJA_TOKEN=keys.get("VIKUNJA_TOKEN",""),
            CAL_URL=keys.get("CAL_URL",""),
            CAL_USER=keys.get("CAL_USER",""),
            CAL_PASS=keys.get("CAL_PASS",""),
            monitor_rows=monitor_rows,
            sink_list=sink_list,
        )
        self.send_html(body)


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 9090), Handler)
    print("Hyprzzite Settings running at http://localhost:9090")
    server.serve_forever()
