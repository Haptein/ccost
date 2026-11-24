#!/bin/sh
# Install ccost on Linux or macOS.
#
#   ./install.sh              install ccost and the Claude Code session-end hook
#   ./install.sh --no-hook    install ccost only
#   ./install.sh --uninstall  remove both (the ledger is kept)
#
# From a clone it links to the clone, so `git pull` updates it. Without one:
#   curl -fsSL https://raw.githubusercontent.com/Haptein/ccost/main/install.sh | sh
set -eu

RAW="https://raw.githubusercontent.com/Haptein/ccost/main/ccost"
BIN_DIR="$HOME/.local/bin"
TARGET="$BIN_DIR/ccost"
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

die() { echo "install.sh: $*" >&2; exit 1; }

# Add or remove the SessionEnd hook in Claude Code's settings.json.
hook() {
    python3 - "$1" "$SETTINGS" "$TARGET --sync >/dev/null 2>&1 || true" <<'PY'
import json, os, shutil, sys
op, path, cmd = sys.argv[1:4]
try:
    with open(path, encoding="utf-8") as fh:
        settings = json.load(fh)
except FileNotFoundError:
    settings = {}
except ValueError as e:
    sys.exit(f"install.sh: {path} is not valid JSON ({e}); hook left unchanged")

groups = settings.get("hooks", {}).get("SessionEnd", [])
kept = [g for g in groups if "ccost --sync" not in json.dumps(g)]
if op == "add":
    if len(kept) < len(groups):
        sys.exit(0)  # already there
    kept.append({"hooks": [{"type": "command", "command": cmd}]})
elif len(kept) == len(groups):
    sys.exit(0)  # nothing to remove
settings.setdefault("hooks", {})["SessionEnd"] = kept
if not kept:
    del settings["hooks"]["SessionEnd"]

os.makedirs(os.path.dirname(path), exist_ok=True)
if os.path.exists(path):
    shutil.copy2(path, path + ".bak-ccost")
with open(path + ".tmp", "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(path + ".tmp", path)
print(("added hook to " if op == "add" else "removed hook from ") + path)
PY
}

command -v python3 >/dev/null || die "python3 (3.9 or newer) is required"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' || die "python 3.9 or newer is required"

case "${1:-}" in
    --uninstall)
        rm -f "$TARGET" && echo "removed $TARGET"
        hook remove
        echo "The ledger in ${XDG_DATA_HOME:-$HOME/.local/share}/ccost was kept."
        exit 0 ;;
    ""|--no-hook) ;;
    *) die "unknown option: $1" ;;
esac

mkdir -p "$BIN_DIR"
verb=installed
[ -e "$TARGET" ] && verb=updated
here=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -f "$here/ccost" ] && [ -f "$here/install.sh" ]; then
    chmod +x "$here/ccost"
    ln -sf "$here/ccost" "$TARGET"
else
    # Download next to the target first, so a failed update keeps the old version.
    curl -fsSL "$RAW" -o "$TARGET.new" || { rm -f "$TARGET.new"; die "download failed; nothing changed"; }
    chmod +x "$TARGET.new"
    mv -f "$TARGET.new" "$TARGET"
fi
echo "$verb $TARGET"

[ "${1:-}" = --no-hook ] || hook add

case ":$PATH:" in
    *":$BIN_DIR:"*) echo "Done. Run: ccost" ;;
    *) echo "Done. $BIN_DIR is not on your PATH: add it, or run $TARGET" ;;
esac
