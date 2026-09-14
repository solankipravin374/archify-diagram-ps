#!/usr/bin/env bash
# Install the archify-diagram-ps skill into your Claude skills directory.
# Usage: bash install.sh          (installs to ~/.claude/skills)
#        CLAUDE_SKILLS_DIR=/path bash install.sh   (custom location)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills/archify-diagram-ps"
DEST_ROOT="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DEST="$DEST_ROOT/archify-diagram-ps"

if [ ! -d "$SRC" ]; then
  echo "error: cannot find $SRC" >&2
  exit 1
fi

mkdir -p "$DEST_ROOT"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

echo "✅ Installed archify-diagram-ps -> $DEST"

if [ ! -d "$DEST_ROOT/archify" ]; then
  echo ""
  echo "⚠️  The 'archify' skill was not found in $DEST_ROOT."
  echo "   archify-diagram-ps needs it to render diagrams. Install it first:"
  echo "     git clone https://github.com/tt-a1i/archify \"$DEST_ROOT/archify\""
  echo "     (cd \"$DEST_ROOT/archify\" && npm install)"
fi

echo ""
echo "Restart Claude Code, then try:  /archify-diagram-ps"
