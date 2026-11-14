// Knowledge Bank: desktop widgets (Quickshell 0.3+)
// Drawn on the wallpaper, below windows. Launched by hyprland.lua: `quickshell -c kb`.
//
//   Good morning.
//   09:41
//   SATURDAY · 14 NOVEMBER · WEEK 46
//   ┌ weather ┐ ┌ notebook ┐ ┌ calendar ┐
//   └─────────┘ └──────────┘ └──────────┘
//   ┌ highlight from your vault ────────┐
//   └───────────────────────────────────┘

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ── Palette: paper & ink (Rosé Pine Dawn) ─────────────────────
    readonly property color paper: "#faf4ed"
    readonly property color card:  "#fffaf3"
    readonly property color fold:  "#f2e9e1"
    readonly property color line:  "#dfdad9"
    readonly property color muted: "#9893a5"
    readonly property color subtle: "#797593"
    readonly property color ink:   "#575279"
    readonly property color rose:  "#d7827e"
    readonly property color gold:  "#ea9d34"

    readonly property string serif: "Fraunces"
    readonly property string mono:  "IBM Plex Mono"
    readonly property string sans:  "IBM Plex Sans"
    readonly property string icons: "JetBrainsMono Nerd Font"

    readonly property int cell: 230
    readonly property int gap: 16
    readonly property string bin: "$HOME/.local/bin/"

    // ── Data ──────────────────────────────────────────────────────
    property var weather: ({ ok: false })
    property var notes: ({ inbox: 0, words: 0, streak: 0, notes: 0 })
    property string quote: ""

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
        id: notesProc
        command: ["sh", "-c", "exec " + root.bin + "kb-stats --raw"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.notes = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 60 * 1000; running: true; repeat: true; onTriggered: root.run(notesProc) }

    Process {
        id: quoteProc
        command: ["sh", "-c", "exec " + root.bin + "kb-quote --plain"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.quote = text.trim() }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.run(quoteProc) }

    function open(cmd) { Quickshell.execDetached(["sh", "-c", root.bin + cmd]) }

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
        spacing: 8
        Rectangle { width: 6; height: 6; radius: 3; color: root.rose; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: parent.text.toUpperCase()
            color: root.subtle
            font.family: root.mono
            font.pixelSize: 11
            font.letterSpacing: 2.4
        }
    }

    // A paper card with a soft ink shadow.
    component Card: Item {
        id: cardRoot
        default property alias content: inner.data
        property string title
        signal clicked()
        width: root.cell
        height: root.cell

        // soft ink shadow: two offset layers under the card
        Rectangle { anchors.fill: bg; anchors.topMargin: 10; anchors.bottomMargin: -10; radius: 24; color: "#0d575279" }
        Rectangle { anchors.fill: bg; anchors.topMargin: 4;  anchors.bottomMargin: -4;  radius: 23; color: "#12575279" }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 22
            color: Qt.rgba(1, 0.98, 0.953, 0.94)
            border.color: root.line
            border.width: 1
        }
        Label { text: cardRoot.title; x: 22; y: 20 }
        Item { id: inner; anchors.fill: parent; anchors.margins: 22; anchors.topMargin: 48 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cardRoot.clicked() }
    }

    // ── One widget layer per screen ───────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            // Shrink everything on small screens (designed for ~1080p and up)
            readonly property real s: Math.min(1, (modelData.height - 130) / 780)

            anchors { top: true; left: true }
            margins { top: Math.round(92 * s); left: Math.round(72 * s) }
            implicitWidth: Math.ceil((root.cell * 3 + root.gap * 2 + 24) * s)
            implicitHeight: Math.ceil(780 * s)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "kb-widgets"

            Column {
                spacing: 0
                scale: win.s
                transformOrigin: Item.TopLeft

                // Greeting
                Text {
                    text: root.greeting(clock.date.getHours())
                    color: root.subtle
                    font.family: root.serif
                    font.italic: true
                    font.pixelSize: 30
                }

                // Clock: HH:MM in a big serif, the colon is the one bit of colour
                Row {
                    spacing: 4
                    Text {
                        text: Qt.formatTime(clock.date, "HH")
                        color: root.ink
                        font.family: root.serif
                        font.pixelSize: 168
                        font.weight: Font.Light
                    }
                    Text {
                        text: ":"
                        color: root.rose
                        opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        font.family: root.serif
                        font.pixelSize: 168
                        font.weight: Font.Light
                    }
                    Text {
                        text: Qt.formatTime(clock.date, "mm")
                        color: root.ink
                        font.family: root.serif
                        font.pixelSize: 168
                        font.weight: Font.Light
                    }
                }

                // Date line
                Text {
                    text: (Qt.locale("en_US").toString(clock.date, "dddd · d MMMM") + " · week " + root.isoWeek(clock.date)).toUpperCase()
                    color: root.subtle
                    font.family: root.mono
                    font.pixelSize: 14
                    font.letterSpacing: 3.2
                    bottomPadding: 34
                }

                // ── Row of cards ─────────────────────────────────
                Row {
                    spacing: root.gap
                    bottomPadding: root.gap

                    // Weather
                    Card {
                        title: root.weather.ok ? root.weather.place : "weather"
                        onClicked: root.run(weatherProc)

                        Column {
                            anchors.fill: parent
                            spacing: 2
                            visible: root.weather.ok
                            Row {
                                spacing: 12
                                Text {
                                    text: root.weather.icon || ""
                                    color: root.gold
                                    font.family: root.icons
                                    font.pixelSize: 44
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: (root.weather.temp ?? "–") + "°"
                                    color: root.ink
                                    font.family: root.serif
                                    font.pixelSize: 62
                                    font.weight: Font.Light
                                }
                            }
                            Text {
                                width: parent.width
                                text: (root.weather.desc || "").toUpperCase()
                                elide: Text.ElideRight
                                color: root.subtle
                                font.family: root.mono
                                font.pixelSize: 11
                                font.letterSpacing: 1.6
                            }
                            Item { width: 1; height: 10 }
                            Text {
                                text: "H " + (root.weather.high ?? "–") + "°   L " + (root.weather.low ?? "–") + "°   feels " + (root.weather.feels ?? "–") + "°"
                                color: root.subtle
                                font.family: root.mono
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            visible: !root.weather.ok
                            anchors.fill: parent
                            wrapMode: Text.WordWrap
                            text: "No weather yet.\nClick to retry."
                            color: root.subtle
                            font.family: root.sans
                            font.pixelSize: 13
                        }
                    }

                    // Notebook
                    Card {
                        title: "notebook"
                        onClicked: root.open("kb-daily")

                        Column {
                            anchors.fill: parent
                            spacing: 4
                            Row {
                                spacing: 10
                                Text {
                                    text: root.notes.inbox ?? 0
                                    color: root.ink
                                    font.family: root.serif
                                    font.pixelSize: 62
                                    font.weight: Font.Light
                                }
                                Text {
                                    text: "in\ninbox"
                                    color: root.subtle
                                    font.family: root.serif
                                    font.italic: true
                                    font.pixelSize: 15
                                    lineHeight: 0.9
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 14
                                }
                            }
                            Repeater {
                                model: 3
                                Item {
                                    id: stat
                                    required property int index
                                    readonly property var row: [
                                        ["words today", root.notes.words ?? 0],
                                        ["streak",      (root.notes.streak ?? 0) + " d"],
                                        ["notes",       root.notes.notes ?? 0]
                                    ][index]
                                    width: 186
                                    height: 20
                                    Text {
                                        text: stat.row[0].toUpperCase()
                                        color: root.subtle
                                        font.family: root.mono
                                        font.pixelSize: 11
                                        font.letterSpacing: 1.4
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: stat.row[1]
                                        color: root.ink
                                        font.family: root.mono
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }

                    // Calendar
                    Card {
                        id: cal
                        title: Qt.locale("en_US").toString(clock.date, "MMMM yyyy")
                        readonly property int year: clock.date.getFullYear()
                        readonly property int month: clock.date.getMonth()
                        readonly property int today: clock.date.getDate()
                        // Monday-first offset of the 1st and number of days
                        readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
                        readonly property int days: new Date(year, month + 1, 0).getDate()

                        Grid {
                            anchors.fill: parent
                            columns: 7
                            rowSpacing: 1
                            columnSpacing: 0
                            Repeater {
                                model: 7
                                Text {
                                    required property int index
                                    width: 26.5; height: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "MTWTFSS"[index]
                                    color: "#b4637a"
                                    font.family: root.mono
                                    font.pixelSize: 10
                                }
                            }
                            Repeater {
                                model: cal.lead + cal.days
                                Item {
                                    required property int index
                                    readonly property int day: index - cal.lead + 1
                                    width: 26.5; height: 21
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 21; height: 21; radius: 10.5
                                        color: root.ink
                                        visible: parent.day === cal.today
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.day > 0 ? parent.day : ""
                                        color: parent.day === cal.today ? root.card : root.ink
                                        font.family: root.mono
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }

                // Highlight from the vault
                Card {
                    title: "from your notes"
                    width: root.cell * 3 + root.gap * 2
                    height: 132
                    onClicked: root.run(quoteProc)

                    Text {
                        anchors.fill: parent
                        text: root.quote.length ? "“" + root.quote + "”" : "Mark a line with > in any note and it will surface here."
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: root.ink
                        font.family: root.serif
                        font.italic: true
                        font.pixelSize: 21
                        lineHeight: 1.15
                    }
                }
            }
        }
    }
}
