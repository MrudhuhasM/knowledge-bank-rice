# Paper & ink: a Hyprland rice for the RL build

A calm, light desktop for CachyOS + Hyprland, built around one thing: the **RL build time log**.
This laptop sits beside the one you work on. It keeps the clock on your steps, tells you when to
take a break, and shows how the build is going.

![Desktop preview](screenshots/desktop-preview.jpg)
<sub>The preview still shows the earlier notes card; the desktop card now shows the RL build.</sub>

- **The time log** opens by itself at login, in its own window on workspace 1 (LOG). Start a step, tick it when it passes review, take timed breaks (5/15/30 min or your own) with an alarm that keeps beeping until you're back. It shows work today and this week, your focus ratio, break overruns, your longest unbroken stretch, a 14-day chart and a finish estimate.
- **Break reminders:** after 50 minutes of unbroken work (25, 50, 90 or off, set in the page) a chime plays and a notification asks you to take a break; it asks again every 10 minutes until you do. "Break's over" is a notification that stays until you're back.
- **Safe on a laptop with no battery:** every click is written to disk at once (`~/.local/share/rl-timelog/data/state.json`, plus a dated copy per day for 30 days). After a power cut the page sees how long it was off and asks whether to leave that time out, so outages never count as work or as breaks.
- **Stays awake while you work:** while a step or break is running, the screen doesn't dim, lock or turn off and the laptop doesn't suspend. When nothing is running, idle works as usual.
- **The desktop card** (Quickshell): with no windows open you see a serif clock and the bench: the step you're on (or the next one), time on it, time since your last break, phase progress and today's total. A small month marks the days you worked on the build. Click it to open the time log.
- **The bar** shows the running step and its time; it turns rose when a break is due and fills in when a break has run out. The **lock screen** shows the next step and today's work.
- **Look:** warm cream paper, ink text, one rose accent (Rosé Pine Dawn). Fraunces serif for clocks and headings, IBM Plex for text and labels. Hyprland (Lua config), floating-island **waybar**, **rofi**, **mako**, **hyprlock**, **hypridle**, **kitty** + **starship**, **zathura** for books and papers. One palette across GTK, Qt/KDE, the terminal, fish, fzf and bat.
- **Safety:** your old desktop configs are backed up (`./restore.sh` puts them back).

Requires **Hyprland 0.55 or newer** (Lua config). The installer checks this.

## Install

```bash
git clone https://github.com/MrudhuhasM/knowledge-bank-rice.git
cd knowledge-bank-rice
./install.sh
```

Then **reboot**. After logging in the time log opens on workspace 1. First time only: click **Test the sounds** in it and turn the volume up until you'd hear the alarm from your desk.

- `Super + K` shows the time log (and starts it if it was closed).
- `Super + /` shows every key. `Super + Space` opens apps.

To update later: `git pull && ./install.sh` (it updates in place, keeps your original backup and never touches the time log's data).

To undo everything: `./restore.sh`, then reboot.

## The time log

It's a web page served by a small saver (`saver.py`, Python standard library only) running as a systemd user service on `http://localhost:8765`, reachable only from this laptop. The window is a separate, minimal Firefox profile (no toolbars, sound allowed without a click, no "restore session?" after a power cut). It uses Firefox, LibreWolf, cachy-browser or Zen if you have one, otherwise Chromium or Brave.

**New phase steps:** when a phase opens, Claude gives you its steps as plain lines:

```
Phase 1 — Thin slice
1.1 Environment interface
1.2 Math verifier
```

Paste them into **Add a new phase's steps**. Steps already there keep their times. A handy way to carry them over: commit them to your RL repo as `phases/p1/STEPS.txt` and copy them from GitHub on this laptop.

**Backups:** the saver keeps a copy per day for 30 days in `~/.local/share/rl-timelog/data/backups/`. **Download backup** in the page saves a JSON file you can keep elsewhere; **Restore from backup** loads one.

**In a terminal:** `rl-status` prints the current step; `rl-status --json` prints the full summary; `systemctl --user status rl-timelog` checks the saver.

## Keys

| Keys | Action |
| --- | --- |
| `Super + K` | RL time log |
| `Super + Shift + K` | Focus mode: no gaps, rounding, blur or animations; bar hidden; notifications paused |
| `Super + Space` | Open an app |
| `Super + Return` | Terminal |
| `Super + Q` | Close window |
| `Super + E` | File manager |
| `Super + F` / `V` | Fullscreen / float window |
| `Super + arrows` | Move focus (add `Shift` to move the window) |
| `Super + 1…5` | Workspaces: **Log · Read · Web · Term · Misc** (add `Shift` to send a window there) |
| `Super + S` | Scratchpad |
| `Super + B` | Hide / show the bar |
| `Super + C` | Clipboard history |
| `Super + Escape` | Lock |
| `Super + Shift + E` | Power menu |
| `Print` / `Shift + Print` | Screenshot area to clipboard / full screen to file |
| `Super + /` | Cheat sheet |

The time log lives on workspace 1 (Log), PDFs on 2 (Read), browsers on 3 (Web). In zathura, `Ctrl+R` switches to dark mode for night reading.

## Idle

hypridle dims at 5 minutes, locks at 10, turns the screen off at 11 and suspends at 30, but each step goes through `kb-idle`, which skips it while a step or break is running. If a step ends while you're away, the next idle timeout after you touch the laptop applies as usual.

## Customising

- **Weather** comes from [wttr.in](https://wttr.in). Set your city in `~/.config/kb/config`: `KB_WEATHER_LOCATION="Kochi"` (empty = guess from your IP) and `KB_WEATHER_UNITS="c"` or `"f"`. Click it to refresh.
- **Your own Hyprland tweaks:** create `~/.config/hypr/user.lua`. It loads last and updates never overwrite it.
- **Colours:** the palette is at the top of `~/.config/hypr/hyprland.lua` and in `~/.config/waybar/style.css`.
- **The desktop card:** `~/.config/quickshell/kb/shell.qml` (Quickshell reloads live as you save). Restart it with `pkill quickshell; quickshell -c kb &`.
- **Port:** set `RL_TIMELOG_PORT` in the service (`systemctl --user edit rl-timelog`) and in your shell if 8765 is taken.
