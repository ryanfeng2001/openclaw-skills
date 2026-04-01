#!/bin/bash
# continuous-learning: learning-cycle.sh
# Scans recent daily notes, promotes patterns to instincts, prunes stale entries

MEMORY_DIR="${MEMORY_DIR:-$HOME/.openclaw/workspace/memory}"
LEARNINGS_DIR="$MEMORY_DIR/learnings"
INSTINCTS_FILE="$MEMORY_DIR/instincts.md"
DAYS_TO_SCAN=${1:-7}  # Default: scan last 7 days
PRUNE_DAYS=${2:-30}   # Prune patterns unused for 30+ days

mkdir -p "$LEARNINGS_DIR"

# Initialize instincts file if needed
if [ ! -f "$INSTINCTS_FILE" ]; then
  cat > "$INSTINCTS_FILE" << 'EOF'
# Instincts
> High-confidence patterns promoted from learnings. Auto-applied in sessions.

EOF
fi

echo "=== Learning Cycle ==="
echo "Scanning last $DAYS_TO_SCAN days of daily notes..."

# List recent daily files
RECENT_FILES=""
for i in $(seq 0 $((DAYS_TO_SCAN - 1))); do
  DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
  FILE="$MEMORY_DIR/$DATE.md"
  if [ -f "$FILE" ]; then
    RECENT_FILES="$RECENT_FILES $FILE"
    echo "  Found: $DATE.md"
  fi
done

if [ -z "$RECENT_FILES" ]; then
  echo "No daily notes found in last $DAYS_TO_SCAN days."
fi

# Count existing learnings and instincts
LEARNING_COUNT=$(find "$LEARNINGS_DIR" -name "*.md" -exec grep -l "Pattern:" {} \; 2>/dev/null | wc -l | tr -d ' ')
INSTINCT_COUNT=$(grep -c "^### " "$INSTINCTS_FILE" 2>/dev/null || echo 0)

echo ""
echo "Current stats:"
echo "  Learnings: $LEARNING_COUNT"
echo "  Instincts: $INSTINCT_COUNT"

# Find patterns eligible for promotion (reuse_count >= 3)
echo ""
echo "Patterns eligible for promotion (reuse_count >= 3):"
PROMOTABLE=0
for f in "$LEARNINGS_DIR"/*.md; do
  [ -f "$f" ] || continue
  # Extract reuse count
  REUSE=$(grep "Reuse count:" "$f" 2>/dev/null | grep -oE '[0-9]+' | head -1)
  CONF=$(grep "Confidence:" "$f" 2>/dev/null | head -1)
  if [ "$REUSE" -ge 3 ] 2>/dev/null; then
    NAME=$(grep "Pattern:" "$f" | head -1 | sed 's/.*Pattern: //')
    echo "  ✅ $NAME (used $REUSE times, $CONF)"
    PROMOTABLE=$((PROMOTABLE + 1))
  fi
done
[ $PROMOTABLE -eq 0 ] && echo "  None yet."

echo ""
echo "=== Cycle complete ==="
echo "Tip: Review promotable patterns and add high-confidence ones to $INSTINCTS_FILE"
