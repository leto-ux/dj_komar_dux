import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import "MixerUtils.js" as MixerUtils

Rectangle {
    id: root

    property var node: AudioService.sink
    property real maxVolume: 1.0
    property bool showVuMeter: true
    property bool activePopout: true

    readonly property var audio: (node && node.audio) ? node.audio : null
    readonly property real currentVol: audio ? audio.volume : 0.0
    readonly property bool isMuted: audio ? audio.muted : false
    readonly property string deviceName: AudioService.displayName(node) || "Master Output"

    width: 82
    implicitWidth: 82
    implicitHeight: 330
    radius: Theme.cornerRadius
    color: Theme.withAlpha(Theme.primaryContainer || "#332211", 0.5)
    border.width: 2
    border.color: Theme.primary

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Top Header: MASTER Badge
        Item {
            width: parent.width
            height: 20

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 4
                height: 18
                radius: 4
                color: Theme.primary

                StyledText {
                    anchors.centerIn: parent
                    text: "MASTER"
                    font.pixelSize: 9
                    font.weight: Font.Black
                    color: Theme.onPrimary
                }
            }
        }

        // Master Device Icon & Name
        Item {
            width: parent.width
            height: 38

            Rectangle {
                id: masterIconBg
                width: 26
                height: 26
                radius: 13
                color: Theme.withAlpha(Theme.primary, 0.25)
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: AudioService.volumeIconName(node)
                    size: 16
                    color: Theme.primary
                }
            }

            StyledText {
                anchors.top: masterIconBg.bottom
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.right: parent.right
                text: root.deviceName
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.primary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Master Fader (VU Meter + Slider)
        Item {
            width: parent.width
            height: 170

            Row {
                anchors.fill: parent
                spacing: 6

                // Master Peak Meter
                MixerVuMeter {
                    visible: root.showVuMeter
                    node: root.node
                    enabled: root.activePopout && root.showVuMeter
                    isVertical: true
                    barThickness: 6
                    height: parent.height
                }

                // Fader Container
                Item {
                    id: faderContainer
                    width: root.showVuMeter ? (parent.width - 12) : parent.width
                    height: parent.height

                    // Track slot
                    Rectangle {
                        id: faderTrack
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 10
                        height: parent.height
                        radius: 5
                        color: Theme.withAlpha(Theme.surfaceContainerHighest || "#111", 0.95)
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.primary, 0.4)

                        // Filled active volume line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 6
                            radius: 3
                            height: Math.max(0, Math.min(parent.height, parent.height * (root.currentVol / root.maxVolume)))
                            color: root.isMuted ? (Theme.error || "#EF5350") : Theme.primary
                        }

                        // Unity tick mark
                        Rectangle {
                            visible: root.maxVolume > 1.05
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * (1.0 - (1.0 / root.maxVolume))
                            width: 14
                            height: 1.5
                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.7)
                        }
                    }

                    // Master Fader Knob
                    Rectangle {
                        id: faderKnob
                        width: Math.min(faderContainer.width - 2, 42)
                        height: 24
                        radius: 5
                        anchors.horizontalCenter: faderTrack.horizontalCenter
                        y: Math.max(0, Math.min(faderTrack.height - height,
                            (faderTrack.height - height) * (1.0 - (root.currentVol / root.maxVolume))))

                        color: faderMouse.pressed ? Theme.primary : Theme.surfaceContainerHighest
                        border.width: 2
                        border.color: Theme.primary

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Rectangle { width: 16; height: 1.5; radius: 1; color: Theme.primary }
                            Rectangle { width: 16; height: 1.5; radius: 1; color: Theme.onPrimaryContainer || Theme.surfaceText }
                            Rectangle { width: 16; height: 1.5; radius: 1; color: Theme.onPrimaryContainer || Theme.surfaceText }
                        }
                    }

                    MouseArea {
                        id: faderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor

                        function updateVolumeFromY(mouseY) {
                            if (!root.audio) return;
                            const usableHeight = faderTrack.height - faderKnob.height;
                            const clampedY = Math.max(0, Math.min(usableHeight, mouseY - faderKnob.height / 2));
                            const fraction = 1.0 - (clampedY / usableHeight);
                            const newVol = Math.round(fraction * root.maxVolume * 100) / 100;
                            SessionData.suppressOSDTemporarily();
                            root.audio.volume = newVol;
                            if (newVol > 0 && root.audio.muted) {
                                root.audio.muted = false;
                            }
                        }

                        onPressed: mouse => updateVolumeFromY(mouse.y)
                        onPositionChanged: mouse => {
                            if (pressed) updateVolumeFromY(mouse.y);
                        }

                        onWheel: wheel => {
                            if (!root.audio) return;
                            const delta = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                            const newVol = Math.max(0.0, Math.min(root.maxVolume, Math.round((root.audio.volume + delta) * 100) / 100));
                            SessionData.suppressOSDTemporarily();
                            root.audio.volume = newVol;
                            if (newVol > 0 && root.audio.muted) {
                                root.audio.muted = false;
                            }
                        }

                        onDoubleClicked: {
                            if (!root.audio) return;
                            SessionData.suppressOSDTemporarily();
                            root.audio.volume = 1.0;
                            if (root.audio.muted) root.audio.muted = false;
                        }
                    }
                }
            }
        }

        // Numeric Readout
        Item {
            width: parent.width
            height: 22

            Column {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MixerUtils.volumeToPercent(root.currentVol) + "%"
                    font.pixelSize: 11
                    font.weight: Font.Black
                    color: root.isMuted ? Theme.error : Theme.primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MixerUtils.volumeToDb(root.currentVol)
                    font.pixelSize: 8
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Master Mute Button
        Rectangle {
            id: masterMuteBtn
            width: parent.width
            height: 26
            radius: 4
            color: root.isMuted ? (Theme.error || "#D32F2F") : (muteMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
            border.width: 1
            border.color: root.isMuted ? Theme.error : Theme.withAlpha(Theme.primary, 0.4)

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (!root.audio) return;
                    SessionData.suppressOSDTemporarily();
                    root.audio.muted = !root.audio.muted;
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 4

                DankIcon {
                    name: root.isMuted ? "volume_off" : "volume_up"
                    size: 13
                    color: root.isMuted ? Theme.onError : Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "MUTE"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.isMuted ? Theme.onError : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
