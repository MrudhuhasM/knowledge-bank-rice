# Knowledge Bank: a paper & ink Hyprland rice

A complete desktop for CachyOS + Hyprland, designed as a personal knowledge bank: a calm, light,
paper-like place to write, keep, read and review notes.

- **Look:** warm cream paper, ink text, rose and gold accents (Rosé Pine Dawn). Serif headings, IBM Plex fonts, a ruled-notebook wallpaper.
- **Desktop:** Hyprland (Lua config), floating-island **waybar**, **rofi** launcher, **mako** notifications, **hyprlock** lock screen that shows one of your own highlights, **hypridle**, **kitty** + **starship**, light GTK theme and Papirus icons.
- **Notes:** **Obsidian** and **Neovim (`kv`)** on the same Markdown vault, **zathura** for PDFs, and Super+K keys for capture, daily notes, search, review, screenshots-to-vault and focus mode.
- **Safety:** your old desktop configs are backed up (`./restore.sh` puts them back), and the vault auto-commits to git every hour.

Requires **Hyprland 0.55 or newer** (Lua config). The installer checks this.

## Install

```bash
git clone https://github.com/MrudhuhasM/knowledge-bank-rice.git
cd knowledge-bank-rice
./install.sh
```

Then **reboot**. After logging in:
- `Super + /` shows every key.
- `Super + Space` opens apps.
- `Super + K` opens the knowledge-bank keys.

First time only:
1. In Obsidian, choose **Open folder as vault** and pick `~/vault`. Then Settings → Core plugins → turn on **Templates**. For the matching look: Settings → Appearance → Themes → **Rosé Pine**, light mode.
2. Run `kv` once while online. It downloads its Neovim plugins.

To update later: `git pull && ./install.sh` (it updates in place and keeps your original backup).

To undo everything: `./restore.sh`, then reboot.

## Keys

| Keys | Action |
| --- | --- |
| `Super + Space` | Open an app |
| `Super + Return` | Terminal |
| `Super + Q` | Close window |
| `Super + E` | File manager |
| `Super + F` / `V` | Fullscreen / float window |
| `Super + arrows` | Move focus (add `Shift` to move the window) |
| `Super + 1…5` | Workspaces: **Write · Read · Web · Term · Misc** (add `Shift` to send a window there) |
| `Super + S` | Scratchpad |
| `Super + B` | Hide / show the bar |
| `Super + C` | Clipboard history |
| `Super + Escape` | Lock |
| `Super + Shift + E` | Power menu |
| `Print` / `Shift + Print` | Screenshot area to clipboard / full screen to file |
| `Super + /` | Cheat sheet |

**Super + K, then:**

| Key | Action |
| --- | --- |
| `C` / `P` | Capture a thought / the clipboard to Inbox |
| `D` / `Shift + D` | Today's note in Neovim / Obsidian |
| `N` / `Shift + N` | New note / new source (book, article, paper) |
| `G` | Screenshot an area into the vault; copies `![[file]]` to paste |
| `S` | Search all notes |
| `R` | Review session (`#review`-tagged and forgotten notes) |
| `O` / `V` | Obsidian / vault in Neovim |
| `I` / `H` | Inbox / Home |
| `F` | Focus mode: no gaps, rounding, blur or animations; bar hidden; notifications paused |

Obsidian opens on workspace 1 (Write), PDFs on 2 (Read), browsers on 3 (Web).

**Inside `kv` (Space is the leader key):**
- `d` today, `y` yesterday, `n` new note
- `f` find a note, `s` search
- `b` backlinks, `l` links, `t` tags
- `T` insert a template, `x` toggle a checkbox
- `i` Inbox, `h` Home
- `z` zen mode, `o` open in Obsidian, `ub` switch light/dark

**In zathura:** `C` sends the selected text to Inbox. `Ctrl+R` switches to dark mode for night reading.

**Bar:** click the book icon for today's note, right-click to start a review, middle-click to capture.

## Vault layout

```
~/vault
├── Home.md        index + how the system works
├── Inbox.md       quick captures
├── Daily/         one note per day
├── Notes/         permanent notes
├── Sources/       books, articles, papers, videos
├── Attachments/   images, screenshots, PDFs
└── Templates/     daily.md, note.md, source.md
```

Lines starting with `> ` (highlights) appear on the lock screen at random.

## Customising

- **Your own Hyprland tweaks:** create `~/.config/hypr/user.lua`. It loads last and updates never overwrite it.
- **Colours:** the palette is at the top of `~/.config/hypr/hyprland.lua` and in `~/.config/waybar/style.css`.
- **Vault location:** set it before installing with `KB_VAULT=~/notes ./install.sh`, or edit `~/.config/kb/config`.
- **Sync notes to another device:** use a **private** git remote for `~/vault` (`kb-sync` pushes hourly), or Syncthing. Never put notes in this public repo.
