import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "MixerUtils.js" as MixerUtils

PluginComponent {
    id: root

    layerNamespacePlugin: "dux-mixer"

    // Configuration / Persistent Settings
    readonly property var savedPins: (pluginData && pluginData.pinnedSinks) ? pluginData.pinnedSinks : []
    property var pinnedSinks: savedPins
    readonly property var customAliases: (pluginData && pluginData.customAliases) ? pluginData.customAliases : ({})
    readonly property bool allowVolumeBoost: (pluginData && pluginData.allowVolumeBoost !== undefined) ? pluginData.allowVolumeBoost : false
    readonly property bool showMasterFader: (pluginData && pluginData.showMasterFader !== undefined) ? pluginData.showMasterFader : true
    readonly property bool enableVuMeters: (pluginData && pluginData.enableVuMeters !== undefined) ? pluginData.enableVuMeters : true
    property string activeTab: (pluginData && pluginData.defaultTab) ? pluginData.defaultTab : "mixer"
    property string layoutMode: (pluginData && pluginData.layoutMode) ? pluginData.layoutMode : "console"

    readonly property real maxVolumeLimit: allowVolumeBoost ? 1.5 : 1.0

    // All active audio nodes from Pipewire / AudioService
    readonly property var allNodes: AudioService.pipewireNodes || []

    // Categorized Node Lists
    readonly property var virtualSinks: allNodes.filter(node => MixerUtils.isVirtualSink(node))
    readonly property var hardwareSinks: allNodes.filter(node => MixerUtils.isHardwareSink(node))
    readonly property var appStreams: allNodes.filter(node => MixerUtils.isAppStream(node) && !AudioService.isOwnStream(node))
    readonly property var audioSources: allNodes.filter(node => MixerUtils.isAudioSource(node))

    // Curated Mixer Nodes:
    // If user has specific pins saved, show those; otherwise default to all virtual sinks + hardware default!
    readonly property var mixerNodes: {
        if (pinnedSinks && pinnedSinks.length > 0) {
            return allNodes.filter(node => pinnedSinks.indexOf(node.name) !== -1);
        }
        // Default: all virtual sinks
        return virtualSinks.length > 0 ? virtualSinks : hardwareSinks;
    }

    // Nodes for current selected tab
    readonly property var currentTabNodes: {
        switch (activeTab) {
        case "mixer": return mixerNodes;
        case "virtual": return virtualSinks;
        case "hardware": return hardwareSinks;
        case "apps": return appStreams;
        case "inputs": return audioSources;
        default: return mixerNodes;
        }
    }

    function isNodePinned(nodeName) {
        if (!nodeName) return false;
        if (pinnedSinks && pinnedSinks.length > 0) {
            return pinnedSinks.indexOf(nodeName) !== -1;
        }
        // If no explicit pins yet, virtual sinks are implicitly in mixer
        for (let i = 0; i < virtualSinks.length; i++) {
            if (virtualSinks[i].name === nodeName) return true;
        }
        return false;
    }

    function togglePin(nodeName) {
        if (!nodeName) return;
        let pins = [];
        if (pinnedSinks && pinnedSinks.length > 0) {
            pins = pinnedSinks.slice();
        } else {
            // Seed with current virtual sink names
            for (let i = 0; i < virtualSinks.length; i++) {
                if (virtualSinks[i].name) pins.push(virtualSinks[i].name);
            }
        }

        const idx = pins.indexOf(nodeName);
        if (idx !== -1) {
            pins.splice(idx, 1);
        } else {
            pins.push(nodeName);
        }

        pinnedSinks = pins;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "pinnedSinks", pins);
        }
    }

    function setDefaultSink(targetNode) {
        if (!targetNode || !targetNode.name) return;
        AudioService.setDefaultSinkByName(targetNode.name);
    }

    function setLayout(mode) {
        layoutMode = mode;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "layoutMode", mode);
        }
    }

    function setTab(tab) {
        activeTab = tab;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "defaultTab", tab);
        }
    }

    // Dynamic Popout Dimensions based on layout mode
    popoutWidth: layoutMode === "console" ? 560 : 480
    popoutHeight: 460

    // Control Center Integration
    ccWidgetIcon: "tune"
    ccWidgetPrimaryText: "Audio Mixer"
    ccWidgetSecondaryText: virtualSinks.length + " Virtual Sinks"
    ccWidgetIsActive: true
    ccWidgetIsToggle: false

    onCcWidgetExpanded: {
        root.triggerPopout();
    }

    // DankBar Horizontal Pill
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "tune"
                size: Math.min(root.widgetThickness, 18)
                color: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.muted) ? Theme.error : Theme.surfaceText
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const vol = (AudioService.sink && AudioService.sink.audio) ? Math.round(AudioService.sink.audio.volume * 100) : 0;
                    return vol + "%";
                }
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            // Virtual Sink badge count
            Rectangle {
                visible: root.virtualSinks.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: badgeText.implicitWidth + 8
                height: 16
                radius: 8
                color: Theme.withAlpha(Theme.primary, 0.25)

                StyledText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.virtualSinks.length + "v"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.primary
                }
            }
        }
    }

    // DankBar Vertical Pill
    verticalBarPill: Component {
        Column {
            spacing: 2
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "tune"
                size: Math.min(root.widgetThickness, 18)
                color: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.muted) ? Theme.error : Theme.surfaceText
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const vol = (AudioService.sink && AudioService.sink.audio) ? Math.round(AudioService.sink.audio.volume * 100) : 0;
                    return vol + "%";
                }
                font.pixelSize: 8
                color: Theme.surfaceVariantText
            }
        }
    }

    // Popout Content (Audio Mixer Console)
    popoutContent: Component {
        PopoutComponent {
            id: mixerPopout

            headerText: "Digital Audio Mixer"
            detailsText: ""

            // Header Action Icons
            headerActions: Component {
                Row {
                    spacing: 4

                    // Create Virtual Sink Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: addSinkDrawer.isOpen ? Theme.primary : (createHover.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.outline, 0.3)

                        MouseArea {
                            id: createHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: addSinkDrawer.isOpen = !addSinkDrawer.isOpen
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "add"
                            size: 16
                            color: addSinkDrawer.isOpen ? Theme.onPrimary : Theme.surfaceText
                        }
                    }

                    // Layout Switcher Button (Console vs Rack)
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: layoutHover.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.outline, 0.3)

                        MouseArea {
                            id: layoutHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.setLayout(root.layoutMode === "console" ? "rack" : "console");
                            }
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: root.layoutMode === "console" ? "view_agenda" : "view_column"
                            size: 16
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            // Main Popout Body
            Column {
                width: parent.width
                spacing: 8

                // Virtual Sink Creator Drawer
                MixerCreateSinkModal {
                    id: addSinkDrawer
                    width: parent.width
                    isOpen: false
                    onCloseRequested: isOpen = false
                    onSinkCreated: name => {
                        // Automatically switch to virtual tab to see new sink
                        root.setTab("virtual");
                    }
                }

                // Filter / Category Tabs Bar
                Item {
                    width: parent.width
                    height: 32

                    Row {
                        anchors.fill: parent
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "mixer", label: "Mixer (" + root.mixerNodes.length + ")", icon: "tune" },
                                { id: "virtual", label: "Virtual (" + root.virtualSinks.length + ")", icon: "alt_route" },
                                { id: "hardware", label: "Hardware (" + root.hardwareSinks.length + ")", icon: "speaker" },
                                { id: "apps", label: "Apps (" + root.appStreams.length + ")", icon: "apps" },
                                { id: "inputs", label: "Inputs (" + root.audioSources.length + ")", icon: "mic" }
                            ]

                            Rectangle {
                                id: tabChip
                                required property var modelData
                                width: chipRow.implicitWidth + 16
                                height: 28
                                radius: 14
                                color: root.activeTab === modelData.id ? Theme.primary : (chipMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                                border.width: 1
                                border.color: root.activeTab === modelData.id ? Theme.primary : Theme.withAlpha(Theme.outline, 0.25)

                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DankIcon {
                                        name: tabChip.modelData.icon
                                        size: 13
                                        color: root.activeTab === tabChip.modelData.id ? Theme.onPrimary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: tabChip.modelData.label
                                        font.pixelSize: 11
                                        font.weight: root.activeTab === tabChip.modelData.id ? Font.Bold : Font.Normal
                                        color: root.activeTab === tabChip.modelData.id ? Theme.onPrimary : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.setTab(tabChip.modelData.id)
                                }
                            }
                        }
                    }
                }

                // Empty State if no channels in selected category
                Rectangle {
                    visible: root.currentTabNodes.length === 0
                    width: parent.width
                    height: 200
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainer || "#222", 0.5)

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        DankIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: "speaker_group"
                            size: 36
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.activeTab === "mixer" ? "No channels pinned to Mixer yet" : "No devices in this category"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.activeTab === "mixer" ? "Star channels in Virtual or Hardware tabs, or create a virtual sink above." : "Check other tabs or audio connections."
                            font.pixelSize: 11
                            color: Theme.surfaceVariantText
                        }
                    }
                }

                // CONSOLE VIEW (Vertical Strips with Master Fader)
                Row {
                    visible: root.layoutMode === "console" && root.currentTabNodes.length > 0
                    width: parent.width
                    height: 340
                    spacing: 8

                    // Master Channel Strip (Fixed on the left)
                    MixerMasterStrip {
                        visible: root.showMasterFader
                        node: AudioService.sink
                        maxVolume: root.maxVolumeLimit
                        showVuMeter: root.enableVuMeters
                        activePopout: true
                        height: parent.height
                    }

                    // Separator line between Master and Channel strips
                    Rectangle {
                        visible: root.showMasterFader
                        width: 1
                        height: parent.height - 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.withAlpha(Theme.outline || "#555", 0.3)
                    }

                    // Scrollable Horizontal Rack of Channel Strips
                    Flickable {
                        id: channelFlickable
                        width: parent.width - (root.showMasterFader ? 91 : 0)
                        height: parent.height
                        contentWidth: channelsRow.implicitWidth
                        contentHeight: parent.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: channelsRow
                            spacing: 8
                            height: parent.height

                            Repeater {
                                model: root.currentTabNodes

                                MixerChannelStrip {
                                    required property var modelData
                                    node: modelData
                                    isPinned: root.isNodePinned(modelData.name)
                                    isDefaultSink: modelData === AudioService.sink
                                    maxVolume: root.maxVolumeLimit
                                    showVuMeter: root.enableVuMeters
                                    customAliases: root.customAliases
                                    activePopout: true
                                    height: parent.height

                                    onPinToggled: nodeName => root.togglePin(nodeName)
                                    onSetDefaultRequested: targetNode => root.setDefaultSink(targetNode)
                                }
                            }
                        }
                    }
                }

                // RACK VIEW (Horizontal Slider Cards)
                ListView {
                    visible: root.layoutMode === "rack" && root.currentTabNodes.length > 0
                    width: parent.width
                    height: 340
                    clip: true
                    spacing: 6
                    model: root.currentTabNodes

                    delegate: MixerChannelRow {
                        required property var modelData
                        node: modelData
                        isPinned: root.isNodePinned(modelData.name)
                        isDefaultSink: modelData === AudioService.sink
                        maxVolume: root.maxVolumeLimit
                        showVuMeter: root.enableVuMeters
                        customAliases: root.customAliases
                        activePopout: true

                        onPinToggled: nodeName => root.togglePin(nodeName)
                        onSetDefaultRequested: targetNode => root.setDefaultSink(targetNode)
                    }
                }

                // Status Footer
                Item {
                    width: parent.width
                    height: 20

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.virtualSinks.length + " virtual sinks • " + root.hardwareSinks.length + " hardware • PipeWire"
                        font.pixelSize: 10
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Double-click fader to reset to 100%"
                        font.pixelSize: 9
                        color: Theme.withAlpha(Theme.surfaceVariantText, 0.7)
                    }
                }
            }
        }
    }
}
