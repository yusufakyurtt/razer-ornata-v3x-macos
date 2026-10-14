# Known Limitations & Technical Constraints

## 1. Hardware Architecture Limitations

### 1.1 Single-Zone RGB Lighting
The **Razer Ornata V3 X (RZ03-0447)** is built with a single-zone lighting zone spanning the entire keyboard membrane.
- **Limitation:** Per-key individually addressable RGB (such as Chroma Studio multi-layer effects, reactive ripple ripples radiating from pressed keys, or custom key-by-key coloring) is physically impossible on this hardware.
- **Design Impact:** Razer Control does not present a fake "Per-Key Chroma Studio" interface for this keyboard. It provides full control over the single-zone hardware effects that the keyboard actually supports: Static Color, Breathing (Single Color, Dual Color, Random), Spectrum Cycling, Wave, Brightness ($0..100\%$), and Backlight Off.

### 1.2 No Onboard Memory for Profiles or Remappings
- **Limitation:** The Ornata V3 X does not contain flash EEPROM for persistent onboard profiles or hardware-level key remapping tables.
- **Design Impact:** All profiles, key remappings, and macros are stored locally on the Mac (under `~/Library/Application Support/RazerControl/`) and executed dynamically in software. When Razer Control is not running, the keyboard operates with standard factory HID key codes.

---

## 2. macOS Platform & Permission Requirements

### 2.1 Accessibility & Input Monitoring Permissions
- **Accessibility:** Required for global key remapping (`CGEventTapCreate`), hotkey interception, and macro event simulation (`CGEventPost`).
- **Input Monitoring:** Required on macOS Catalina and later to observe global keyboard events when the application is in the background.
- **Design Impact:** Razer Control includes a dedicated Permissions Manager and onboarding flow that checks authorization status, guides the user to System Settings > Privacy & Security, and provides live status updates.

### 2.2 USB HID Device Exclusivity
- Standard keyboard typing events (Interface 0) are handled by macOS WindowServer. Razer Control never captures or logs user typing.
- Management commands are sent exclusively to the vendor feature interface (Interface 2, Max Feature Report Size 90 bytes). This ensures zero interference with normal system typing and no keystroke logging.
