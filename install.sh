#!/usr/bin/env bash
# Knowledge Bank: full "paper & ink" desktop for CachyOS / Arch + Hyprland (0.55+, Lua config).
#
#   ./install.sh                  install everything (vault at ~/vault)
#   KB_VAULT=~/notes ./install.sh use another vault folder
#   ./install.sh --no-packages    skip pacman
#
# Your current desktop configs are MOVED (not deleted) to ~/.config/kb-backup/<date>/.
# Undo everything with:  ./restore.sh
# An existing vault is never touched.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
VAULT="${KB_VAULT:-$HOME/vault}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/kb"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$CFG/kb-backup/$STAMP"

say()  { printf '\033[1;35m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

(( EUID != 0 )) || die "Run this as your normal user, not root (it uses sudo for pacman)."
command -v pacman >/dev/null || die "pacman not found - this is for CachyOS / Arch."

# ── 1. Packages ──────────────────────────────────────────────────
PKGS=(
  # desktop
  hyprland hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar mako swaybg kitty starship
  # utilities
  cliphist wl-clipboard grim slurp brightnessctl playerctl pavucontrol network-manager-applet
  libnotify jq ripgrep fzf bat git xdg-utils
  # knowledge bank
  obsidian neovim zathura zathura-pdf-mupdf
  # look
  adw-gtk-theme papirus-icon-theme ttf-ibm-plex ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
)
# rofi: older systems ship it as rofi-wayland; don't fight over it
if ! pacman -Qq rofi >/dev/null 2>&1 && ! pacman -Qq rofi-wayland >/dev/null 2>&1; then
  PKGS+=(rofi)
fi

if [[ ${1:-} != --no-packages ]]; then
  say "Installing packages (sudo)"
  sudo pacman -S --needed "${PKGS[@]}"
fi

# ── 2. Hyprland version check (Lua config needs 0.55+) ───────────
ver=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
minor=$(cut -d. -f2 <<<"${ver:-0.0}")
if [[ -z $ver ]]; then
  warn "Couldn't read the Hyprland version. This rice needs Hyprland 0.55 or newer."
elif (( minor < 55 )); then
  die "Hyprland $ver is too old for Lua configs (needs 0.55+). Update first: sudo pacman -Syu"
else
  say "Hyprland $ver"
fi

# ── 3. Detect and back up the current desktop ────────────────────
found=()
[[ -d $CFG/hyde || -d $HOME/.local/share/hyde ]]    && found+=("HyDE")
[[ -d $CFG/ml4w || -d $HOME/.mydotfiles ]]          && found+=("ML4W")
[[ -d $CFG/hypr/UserConfigs ]]                      && found+=("JaKooLit")
[[ -d $CFG/quickshell/ii || -d $CFG/ags ]]          && found+=("end-4 / AGS")
[[ -d $CFG/quickshell/caelestia ]]                  && found+=("Caelestia")
[[ -f $CFG/hypr/knowledge-bank.conf ]]              && found+=("earlier Knowledge Bank add-on")
if (( ${#found[@]} )); then say "Found existing setup: ${found[*]}"; fi

# Everything this rice owns. Whatever exists is moved into the backup folder.
OWNED=(hypr waybar rofi mako kitty kbvim zathura starship.toml fish/conf.d/kb.fish
       swaync dunst wofi fuzzel)
if grep -qs "Knowledge Bank" "$CFG/hypr/hyprland.lua"; then
  # Re-run: already on this rice, so just update files and keep the ORIGINAL backup
  say "Knowledge Bank already installed - updating in place (original backup kept)."
  BACKUP=""
else
  say "Backing up current configs to $BACKUP"
  mkdir -p "$BACKUP"
  for item in "${OWNED[@]}"; do
    if [[ -e $CFG/$item || -L $CFG/$item ]]; then
      mkdir -p "$BACKUP/$(dirname "$item")"
      mv "$CFG/$item" "$BACKUP/$item"
      printf '   moved %s\n' "$item"
    fi
  done
  echo "$BACKUP" >"$CFG/kb-backup/latest"
fi
rm -f "$BIN/kb-focus" # from the earlier add-on version

# ── 4. Install configs, scripts, wallpaper ───────────────────────
say "Installing the Knowledge Bank desktop"
mkdir -p "$CFG"
cp -r "$HERE/config/." "$CFG/"
sed -i "s|@BIN@|$BIN|g" "$CFG/zathura/zathurarc"

install -Dm644 "$HERE/share/wallpaper.png" "$SHARE/wallpaper.png"

mkdir -p "$BIN"
for f in "$HERE"/bin/*; do
  install -m755 "$f" "$BIN/$(basename "$f")"
done

mkdir -p "$CFG/kb"
[[ -f $CFG/kb/config ]] || printf 'VAULT="%s"\n' "$VAULT" >"$CFG/kb/config"

# bash users get the prompt too (fish is handled by conf.d/kb.fish)
if [[ -f $HOME/.bashrc ]] && ! grep -q 'starship init bash' "$HOME/.bashrc"; then
  printf '\n# Knowledge Bank\nexport PATH="$HOME/.local/bin:$PATH"\ncommand -v starship >/dev/null && eval "$(starship init bash)"\n' >>"$HOME/.bashrc"
fi

# ── 5. App theme (GTK), default apps ─────────────────────────────
say "Applying the light GTK theme, icons and fonts"
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme           'adw-gtk3'        || true
  gsettings set org.gnome.desktop.interface color-scheme        'prefer-light'    || true
  gsettings set org.gnome.desktop.interface icon-theme          'Papirus-Light'   || true
  gsettings set org.gnome.desktop.interface font-name           'IBM Plex Sans 11' || true
  gsettings set org.gnome.desktop.interface document-font-name  'IBM Plex Serif 11' || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' || true
  gsettings set org.gnome.desktop.interface cursor-theme        'Adwaita'         || true
  gsettings set org.gnome.desktop.interface cursor-size         24                || true
fi
xdg-mime default org.pwmt.zathura.desktop application/pdf 2>/dev/null || true

# ── 6. Vault ─────────────────────────────────────────────────────
if [[ -e $VAULT ]]; then
  say "Vault $VAULT already exists - left untouched."
else
  say "Creating vault at $VAULT"
  cp -r "$HERE/vault" "$VAULT"
  git -C "$VAULT" init -q
  git -C "$VAULT" config user.name  >/dev/null || git -C "$VAULT" config user.name "Knowledge Bank"
  git -C "$VAULT" config user.email >/dev/null || git -C "$VAULT" config user.email "kb@localhost"
  git -C "$VAULT" add -A
  git -C "$VAULT" commit -qm "Start knowledge bank"
fi

# ── 7. Hourly vault auto-commit ──────────────────────────────────
say "Enabling hourly vault commits"
install -Dm644 "$HERE/systemd/kb-sync.service" "$CFG/systemd/user/kb-sync.service"
install -Dm644 "$HERE/systemd/kb-sync.timer"   "$CFG/systemd/user/kb-sync.timer"
systemctl --user daemon-reload
systemctl --user enable --now kb-sync.timer >/dev/null

cat <<EOF

$(say "Done. Now REBOOT (or log out and back in) so the old bar and apps stop and the new desktop starts.")

  After logging in:
    Super + /        shows every key
    Super + Space    opens apps
    Super + K        knowledge-bank keys (capture, daily note, search, review…)

  First time only:
    1. Obsidian → "Open folder as vault" → $VAULT, then Settings → Core plugins → turn on Templates.
       Matching theme: Settings → Appearance → Themes → "Rosé Pine" (switch it to light).
    2. Run  kv  once while online - it downloads its Neovim plugins.

  Your old configs are in: $(cat "$CFG/kb-backup/latest" 2>/dev/null || echo "(nothing to back up)")
  Go back to them anytime:  ./restore.sh
EOF
