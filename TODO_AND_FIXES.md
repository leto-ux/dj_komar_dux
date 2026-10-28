# Digital Audio Mixer Plugin - Tasks & Fixes Checklist

## 1. Issues & Fixes Identified

### A. QML Compatibility & Syntax Fixes
- [x] **Optional Chaining (`?.`) & Nullish Coalescing (`??`) in Property Bindings**:
  - Replaced all raw `?.` and `??` in property declarations across `DuxMixerWidget.qml`, `MixerChannelStrip.qml`, `MixerChannelRow.qml`, and `MixerMasterStrip.qml` with safe ternary checks `(obj && obj.prop) ? obj.prop : default`.
- [ ] **`Layout.fillWidth` inside standard `Row` items**:
  - Found occurrences of `Layout.fillWidth: true` inside standard QtQuick `Row` items in:
    - `MixerChannelStrip.qml` (line 38)
    - `MixerChannelRow.qml` (line 74)
    - `DuxMixerWidget.qml` (lines 389, 545)
    - `MixerCreateSinkModal.qml` (lines 72, 156)
  - *Fix*: Standard QtQuick `Row` does not use `QtQuick.Layouts`. Either add `import QtQuick.Layouts` and use `RowLayout`, or replace the spacer with `Item { width: Math.max(0, parent.width - ...); height: 1 }` or anchor-based positioning.
- [ ] **`popoutHeight` dynamic calculation**:
  - Ensure `popoutHeight` adjusts cleanly between `console` (340px content + header/tabs = ~460px) and `rack` (flexible or scrollable height).

---

## 2. Shell Integration & Registration

- [ ] **Symlink to DMS Plugins Directory**:
  - Create the symlink:
    ```bash
    mkdir -p ~/.config/dms/plugins
    ln -s /home/mirai/git/dux_mixer ~/.config/dms/plugins/duxMixer
    ```
- [ ] **Verify Plugin Discovery**:
  - Run `dms plugins list` to ensure `duxMixer` appears under installed plugins with category, version, and capabilities.
- [ ] **Add to DankBar or Control Center**:
  - Enable `duxMixer` in `~/.config/dms/settings.json` under `barWidgets` or access it from the Control Center tile / DankBar widget list.

---

## 3. Functional Testing & Live Verification

- [ ] **Channel Strip Loading**:
  - Confirm all 6 existing virtual sinks on the user's system are populated:
    - `1. Master`
    - `2. Browser`
    - `3. Music`
    - `4. Comms`
    - `5. Games`
    - `6. Others`
  - Confirm hardware sinks are listed in the `Hardware` tab:
    - `Ryzen HD Audio Controller Analog Stereo`
    - `Navi 21/23 HDMI/DP Audio Controller Digital Stereo`
- [ ] **Fader & Volume Control**:
  - Test moving faders and verifying volume changes via `pactl list sinks` or `wpctl status`.
  - Confirm double-clicking a fader resets volume to 100% (0 dB unity gain).
  - Verify mouse wheel scrolling steps volume by ±2%.
- [ ] **Mute & Default Sink Switching**:
  - Verify clicking `M` toggles mute in PipeWire without activating the desktop OSD notification (`SessionData.suppressOSDTemporarily()`).
  - Verify clicking the check/radio button calls `AudioService.setDefaultSinkByName()`.
- [ ] **Live VU Peak Metering**:
  - Play an audio stream into one of the virtual sinks (e.g. `2. Browser` or `3. Music`).
  - Confirm `PwNodePeakMonitor` reflects audio activity in real time with green/yellow/red LED indicators and peak hold decay.
- [ ] **Virtual Sink Creator**:
  - Test clicking the `+` icon in the mixer header and creating a test virtual sink (e.g., `TestSink`).
  - Verify `pactl load-module module-null-sink` executes and the new sink appears immediately in the mixer view without restarting the shell.
- [ ] **Settings Persistence**:
  - Test toggling pins (starring channels) and confirm that `pinnedSinks` persists across shell restarts in `~/.config/dms/plugin_settings.json`.
  - Test renaming channels with custom aliases in `DuxMixerSettings.qml` and confirm the custom names display on the channel strips.
