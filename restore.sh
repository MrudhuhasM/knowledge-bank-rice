#!/usr/bin/env bash
# restore.sh - put back the desktop configs that install.sh backed up.
#   ./restore.sh                 restore the original backup
#   ./restore.sh <backup-dir>    restore a specific one (see ~/.config/kb-backup/)
# The rice's configs being removed are parked in ~/.config/kb-backup/removed-<date>/.
# The time log's data (~/.local/share/rl-timelog/data) is not touched.
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
src="${1:-$(cat "$CFG/kb-backup/latest" 2>/dev/null || true)}"
[[ -n $src && -d $src ]] || { echo "No backup found. Look in $CFG/kb-backup/"; exit 1; }

# Same list as install.sh
OWNED=(hypr waybar rofi mako kitty zathura starship.toml fish/conf.d/kb.fish
       swaync dunst wofi fuzzel quickshell/kb qt6ct kdeglobals
       gtk-3.0/gtk.css gtk-3.0/colors.css gtk-3.0/settings.ini
       gtk-4.0/gtk.css gtk-4.0/colors.css gtk-4.0/settings.ini)
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

rm -f "$CFG/kb-backup/latest" "$CFG/kb/owned"
systemctl --user disable --now kb-sync.timer >/dev/null 2>&1 || true
systemctl --user disable --now rl-timelog.service >/dev/null 2>&1 || true
echo ":: Done. The rice's configs were moved to $parked"
echo ":: The time log saver is stopped; its data is still in ~/.local/share/rl-timelog/data"
echo ":: Reboot (or log out and in) to get your old desktop back."
