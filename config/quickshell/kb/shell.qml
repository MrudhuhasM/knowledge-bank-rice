// Paper & ink desktop (Quickshell 0.3+)
// Drawn on the wallpaper, below windows. Launched by hyprland.lua: `quickshell -c kb`.
//
// When no window covers it, the desktop shows where the RL build stands,
// read from the time log's saver (rl-status --json):
//
//   Good morning.
//   09:41
//   SATURDAY · 14 NOVEMBER · WEEK 46
//   ┌ the bench ──────────────── CHAPTER 0 · THE WORKBENCH ┐
//   │ NOW · 0.3                                          │
//   │ Batched generation with padding                    │
//   │ 42m on this section · 18m since your last break    │
//   │ ●●○○○  2 of 5 sections     today 1h 20m · 7 days … │
//   │ COURSE · 5.5 OF 37 · ON PACE · DONE ~MON 30 NOV, 11:00 │
//   └────────────────────────────────────────────────────┘
//
//   (next to the clock, quiet) a small month with your work days · the weather
//   Click the card to open the time log.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ── Palette: paper & ink (Rosé Pine Dawn) ─────────────────────
    readonly property color paper: "#faf4ed"
    readonly property color card:  "#fffaf3"
    readonly property color line:  "#dfdad9"
    readonly property color muted: "#9893a5"     // decoration only
    readonly property color subtle: "#6e6a86"    // readable grey
    readonly property color ink:   "#575279"
    readonly property color rose:  "#d7827e"     // decoration only
    readonly property color love:  "#b4637a"
    readonly property color pine:  "#286983"
    readonly property color gold:  "#b0700f"

    readonly property string serif: "Fraunces"
    readonly property string mono:  "IBM Plex Mono"
    readonly property string sans:  "IBM Plex Sans"
    readonly property string icons: "JetBrainsMono Nerd Font"

    readonly property int sheetWidth: 640
    readonly property string bin: "$HOME/.local/bin/"

    // ── Data ──────────────────────────────────────────────────────
    property var weather: ({ ok: false })
    property var rl: ({ ok: false })

    SystemClock { id: clock; precision: SystemClock.Seconds }

    function run(proc) { proc.running = false; proc.running = true }

    Process {
        id: weatherProc
        command: ["sh", "-c", "exec " + root.bin + "kb-weather"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.weather = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.run(weatherProc) }

    Process {
        id: rlProc
        command: ["sh", "-c", "exec " + root.bin + "rl-status --json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.rl = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 10 * 1000; running: true; repeat: true; onTriggered: root.run(rlProc) }

    function open(cmd) { Quickshell.execDetached(["sh", "-c", root.bin + cmd]) }

    // 3m · 42m · 1h 05m
    function dur(ms) {
        const m = Math.round(Math.max(0, ms || 0) / 60000)
        return m < 60 ? m + "m" : Math.floor(m / 60) + "h " + String(m % 60).padStart(2, "0") + "m"
    }

    function greeting(h) {
        if (h < 5) return "Still up?"
        if (h < 12) return "Good morning."
        if (h < 17) return "Good afternoon."
        if (h < 21) return "Good evening."
        return "Good night."
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7)
    }

    // ── Building blocks ───────────────────────────────────────────
    // Small uppercase label with a rose dot, like a page header.
    component Label: Row {
        property string text
        property color tint: root.subtle
        spacing: 8
        Rectangle { width: 5; height: 5; radius: 2.5; color: root.rose; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: parent.text.toUpperCase()
            color: parent.tint
            font.family: root.mono
            font.pixelSize: 11
            font.letterSpacing: 2.2
        }
    }

    // Mono caption (uppercase, wide-spaced)
    component Caption: Text {
        color: root.subtle
        font.family: root.mono
        font.pixelSize: 11
        font.letterSpacing: 1.4
        elide: Text.ElideRight
    }

    component Rule: Rectangle { width: parent.width; height: 1; color: root.line }

    // ── One desktop per screen ────────────────────────────────────
    Variants {
        model: Quickshell.screens

        Scope {
            id: scr
            required property var modelData
            // Shrink everything on small screens (designed for ~1080p and up)
            readonly property real s: Math.min(1, (modelData.height - 120) / 860)

            // ── Top left: clock and "where you left off" ─────────
            PanelWindow {
                id: win
                screen: scr.modelData
                anchors { top: true; left: true }
                margins { top: Math.round(84 * scr.s); left: Math.round(76 * scr.s) }
                implicitWidth: Math.ceil((root.sheetWidth + 30) * scr.s)
                implicitHeight: Math.ceil(main.implicitHeight * scr.s + 30)
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "kb-desktop"

                Column {
                    id: main
                    spacing: 0
                    scale: scr.s
                    transformOrigin: Item.TopLeft

                    // Clock on the left; the month and weather, quietly, on the right
                    Item {
                        width: root.sheetWidth
                        height: head.implicitHeight + 36
                        Column {
                            id: head
                            Text {
                                text: root.greeting(clock.date.getHours())
                                color: root.subtle
                                font.family: root.serif
                                font.italic: true
                                font.pixelSize: 26
                            }

                            // Clock: the colon is the one bit of colour
                            Row {
                                spacing: 3
                                Repeater {
                                    model: 3
                                    Text {
                                        required property int index
                                        text: index === 0 ? Qt.formatTime(clock.date, "HH") : index === 1 ? ":" : Qt.formatTime(clock.date, "mm")
                                        color: index === 1 ? root.rose : root.ink
                                        opacity: index === 1 && clock.date.getSeconds() % 2 ? 0.35 : 1
                                        Behavior on opacity { NumberAnimation { duration: 400 } }
                                        font.family: root.serif
                                        font.pixelSize: 136
                                        font.weight: Font.Light
                                    }
                                }
                            }

                            Text {
                                text: (Qt.locale("en_US").toString(clock.date, "dddd · d MMMM") + " · week " + root.isoWeek(clock.date)).toUpperCase()
                                color: root.subtle
                                font.family: root.mono
                                font.pixelSize: 13
                                font.letterSpacing: 3
                            }
                        }
                        Column {
                            id: quiet
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 36
                            spacing: 14
                            opacity: 0.9

                            // Mini month: today is ink, days you worked on the build carry a rose dot
                            Column {
                                id: cal
                                spacing: 4
                                readonly property int year: clock.date.getFullYear()
                                readonly property int month: clock.date.getMonth()
                                readonly property int today: clock.date.getDate()
                                readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
                                readonly property int days: new Date(year, month + 1, 0).getDate()
                                readonly property var active: root.rl.monthDays || []

                                anchors.right: parent.right
                                Caption { text: Qt.locale("en_US").toString(clock.date, "MMMM").toUpperCase(); font.pixelSize: 10 }
                                Grid {
                                    columns: 7
                                    rowSpacing: 0
                                    columnSpacing: 0
                                    Repeater {
                                        model: cal.lead + cal.days
                                        Item {
                                            required property int index
                                            readonly property int day: index - cal.lead + 1
                                            readonly property bool studied: cal.active.indexOf(day) >= 0
                                            width: 19; height: 17
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                y: 0
                                                text: parent.day > 0 ? parent.day : ""
                                                color: parent.day === cal.today ? root.ink : root.subtle
                                                font.family: root.mono
                                                font.pixelSize: 9
                                                font.weight: parent.day === cal.today ? Font.Bold : Font.Normal
                                                font.underline: parent.day === cal.today
                                            }
                                            Rectangle {
                                                visible: parent.studied
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                y: 13
                                                width: 3; height: 3; radius: 1.5
                                                color: root.rose
                                            }
                                        }
                                    }
                                }
                            }

                            // Weather, quietly
                            Column {
                                anchors.right: parent.right
                                spacing: 1
                                visible: root.weather.ok === true
                                Row {
                                    anchors.right: parent.right
                                    spacing: 7
                                    Text {
                                        text: root.weather.icon || ""
                                        color: root.gold
                                        font.family: root.icons
                                        font.pixelSize: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: (root.weather.temp ?? "–") + "°"
                                        color: root.ink
                                        font.family: root.serif
                                        font.pixelSize: 22
                                        font.weight: Font.Light
                                    }
                                }
                                Caption {
                                    anchors.right: parent.right
                                    font.pixelSize: 10
                                    text: (root.weather.desc || "").toUpperCase()
                                }
                                Caption {
                                    anchors.right: parent.right
                                    font.pixelSize: 10
                                    text: ((root.weather.place || "") + " · H " + (root.weather.high ?? "–") + "° L " + (root.weather.low ?? "–") + "°").toUpperCase()
                                }
                            }
                        }
                        MouseArea { anchors.fill: quiet; onClicked: root.run(weatherProc) }
                    }

                    // ── The bench: where the RL build stands ──────
                    Item {
                        id: sheet
                        readonly property var r: root.rl
                        readonly property bool live: r.ok === true && r.empty !== true
                        readonly property var step: r.step || null
                        readonly property var nxt: r.next || null
                        readonly property var brk: r.brk || null
                        readonly property var ph: r.phase || null
                        readonly property bool over: brk !== null && brk.planMs > 0 && brk.leftMs === 0
                        visible: live
                        width: root.sheetWidth
                        height: visible ? body.implicitHeight + 56 : 0

                        // soft ink shadow, then paper
                        Rectangle { anchors.fill: bg; anchors.topMargin: 10; anchors.bottomMargin: -10; radius: 24; color: "#0b575279" }
                        Rectangle { anchors.fill: bg; anchors.topMargin: 3;  anchors.bottomMargin: -3;  radius: 23; color: "#10575279" }
                        Rectangle {
                            id: bg
                            anchors.fill: parent
                            radius: 22
                            color: Qt.rgba(1, 0.98, 0.953, 0.93)
                            border.color: sheet.over || sheet.r.due ? root.rose : root.line
                        }
                        // a rose margin line, like a notebook page
                        Rectangle { x: 18; y: 24; width: 1.5; height: parent.height - 48; color: root.rose; opacity: 0.45 }

                        Column {
                            id: body
                            x: 40; y: 26
                            width: parent.width - 72
                            spacing: 18

                            // header
                            Item {
                                width: parent.width; height: 16
                                Label { text: "the bench" }
                                Caption {
                                    anchors.right: parent.right
                                    visible: sheet.ph !== null
                                    text: sheet.ph ? ("chapter " + sheet.ph.id + " · " + sheet.ph.name).toUpperCase() : ""
                                    width: Math.min(implicitWidth, parent.width - 140)
                                }
                            }

                            // the step: now / on a break / next
                            Column {
                                width: parent.width
                                spacing: 6
                                Caption {
                                    width: parent.width
                                    text: (sheet.step ? (sheet.brk ? "on a break · " : "now · ") + sheet.step.id
                                           : sheet.nxt ? "next · " + sheet.nxt.id : "nothing waiting").toUpperCase()
                                }
                                Text {
                                    width: parent.width
                                    text: sheet.step ? sheet.step.name : sheet.nxt ? sheet.nxt.name : "Import the next chapter’s sections into the time log."
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: root.ink
                                    font.family: root.serif
                                    font.pixelSize: 30
                                    lineHeight: 1.05
                                }
                                Text {
                                    width: parent.width
                                    visible: text.length > 0
                                    wrapMode: Text.WordWrap
                                    color: sheet.over || sheet.r.due ? root.love : sheet.brk ? root.pine : root.subtle
                                    font.family: sheet.over || sheet.r.due ? root.serif : root.sans
                                    font.italic: sheet.over || sheet.r.due
                                    font.pixelSize: sheet.over || sheet.r.due ? 19 : 15
                                    text: sheet.over ? "Break’s over — " + root.dur(sheet.brk.overMs) + " past the plan. Back to work."
                                        : sheet.brk ? (sheet.brk.planMs ? "Break · " + root.dur(sheet.brk.leftMs) + " left" : "Break · " + root.dur(sheet.brk.sinceMs) + " so far")
                                        : sheet.r.due ? root.dur(sheet.r.sinceBreakMs) + " without a break. Stand up for " + sheet.r.restMin + " minutes."
                                        : sheet.step ? root.dur(sheet.step.workMs) + " on this section · " + root.dur(sheet.r.sinceBreakMs) + " since your last break"
                                        : ""
                                }
                            }

                            Rule {}

                            // phase progress | today and this week
                            Item {
                                width: parent.width
                                height: Math.max(prog.implicitHeight, totals.implicitHeight)
                                Column {
                                    id: prog
                                    spacing: 8
                                    visible: sheet.ph !== null
                                    Caption { text: "CHAPTER PROGRESS" }
                                    Row {
                                        spacing: 10
                                        Row {
                                            spacing: 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            Repeater {
                                                model: sheet.ph ? Math.min(sheet.ph.total, 24) : 0
                                                Rectangle {
                                                    required property int index
                                                    width: 8; height: 8; radius: 4
                                                    color: index < sheet.ph.done ? root.rose : "transparent"
                                                    border.color: root.muted
                                                    border.width: index < sheet.ph.done ? 0 : 1
                                                }
                                            }
                                        }
                                        Caption { text: sheet.ph ? (sheet.ph.done + " of " + sheet.ph.total + " sections").toUpperCase() : "" }
                                    }
                                }
                                Row {
                                    id: totals
                                    anchors.right: parent.right
                                    spacing: 26
                                    Repeater {
                                        model: [["today", sheet.r.todayMs], ["last 7 days", sheet.r.weekMs]]
                                        Column {
                                            required property var modelData
                                            spacing: 2
                                            Caption { text: modelData[0].toUpperCase() }
                                            Text {
                                                text: root.dur(modelData[1])
                                                color: root.ink
                                                font.family: root.serif
                                                font.pixelSize: 24
                                                font.weight: Font.Light
                                            }
                                        }
                                    }
                                }
                            }

                            // the three-book course, from the coach
                            Text {
                                readonly property var c: sheet.r.course || null
                                visible: c !== null
                                width: parent.width
                                elide: Text.ElideRight
                                color: c && c.diff < -0.05 ? root.love : root.subtle
                                font.family: root.mono
                                font.pixelSize: 11
                                font.letterSpacing: 1.3
                                text: !c ? "" : ("course · " + c.done + " of " + c.total + " · "
                                      + (c.diff > 0.05 ? "ahead by " + c.diff.toFixed(1) + " ch."
                                         : c.diff < -0.05 ? "behind by " + (-c.diff).toFixed(1) + " ch." : "on pace")
                                      + (c.finish ? " · done ~" + Qt.formatDateTime(new Date(c.finish), "ddd d MMM, HH:00") : " · finished")).toUpperCase()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.open("rl-open")
                        }
                    }

                    // The saver isn't answering, or nothing has been tracked yet
                    Text {
                        visible: !sheet.live
                        width: root.sheetWidth
                        text: root.rl.ok === true ? "The bench is ready.\nSuper + K opens the time log; start your first section there."
                                                  : "The time log isn’t running.\nsystemctl --user start rl-timelog"
                        color: root.subtle
                        font.family: root.serif
                        font.italic: true
                        font.pixelSize: 20
                        lineHeight: 1.2
                        MouseArea { anchors.fill: parent; onClicked: root.open("rl-open") }
                    }
                }
            }
        }
    }
}
