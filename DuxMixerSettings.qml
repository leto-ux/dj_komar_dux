import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "MixerUtils.js" as MixerUtils

PluginSettings {
    id: root

    pluginId: "duxMixer"

    // Load initial settings
    property var pinnedSinks: []
    property var customAliases: ({})

    Component.onCompleted: {
        pinnedSinks = root.loadValue("pinnedSinks", []);
        customAliases = root.loadValue("customAliases", {});
    }

    function saveAlias(nodeName, newAlias) {
        let aliases = Object.assign({}, customAliases);
        if (newAlias && newAlias.trim().length > 0) {
            aliases[nodeName] = newAlias.trim();
        } else {
            delete aliases[nodeName];
        }
        customAliases = aliases;
        root.saveValue("customAliases", aliases);
    }

    function toggleSinkPinned(nodeName) {
        let pins = (pinnedSinks || []).slice();
        const idx = pins.indexOf(nodeName);
        if (idx !== -1) {
            pins.splice(idx, 1);
        } else {
            pins.push(nodeName);
        }
        pinnedSinks = pins;
        root.saveValue("pinnedSinks", pins);
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Header Title & Description
        StyledText {
            width: parent.width
            text: "Digital Audio Mixer"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: "Configure channel strips, live VU meters, volume boost, and channel selection for your virtual and hardware audio sinks."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.3
        }

        // Section: General Preferences
        StyledText {
            text: "Mixer Preferences"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
        }

        ToggleSetting {
            settingKey: "allowVolumeBoost"
            label: "Allow Volume Boost (>100%)"
            description: "Allows volume faders to be pushed up to 150% (+3.5 dB) for quiet audio sources."
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showMasterFader"
            label: "Show Master Fader"
            description: "Display a dedicated Master output fader strip on the left side of the mixer console."
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "enableVuMeters"
            label: "Enable Real-time VU Peak Meters"
            description: "Shows live peak audio level meters on each fader strip using PipeWire's native peak monitor."
            defaultValue: true
        }

        SelectionSetting {
            settingKey: "layoutMode"
            label: "Default Mixer Layout"
            description: "Choose between classic vertical mixing console strips or horizontal rack sliders."
            defaultValue: "console"
            options: [
                { label: "Console View (Vertical Fader Strips)", value: "console" },
                { label: "Rack View (Horizontal Slider Rows)", value: "rack" }
            ]
        }

        SelectionSetting {
            settingKey: "defaultTab"
            label: "Default View Tab"
            description: "Category shown when opening the mixer popup."
            defaultValue: "mixer"
            options: [
                { label: "Mixer (Curated & Pinned Channels)", value: "mixer" },
                { label: "Virtual Sinks (All Virtual Audio Channels)", value: "virtual" },
                { label: "Hardware Sinks (Physical Audio Devices)", value: "hardware" },
                { label: "Applications (Per-App Playback Streams)", value: "apps" }
            ]
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.3
        }

        // Section: Channel Management & Custom Aliases
        StyledText {
            text: "Channel Selection & Aliases"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: "Toggle which sinks appear in the primary 'Mixer' tab, or assign custom friendly display names:"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        // List of all detected Sinks
        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: (AudioService.pipewireNodes || []).filter(n => n.isSink && !n.isStream)

                Rectangle {
                    id: channelConfigRow
                    required property var modelData
                    width: parent.width
                    height: 52
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh || "#2a2a2a"
                    border.width: 1
                    border.color: isPinned ? Theme.primary : Theme.withAlpha(Theme.outline, 0.25)

                    readonly property bool isPinned: {
                        if (root.pinnedSinks && root.pinnedSinks.length > 0) {
                            return root.pinnedSinks.indexOf(modelData.name) !== -1;
                        }
                        return MixerUtils.isVirtualSink(modelData);
                    }

                    readonly property string currentAlias: (root.customAliases && root.customAliases[modelData.name]) || ""

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Pin Checkbox
                        MouseArea {
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleSinkPinned(channelConfigRow.modelData.name)

                            DankIcon {
                                anchors.centerIn: parent
                                name: channelConfigRow.isPinned ? "check_box" : "check_box_outline_blank"
                                size: 20
                                color: channelConfigRow.isPinned ? Theme.primary : Theme.surfaceVariantText
                            }
                        }

                        // Type Badge & Default Name
                        Column {
                            width: (parent.width - 24 - 10 - 180 - 10)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Row {
                                spacing: 6
                                Rectangle {
                                    width: MixerUtils.isVirtualSink(channelConfigRow.modelData) ? 30 : 22
                                    height: 14
                                    radius: 3
                                    color: MixerUtils.isVirtualSink(channelConfigRow.modelData) ? Theme.withAlpha(Theme.secondary || "#26A69A", 0.2) : Theme.withAlpha(Theme.surfaceVariantText, 0.15)
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: MixerUtils.isVirtualSink(channelConfigRow.modelData) ? "VIRT" : "HW"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: MixerUtils.isVirtualSink(channelConfigRow.modelData) ? (Theme.secondary || "#26A69A") : Theme.surfaceVariantText
                                    }
                                }

                                StyledText {
                                    text: channelConfigRow.modelData.description || channelConfigRow.modelData.name
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceText
                                    elide: Text.ElideRight
                                    width: parent.parent.width - 36
                                }
                            }

                            StyledText {
                                text: channelConfigRow.modelData.name
                                font.pixelSize: 9
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Alias Input Box
                        Rectangle {
                            width: 170
                            height: 32
                            radius: 4
                            color: Theme.surfaceContainerHighest || "#1e1e1e"
                            anchors.verticalCenter: parent.verticalCenter
                            border.width: 1
                            border.color: aliasInput.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3)

                            TextInput {
                                id: aliasInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 11
                                color: Theme.surfaceText
                                text: channelConfigRow.currentAlias
                                clip: true

                                StyledText {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Custom alias..."
                                    font.pixelSize: 11
                                    color: Theme.withAlpha(Theme.surfaceVariantText, 0.5)
                                    visible: !aliasInput.text && !aliasInput.activeFocus
                                }

                                onEditingFinished: {
                                    root.saveAlias(channelConfigRow.modelData.name, text);
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.3
        }

        // Section: Usage & PipeWire Info
        StyledText {
            text: "PipeWire Virtual Sinks"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
        }

        Column {
            width: parent.width
            spacing: Theme.spacingXS
            leftPadding: Theme.spacingM
            bottomPadding: Theme.spacingL

            StyledText {
                width: parent.width
                text: "• Virtual sinks can be created directly from the mixer popup (+) or via pactl/pw-cli commands."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
            StyledText {
                width: parent.width
                text: "• Applications can be assigned to different virtual sinks in your desktop sound settings or patchbay (Helvum / Carla)."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
            StyledText {
                width: parent.width
                text: "• Double-clicking any fader knob immediately resets its volume to unity gain (100% / 0 dB)."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
