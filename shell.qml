
import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitWidth: 220
    implicitHeight: 90
    margins.top: 3

    color: "transparent"
    exclusiveZone: 42
    

    property bool expanded: false
    property bool utilityExpanded: false

    property string mediaTitle: "Nothing playing"
    property string mediaArtist: ""
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: ""

    property string batteryPercent: "N/A"
    property string wifiStatus: "disabled"
    property string bluetoothStatus: "no"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ── MEDIA STATUS ──────────────────────────

    Process {
        id: mediaProc

        command: [
            "/home/soma/.config/quickshell/dynamic-island/scripts/media.sh"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")

                root.mediaTitle = lines[0] || "Nothing playing"
                root.mediaArtist = lines[1] || ""
                root.mediaStatus = lines[2] || "Stopped"
                root.mediaArtUrl = lines[3] || ""
            }
        }
    }

    Process {
        id: controlProc

        property string action: "play-pause"

        command: ["playerctl", action]

        onExited: refreshTimer.restart()
    }

    // ── UTILITY STATUS ────────────────────────

    Process {
        id: utilityStatusProc

        command: [
            "/home/soma/.config/quickshell/dynamic-island/scripts/utilities.sh",
            "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")

                root.batteryPercent = lines[0] || "N/A"
                root.wifiStatus = lines[1] || "disabled"
                root.bluetoothStatus = lines[2] || "no"
            }
        }
    }

    Process {
        id: utilityActionProc

        property string action: "status"

        command: [
            "/home/soma/.config/quickshell/dynamic-island/scripts/utilities.sh",
            action
        ]

        onExited: utilityRefresh.restart()
    }

    Timer {
        id: refreshTimer

        interval: 2000
        running: true
        repeat: true

        onTriggered: {
            if (!mediaProc.running)
                mediaProc.running = true

            if (!utilityStatusProc.running)
                utilityStatusProc.running = true
        }
    }

    Timer {
        id: utilityRefresh

        interval: 700
        repeat: false

        onTriggered: {
            if (!utilityStatusProc.running)
                utilityStatusProc.running = true
        }
    }

    Component.onCompleted: {
        if (!mediaProc.running)
            mediaProc.running = true

        if (!utilityStatusProc.running)
            utilityStatusProc.running = true
    }

    // ── CENTER CLOCK ──────────────────────────

    Rectangle {
        id: pill

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        width: root.expanded ? 100 : 85
        height: root.expanded ? 76 : 32
        radius: root.expanded ? 24 : height / 2

        color: "#000000"
        border.color: "#151515"
        border.width: 1

        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation { duration: 180 }
        }

        Column {
            anchors.centerIn: parent
            spacing: root.expanded ? 5 : 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: "#ffffff"
                font.pixelSize: root.expanded ? 25 : 14
                font.weight: Font.DemiBold

                Behavior on font.pixelSize {
                    NumberAnimation { duration: 180 }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                visible: root.expanded

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd").toLowerCase()
                    color: "#00a86b"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "dd")
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.expanded = true
            onExited: root.expanded = false
        }
    }

    // ── LEFT UTILITY PILL ─────────────────────

    Rectangle {
        id: utilityPill

        anchors {
            right: pill.left
            rightMargin: 8
            top: pill.top
        }

        width: root.utilityExpanded ? 290 : 32
        height: root.utilityExpanded ? 76 : 32
        radius: root.utilityExpanded ? 24 : 16

        color: "#000000"
        border.color: "#202020"
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation { duration: 180 }
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            hoverEnabled: true

            onEntered: root.utilityExpanded = true
            onExited: root.utilityExpanded = false
        }

        Text {
            anchors.centerIn: parent
            visible: !root.utilityExpanded

            text: "S"
            color: "#ffffff"
            font.pixelSize: 14
            font.weight: Font.Bold
            z: 1
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            visible: root.utilityExpanded
            z: 1

            // Wi-Fi
            Rectangle {
                width: 48
                height: 44
                radius: 15

                color: root.wifiStatus === "enabled"
                       ? "#183b2d" : "#191919"

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Image {
                    anchors.centerIn: parent
                    width: 21
                    height: 21

                    source: "file:///home/soma/.config/quickshell/dynamic-island/icons/wifi.svg"
                    opacity: root.wifiStatus === "enabled" ? 1.0 : 0.4
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (!utilityActionProc.running) {
                            utilityActionProc.action = "wifi"
                            utilityActionProc.running = true
                        }
                    }
                }
            }

            // Bluetooth
            Rectangle {
                width: 48
                height: 44
                radius: 15

                color: root.bluetoothStatus === "yes"
                       ? "#183b2d" : "#191919"

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Image {
                    anchors.centerIn: parent
                    width: 21
                    height: 21

                    source: "file:///home/soma/.config/quickshell/dynamic-island/icons/bluetooth.svg"
                    opacity: root.bluetoothStatus === "yes" ? 1.0 : 0.4
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (!utilityActionProc.running) {
                            utilityActionProc.action = "bluetooth"
                            utilityActionProc.running = true
                        }
                    }
                }
            }

            // Battery
            Row {
                height: 44
                spacing: 7

                Rectangle {
                    width: 44
                    height: 44
                    radius: 15
                    color: "#191919"

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22

                        source: "file:///home/soma/.config/quickshell/dynamic-island/icons/battery.svg"
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: root.batteryPercent === "N/A"
                              ? "--%" : root.batteryPercent + "%"

                        color: "#ffffff"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        width: 43
                        height: 3
                        radius: 2
                        color: "#292929"

                        Rectangle {
                            width: {
                                let value = parseInt(root.batteryPercent)
                                return isNaN(value)
                                    ? 0
                                    : parent.width * Math.max(0, Math.min(100, value)) / 100
                            }

                            height: parent.height
                            radius: parent.radius

                            color: {
                                let value = parseInt(root.batteryPercent)
                                if (isNaN(value))
                                    return "#777777"
                                if (value <= 20)
                                    return "#ff453a"
                                return "#00a86b"
                            }

                            Behavior on width {
                                NumberAnimation { duration: 250 }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── RIGHT MUSIC PILL ──────────────────────

    Rectangle {
        id: musicPill

        anchors {
            left: pill.right
            leftMargin: 8
            top: pill.top
        }

        property bool musicExpanded: false

        width: musicExpanded ? 270 : 32
        height: musicExpanded ? 76 : 32
        radius: musicExpanded ? 24 : 16

        color: "#000000"
        border.color: "#202020"
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation { duration: 180 }
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            hoverEnabled: true

            onEntered: musicPill.musicExpanded = true
            onExited: musicPill.musicExpanded = false
        }

        // COLLAPSED: GENERIC MUSIC ICON

        Item {
            id: collapsedArtwork

            width: 24
            height: 24

            anchors.centerIn: parent
            visible: !musicPill.musicExpanded
            z: 1

            Text {
                anchors.centerIn: parent

                text: "♫"
                color: "#ffffff"
                font.pixelSize: 21
                font.weight: Font.DemiBold
            }
        }

        // EXPANDED: SQUARE ALBUM ART AND TRACK INFO

        Row {
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }

            spacing: 10
            visible: musicPill.musicExpanded
            z: 1

            Rectangle {
                id: expandedArtwork

                width: 48
                height: 48
                radius: 12

                color: "#191919"
                clip: true

                Image {
                    anchors.fill: parent

                    source: root.mediaArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: root.mediaArtUrl !== ""
                }

                Text {
                    anchors.centerIn: parent

                    visible: root.mediaArtUrl === ""
                    text: "♫"
                    color: "#ffffff"
                    font.pixelSize: 24
                }
            }

            Column {
                width: 112
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Text {
                    width: parent.width

                    text: root.mediaTitle
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold

                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    width: parent.width

                    text: root.mediaArtist
                    color: "#999999"
                    font.pixelSize: 10

                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    text: root.mediaStatus === "Playing"
                          ? "NOW PLAYING"
                          : root.mediaStatus.toUpperCase()

                    color: root.mediaStatus === "Playing"
                           ? "#00a86b" : "#777777"

                    font.pixelSize: 8
                    font.weight: Font.Bold
                }
            }
        }

        // PLAYBACK CONTROLS

        Row {
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 7
            visible: musicPill.musicExpanded
            z: 2

            Repeater {
                model: [
                    { symbol: "◂", action: "previous" },
                    {
                        symbol: root.mediaStatus === "Playing" ? "Ⅱ" : "▶",
                        action: "play-pause"
                    },
                    { symbol: "▸", action: "next" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: 23
                    height: 32
                    radius: 9
                    color: "#191919"

                    Text {
                        anchors.centerIn: parent

                        text: modelData.symbol
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (!controlProc.running) {
                                controlProc.action = modelData.action
                                controlProc.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}
