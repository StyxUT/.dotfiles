-- Hyprland 0.57 Lua configuration.

local terminal = "kitty"
local fileManager = "thunar"
local menu = "wofi"
local calculator = "wofi-calc"
local browser = "librewolf"

hl.monitor({
    output = "DP-3",
    mode = "3440x1440@59.97",
    position = "3515x0",
    scale = "1.0",
    transform = 2,
})
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60.0",
    position = "721x1800",
    scale = "1.0",
})
hl.monitor({
    output = "DP-2",
    mode = "5120x1440@240.0",
    position = "2641x1440",
    scale = "1.0",
    bitdepth = 10,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper & hypridle & hyprlock & hyprsunset")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync -c ~/.config/swaync/config.json")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("WLR_NO_HARDWARE_CURSORs", "1")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 1,
        border_size = 3,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = false,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 1.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 10, bezier = "easeInOutCubic", style = "popin 20%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 10, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 10, bezier = "easeOutQuint", style = "popin 20%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.94, bezier = "almostLinear", style = "fade" })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd('bash -c "hyprlock & sudo /usr/local/bin/mounts -um"'))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.exec_cmd(calculator))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pkill waybar && hyprctl dispatch exec waybar"))
hl.bind(mainMod .. " + SHIFT + F4", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("bash ~/.config/hypr/toggle-side-monitors.sh"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprctl reload"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

local function workspaceRule(workspace, monitor, persistent, default)
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = monitor,
        persistent = persistent or false,
        default = default or false,
    })
end

workspaceRule(1, "DP-2", true, true)
for _, workspace in ipairs({ 4, 7, 10, 11, 12, 13, 14, 15 }) do
    workspaceRule(workspace, "DP-2")
end
workspaceRule(2, "DP-3", true, true)
workspaceRule(5, "DP-3")
workspaceRule(8, "DP-3")
workspaceRule(3, "HDMI-A-1", true, true)
workspaceRule(6, "HDMI-A-1")
workspaceRule(9, "HDMI-A-1")

local function appWorkspaceRule(name, class, workspace)
    hl.window_rule({
        name = name,
        match = { class = class },
        workspace = tostring(workspace),
    })
end

-- Preserve both the lowercase and title-case matches from the previous config.
appWorkspaceRule("signal-lowercase", "^(signal)$", 5)
appWorkspaceRule("spotify-lowercase", "^(spotify)$", 5)
appWorkspaceRule("chrome-generic", "(chrome)", 3)
appWorkspaceRule("signal", "^(Signal)$", 5)
appWorkspaceRule("spotify", "^(Spotify)$", 5)
appWorkspaceRule("steam", "^(Steam)$", 4)
appWorkspaceRule("google-chrome", "^(google-chrome)$", 3)

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
