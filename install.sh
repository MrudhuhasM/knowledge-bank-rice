#!/usr/bin/env bash
# Paper & ink desktop for the RL build: CachyOS / Arch + Hyprland (0.55+, Lua config),
# with the RL build time log at the centre of it.
#
#   ./install.sh                  install everything
#   ./install.sh --no-packages    skip pacman
#
# Your current desktop configs are MOVED (not deleted) to ~/.config/kb-backup/<date>/.
# Undo everything with:  ./restore.sh
# Time log data in ~/.local/share/rl-timelog/data is never touched.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
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
  waybar mako swaybg kitty starship quickshell qt6ct
  # utilities
  cliphist wl-clipboard grim slurp brightnessctl playerctl pavucontrol network-manager-applet
  libnotify jq ripgrep fzf bat git xdg-utils curl fontconfig python
  # reading
  zathura zathura-pdf-mupdf
  # look
  adw-gtk-theme papirus-icon-theme ttf-ibm-plex ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
)
# rofi: older systems ship it as rofi-wayland; don't fight over it
if ! pacman -Qq rofi >/dev/null 2>&1 && ! pacman -Qq rofi-wayland >/dev/null 2>&1; then
  PKGS+=(rofi)
fi

# The time log opens in its own browser window: Firefox (or a Firefox fork, or Chromium).
if ! command -v firefox >/dev/null && ! command -v librewolf >/dev/null && ! command -v cachy-browser >/dev/null &&
   ! command -v zen-browser >/dev/null && ! command -v chromium >/dev/null && ! command -v brave >/dev/null; then
  PKGS+=(firefox)
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

# Everything this rice owns (keep in sync with restore.sh).
# Whatever exists and isn't already ours is moved into the backup folder.
OWNED=(hypr waybar rofi mako kitty zathura starship.toml fish/conf.d/kb.fish
       swaync dunst wofi fuzzel quickshell/kb qt6ct kdeglobals
       gtk-3.0/gtk.css gtk-3.0/colors.css gtk-3.0/settings.ini
       gtk-4.0/gtk.css gtk-4.0/colors.css gtk-4.0/settings.ini)
OWNED_LIST="$CFG/kb/owned"

# Which items are already ours from an earlier install?
declare -A ours=()
if [[ -f $OWNED_LIST ]]; then
  while IFS= read -r item; do ours[$item]=1; done <"$OWNED_LIST"
elif grep -qs "Knowledge Bank" "$CFG/hypr/hyprland.lua"; then
  # installed by the previous version, which didn't keep a list
  for item in hypr waybar rofi mako kitty kbvim zathura starship.toml fish/conf.d/kb.fish swaync dunst wofi fuzzel; do
    ours[$item]=1
  done
fi

if (( ${#ours[@]} )); then
  # Update: add newly-owned files to the ORIGINAL backup
  BACKUP=$(cat "$CFG/kb-backup/latest" 2>/dev/null || echo "$BACKUP")
  say "Already installed - updating (backup: $BACKUP)"
else
  say "Backing up current configs to $BACKUP"
fi
mkdir -p "$BACKUP"
for item in "${OWNED[@]}"; do
  [[ -n ${ours[$item]:-} ]] && continue
  if [[ -e $CFG/$item || -L $CFG/$item ]] && [[ ! -e $BACKUP/$item ]]; then
    mkdir -p "$BACKUP/$(dirname "$item")"
    mv "$CFG/$item" "$BACKUP/$item"
    printf '   moved %s\n' "$item"
  fi
done
echo "$BACKUP" >"$CFG/kb-backup/latest"
rm -f "$BIN/kb-focus" # from the earlier add-on version

# ── 4. Install configs, scripts, wallpaper ───────────────────────
say "Installing the desktop"
mkdir -p "$CFG"
cp -r "$HERE/config/." "$CFG/"
sed -i "s|@HOME@|$HOME|g" "$CFG/qt6ct/qt6ct.conf"
mkdir -p "$CFG/kb"
printf '%s\n' "${OWNED[@]}" >"$OWNED_LIST"

# Fraunces (display serif for clocks and headings, SIL OFL) from Google Fonts
FONTDIR="$HOME/.local/share/fonts/fraunces"
if ! fc-list 2>/dev/null | grep -qi fraunces; then
  say "Downloading the Fraunces font (Google Fonts, OFL)"
  base="https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces"
  mkdir -p "$FONTDIR"
  if curl -fsSL --max-time 60 -o "$FONTDIR/Fraunces.ttf"        "$base/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf" &&
     curl -fsSL --max-time 60 -o "$FONTDIR/Fraunces-Italic.ttf" "$base/Fraunces-Italic%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf" &&
     curl -fsSL --max-time 30 -o "$FONTDIR/OFL.txt"             "$base/OFL.txt"; then
    fc-cache -f "$FONTDIR" >/dev/null
  else
    rm -rf "$FONTDIR"
    warn "Couldn't download Fraunces - using IBM Plex Serif instead."
    sed -i 's/"Fraunces"/"IBM Plex Serif"/' "$CFG/quickshell/kb/shell.qml"
    sed -i 's/^\$serif = Fraunces/$serif = IBM Plex Serif/' "$CFG/hypr/hyprlock.conf"
    sed -i 's/"Fraunces Italic 13"/"IBM Plex Serif Italic 12"/' "$CFG/rofi/config.rasi"
  fi
fi

install -Dm644 "$HERE/share/wallpaper.png" "$SHARE/wallpaper.png"

mkdir -p "$BIN"
for f in "$HERE"/bin/*; do
  install -m755 "$f" "$BIN/$(basename "$f")"
done
# scripts from the notes version of this rice
for old in kb-capture kb-common kb-daily kb-new kb-open kb-quote kb-resume kb-review kb-search kb-shot kb-stats kb-sync kv; do
  rm -f "$BIN/$old"
done

touch "$CFG/kb/config"
grep -q '^KB_WEATHER_LOCATION=' "$CFG/kb/config" ||
  printf '# Weather widget: a city name (empty = guess from your IP), units c or f\nKB_WEATHER_LOCATION=""\nKB_WEATHER_UNITS="c"\n' >>"$CFG/kb/config"

# bash users get the prompt too (fish is handled by conf.d/kb.fish)
if [[ -f $HOME/.bashrc ]] && ! grep -q 'starship init bash' "$HOME/.bashrc"; then
  printf '\n# paper & ink rice\nexport PATH="$HOME/.local/bin:$PATH"\ncommand -v starship >/dev/null && eval "$(starship init bash)"\n' >>"$HOME/.bashrc"
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

# ── 6. The RL build time log ─────────────────────────────────────
say "Installing the RL build time log (saver on http://localhost:8765)"
RL="$HOME/.local/share/rl-timelog"
mkdir -p "$RL/data"
install -m644 "$HERE/rl-timelog/saver.py" "$HERE/rl-timelog/rl-time-log.html" \
              "$HERE/rl-timelog/user.js" "$HERE/rl-timelog/userChrome.css" "$RL/"
install -Dm644 "$HERE/systemd/rl-timelog.service" "$CFG/systemd/user/rl-timelog.service"

# The notes version committed a vault every hour; that timer is gone now.
if systemctl --user list-unit-files kb-sync.timer >/dev/null 2>&1; then
  systemctl --user disable --now kb-sync.timer >/dev/null 2>&1 || true
fi
rm -f "$CFG/systemd/user/kb-sync.service" "$CFG/systemd/user/kb-sync.timer"

systemctl --user daemon-reload
systemctl --user enable rl-timelog.service >/dev/null
systemctl --user restart rl-timelog.service
sleep 1
if curl -fsS --max-time 3 http://localhost:8765/api/summary >/dev/null 2>&1; then
  say "Time log saver is running"
else
  warn "The saver didn't answer yet. Check: systemctl --user status rl-timelog"
fi

cat <<EOF

$(say "Done. Now REBOOT (or log out and back in) so the old bar and apps stop and the new desktop starts.")

  After logging in:
    Super + /        shows every key
    Super + Space    opens apps
    Super + K        the RL build time log (it also opens by itself at login, on workspace 1)

  First time only: in the time log, click "Test the sounds" and turn the volume up
  until you'd hear the break alarm from your desk.

  Your old configs are in: $(cat "$CFG/kb-backup/latest" 2>/dev/null || echo "(nothing to back up)")
  Go back to them anytime:  ./restore.sh
EOF
