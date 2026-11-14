-- ╭──────────────────────────────────────────────────────────────╮
-- │  Knowledge Bank: a "paper & ink" Hyprland rice               │
-- │  Lua config for Hyprland 0.55+ (syntax follows the official  │
-- │  example/hyprland.lua). Personal tweaks go in user.lua.      │
-- ╰──────────────────────────────────────────────────────────────╯

local home = os.getenv("HOME")
local bin  = home .. "/.local/bin"

-- Palette: Rosé Pine Dawn ("paper & ink")
local c = {
    paper   = "faf4ed", -- base
    card    = "fffaf3", -- surface
    fold    = "f2e9e1", -- overlay
    line    = "dfdad9", -- highlight med
    muted   = "9893a5",
    ink     = "575279", -- text
    rose    = "d7827e",
    gold    = "ea9d34",
    love    = "b4637a",
    pine    = "286983",
}
local function rgba(hex, a) return "rgba(" .. hex .. (a or "ff") .. ")" end

local terminal    = "kitty"
local fileManager = "dolphin || thunar || nautilus"
local menu        = "rofi -show drun"


------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -m fill -i " .. home .. "/.local/share/kb/wallpaper.png")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("command -v nm-applet >/dev/null && nm-applet --indicator")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- Obsidian runs natively on Wayland
hl.env("QT_QPA_PLATFORM", "wayland;xcb")


-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Kept in a table so focus mode can restore it.
local look = { gaps_in = 6, gaps_out = 14, border_size = 2, rounding = 12 }

hl.config({
    general = {
        gaps_in     = look.gaps_in,
        gaps_out    = look.gaps_out,
        border_size = look.border_size,
        col = {
            active_border   = { colors = { rgba(c.rose), rgba(c.gold) }, angle = 45 },
            inactive_border = rgba(c.line),
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = look.rounding,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.97,

        shadow = {
            enabled      = true,
            range        = 14,
            render_power = 3,
            color        = 0x22575279, -- a soft ink shadow, like paper on a desk
        },

        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Gentle, quick animations (calm, not flashy)
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},  {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},     {1, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0},  {0.1, 1}  } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",   style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 90%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5,  bezier = "almostLinear", style = "slidefade 12%" })

hl.config({
    dwindle = { preserve_split = true },
    master  = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})


---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


--------------------
---- FOCUS MODE ----
--------------------
-- Super+K then F: no gaps, borders, rounding, blur or animations; bar hidden; notifications paused.
local focused = false
local function toggle_focus()
    focused = not focused
    if focused then
        hl.config({
            general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
            decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } },
            animations = { enabled = false },
        })
        hl.exec_cmd("makoctl mode -a do-not-disturb")
    else
        hl.config({
            general    = { gaps_in = look.gaps_in, gaps_out = look.gaps_out, border_size = look.border_size },
            decoration = { rounding = look.rounding, blur = { enabled = true }, shadow = { enabled = true } },
            animations = { enabled = true },
        })
        hl.exec_cmd("makoctl mode -r do-not-disturb")
    end
    hl.exec_cmd("pkill -SIGUSR1 -x waybar")
end


---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Essentials
hl.bind(mainMod .. " + Return",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + space",       hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B",           hl.dsp.exec_cmd("pkill -SIGUSR1 -x waybar"))
hl.bind(mainMod .. " + C",           hl.dsp.exec_cmd(bin .. "/kb-clipboard"))
hl.bind(mainMod .. " + slash",       hl.dsp.exec_cmd(bin .. "/kb-keys"))
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exec_cmd(bin .. "/kb-power"))

-- Windows
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Workspaces: 1 Write · 2 Read · 3 Web · 4 Term · 5 Misc
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Mouse: Super + left-drag moves, Super + right-drag resizes
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print",         hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy && notify-send -a Screenshot 'Copied to clipboard'"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png && notify-send -a Screenshot 'Saved to ~/Pictures/Screenshots'"))

-- Laptop keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


-------------------------------
---- KNOWLEDGE BANK (Super+K) ----
-------------------------------
-- Press Super+K, then one key. A notification lists them.
hl.bind(mainMod .. " + K", function()
    hl.exec_cmd("notify-send -t 4000 -a 'Knowledge Bank' 'Super+K …' "
        .. "'C capture · P clip · D daily · N note · ⇧N source · G screenshot\n"
        .. "S search · R review · O Obsidian · V vim · I inbox · H home · F focus'")
    hl.dispatch(hl.dsp.submap("kb"))
end)

hl.define_submap("kb", function()
    local function act(key, cmd)
        hl.bind(key, function()
            hl.exec_cmd(cmd)
            hl.dispatch(hl.dsp.submap("reset"))
        end)
    end
    act("C",         bin .. "/kb-capture")
    act("P",         bin .. "/kb-capture --clip")
    act("D",         bin .. "/kb-daily")
    act("SHIFT + D", bin .. "/kb-daily --obsidian")
    act("N",         bin .. "/kb-new")
    act("SHIFT + N", bin .. "/kb-new --source")
    act("G",         bin .. "/kb-shot")
    act("S",         bin .. "/kb-search")
    act("R",         bin .. "/kb-review")
    act("O",         "obsidian")
    act("V",         bin .. "/kb-open")
    act("I",         bin .. "/kb-open inbox")
    act("H",         bin .. "/kb-open home")
    hl.bind("F", function()
        toggle_focus()
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("escape", hl.dsp.submap("reset"))
end)


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Each kind of work has a home
hl.window_rule({ name = "write-obsidian", match = { class = "^(obsidian)$" },               workspace = "1" })
hl.window_rule({ name = "read-zathura",   match = { class = "^(org.pwmt.zathura)$" },       workspace = "2" })
hl.window_rule({ name = "web-browsers",   match = { class = "^(firefox|cachy-browser|chromium|brave-browser|zen)$" }, workspace = "3" })

-- Floating pop-ups (search, review, settings)
hl.window_rule({
    name   = "kb-float",
    match  = { class = "^(kb\\.float)$" },
    float  = true,
    size   = { 1100, 650 },
    center = true,
})
hl.window_rule({
    name   = "float-utilities",
    match  = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)$" },
    float  = true,
    size   = { 900, 600 },
    center = true,
})


-------------------------
---- PERSONAL TWEAKS ----
-------------------------
-- Put your own changes in ~/.config/hypr/user.lua so updates never overwrite them.
pcall(require, "user")
