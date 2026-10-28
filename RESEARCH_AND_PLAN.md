# Dux Shell Audio Mixer Plugin - Research & Architecture Plan

## 1. Research Summary

### A. Dux Shell (`dms`) Architecture & Runtime
- **Framework**: Dux Shell is built on top of [Quickshell](https://quickshell.org/) (Qt6 QML framework for Wayland compositors) and a Go backend (`dms`).
- **Runtime Environment**: DMS runs as a user service (`dms run --session`) and executes Quickshell against an extracted shell runtime located in `/run/user/1000/dms-shell/<hash>/`.
- **Plugin Management**: User plugins reside in `~/.config/dms/plugins/<PluginId>/`. DMS automatically discovers and manages them via `PluginService` and tracks installed plugins in `plugins.lock.json`.

---

### B. Plugin Specification & Manifest (`plugin.json`)
Plugins are defined by a `plugin.json` manifest conforming to DMS specifications:
- `id`: Unique identifier (e.g., `"duxMixer"`).
- `name`: Display name (e.g., `"Digital Audio Mixer"`).
- `description`: Overview of plugin functionality.
- `version`: Semantic version string (e.g., `"1.0.0"`).
- `author`: Author information.
- `type`: `"widget"` (or `"composite"` if combined with a background daemon).
- `capabilities`: `["dankbar-widget", "control-center", "audio"]`.
- `component`: Entry QML file (e.g., `"./DuxMixerWidget.qml"`).
- `settings`: Settings QML file (e.g., `"./DuxMixerSettings.qml"`).
- `icon`: Material icon name (e.g., `"tune"` or `"volume_up"`).
- `permissions`: `["settings_read", "settings_write", "process"]`.

---

### C. Plugin UI Framework (`qs.Modules.Plugins`, `qs.Widgets`, `qs.Common`)
- **`PluginComponent`**:
  - Serves as the root component for bar and dock widgets.
  - Supports `horizontalBarPill` and `verticalBarPill` delegates for DankBar.
  - Automatically manages a popup window anchored to the bar pill via `popoutContent` using `PluginPopout` or `PopoutComponent`.
  - Configurable popup geometry (`popoutWidth`, `popoutHeight`).
  - Injects `pluginData` (persistent settings stored via DMS) and notifies on settings changes.
  - Supports Control Center integration via `ccWidgetIcon`, `ccWidgetPrimaryText`, and `ccDetailContent`.
- **Pre-built UI Components**:
  - `qs.Widgets`: Pre-styled Material 3 controls: `DankSlider` / `DSlider`, `DankButton`, `DankIcon`, `DankToggle`, `DankTabBar`, `DankFilterChips`, `DankListView`, `StyledText`, and `StyledRect`.
  - `qs.Common`: `Theme` singleton (system-wide dynamic M3 palette: `Theme.surface`, `Theme.surfaceContainer`, `Theme.primary`, `Theme.error`, `Theme.cornerRadius`, `Theme.spacingM`, font scale, etc.).

---

### D. Audio Subsystem Integration (PipeWire & Quickshell)
- **Built-in `AudioService`** (`qs.Services`):
  - Provides system-wide state: `AudioService.sink` (default output), `AudioService.source` (default input), and `AudioService.allNodes`.
  - Helper functions for display names (`displayName(node)`), device icons (`sinkIcon(node)`), volume icons, and default sink selection (`setDefaultSinkByName`).
- **Native Quickshell PipeWire Service** (`Quickshell.Services.Pipewire`):
  - **`Pipewire` singleton**: Direct access to `Pipewire.nodes.values`, `Pipewire.defaultAudioSink`, and `Pipewire.defaultAudioSource`.
  - **`PwNode`**: Exposes `id`, `name`, `description`, `nickname`, `isSink`, `isStream`, `type`, and `properties` (contains PipeWire dictionary entries: `media.class`, `node.name`, `device.description`, `node.driver`, `factory.name`, etc.).
  - **`PwNodeAudio`**: Direct read/write bindings for `volume` (float `0.0`–`1.0`+), `muted` (bool), `channels`, and `volumes` (per-channel faders). Mutating `audio.volume` or `audio.muted` immediately affects the audio graph without running external commands.
  - **`PwNodePeakMonitor`**: Native real-time VU meter peak monitoring (`node`, `enabled`, `peak` [0.0–1.0], and per-channel `peaks`), allowing responsive visual volume meters like on a hardware mixing board.
  - **`PwObjectTracker`**: Ensures nodes remain tracked and reactive across hotplug events.

---

## 2. Theory & Implementation Plan

### A. Sink Classification & Virtual Sink Detection Logic
PipeWire nodes can be classified based on node attributes and properties:
- **Hardware Output Sinks**:
  - Condition: `isSink && !isStream && properties["device.bus"] !== undefined`
  - Examples: Built-in analog audio, USB DAC, HDMI / DisplayPort audio, Bluetooth headsets.
- **Virtual Sinks**:
  - Condition: `isSink && !isStream && (properties["device.bus"] === undefined || properties["factory.name"] === "support.null-audio-sink" || (properties["node.name"] && properties["node.name"].includes("virtual")))`
  - Examples: Null sinks (`module-null-sink`), virtual cables, OBS audio loops, Discord / DAW loopback sinks, noise filter / EasyEffects virtual nodes.
- **Application Playback Streams**:
  - Condition: `isSink && isStream`
  - Examples: Media players, browser tabs, Discord voice stream, game audio.
- **Audio Inputs / Sources**:
  - Condition: `!isSink && !isStream`
  - Examples: Microphones, line-in inputs, monitor sources.

---

### B. Device Selection & Persistence ("Chosen Devices")
To fulfill the requirement of showing and changing volume levels of **chosen** virtual sinks/audio devices:
1. **Persistent Configuration (`pluginData`)**:
   - `pinnedNodeNames`: Array of node names selected by the user to appear on the main mixer strip.
   - `customLabels`: Key-value map of friendly aliases for virtual sinks (e.g., `{"virtual_sink_music": "Music / Spotify"}`).
   - `channelOrder`: Array determining fader ordering.
   - `showMasterFader`: Boolean indicating if a dedicated master output fader is displayed.
   - `allowVolumeBoost`: Boolean permitting sliders up to 150% volume.
2. **In-Popup Quick Filter / Mode Selector**:
   - Tabs or filter chips:
     - **Mixer** (User's chosen/pinned virtual sinks & devices)
     - **Virtual Sinks** (All detected virtual audio sinks)
     - **Hardware Sinks** (Physical output devices)
     - **Apps** (Active application playback streams)
     - **Inputs** (Microphones / input streams)
3. **Quick Pin / Select Action**:
   - Each channel strip includes a quick pin toggle button (star / pin icon) to add/remove the device to/from the active mixer view without opening settings.

---

### C. Digital Audio Mixer UI & Layout
A digital audio mixing console popup window:
1. **Master Fader Strip**:
   - Controls default system sink volume and mute.
   - Live stereo/mono VU meter using `PwNodePeakMonitor`.
2. **Channel Strips (Mixer Grid / Rack)**:
   - **Header**: Channel icon, label (custom alias or device description), and badge indicating Virtual/Hardware.
   - **VU Meter**: Vertical or horizontal real-time peak meter displaying current audio levels in green/yellow/red zones.
   - **Fader**: Smooth slider (`0%` to `100%` or `150%`) with numeric percentage and decibel readout.
   - **Controls**:
     - `M` (Mute toggle): Highlighted in `Theme.error` when muted.
     - `★` (Set Default Sink): Allows setting any sink as current default.
     - `📌` (Pin/Mixer inclusion): Toggles inclusion in the curated mixer tab.
3. **Control Bar / Header**:
   - Filter selector (Mixer, Virtual, Hardware, Apps).
   - "Add Virtual Sink" quick-action button.
   - Settings button opening the configuration view.

---

### D. Optional: On-the-Fly Virtual Sink Creation
- Ability to create a new virtual sink directly from the plugin UI via PipeWire/PulseAudio command:
  ```bash
  pactl load-module module-null-sink sink_name="DuxMixerVirtual" sink_properties=device.description="Dux\ Virtual\ Sink"
  ```
- Allows users to spin up new virtual audio channels instantly for routing audio between applications.
