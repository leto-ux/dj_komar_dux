import QtQuick
import Quickshell.Services.Pipewire
import qs.Common

Item {
    id: root

    property var node: null
    property bool enabled: true
    property bool isVertical: true
    property int barThickness: 6
    property real peakValue: peakMonitor.peak || 0.0

    PwNodePeakMonitor {
        id: peakMonitor
        node: root.node
        enabled: root.enabled && root.node !== null
    }

    // Smooth animation on meter drop, instant on rise
    property real displayLevel: 0.0
    property real peakHold: 0.0

    onPeakValueChanged: {
        if (peakValue > displayLevel) {
            displayLevel = peakValue;
        }
        if (peakValue > peakHold) {
            peakHold = peakValue;
            peakHoldTimer.restart();
        }
    }

    Timer {
        id: decayTimer
        interval: 35
        running: root.enabled && displayLevel > 0.005
        repeat: true
        onTriggered: {
            displayLevel = Math.max(0.0, displayLevel * 0.88 - 0.01);
        }
    }

    Timer {
        id: peakHoldTimer
        interval: 800
        repeat: false
        onTriggered: {
            peakHoldDecayTimer.start();
        }
    }

    Timer {
        id: peakHoldDecayTimer
        interval: 40
        repeat: true
        running: false
        onTriggered: {
            peakHold = Math.max(0.0, peakHold - 0.04);
            if (peakHold <= displayLevel) {
                peakHold = displayLevel;
                stop();
            }
        }
    }

    implicitWidth: isVertical ? barThickness : 120
    implicitHeight: isVertical ? 120 : barThickness

    // Background track
    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: Theme.withAlpha(Theme.surfaceContainerHighest || "#333", 0.5)
        clip: true

        // Active meter fill
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: isVertical ? Math.min(parent.height, Math.max(0, parent.height * root.displayLevel)) : parent.height
            width: isVertical ? parent.width : Math.min(parent.width, Math.max(0, parent.width * root.displayLevel))
            anchors.top: isVertical ? undefined : parent.top

            Rectangle {
                anchors.fill: parent
                radius: Math.min(width, height) / 2
                gradient: Gradient {
                    orientation: root.isVertical ? Gradient.Vertical : Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: root.displayLevel > 0.88 ? (Theme.error || "#EF5350") : (root.displayLevel > 0.65 ? "#FFCA28" : "#66BB6A")
                    }
                    GradientStop {
                        position: 0.4
                        color: root.displayLevel > 0.65 ? "#FFCA28" : "#66BB6A"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#4CAF50"
                    }
                }
            }
        }

        // Peak hold line
        Rectangle {
            visible: root.peakHold > 0.02
            width: isVertical ? parent.width : 2
            height: isVertical ? 2 : parent.height
            color: root.peakHold > 0.88 ? (Theme.error || "#EF5350") : (root.peakHold > 0.65 ? "#FFD54F" : "#A5D6A7")
            x: isVertical ? 0 : Math.max(0, Math.min(parent.width - 2, parent.width * root.peakHold))
            y: isVertical ? Math.max(0, Math.min(parent.height - 2, parent.height * (1.0 - root.peakHold))) : 0
        }
    }
}
