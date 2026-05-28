-- 11-audio-profiles.lua
-- Auto-switch to HDMI sink when it becomes the only available output (TV-only mode).
-- Also ensures "follow" and "move" policies so apps get re-routed on sink changes.

alsa_monitor = alsa_monitor or {}
alsa_monitor.rules = alsa_monitor.rules or {}

table.insert(alsa_monitor.rules, {
  matches = {
    { "device.name", "matches", "*hdmi*" },
  },
  apply_properties = {
    ["device.profile"] = "output:hdmi-stereo-extra1",
  },
})

-- When the default sink changes, move all active streams to it
default_policy = default_policy or {}
default_policy.policy = default_policy.policy or {}
default_policy.policy["move"]   = true
default_policy.policy["follow"] = true
