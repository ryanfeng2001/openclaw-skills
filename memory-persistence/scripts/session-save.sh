#!/bin/bash
# memory-persistence: session-save.sh
# Save current session state to checkpoint files

STATE_DIR="${STATE_DIR:-$HOME/.openclaw/workspace/memory/state}"
mkdir -p "$STATE_DIR"

MODE="${1:---full}"  # --full or --quick

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S%z)
DATE=$(date +%Y-%m-%d)

# Quick save: just update timestamp and active context
if [ "$MODE" = "--quick" ]; then
  echo "Quick save at $TIMESTAMP"
  # Update session meta with current timestamp
  if [ -f "$STATE_DIR/session-meta.json" ]; then
    # Use python for JSON manipulation
    python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_DIR/session-meta.json'))
except: d = {}
d['last_quick_save'] = '$TIMESTAMP'
json.dump(d, open('$STATE_DIR/session-meta.json','w'), indent=2)
"
  else
    echo "{\"last_quick_save\": \"$TIMESTAMP\", \"created\": \"$TIMESTAMP\"}" > "$STATE_DIR/session-meta.json"
  fi
  echo "Quick checkpoint saved."
  exit 0
fi

# Full save: update all state files
echo "=== Session Save ($TIMESTAMP) ==="

# Initialize session meta
python3 -c "
import json
meta = {
    'last_save': '$TIMESTAMP',
    'date': '$DATE'
}
try:
    old = json.load(open('$STATE_DIR/session-meta.json'))
    meta.update(old)
    meta['last_save'] = '$TIMESTAMP'
    meta['save_count'] = old.get('save_count', 0) + 1
except:
    meta['save_count'] = 1
json.dump(meta, open('$STATE_DIR/session-meta.json','w'), indent=2)
print(f'Session meta updated (save #{meta[\"save_count\"]})')
"

# Ensure checkpoint.json exists with template
if [ ! -f "$STATE_DIR/checkpoint.json" ]; then
  cat > "$STATE_DIR/checkpoint.json" << 'EOF'
{
  "timestamp": "",
  "summary": "",
  "active_tasks": [],
  "files_modified": [],
  "key_decisions": [],
  "pending_items": []
}
EOF
  echo "Created checkpoint.json template"
fi

# Ensure pending-tasks.md exists
if [ ! -f "$STATE_DIR/pending-tasks.md" ]; then
  echo "# Pending Tasks" > "$STATE_DIR/pending-tasks.md"
  echo "" >> "$STATE_DIR/pending-tasks.md"
  echo "> Tasks carried over from previous sessions." >> "$STATE_DIR/pending-tasks.md"
  echo "Created pending-tasks.md"
fi

echo ""
echo "State files updated. Agent should fill in checkpoint.json details."
echo "Files:"
ls -la "$STATE_DIR/"
