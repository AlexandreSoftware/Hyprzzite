#!/bin/bash
# vikunja-due.sh — count tasks due today for waybar badge

KEYS_FILE="$HOME/.config/ai/keys"

if [ ! -f "$KEYS_FILE" ]; then
    echo "?"
    exit 0
fi

TOKEN=$(grep '^VIKUNJA_TOKEN=' "$KEYS_FILE" | cut -d= -f2-)
URL=$(grep '^VIKUNJA_URL=' "$KEYS_FILE" | cut -d= -f2-)

if [ -z "$TOKEN" ] || [ -z "$URL" ]; then
    echo "?"
    exit 0
fi

TODAY=$(date +%Y-%m-%dT00:00:00+00:00)
TOMORROW=$(date -d '+1 day' +%Y-%m-%dT00:00:00+00:00)

COUNT=$(curl -sf \
    -H "Authorization: Bearer $TOKEN" \
    "${URL%/}/api/v1/tasks/all?filter_by=due_date&filter_comparator=less&filter_value=${TOMORROW}&filter_by=due_date&filter_comparator=greater_equals&filter_value2=${TODAY}" \
    2>/dev/null | jq 'length' 2>/dev/null || echo "?")

if [ "$COUNT" = "0" ]; then
    echo "clear"
else
    echo "$COUNT due"
fi
