#!/bin/bash
# machine-stats.sh — fetch CPU/RAM/temp for waybar modules
# Usage: machine-stats.sh [local|homeserver|deck]

TARGET="${1:-local}"

case "$TARGET" in
  local)
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    RAM=$(free -m | awk '/Mem:/{printf "%.0f%%", $3/$2*100}')
    TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null \
           | sort -n | tail -1 | awk '{printf "%.0f°C", $1/1000}')
    echo "${CPU}% ${RAM} ${TEMP}"
    ;;
  homeserver|deck)
    RESULT=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=no \
        "$TARGET" \
        "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d. -f1 | tr -d '\n'; \
         echo -n '% '; \
         free -m | awk '/Mem:/{printf \"%.0f%%\", \$3/\$2*100}'" 2>/dev/null) \
        || RESULT=""
    if [ -z "$RESULT" ]; then
        echo "offline"
    else
        echo "$RESULT"
    fi
    ;;
  *)
    echo "?"
    ;;
esac
