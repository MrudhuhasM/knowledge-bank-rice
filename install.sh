#!/usr/bin/env bash
# Knowledge Bank rice installer for CachyOS / Arch + Hyprland.
# Adds on top of your existing Hyprland setup; it doesn't replace it.
#
#   ./install.sh                  install everything (vault at ~/vault)
#   KB_VAULT=~/notes ./install.sh use another vault folder
#   ./install.sh --no-packages    skip pacman
#
# Safe to run again: existing files get a .bak copy, an existing vault is never touched.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
VAULT="${KB_VAULT:-$HOME/vault}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
HYPR="$CFG/hypr"
STAMP=$(date +%Y%m%d-%H%M%S)

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

backup() { # copy a real file aside before we overwrite it
  if [[ -f $1 && ! -L $1 ]]; then
    cp -a "$1" "$1.bak.$STAMP"
    warn "Backed up $1 -> $1.bak.$STAMP"
  fi
}

place() { # place SRC DEST MODE  - install, backing up DEST if it differs
  if [[ -f $2 ]] && cmp -s "$1" "$2"; then return 0; fi
  backup "$2"
  install -Dm"$3" "$1" "$2"
}

(( EUID != 0 )) || die "Run this as your normal user, not root (it uses sudo for pacman)."
command -v pacman >/dev/null || die "pacman not found - this script is for CachyOS / Arch."

# ── 1. Packages ──────────────────────────────────────────────────
PKGS=(
  obsidian neovim git ripgrep fzf bat jq     # writing + search
  zathura zathura-pdf-mupdf                  # reading PDFs / books
  wl-clipboard libnotify xdg-utils           # clipboard, notifications, links
  ttf-ibm-plex ttf-jetbrains-mono-nerd       # fonts
)
if [[ ${1:-} != --no-packages ]]; then
  say "Installing packages (sudo)"
  sudo pacman -S --needed "${PKGS[@]}"
fi

command -v rofi >/dev/null || command -v fuzzel >/dev/null || command -v wofi >/dev/null ||
  warn "No menu program found. Install one: sudo pacman -S rofi   (or fuzzel)"
command -v kitty >/dev/null || command -v ghostty >/dev/null || command -v alacritty >/dev/null ||
  command -v foot >/dev/null || command -v wezterm >/dev/null ||
  warn "No supported terminal found. Install one: sudo pacman -S kitty"

# ── 2. Scripts ───────────────────────────────────────────────────
say "Installing kb-* scripts to $BIN"
for f in "$HERE"/bin/*; do
  place "$f" "$BIN/$(basename "$f")" 755
done
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) warn "$BIN is not on your PATH. Add to your shell rc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

mkdir -p "$CFG/kb"
if [[ ! -f $CFG/kb/config ]]; then
  printf 'VAULT="%s"\n' "$VAULT" >"$CFG/kb/config"
fi

# ── 3. Configs ───────────────────────────────────────────────────
say "Installing Neovim config (kbvim) and zathura config"
place "$HERE/kbvim/init.lua" "$CFG/kbvim/init.lua" 644

tmp=$(mktemp)
sed "s|@BIN@|$BIN|g" "$HERE/zathura/zathurarc" >"$tmp"
place "$tmp" "$CFG/zathura/zathurarc" 644
rm -f "$tmp"

# Make zathura the default PDF app
xdg-mime default org.pwmt.zathura.desktop application/pdf 2>/dev/null || true

# ── 4. Hyprland ──────────────────────────────────────────────────
say "Adding Knowledge Bank keybinds to Hyprland"
[[ -d $HYPR ]] || die "$HYPR not found - is Hyprland set up?"
place "$HERE/hypr/knowledge-bank.conf" "$HYPR/knowledge-bank.conf" 644

# Pick the file your dotfiles expect user changes in, so updates don't wipe it
if   [[ -f $HYPR/userprefs.conf ]];                 then target=$HYPR/userprefs.conf                 # HyDE
elif [[ -f $HYPR/conf/custom.conf ]];               then target=$HYPR/conf/custom.conf               # ML4W
elif [[ -f $HYPR/UserConfigs/UserKeybinds.conf ]];  then target=$HYPR/UserConfigs/UserKeybinds.conf  # JaKooLit
elif [[ -f $HYPR/custom/keybinds.conf ]];           then target=$HYPR/custom/keybinds.conf           # end-4
else target=$HYPR/hyprland.conf
fi

if grep -qF "knowledge-bank.conf" "$target" 2>/dev/null; then
  say "Already sourced from $target"
else
  if command -v hyprctl >/dev/null && hyprctl binds -j 2>/dev/null |
      jq -e 'any(.[]; .modmask == 64 and (.key | ascii_downcase) == "k")' >/dev/null 2>&1; then
    warn "Super+K is already bound in your setup. Both will fire; change the key in $HYPR/knowledge-bank.conf if that's a problem."
  fi
  backup "$target"
  printf '\n# Knowledge Bank rice\nsource = %s\n' "$HYPR/knowledge-bank.conf" >>"$target"
  say "Sourced from $target"
fi
command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true

# ── 5. Vault ─────────────────────────────────────────────────────
if [[ -e $VAULT ]]; then
  warn "$VAULT already exists - leaving it untouched."
else
  say "Creating vault at $VAULT"
  cp -r "$HERE/vault" "$VAULT"
  git -C "$VAULT" init -q
  git -C "$VAULT" config user.name >/dev/null || git -C "$VAULT" config user.name "Knowledge Bank"
  git -C "$VAULT" config user.email >/dev/null || git -C "$VAULT" config user.email "kb@localhost"
  git -C "$VAULT" add -A
  git -C "$VAULT" commit -qm "Start knowledge bank"
fi

# ── 6. Hourly auto-commit ────────────────────────────────────────
say "Enabling hourly vault commits (kb-sync.timer)"
place "$HERE/systemd/kb-sync.service" "$CFG/systemd/user/kb-sync.service" 644
place "$HERE/systemd/kb-sync.timer"   "$CFG/systemd/user/kb-sync.timer"   644
systemctl --user daemon-reload
systemctl --user enable --now kb-sync.timer >/dev/null

cat <<EOF

$(say "Done.")
  1. Open Obsidian → "Open folder as vault" → $VAULT
     Then Settings → Core plugins → turn on "Templates" (Daily notes is on by default).
  2. Run  kv  once with internet on - it downloads its Neovim plugins.
  3. Press Super+K to see the Knowledge Bank keys.
  4. Optional: add the waybar module from $HERE/waybar/kb-module.jsonc
EOF
