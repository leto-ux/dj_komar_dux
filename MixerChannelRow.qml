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

    width: parent ? parent.width : 420
    height: 58
    radius: Theme.cornerRadius
    color: isMasterSink ? Theme.withAlpha(Theme.primaryContainer || "#332211", 0.5) : Theme.withAlpha(Theme.surfaceContainer || "#222", 0.75)
    border.width: (isMasterSink || isDefaultSink) ? 2 : 1
    border.color: (isMasterSink || isDefaultSink) ? Theme.primary : Theme.withAlpha(Theme.outline || "#555", 0.25)

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        // Channel Icon & Badge
        Item {
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Theme.withAlpha(root.accentColor, 0.2)

                DankIcon {
                    anchors.centerIn: parent
                    name: MixerUtils.getChannelIcon(node)
                    size: 18
                    color: root.accentColor
                }
            }
        }

        // Center Content: Label, Slider & VU Meter
        Column {
            width: parent.width - 36 - 10 - 132 - 10
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            // Top line: Name, Type badge, dB readout
            Item {
                width: parent.width
                height: 18

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    StyledText {
                        text: root.cleanTitle
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, root.width - 240)
                    }

                    Rectangle {
                        visible: root.isMasterSink
                        width: 44
                        height: 14
                        radius: 3
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            anchors.centerIn: parent
                            text: "MASTER"
                            font.pixelSize: 8
                            font.weight: Font.Black
                            color: Theme.onPrimary
                        }
                    }

                    Rectangle {
                        width: isVirtual ? 28 : 22
                        height: 14
                        radius: 3
                        color: isVirtual ? Theme.withAlpha(root.accentColor, 0.2) : Theme.withAlpha(Theme.surfaceVariantText, 0.15)
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            anchors.centerIn: parent
                            text: isVirtual ? "VIRT" : "HW"
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: isVirtual ? root.accentColor : Theme.surfaceVariantText
                        }
                    }
                }

                StyledText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: MixerUtils.volumeToPercent(root.currentVol) + "% (" + MixerUtils.volumeToDb(root.currentVol) + ")"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: root.isMuted ? Theme.error : Theme.surfaceVariantText
                }
            }

            // Bottom line: Slider & VU meter
            Row {
                width: parent.width
                height: 20
                spacing: 6

                // Horizontal Slider track
                Item {
                    id: sliderContainer
                    width: parent.width - (root.showVuMeter ? 46 : 0)
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: sliderTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.withAlpha(Theme.surfaceContainerHighest || "#111", 0.9)
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.outline || "#444", 0.3)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            radius: 3
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.currentVol / root.maxVolume)))
                            color: root.isMuted ? (Theme.error || "#EF5350") : root.accentColor
                        }

                        // Unity tick mark
                        Rectangle {
                            visible: root.maxVolume > 1.05
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * (1.0 / root.maxVolume)
                            width: 1.5
                            height: 10
                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.6)
                        }
                    }

                    // Slider Knob
                    Rectangle {
                        id: sliderKnob
                        width: 14
                        height: 14
                        radius: 7
                        anchors.verticalCenter: sliderTrack.verticalCenter
                        x: Math.max(0, Math.min(sliderTrack.width - width, (sliderTrack.width - width) * (root.currentVol / root.maxVolume)))
                        color: sliderMouse.pressed ? Theme.primary : Theme.surfaceText
                        border.width: 2
                        border.color: root.accentColor
                    }

                    MouseArea {
                        id: sliderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateFromX(mouseX) {
                            if (!root.audio) return;
                            const usableWidth = sliderTrack.width - sliderKnob.width;
                            const clampedX = Math.max(0, Math.min(usableWidth, mouseX - sliderKnob.width / 2));
                            const fraction = clampedX / usableWidth;
                            const newVol = Math.round(fraction * root.maxVolume * 100) / 100;
                            SessionData.suppressOSDTemporarily();
                            root.audio.volume = newVol;
                            if (newVol > 0 && root.audio.muted) {
                                root.audio.muted = false;
                            }
                        }

                        onPressed: mouse => updateFromX(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed) updateFromX(mouse.x);
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

                // Horizontal VU Meter
                MixerVuMeter {
                    visible: root.showVuMeter
                    node: root.node
                    enabled: root.activePopout && root.showVuMeter
                    isVertical: false
                    barThickness: 5
                    width: 40
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Action Buttons: Mute, Default, Master, Pin
        Row {
            width: 124
            height: 28
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            // MUTE button (M)
            Rectangle {
                width: 28
                height: 28
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

            // DEFAULT SINK button
            Rectangle {
                width: 28
                height: 28
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
                    size: 14
                    color: root.isDefaultSink ? Theme.onPrimary : Theme.surfaceVariantText
                }
            }

            // MASTER FADER button
            Rectangle {
                width: 28
                height: 28
                radius: 4
                color: root.isMasterSink ? Theme.primary : (masterMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                border.width: 1
                border.color: root.isMasterSink ? Theme.primary : Theme.withAlpha(Theme.outline, 0.4)

                MouseArea {
                    id: masterMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (node && node.name) {
                            root.setMasterRequested(node.name);
                        }
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "album"
                    size: 14
                    color: root.isMasterSink ? Theme.onPrimary : Theme.surfaceVariantText
                }
            }

            // PIN button
            Rectangle {
                width: 28
                height: 28
                radius: 4
                color: pinMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                border.width: 1
                border.color: Theme.withAlpha(Theme.outline, 0.4)

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (node && node.name) {
                            root.pinToggled(node.name);
                        }
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: root.isPinned ? "star" : "star_outline"
                    size: 14
                    color: root.isPinned ? (Theme.primary || "#FFB300") : Theme.surfaceVariantText
                }
            }
        }
    }
}
