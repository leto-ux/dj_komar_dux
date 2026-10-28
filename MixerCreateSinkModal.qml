import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool isOpen: false
    signal sinkCreated(string name)
    signal closeRequested

    visible: isOpen
    width: parent ? parent.width : 400
    height: contentCol.implicitHeight + 24
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh || "#2a2a2a"
    border.width: 1
    border.color: Theme.primary

    Process {
        id: createSinkProcess
        command: []

        onExited: (exitCode, exitStatus) => {
            creatingSpinner.running = false;
            if (exitCode === 0) {
                const createdName = sinkNameInput.text.trim();
                sinkNameInput.text = "";
                root.isOpen = false;
                root.sinkCreated(createdName);
            } else {
                statusText.text = "Failed to create virtual sink (exit code " + exitCode + ")";
            }
        }
    }

    Column {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Title Row
        Item {
            width: parent.width
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                DankIcon {
                    name: "alt_route"
                    size: 18
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "Create Virtual Audio Sink"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                width: 24
                height: 24
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()

                DankIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 16
                    color: Theme.surfaceVariantText
                }
            }
        }

        StyledText {
            width: parent.width
            text: "Create an independent virtual PipeWire/PulseAudio sink for routing audio (e.g. Discord, Music, Games)."
            font.pixelSize: 10
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        // Input field
        Rectangle {
            width: parent.width
            height: 36
            radius: 6
            color: Theme.surfaceContainerHighest || "#1e1e1e"
            border.width: sinkNameInput.activeFocus ? 2 : 1
            border.color: sinkNameInput.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.4)

            TextInput {
                id: sinkNameInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 12
                color: Theme.surfaceText
                clip: true

                StyledText {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Enter sink name (e.g., Discord_Audio, Music_Stream)..."
                    font.pixelSize: 12
                    color: Theme.withAlpha(Theme.surfaceVariantText, 0.6)
                    visible: !sinkNameInput.text && !sinkNameInput.activeFocus
                }

                Keys.onReturnPressed: createButton.createSink()
            }
        }

        // Quick Preset Suggestions
        Row {
            spacing: 6
            width: parent.width

            Repeater {
                model: ["Voice", "Music", "Game", "Aux", "Stream"]

                Rectangle {
                    width: presetText.implicitWidth + 12
                    height: 22
                    radius: 11
                    color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)

                    StyledText {
                        id: presetText
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 10
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sinkNameInput.text = modelData;
                            sinkNameInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Action Buttons Row
        Item {
            width: parent.width
            height: 32

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

            // Cancel
            Rectangle {
                width: 70
                height: 30
                radius: 6
                color: Theme.withAlpha(Theme.surfaceVariantText, 0.2)

                StyledText {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 11
                    color: Theme.surfaceText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }

            // Create button
            Rectangle {
                id: createButton
                width: 80
                height: 30
                radius: 6
                color: sinkNameInput.text.trim().length > 0 ? Theme.primary : Theme.withAlpha(Theme.primary, 0.4)

                function createSink() {
                    const rawName = sinkNameInput.text.trim();
                    if (!rawName) return;
                    const safeName = rawName.replace(/[^a-zA-Z0-9_-]/g, "_");
                    creatingSpinner.running = true;
                    statusText.text = "Creating " + safeName + "...";
                    createSinkProcess.command = [
                        "pactl",
                        "load-module",
                        "module-null-sink",
                        "sink_name=" + safeName,
                        "sink_properties=device.description=" + rawName
                    ];
                    createSinkProcess.running = true;
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    DankIcon {
                        name: "add"
                        size: 14
                        color: Theme.onPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Create"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.onPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: sinkNameInput.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (sinkNameInput.text.trim().length > 0) {
                            createButton.createSink();
                        }
                    }
                }
            }
        }

        // Status text
        StyledText {
            id: statusText
            width: parent.width
            text: ""
            font.pixelSize: 10
            color: Theme.error
            visible: text.length > 0
        }

        DankSpinner {
            id: creatingSpinner
            anchors.horizontalCenter: parent.horizontalCenter
            visible: running
            running: false
        }
    }
}
