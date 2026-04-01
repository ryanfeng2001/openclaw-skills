#!/bin/zsh
# clip.sh — Save web page as Markdown to Obsidian Inbox
# Usage: clip.sh <URL> [TITLE]

VAULT_DIR="/Volumes/satachi/macobi/macobi/Inbox"
mkdir -p "$VAULT_DIR"

URL="$1"
TITLE="$2"

if [ -z "$URL" ]; then
  echo "Usage: clip.sh <URL> [TITLE]"
  exit 1
fi

# Default title
if [ -z "$TITLE" ]; then
  TITLE=$(date '+%Y-%m-%d %H-%M-%S')
fi

# Sanitize filename (remove / \ : * ? " < > |)
SAFE_TITLE=$(echo "$TITLE" | sed 's[/\\:*?"<>|][_]g')
TARGET="$VAULT_DIR/${SAFE_TITLE}.md"

# Avoid overwrite
if [ -f "$TARGET" ]; then
  TARGET="$VAULT_DIR/${SAFE_TITLE} $(date '+%H%M%S').md"
fi

# Fetch clean Markdown via Jina Reader
HTTP_PROXY="${HTTP_PROXY:-}"
if [ -n "$HTTP_PROXY" ]; then
  CONTENT=$(curl -sL --max-time 30 -x "$HTTP_PROXY" "https://r.jina.ai/$URL")
else
  CONTENT=$(curl -sL --max-time 30 "https://r.jina.ai/$URL")
fi

if [ -z "$CONTENT" ] || echo "$CONTENT" | grep -qi "error\|403\|forbidden"; then
  echo "ERROR: Failed to fetch $URL"
  exit 1
fi

# Write file with metadata header
cat > "$TARGET" << EOF
---
source: $URL
clipped: $(date '+%Y-%m-%d %H:%M:%S')
---

$CONTENT
EOF

echo "$TARGET"
