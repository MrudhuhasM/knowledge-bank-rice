# Knowledge Bank rice

Turns a CachyOS + Hyprland laptop into a personal knowledge bank: write, keep, read and review notes.
It goes **on top of** your existing Hyprland dotfiles. Your theme, bar and binds stay as they are.

- **Obsidian** for browsing, linking, graph view and reading notes.
- **Neovim (`kv`)** for fast, light writing in the same vault.
- **zathura** for PDFs and books. Select text, press `C`, and it lands in your Inbox.
- **One key, Super+K**, for capture, daily note, search and review from anywhere.
- **Git auto-commit every hour**, so nothing is ever lost.

All notes are plain Markdown in `~/vault`.

## Install (on the laptop)

```bash
git clone https://github.com/MrudhuhasM/knowledge-bank-rice.git
cd knowledge-bank-rice
./install.sh
```

To update later: `git pull && ./install.sh`.

Then:
1. In Obsidian, choose **Open folder as vault** and pick `~/vault`. Under Settings → Core plugins, turn on **Templates**.
2. Run `kv` once while online. It downloads its Neovim plugins.
3. Press **Super+K**. A notification lists the keys.

Optional: add the bar widget from `waybar/kb-module.jsonc` (shows inbox count, words today and daily streak).
For a matching look in Obsidian: Settings → Appearance → Themes → install **Rosé Pine**.

## Keys

**Super+K, then:**

| Key | Action |
| --- | --- |
| `C` | Capture a one-line thought to Inbox |
| `P` | Capture the clipboard to Inbox |
| `D` / `Shift+D` | Today's note in Neovim / Obsidian |
| `N` / `Shift+N` | New note / new source (book, article, paper) |
| `S` | Search all notes (names and contents) |
| `R` | Review session (`#review` tagged + forgotten notes) |
| `O` | Open Obsidian |
| `V` | Open the vault in Neovim |
| `I` / `H` | Open Inbox / Home |
| `F` | Focus mode (no gaps or animations, bar hidden, notifications paused) |
| `Esc` | Cancel |

**Inside `kv` (Space is the leader key):** `d` today · `y` yesterday · `n` new · `f` find note · `s` search ·
`b` backlinks · `l` links · `t` tags · `T` insert template · `x` toggle checkbox · `i` inbox · `h` home ·
`z` zen mode · `o` open in Obsidian · `ub` light/dark. Press `Enter` on a `[[link]]` to follow it.

**In zathura:** `C` sends the selected text to Inbox · `Ctrl+R` dark mode for night reading.

## Vault layout

```
~/vault
├── Home.md        index + how the system works
├── Inbox.md       quick captures
├── Daily/         one note per day
├── Notes/         permanent notes
├── Sources/       books, articles, papers, videos
├── Attachments/
└── Templates/     daily.md, note.md, source.md
```

## Customising

- **Vault location:** set before installing with `KB_VAULT=~/notes ./install.sh`, or edit `~/.config/kb/config` afterwards.
- **Terminal:** auto-detected (kitty, ghostty, alacritty, foot, wezterm). To force one, add `KB_TERMINAL=foot` to `~/.config/kb/config`.
- **Leader key:** change `SUPER, K` in `~/.config/hypr/knowledge-bank.conf`.
- **Sync to another device:** add a git remote to the vault (`git -C ~/vault remote add origin …`) and `kb-sync` will push each hour. Or use Syncthing on the `~/vault` folder.

## Uninstall

```bash
systemctl --user disable --now kb-sync.timer
rm ~/.local/bin/kb-* ~/.local/bin/kv ~/.config/hypr/knowledge-bank.conf
rm -r ~/.config/kbvim ~/.local/share/kbvim ~/.config/kb
```

Then remove the `source = …knowledge-bank.conf` line from your Hyprland config. `.bak.*` files hold your old configs. Your vault is never deleted.
