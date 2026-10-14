# Razer Control for Intel macOS
### Native macOS Alternative to Razer Synapse for Razer Ornata V3 X

**Razer Control** is a lightweight, high-performance, native macOS application designed specifically for the **Razer Ornata V3 X** gaming keyboard (model family `RZ03-0447`, USB VID `0x1532`, PID `0x02A2` / `0x0294`). Built from the ground up in pure **Swift** and **SwiftUI** for **Intel (`x86_64`) Macs**, it provides complete, reliable control without Razer Synapse, Windows, cloud accounts, or Electron overhead.

---

## Key Highlights

- **100% Native & Intel-Optimized**: Native Swift 6 / SwiftUI application compiled specifically for Intel `x86_64` macOS (macOS 13.0 Ventura or later).
- **Zero Mock / 100% Verified Hardware Communication**: Communicates directly with the physical Ornata V3 X using low-level macOS `IOHIDManager` feature reports. No fake firmware, no simulated telemetry.
- **Privacy-First & Fully Local**: Operates completely offline. Keystrokes, profiles, and settings never leave your machine (`~/Library/Application Support/RazerControl/`).
- **Bilingual & Adaptive Theming**: Full native English and Turkish localization with dynamic Dark, Light, and System appearance modes.

---

## Features

### 1. Dashboard
- Live hardware detection and connection status.
- Real device attributes extracted from hardware: Serial Number (`SI...`), Firmware Version (`v2.0`), USB Vendor ID (`0x1532`), Product ID (`0x02A2`), Location ID.
- Capability verification status matrix.
- System permissions monitor (Accessibility and Input Monitoring).
- Quick hardware toggles for Game Mode and Macro Mode indicator LEDs.

### 2. Keyboard Visualizer
- Interactive, responsive rendering of the full 104/105-key physical layout.
- Real-time visual feedback on key presses via event monitoring.
- Visual display of active remaps and hardware indicator states.

### 3. Lighting Studio
- Full hardware lighting control via verified 90-byte Extended Matrix Class `0x0F` reports:
  - **Static**: Custom RGB color.
  - **Breathing**: Single color or Dual color fading.
  - **Spectrum Cycling**: Smooth cycling through the full RGB spectrum.
  - **Wave**: Animated gradient wave across the lighting layer.
  - **Off**: Complete backlight power cutoff.
- Hardware brightness control (0%–100%) mapped directly to device registers `0x00`–`0xFF`.
- Direct hardware indicator controls: Game Mode LED ('G') and Macro Mode LED ('M') toggling via Class `0x03`.

### 4. Key Remapping
- Low-level key remapping powered by a native macOS `CGEventTap` engine.
- Remap physical keys to any standard key code with optional modifier flags (Cmd, Opt, Ctrl, Shift).
- Key disablement / mute capability.
- Audible feedback clicks (optional) on remapped keystrokes.
- Safe pass-through mode during editing.

### 5. Macro Studio
- Real-time keystroke macro recorder with millisecond delay precision.
- Execution options: Play Once, Repeat N times, Repeat while held, Toggle continuous loop.
- Built-in safe stop shortcut (`Escape` or `Cmd+.`).
- Profile-aware macro assignment.

### 6. Profiles & Auto-Switching
- Unlimited custom profiles saving lighting effects, key mappings, and macro bindings.
- Automatic profile switching based on active frontmost application bundle ID (e.g., auto-switch to gaming profile when running Steam or a game).
- Profile export and import as clean, human-readable JSON.

### 7. Diagnostics & Logging
- Live streaming diagnostic log capturing USB/HID transactions, event taps, and profile switches.
- Direct capability inspection matrix with verification status.
- One-click diagnostic report exporter.

### 8. System & Appearance
- Dark, Light, and System match appearance settings.
- English and Turkish language switcher.
- Launch at login configuration.
- Optional background menu bar icon for quick lighting and profile switching.

---

## Hardware Research & Physical Limitations

Extensive physical reverse engineering was conducted on the physical Razer Ornata V3 X. See [`docs/HARDWARE_RESEARCH.md`](docs/HARDWARE_RESEARCH.md) and [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md) for complete technical reports.

1. **Single-Zone Lighting**: The Ornata V3 X is mechanically built with a single translucent diffuser plate covering all keys, illuminated by a shared backlight bus. It **physically cannot** display per-key RGB colors. The application truthfully displays single-zone controls and does not simulate impossible per-key effects.
2. **Lighting Protocol Specifics**: Standard Chroma Class `0x03` commands for backlighting return `0x05` (unsupported). Lighting must be sent via Extended Matrix Class `0x0F` (CMD `0x02` for effects, CMD `0x04` for brightness). Indicator LEDs, however, use Class `0x03` CMD `0x00`.
3. **No Onboard Memory**: The Ornata V3 X does not contain onboard flash memory for storing key remappings or profiles when unplugged. All key remapping, macros, and profile switching are handled natively by the host application via macOS event taps.

---

## System Requirements & Permissions

### Requirements
- **Hardware**: Intel (`x86_64`) Mac (or Apple Silicon via Rosetta 2).
- **Operating System**: macOS 13.0 (Ventura) or newer (macOS 14 Sonoma / macOS 15 Sequoia / macOS 26 fully supported).
- **Target Device**: Razer Ornata V3 X (USB VID `0x1532`, PID `0x02A2` or `0x0294`).

### Permissions Required
- **Accessibility**: Required for `CGEventTap` to intercept and remap keystrokes as well as dispatch macro actions.
- **Input Monitoring**: Required for live keyboard visualizer event listening.
- Both permissions can be granted under **System Settings > Privacy & Security > Accessibility** and **Input Monitoring**. The application includes an in-app setup assistant to open these preference panes directly.

---

## Installation & Running

### Option 1: Using the `.dmg` Installer (Recommended)
1. Download **`Razer-Control-v1.0.0-macOS-x86_64.dmg`** from GitHub Releases.
2. Double-click the DMG and drag **`Razer Control`** into your **`Applications`** folder.
3. Launch the app and grant Accessibility permissions when prompted.

### Option 2: Building from Source
Ensure Xcode Command Line Tools or full Xcode is installed:

```bash
# Clone or navigate to the repository
cd razer-ornata-v3x

# Run automated tests
swift test

# Build release application bundle and DMG installer
./scripts/create_dmg.sh
```

---

## Project Structure

```
razer-ornata-v3x/
├── Package.swift                    # Swift Package Manager manifest
├── Sources/
│   ├── RazerControl/                # Executable target & main entry point
│   │   └── main.swift
│   └── RazerControlKit/             # Modular framework target
│       ├── AppDelegate.swift        # AppKit lifecycle & status item
│       ├── Models/                  # Device, Lighting, Profile, Macro, Settings
│       ├── Services/                # HID Protocol, Discovery, Lighting, Remap, Macro
│       ├── ViewModels/              # MVVM ViewModels for all views
│       ├── Views/                   # Native SwiftUI interfaces & components
│       └── Resources/               # Localization strings (.lproj)
├── Tests/
│   └── RazerControlTests/           # Automated test suite (7/7 passing)
├── scripts/
│   ├── build_release_app.sh         # Release packaging and code-signing script
│   └── test_device_comm.swift       # Direct hardware verification script
├── docs/
│   ├── HARDWARE_RESEARCH.md         # Deep-dive USB/HID reverse engineering notes
│   ├── HARDWARE_TEST_RESULTS.md     # Verified test log on physical device
│   ├── KNOWN_LIMITATIONS.md         # Truthful hardware constraints
│   └── ARCHITECTURE.md              # Software design & architectural blueprint
└── build/
    └── Razer Control.app            # Distributable signed macOS application bundle
```

---

## Automated Tests

To run the unit test suite covering protocol packet generation, XOR checksum verification, lighting effects, remapping, and serialization:

```bash
swift test
```

---

## License

MIT License. Designed with integrity for the native macOS and open-source keyboard community.
