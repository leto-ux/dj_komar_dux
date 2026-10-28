// MixerUtils.js - Audio Mixer Utilities for Dux Shell
.pragma library

/**
 * Convert linear volume (0.0 to 1.5) to approximate decibels (dB)
 */
function volumeToDb(linear) {
    if (!linear || linear <= 0.0001) return "-inf dB";
    const db = 20 * Math.log10(linear);
    if (Math.abs(db) < 0.05) return "0.0 dB";
    const sign = db > 0 ? "+" : "";
    return sign + db.toFixed(1) + " dB";
}

/**
 * Format volume percentage
 */
function volumeToPercent(linear) {
    if (!linear || linear <= 0) return 0;
    return Math.round(linear * 100);
}

/**
 * Detect whether a PipeWire node is a Virtual Sink
 */
function isVirtualSink(node) {
    if (!node) return false;
    const props = node.properties || {};
    const factory = props["factory.name"] || "";
    const bus = props["device.bus"];
    const mediaClass = props["media.class"] || "";
    const name = (node.name || "").toLowerCase();
    const desc = (node.description || "").toLowerCase();

    // Explicit null-audio-sink factory
    if (factory === "support.null-audio-sink") return true;

    // Name or description containing virtual/null keywords
    if (name.includes("virtual") || name.includes("null-sink") || desc.includes("virtual sink")) return true;

    // Audio/Duplex or Sink with no physical hardware bus (pci, usb, bluetooth) and not a client stream
    if (!bus && !node.isStream && (node.isSink || mediaClass.includes("Sink") || mediaClass.includes("Duplex"))) {
        return true;
    }

    return false;
}

/**
 * Detect whether a node is a Physical/Hardware Sink
 */
function isHardwareSink(node) {
    if (!node || node.isStream) return false;
    const props = node.properties || {};
    const bus = props["device.bus"];
    const mediaClass = props["media.class"] || "";
    if (isVirtualSink(node)) return false;
    return (node.isSink || mediaClass.includes("Sink")) && !!bus;
}

/**
 * Detect whether a node is an Application Playback Stream
 */
function isAppStream(node) {
    if (!node) return false;
    const props = node.properties || {};
    const mediaClass = props["media.class"] || "";
    return node.isStream && (node.isSink || mediaClass.includes("Stream/Output") || mediaClass.includes("Stream"));
}

/**
 * Detect whether a node is an Audio Input / Source
 */
function isAudioSource(node) {
    if (!node || node.isStream) return false;
    const props = node.properties || {};
    const mediaClass = props["media.class"] || "";
    return !node.isSink && (mediaClass.includes("Source") || mediaClass.includes("Input"));
}

/**
 * Get an appropriate Material icon for a channel based on its name and properties
 */
function getChannelIcon(node) {
    if (!node) return "tune";
    const name = ((node.nickname || node.name || node.description) + "").toLowerCase();
    const props = node.properties || {};

    if (name.includes("master")) return "album";
    if (name.includes("browser") || name.includes("chrome") || name.includes("firefox")) return "language";
    if (name.includes("music") || name.includes("spotify")) return "music_note";
    if (name.includes("comm") || name.includes("discord") || name.includes("voice") || name.includes("call")) return "chat";
    if (name.includes("game") || name.includes("steam") || name.includes("play")) return "sports_esports";
    if (name.includes("headphone") || name.includes("headset")) return "headphones";
    if (name.includes("speaker")) return "speaker";
    if (name.includes("mic") || name.includes("input")) return "mic";
    if (name.includes("bot") || name.includes("soundboard")) return "smart_toy";
    if (name.includes("other") || name.includes("aux")) return "more_horiz";

    if (props["device.bus"] === "bluetooth") return "bluetooth_audio";
    if (isVirtualSink(node)) return "alt_route";
    if (node.isStream) return "apps";

    return "volume_up";
}

/**
 * Clean up display name for channel strip
 */
function getCleanName(node, customAliases) {
    if (!node) return "Channel";
    const nodeName = node.name || "";
    if (customAliases && customAliases[nodeName]) {
        return customAliases[nodeName];
    }
    const nick = node.nickname || "";
    if (nick && nick.length > 0 && nick !== nodeName) {
        return nick;
    }
    const desc = node.description || "";
    if (desc && desc.length > 0) {
        return desc;
    }
    return nodeName || "Audio Channel";
}

/**
 * Color coding for channels
 */
function getChannelAccent(node, theme) {
    if (!node) return theme.primary;
    const name = ((node.name || "") + "").toLowerCase();
    if (name.includes("master")) return theme.primary;
    if (name.includes("browser")) return "#29B6F6"; // light blue
    if (name.includes("music")) return "#66BB6A";   // green
    if (name.includes("comm") || name.includes("discord")) return "#AB47BC"; // purple
    if (name.includes("game")) return "#FFA726";    // orange
    if (name.includes("other")) return "#78909C";   // blue grey
    if (isVirtualSink(node)) return theme.secondary || "#26A69A";
    return theme.primary;
}
