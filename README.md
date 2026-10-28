# Dux Mixer (`duxMixer`)

A digital audio mixer popup plugin for [Dux Shell](https://duxlabs.dev) (Wayland desktop shell built with Quickshell & Go).

Designed for multi-sink audio setups, virtual audio cables, and streaming routing (e.g. Master, Browser, Music, Comms, Games, Others), providing real-time volume faders, decibel readouts, and live VU peak meters.

![Dux Mixer](screenshot.png)

---

## Features

- 🎚️ **Digital Mixing Console Strips**:
  - Classic vertical mixing console channel strips with fader knobs, grip grooves, and smooth decibel scaling.
  - Optional **Horizontal Rack View** for compact lists or small screens.
  - **Master Fader Strip**: Dedicated master output channel controlling system default sink volume and mute.
- 📊 **Real-time Live VU Peak Meters**:
  - Live audio activity meters powered by PipeWire's native `PwNodePeakMonitor`.
  - Multi-zone coloring (Green safe, Yellow warning, Red peak/clipping) with peak-hold decay indicator.
- 🔀 **Virtual Sink & Hardware Sink Routing**:
  - Automatic detection and categorization:
    - **Virtual Sinks** (e.g. `1. Master`, `2. Browser`, `3. Music`, `4. Comms`, `5. Games`, `6. Others`, null sinks, loopbacks)
    - **Hardware Sinks** (e.g. ALSA PCI, USB DAC, HDMI/DisplayPort, Bluetooth)
    - **Applications** (active per-app playback streams)
    - **Inputs** (microphones and line-in sources)
- ⭐ **Curated Mixer Channels ("Chosen Sinks")**:
  - Star/pin individual channels to curate your active mixer view.
  - Filter tabs in the popup: `Mixer`, `Virtual`, `Hardware`, `Apps`, `Inputs`.
- ➕ **On-the-Fly Virtual Sink Creation**:
  - Create new virtual audio channels instantly directly from the mixer popup with custom names (e.g. `Voice`, `Music`, `Soundboard`, `Discord`).
- ⚡ **Audio Precision Controls**:
  - Mute toggles (`M`) with illuminated indicator.
  - Set Default Sink button to switch the system's active audio route on the fly.
  - Double-click any fader to instantly reset volume to unity gain (100% / 0 dB).
  - Optional **Volume Boost** up to 150% (+3.5 dB).
  - Wheel scrolling on faders for fine 2% stepping.
  - Custom friendly aliases per channel configurable in settings.

---

## Installation

### Method 1: Local Development Symlink
Link the repository into your Dux Shell plugins directory:

```bash
mkdir -p ~/.config/dms/plugins
ln -s /home/mirai/git/dux_mixer ~/.config/dms/plugins/duxMixer
```

DMS will automatically discover the plugin on next startup or reload:

```bash
dms plugins list
```

Add the widget to your DankBar or Dock via **DMS Settings -> Bar -> Widgets** or **Control Center**.

---

## Architecture & File Structure

```
dux_mixer/
├── plugin.json               # Plugin manifest & capabilities
├── DuxMixerWidget.qml         # Main plugin widget (PluginComponent, DankBar pill, Popout)
├── MixerChannelStrip.qml      # Vertical console fader strip
├── MixerChannelRow.qml        # Horizontal rack slider row
├── MixerMasterStrip.qml       # Dedicated Master fader strip
├── MixerVuMeter.qml           # Real-time LED VU peak meter (PipeWire PeakMonitor)
├── MixerCreateSinkModal.qml   # On-the-fly virtual sink creation drawer
├── DuxMixerSettings.qml       # Plugin settings page in DMS Settings
├── MixerUtils.js              # Helpers for node classification, dB conversion & icons
├── RESEARCH_AND_PLAN.md       # Technical research & PipeWire architecture document
└── README.md                  # Plugin documentation
```

---

## Keyboard & Mouse Shortcuts

### Global Keyboard Shortcut (Toggle Overlay)
The plugin exposes a Quickshell IPC target (`duxMixer`) that toggles the mixer overlay on/off (displays it if hidden, hides it if currently displayed):

```bash
dms ipc call duxMixer toggle
```
*(Or using Quickshell directly: `qs ipc call duxMixer toggle`)*

**Example Compositor Keybindings:**
- **Hyprland (`~/.config/hypr/hyprland.conf`)**:
  ```ini
  bind = $mainMod, M, exec, dms ipc call duxMixer toggle
  ```
- **Niri (`~/.config/niri/config.kdl`)**:
  ```kdl
  Mod+M { spawn "dms" "ipc" "call" "duxMixer" "toggle"; }
  ```
- **Sway / i3 (`~/.config/sway/config`)**:
  ```ini
  bindsym $mod+m exec dms ipc call duxMixer toggle
  ```

### In-Mixer Mouse & Key Controls
- **Escape / Click Outside Backdrop**: Close the mixer overlay.
- **Click Fader**: Set volume to clicked level.
- **Drag Fader**: Smooth continuous volume adjustment.
- **Scroll Wheel over Fader**: Step volume up/down by 2%.
- **Double-Click Fader Knob**: Reset to 100% (0 dB unity gain).
- **Click 'M'**: Toggle channel mute.
- **Click Check / Radio**: Set device as current system default audio output.
- **Click Disc Icon (`album`)**: Set channel as the dedicated `MASTER` fader strip.
- **Click Star**: Pin / unpin channel from the curated Mixer view.

---

## License

MIT License
