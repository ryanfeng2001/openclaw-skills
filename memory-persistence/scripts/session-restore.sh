#!/bin/bash
# memory-persistence: session-restore.sh
# Restore session context from checkpoint files

STATE_DIR="${STATE_DIR:-$HOME/.openclaw/workspace/memory/state}"
DAILY_DIR="${DAILY_DIR:-$HOME/.openclaw/workspace/memory}"

echo "=== Session Restore ==="

# Check state directory
if [ ! -d "$STATE_DIR" ]; then
  echo "No state directory found. Fresh session."
  exit 0
fi

# Load checkpoint
if [ -f "$STATE_DIR/checkpoint.json" ]; then
  echo "Last checkpoint:"
  python3 -c "
import json
try:
    d = json.load(open('$STATE_DIR/checkpoint.json'))
    print(f'  Time: {d.get(\"timestamp\", \"unknown\")}')
    print(f'  Summary: {d.get(\"summary\", \"(none)\")[:200]}')
    tasks = d.get('active_tasks', [])
    if tasks:
        print(f'  Active tasks: {len(tasks)}')
        for t in tasks[:5]:
            print(f'    - {t}')
    pending = d.get('pending_items', [])
    if pending:
        print(f'  Pending items: {len(pending)}')
        for p in pending[:5]:
            print(f'    - {p}')
except Exception as e:
    print(f'  Error reading checkpoint: {e}')
"
else
  echo "No checkpoint found."
fi

# Show pending tasks
if [ -f "$STATE_DIR/pending-tasks.md" ]; then
  PENDING=$(grep -c "^- \[" "$STATE_DIR/pending-tasks.md" 2>/dev/null || echo 0)
  if [ "$PENDING" -gt 0 ]; then
    echo ""
    echo "Pending tasks ($PENDING):"
    grep "^- \[" "$STATE_DIR/pending-tasks.md" | head -10
  fi
fi

# Show session meta
if [ -f "$STATE_DIR/session-meta.json" ]; then
  echo ""
  echo "Session history:"
  python3 -c "
import json
d = json.load(open('$STATE_DIR/session-meta.json'))
print(f'  Total saves: {d.get(\"save_count\", 0)}')
print(f'  Last full save: {d.get(\"last_save\", \"never\")}')
print(f'  Last quick save: {d.get(\"last_quick_save\", \"never\")}')
"
fi

echo ""
echo "=== Restore complete ==="
