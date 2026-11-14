#!/usr/bin/env bash
# restore.sh - put back the desktop configs that install.sh backed up.
#   ./restore.sh                 restore the original backup
#   ./restore.sh <backup-dir>    restore a specific one (see ~/.config/kb-backup/)
# The Knowledge Bank configs being removed are parked in ~/.config/kb-backup/removed-<date>/.
# Your vault is not touched.
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
src="${1:-$(cat "$CFG/kb-backup/latest" 2>/dev/null || true)}"
[[ -n $src && -d $src ]] || { echo "No backup found. Look in $CFG/kb-backup/"; exit 1; }

# Same list as install.sh
OWNED=(hypr waybar rofi mako kitty kbvim zathura starship.toml fish/conf.d/kb.fish
       swaync dunst wofi fuzzel)
parked="$CFG/kb-backup/removed-$(date +%Y%m%d-%H%M%S)"

echo ":: Restoring from $src"
for item in "${OWNED[@]}"; do
  if [[ -e $CFG/$item || -L $CFG/$item ]]; then
    mkdir -p "$parked/$(dirname "$item")"
    mv "$CFG/$item" "$parked/$item"
  fi
  if [[ -e $src/$item || -L $src/$item ]]; then
    mkdir -p "$CFG/$(dirname "$item")"
    mv "$src/$item" "$CFG/$item"
    echo "   restored $item"
  fi
done

rm -f "$CFG/kb-backup/latest"
systemctl --user disable --now kb-sync.timer >/dev/null 2>&1 || true
echo ":: Done. Knowledge Bank configs were moved to $parked"
echo ":: Reboot (or log out and in) to get your old desktop back."
