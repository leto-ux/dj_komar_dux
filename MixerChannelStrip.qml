import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import "MixerUtils.js" as MixerUtils

Rectangle {
    id: root

    required property var node
    property bool isPinned: false
    property bool isDefaultSink: false
    property bool isMasterSink: false
    property real maxVolume: 1.0
    property bool showVuMeter: true
    property var customAliases: ({})
    property bool activePopout: true

    signal pinToggled(string nodeName)
    signal setDefaultRequested(var targetNode)
    signal setMasterRequested(string nodeName)

    readonly property var audio: (node && node.audio) ? node.audio : null
    readonly property real currentVol: audio ? audio.volume : 0.0
    readonly property bool isMuted: audio ? audio.muted : false
    readonly property string cleanTitle: MixerUtils.getCleanName(node, customAliases)
    readonly property color accentColor: MixerUtils.getChannelAccent(node, Theme)
    readonly property bool isVirtual: MixerUtils.isVirtualSink(node)

    width: 76
    implicitWidth: 76
    implicitHeight: 330
    radius: Theme.cornerRadius
    color: Theme.withAlpha(Theme.surfaceContainer || "#222", 0.75)
    border.width: isDefaultSink ? 2 : 1
    border.color: isDefaultSink ? Theme.primary : Theme.withAlpha(Theme.outline || "#555", 0.25)

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Top bar: Pin button & Type badge
        Item {
            width: parent.width
            height: 20

            // Virtual Sink indicator pill
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: isVirtual ? 26 : 20
                height: 16
                radius: 4
                color: isVirtual ? Theme.withAlpha(root.accentColor, 0.2) : Theme.withAlpha(Theme.surfaceVariantText, 0.15)

                StyledText {
                    anchors.centerIn: parent
                    text: isVirtual ? "VIRT" : "HW"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: isVirtual ? root.accentColor : Theme.surfaceVariantText
                }
            }

            // Master Fader selection button
            MouseArea {
                id: masterArea
                width: 18
                height: 18
                anchors.right: pinArea.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (node && node.name) {
                        root.setMasterRequested(node.name);
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "album"
                    size: 13
                    color: root.isMasterSink ? Theme.primary : (masterArea.containsMouse ? Theme.surfaceText : Theme.surfaceVariantText)
                }
            }

            // Pin / Favorite button
            MouseArea {
                id: pinArea
                width: 18
                height: 18
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (node && node.name) {
                        root.pinToggled(node.name);
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: root.isPinned ? "star" : "star_outline"
                    size: 14
                    color: root.isPinned ? (Theme.primary || "#FFB300") : (pinArea.containsMouse ? Theme.surfaceText : Theme.surfaceVariantText)
                }
            }
        }

        // Channel Icon & Title
        Item {
            width: parent.width
            height: 38

            Rectangle {
                id: iconBg
                width: 26
                height: 26
                radius: 13
                color: Theme.withAlpha(root.accentColor, 0.2)
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: MixerUtils.getChannelIcon(node)
                    size: 15
                    color: root.accentColor
                }
            }

            StyledText {
                id: titleText
                anchors.top: iconBg.bottom
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.right: parent.right
                text: root.cleanTitle
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Main Fader Section (VU meter + Vertical Slider)
        Item {
            width: parent.width
            height: 170

            Row {
                anchors.fill: parent
                spacing: 6

                // VU Peak Meter
                MixerVuMeter {
                    id: vuMeter
                    visible: root.showVuMeter
                    node: root.node
                    enabled: root.activePopout && root.showVuMeter
                    isVertical: true
                    barThickness: 5
                    height: parent.height
                }

                // Vertical Fader Slot & Thumb
                Item {
                    id: faderContainer
                    width: root.showVuMeter ? (parent.width - 11) : parent.width
                    height: parent.height

                    // Track slot groove
                    Rectangle {
                        id: faderTrack
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 8
                        height: parent.height
                        radius: 4
                        color: Theme.withAlpha(Theme.surfaceContainerHighest || "#111", 0.9)
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.outline || "#444", 0.3)

                        // Filled active volume line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 4
                            radius: 2
                            height: Math.max(0, Math.min(parent.height, parent.height * (root.currentVol / root.maxVolume)))
                            color: root.isMuted ? (Theme.error || "#EF5350") : root.accentColor
                        }

                        // Unity (100% / 0dB) tick mark
                        Rectangle {
                            visible: root.maxVolume > 1.05
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * (1.0 - (1.0 / root.maxVolume))
                            width: 12
                            height: 1.5
                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.6)
                        }
                    }

                    // Fader Thumb / Knob (Console style)
                    Rectangle {
                        id: faderKnob
                        width: Math.min(faderContainer.width - 4, 38)
                        height: 22
                        radius: 5
                        anchors.horizontalCenter: faderTrack.horizontalCenter
                        y: Math.max(0, Math.min(faderTrack.height - height,
                            (faderTrack.height - height) * (1.0 - (root.currentVol / root.maxVolume))))

                        color: faderMouse.pressed ? Theme.primaryContainer : (faderMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                        border.width: 1
                        border.color: faderMouse.pressed ? Theme.primary : Theme.withAlpha(Theme.outline, 0.5)

                        // Console knob grip grooves
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Rectangle { width: 14; height: 1.5; radius: 1; color: root.accentColor }
                            Rectangle { width: 14; height: 1.5; radius: 1; color: Theme.withAlpha(Theme.surfaceVariantText, 0.7) }
                            Rectangle { width: 14; height: 1.5; radius: 1; color: Theme.withAlpha(Theme.surfaceVariantText, 0.7) }
                        }
                    }

                    // Fader Mouse & Wheel Interaction
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

                        // Wheel adjusts volume by 2%
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

                        // Double click resets to 100% (Unity gain)
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

        // Numeric Readout (% and dB)
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
                    font.weight: Font.Bold
                    color: root.isMuted ? Theme.error : Theme.surfaceText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MixerUtils.volumeToDb(root.currentVol)
                    font.pixelSize: 8
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Bottom Controls: MUTE and DEFAULT / SOLO
        Row {
            width: parent.width
            height: 26
            spacing: 4

            // MUTE button (M)
            Rectangle {
                id: muteBtn
                width: (parent.width - 4) / 2
                height: 26
                radius: 4
                color: root.isMuted ? (Theme.error || "#D32F2F") : (muteMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                border.width: 1
                border.color: root.isMuted ? Theme.error : Theme.withAlpha(Theme.outline, 0.4)

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

                StyledText {
                    anchors.centerIn: parent
                    text: "M"
                    font.pixelSize: 11
                    font.weight: Font.Black
                    color: root.isMuted ? (Theme.onError || "#FFFFFF") : Theme.surfaceText
                }
            }

            // DEFAULT SINK / STAR button
            Rectangle {
                id: defaultBtn
                width: (parent.width - 4) / 2
                height: 26
                radius: 4
                color: root.isDefaultSink ? Theme.primary : (defaultMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                border.width: 1
                border.color: root.isDefaultSink ? Theme.primary : Theme.withAlpha(Theme.outline, 0.4)

                MouseArea {
                    id: defaultMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.setDefaultRequested(root.node);
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: root.isDefaultSink ? "check" : "radio_button_unchecked"
                    size: 13
                    color: root.isDefaultSink ? Theme.onPrimary : Theme.surfaceVariantText
                }
            }
        }
    }
}
