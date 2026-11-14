// Knowledge Bank: desktop (Quickshell 0.3+)
// Drawn on the wallpaper, below windows. Launched by hyprland.lua: `quickshell -c kb`.
//
// When no window is open, the desktop shows where you left off in your learning,
// read from the vault by kb-resume:
//
//   Good morning.
//   09:41
//   SATURDAY · 14 NOVEMBER · WEEK 46
//   ┌ where you left off ─────────────────────┐
//   │ the module you're on, in the course     │
//   │ next milestone on the path · last notes │
//   │ a question waiting for you              │
//   └─────────────────────────────────────────┘
//
//   (next to the clock, quiet) a small month with your study days · the weather

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
    property var resume: ({ ok: false })

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
        id: resumeProc
        command: ["sh", "-c", "exec " + root.bin + "kb-resume"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.resume = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 2 * 60 * 1000; running: true; repeat: true; onTriggered: root.run(resumeProc) }

    function open(cmd) { Quickshell.execDetached(["sh", "-c", root.bin + cmd]) }

    // Open a vault file (path relative to the vault) in Obsidian.
    function openNote(file) {
        if (!file || !root.resume.vault) return
        Quickshell.execDetached(["xdg-open", "obsidian://open?vault=" + encodeURIComponent(root.resume.vault)
                                 + "&file=" + encodeURIComponent(file.replace(/\.md$/, ""))])
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

    // A block you can click to open its note; ink darkens a touch on hover.
    component Block: Item {
        id: blk
        default property alias content: col.data
        property string file
        property alias hovered: ma.containsMouse
        width: parent.width
        implicitHeight: col.implicitHeight
        Column { id: col; width: parent.width; spacing: 6 }
        MouseArea {
            id: ma
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: blk.file ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.openNote(blk.file)
        }
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

                            // Mini month: today is ink, study days carry a rose dot
                            Column {
                                id: cal
                                spacing: 4
                                readonly property int year: clock.date.getFullYear()
                                readonly property int month: clock.date.getMonth()
                                readonly property int today: clock.date.getDate()
                                readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
                                readonly property int days: new Date(year, month + 1, 0).getDate()
                                readonly property var active: root.resume.monthActive || []

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

                    // ── The sheet ──────────────────────────────────
                    Item {
                        id: sheet
                        visible: root.resume.ok === true
                        width: root.sheetWidth
                        height: visible ? body.implicitHeight + 56 : 0
                        readonly property var r: root.resume
                        readonly property var src: r.source || null
                        readonly property var trk: r.track || null
                        readonly property var rec: r.recent || []
                        readonly property var q: (r.questions && r.questions.first) || null
                        readonly property var grow: r.revisit || null

                        // soft ink shadow, then paper
                        Rectangle { anchors.fill: bg; anchors.topMargin: 10; anchors.bottomMargin: -10; radius: 24; color: "#0b575279" }
                        Rectangle { anchors.fill: bg; anchors.topMargin: 3;  anchors.bottomMargin: -3;  radius: 23; color: "#10575279" }
                        Rectangle {
                            id: bg
                            anchors.fill: parent
                            radius: 22
                            color: Qt.rgba(1, 0.98, 0.953, 0.93)
                            border.color: root.line
                        }
                        // a rose margin line, like a notebook page
                        Rectangle { x: 18; y: 24; width: 1.5; height: parent.height - 48; color: root.rose; opacity: 0.45 }

                        Column {
                            id: body
                            x: 40; y: 26
                            width: parent.width - 72
                            spacing: 20

                            // header
                            Item {
                                width: parent.width; height: 16
                                Label { text: "where you left off" }
                                Caption {
                                    anchors.right: parent.right
                                    visible: sheet.rec.length > 0
                                    text: sheet.rec.length ? ("last here " + sheet.rec[0].ago).toUpperCase() : ""
                                }
                            }

                            // 1 · the source and the module you're on
                            Block {
                                visible: sheet.src !== null
                                file: sheet.src ? sheet.src.file : ""
                                Caption {
                                    width: parent.width
                                    text: sheet.src ? (["continue", sheet.src.title, sheet.src.section].filter(x => x).join("  ·  ")).toUpperCase() : ""
                                }
                                Text {
                                    width: parent.width
                                    text: sheet.src ? (sheet.src.next || sheet.src.progress || sheet.src.full) : ""
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: root.ink
                                    font.family: root.serif
                                    font.pixelSize: 30
                                    font.weight: Font.Normal
                                    lineHeight: 1.05
                                }
                                Text {
                                    width: parent.width
                                    visible: text.length > 0
                                    text: sheet.src && sheet.src.nextConcepts.length ? sheet.src.nextConcepts.join("  ·  ") : ""
                                    elide: Text.ElideRight
                                    color: root.pine
                                    font.family: root.sans
                                    font.pixelSize: 14
                                }
                            }

                            Rule { visible: sheet.src !== null && (sheet.trk !== null || sheet.rec.length > 0) }

                            // 2 · next on the path | last touched
                            Row {
                                width: parent.width
                                spacing: 28
                                visible: sheet.trk !== null || sheet.rec.length > 0

                                Block {
                                    width: sheet.rec.length ? (parent.width - 28) * 0.55 : parent.width
                                    visible: sheet.trk !== null
                                    file: sheet.trk ? sheet.trk.file : ""
                                    Caption { width: parent.width; text: "NEXT ON THE PATH" }
                                    Text {
                                        width: parent.width
                                        text: sheet.trk ? sheet.trk.next : ""
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        color: root.ink
                                        font.family: root.serif
                                        font.pixelSize: 18
                                    }
                                    // stage progress as small dots
                                    Row {
                                        spacing: 8
                                        Row {
                                            spacing: 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            Repeater {
                                                model: sheet.trk ? sheet.trk.stageTotal : 0
                                                Rectangle {
                                                    required property int index
                                                    width: 7; height: 7; radius: 3.5
                                                    color: index < sheet.trk.stageDone ? root.rose : "transparent"
                                                    border.color: root.muted
                                                    border.width: index < sheet.trk.stageDone ? 0 : 1
                                                }
                                            }
                                        }
                                        Caption {
                                            text: sheet.trk ? ("stage " + sheet.trk.stage).toUpperCase() : ""
                                        }
                                    }
                                }

                                Column {
                                    width: sheet.trk ? (parent.width - 28) * 0.45 : parent.width
                                    visible: sheet.rec.length > 0
                                    spacing: 6
                                    Caption { text: "LAST TOUCHED" }
                                    Repeater {
                                        model: Math.min(3, sheet.rec.length)
                                        Item {
                                            id: recRow
                                            required property int index
                                            readonly property var n: sheet.rec[index]
                                            width: parent.width; height: 22
                                            Text {
                                                width: parent.width - 4
                                                text: (recRow.n.icon ? recRow.n.icon + " " : "") + recRow.n.title
                                                elide: Text.ElideRight
                                                color: recRow.index === 0 ? root.ink : root.subtle
                                                font.family: root.sans
                                                font.pixelSize: 14
                                                font.weight: recRow.index === 0 ? Font.Medium : Font.Normal
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.openNote(recRow.n.file)
                                            }
                                        }
                                    }
                                }
                            }

                            Rule { visible: sheet.q !== null || sheet.grow !== null }

                            // 3 · a question waiting (or a seed to grow)
                            Block {
                                visible: sheet.q !== null || sheet.grow !== null
                                file: sheet.q ? sheet.q.file : (sheet.grow ? sheet.grow.file : "")
                                Item {
                                    width: parent.width; height: 14
                                    Caption { text: sheet.q ? "A QUESTION WAITING" : "A SEED TO GROW" }
                                    Caption {
                                        anchors.right: parent.right
                                        visible: sheet.q !== null && root.resume.questions.count > 1
                                        text: sheet.q ? (root.resume.questions.count - 1) + " MORE OPEN" : ""
                                    }
                                }
                                Text {
                                    width: parent.width
                                    text: sheet.q ? sheet.q.text : (sheet.grow ? sheet.grow.icon + " " + sheet.grow.title + (sheet.grow.hint ? " — " + sheet.grow.hint : "") : "")
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: root.love
                                    font.family: root.serif
                                    font.italic: true
                                    font.pixelSize: 19
                                    lineHeight: 1.1
                                }
                            }
                        }
                    }

                    // Nothing to resume yet (a new vault)
                    Text {
                        visible: root.resume.ok !== true
                        width: root.sheetWidth
                        text: "Your notes will meet you here.\nSuper + K, then C to capture the first thought."
                        color: root.subtle
                        font.family: root.serif
                        font.italic: true
                        font.pixelSize: 20
                        lineHeight: 1.2
                    }
                }
            }
        }
    }
}
