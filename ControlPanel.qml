
import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: panel

    property string section: "home"
    property string wifiOutput: ""
    property string bluetoothOutput: ""
    property string notice: ""
    property string selectedSsid: ""
    property string password: ""
    property string selectedDevice: ""
    property bool busy: false
    property string pendingAction: ""

    implicitWidth: 460
    implicitHeight: 560
    color: "transparent"
    visible: false
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
    }

    Process {
        id: actionProc

        property var args: []

        command: [
            "/home/soma/.config/quickshell/dynamic-island/scripts/utilities.sh",
            ...args
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text

                if (panel.pendingAction === "wifi-list")
                    panel.wifiOutput = output

                if (panel.pendingAction === "bluetooth-list")
                    panel.bluetoothOutput = output
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "")
                    panel.notice = this.text.trim()
            }
        }

        onExited: function(code) {
            panel.busy = false

            if (code === 0) {
                if (panel.notice === "")
                    panel.notice = "Done"
            } else if (panel.notice === "") {
                panel.notice = "Action failed. Check the terminal for details."
            }
        }
    }

    function runAction(argumentsList) {
        if (actionProc.running)
            return

        notice = ""
        busy = true
        pendingAction = argumentsList[0]
        actionProc.args = argumentsList
        actionProc.running = true
    }

    function refreshWifi() {
        runAction(["wifi-list"])
    }

    function refreshBluetooth() {
        runAction(["bluetooth-list"])
    }

    function openSection(name) {
        section = name
        notice = ""

        if (name === "wifi")
            refreshWifi()
        else if (name === "bluetooth")
            refreshBluetooth()
    }

    function connectWifi() {
        if (selectedSsid === "") {
            notice = "Select a network first."
            return
        }

        if (password.length > 0)
            runAction(["wifi-connect", selectedSsid, password])
        else
            runAction(["wifi-connect", selectedSsid])
    }

    function connectBluetooth() {
        if (selectedDevice === "") {
            notice = "Select a device first."
            return
        }

        runAction(["bluetooth-connect", selectedDevice])
    }

    Rectangle {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 44
        }

        width: 420
        height: 490
        radius: 26
        color: "#101010"
        border.color: "#292929"
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // HEADER
            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: parent.width - 50
                    spacing: 3

                    Text {
                        text: "Control Centre"
                        color: "#ffffff"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "SYSTEM CONTROLS"
                        color: "#777777"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: "#242424"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "#ffffff"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: panel.visible = false
                    }
                }
            }

            // NAVIGATION
            Row {
                width: parent.width
                spacing: 7

                Repeater {
                    model: [
                        { label: "Home", value: "home" },
                        { label: "Wi-Fi", value: "wifi" },
                        { label: "Bluetooth", value: "bluetooth" },
                        { label: "Power", value: "power" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: (parent.width - 21) / 4
                        height: 34
                        radius: 12
                        color: panel.section === modelData.value
                               ? "#183b2d" : "#202020"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#ffffff"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.openSection(modelData.value)
                        }
                    }
                }
            }

            // MAIN CONTENT
            Item {
                width: parent.width
                height: 340

                // HOME
                Column {
                    anchors.fill: parent
                    spacing: 10
                    visible: panel.section === "home"

                    Text {
                        text: "Quick settings"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: [
                            {
                                title: "Wi-Fi",
                                subtitle: "View networks and connect",
                                destination: "wifi"
                            },
                            {
                                title: "Bluetooth",
                                subtitle: "Manage nearby devices",
                                destination: "bluetooth"
                            },
                            {
                                title: "Power",
                                subtitle: "Lock, log out or power off",
                                destination: "power"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: parent.width
                            height: 70
                            radius: 16
                            color: "#1b1b1b"
                            border.color: "#292929"

                            Column {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 14
                                }
                                spacing: 5

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: modelData.subtitle
                                    color: "#888888"
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 14
                                }
                                text: "›"
                                color: "#888888"
                                font.pixelSize: 24
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.openSection(modelData.destination)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Tip: use the S pill to open or close this panel."
                        color: "#777777"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 10
                    }
                }

                // WI-FI
                Column {
                    anchors.fill: parent
                    spacing: 9
                    visible: panel.section === "wifi"

                    Text {
                        text: "Available networks"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        width: parent.width
                        height: 170
                        radius: 13
                        color: "#191919"
                        border.color: "#292929"
                        clip: true

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentWidth: width
                            contentHeight: networkColumn.implicitHeight
                            clip: true

                            Column {
                                id: networkColumn
                                width: parent.width
                                spacing: 5

                                Repeater {
                                    model: panel.wifiOutput.trim() === ""
                                           ? [] : panel.wifiOutput.trim().split("\n")

                                    delegate: Rectangle {
                                        required property string modelData

                                        width: networkColumn.width
                                        height: 34
                                        radius: 8
                                        color: panel.selectedSsid === modelData.split("\t")[1]
                                               ? "#183b2d" : "#242424"

                                        Text {
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: 9
                                                rightMargin: 5
                                            }

                                            text: modelData
                                            color: "#ffffff"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                let parts = modelData.split("\t")
                                                panel.selectedSsid =
                                                    parts.length > 1
                                                    ? parts[1] : modelData
                                                panel.notice = "Selected: " + panel.selectedSsid
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: panel.selectedSsid === ""
                              ? "Select a network above"
                              : "Selected: " + panel.selectedSsid
                        color: "#aaaaaa"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 11
                        color: "#191919"
                        border.color: "#303030"

                        TextInput {
                            anchors {
                                fill: parent
                                leftMargin: 11
                                rightMargin: 11
                            }

                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"
                            font.pixelSize: 12
                            echoMode: TextInput.Password
                            clip: true
                            text: panel.password
                            onTextChanged: panel.password = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Wi-Fi password (if required)"
                                color: "#666666"
                                font.pixelSize: 11
                                visible: parent.text.length === 0
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        Rectangle {
                            width: 112
                            height: 36
                            radius: 11
                            color: "#242424"

                            Text {
                                anchors.centerIn: parent
                                text: "Refresh"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.refreshWifi()
                            }
                        }

                        Rectangle {
                            width: 150
                            height: 36
                            radius: 11
                            color: "#183b2d"

                            Text {
                                anchors.centerIn: parent
                                text: panel.busy ? "Working…" : "Connect"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !panel.busy
                                onClicked: panel.connectWifi()
                            }
                        }
                    }
                }

                // BLUETOOTH
                Column {
                    anchors.fill: parent
                    spacing: 9
                    visible: panel.section === "bluetooth"

                    Text {
                        text: "Bluetooth devices"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        width: parent.width
                        height: 200
                        radius: 13
                        color: "#191919"
                        border.color: "#292929"
                        clip: true

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentWidth: width
                            contentHeight: deviceColumn.implicitHeight
                            clip: true

                            Column {
                                id: deviceColumn
                                width: parent.width
                                spacing: 5

                                Repeater {
                                    model: panel.bluetoothOutput.trim() === ""
                                           ? [] : panel.bluetoothOutput.trim().split("\n")

                                    delegate: Rectangle {
                                        required property string modelData

                                        width: deviceColumn.width
                                        height: 38
                                        radius: 8
                                        color: panel.selectedDevice !== ""
                                               && modelData.indexOf(panel.selectedDevice) >= 0
                                               ? "#183b2d" : "#242424"

                                        Text {
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: 9
                                                rightMargin: 5
                                            }

                                            text: modelData
                                            color: "#ffffff"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                let parts = modelData.trim().split(/\s+/)
                                                panel.selectedDevice =
                                                    parts.length > 1 ? parts[1] : ""
                                                panel.notice =
                                                    panel.selectedDevice === ""
                                                    ? "Could not read device address."
                                                    : "Selected: " + panel.selectedDevice
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        Rectangle {
                            width: 100
                            height: 36
                            radius: 11
                            color: "#242424"

                            Text {
                                anchors.centerIn: parent
                                text: "Refresh"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.refreshBluetooth()
                            }
                        }

                        Rectangle {
                            width: 100
                            height: 36
                            radius: 11
                            color: "#242424"

                            Text {
                                anchors.centerIn: parent
                                text: "Scan"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.runAction(["bluetooth-scan"])
                            }
                        }

                        Rectangle {
                            width: 120
                            height: 36
                            radius: 11
                            color: "#183b2d"

                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.connectBluetooth()
                            }
                        }
                    }
                }

                // POWER
                Column {
                    anchors.fill: parent
                    spacing: 10
                    visible: panel.section === "power"

                    Text {
                        text: "Power options"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: [
                            {
                                title: "Lock screen",
                                action: "lock",
                                subtitle: "Lock your current session"
                            },
                            {
                                title: "Log out",
                                action: "logout",
                                subtitle: "End your Hyprland session"
                            },
                            {
                                title: "Restart",
                                action: "restart",
                                subtitle: "Restart this computer"
                            },
                            {
                                title: "Shut down",
                                action: "shutdown",
                                subtitle: "Power off this computer"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: parent.width
                            height: 62
                            radius: 14
                            color: "#1b1b1b"
                            border.color: "#292929"

                            Column {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 13
                                }
                                spacing: 4

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: modelData.subtitle
                                    color: "#888888"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.action === "lock") {
                                        panel.runAction(["lock"])
                                    } else {
                                        panel.pendingAction = modelData.action
                                        panel.notice =
                                            "Confirm " + modelData.title.toLowerCase() + " below."
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        spacing: 8
                        visible: ["logout", "restart", "shutdown"].indexOf(panel.pendingAction) >= 0

                        Rectangle {
                            width: 140
                            height: 36
                            radius: 11
                            color: "#572522"

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm " + panel.pendingAction
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let action = panel.pendingAction
                                    panel.pendingAction = ""
                                    panel.visible = false
                                    panel.runAction([action])
                                }
                            }
                        }

                        Rectangle {
                            width: 100
                            height: 36
                            radius: 11
                            color: "#242424"

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: "#ffffff"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    panel.pendingAction = ""
                                    panel.notice = ""
                                }
                            }
                        }
                    }
                }
            }

            // STATUS MESSAGE
            Text {
                width: parent.width
                height: 30
                text: panel.busy ? "Working…" : panel.notice
                color: panel.notice.indexOf("failed") >= 0
                       ? "#ff6259" : "#00a86b"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
            }
        }
    }
}
