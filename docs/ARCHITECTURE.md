# Razer Control Architecture Document

## 1. System Overview

**Razer Control** is a native macOS application engineered in Swift and SwiftUI, targeting Intel (`x86_64`) Macs, designed as a full-featured, local alternative to Razer Synapse for the **Razer Ornata V3 X (Model Family RZ03-0447, VID 0x1532, PID 0x02A2)**.

The application follows a clean, modular Model-View-ViewModel (MVVM) architecture with strict separation between user interface, business logic, persistence, and hardware communication.

---

## 2. Architecture Layers

```
+-------------------------------------------------------------------+
|                           SwiftUI Views                           |
|  Dashboard | Keyboard | Lighting | KeyRemap | Macro | Profile |   |
|            Settings | Diagnostics | Sidebar | Modal Alerts        |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                            ViewModels                             |
|  AppViewModel | DashboardVM | LightingStudioVM | KeyRemappingVM   |
|  MacroStudioVM | ProfilesVM | SettingsVM | DiagnosticsVM         |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                          Service Layer                            |
|  - DeviceDiscoveryService (IOHIDManager event loop)               |
|  - RazerDeviceSession (Bidirectional 90-byte Feature Reports)     |
|  - LightingService (Single-zone effects, brightness, live sync)   |
|  - KeyRemappingEngine (CGEventTap / IOHIDEvent software dispatch) |
|  - MacroEngine (Synthetic event generation & state safety)        |
|  - ProfileManager (Active profile switching & application link)   |
|  - PersistenceService (Atomic JSON storage under App Support)     |
|  - PermissionService (Accessibility / Input Monitoring TCC check) |
|  - DiagnosticService (Structured logging & real-time telemetry)   |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                       macOS Native Subsystems                     |
|  IOKit.hid (IOHIDManager) | CoreGraphics (CGEvent) | AppKit       |
+-------------------------------------------------------------------+
```

---

## 3. Module Responsibilities

### 3.1 Device Discovery & Session Management (`Services/DeviceDiscovery`, `Services/HID`)
- Monitors USB and HID attachment/detachment events using native `IOHIDManager`.
- Specifically filters for Vendor ID `0x1532` and Product ID `0x02A2` (Ornata V3 X).
- Automatically isolates the vendor management collection (Interface 2, Max Feature Report Size 90 bytes).
- Implements `RazerDeviceSession` which owns thread-safe bidirectional communications (`IOHIDDeviceSetReport` and `IOHIDDeviceGetReport`).
- Thread safety: all hardware writes and reads run asynchronously on a dedicated serial background queue (`razer.hid.comm.queue`), never blocking the main UI thread.

### 3.2 Lighting Studio (`Services/Lighting`, `ViewModels/LightingStudioViewModel`)
- Translates UI lighting adjustments into validated 90-byte Extended Matrix (Class `0x0F`) command packets.
- Implements:
  - Static Color (`0x0F, 0x02, 0x09`)
  - Breathing Effect (`0x0F, 0x02, 0x09` or `0x0C`)
  - Spectrum Cycling (`0x0F, 0x02, 0x06`)
  - Wave Effect (`0x0F, 0x02, 0x06`)
  - Backlight Off (`0x0F, 0x02, 0x06`)
  - Hardware Brightness Query & Setting (`0x0F, 0x84` & `0x0F, 0x04`)
  - Indicator LEDs (Game Mode & Macro Mode: `0x03, 0x00`)
- Validates every response packet's status byte (`0x02` = Success) and logs telemetry.

### 3.3 Key Remapping Engine (`Services/KeyRemapping`)
- Implements non-destructive, host-level key remapping using a low-overhead `CGEventTap` at `kCGHeadInsertEventTap`.
- Intercepts designated key codes from the connected keyboard and synthesizes remapped target keys or shortcuts.
- Safety measures:
  - Tracks key-down and key-up states to guarantee modifier keys (Command, Option, Control, Shift) never remain stuck.
  - Automatically resets synthetic key states upon application deactivation, profile switch, or device disconnection.
  - Passes through untranslated events with minimal latency ($< 1$ ms).

### 3.4 Macro Studio & Playback Engine (`Services/MacroEngine`)
- Allows authoring and recording sequences of key presses, modifier combinations, and configurable delays.
- Playback dispatches synthetic `CGEvent` instances on an asynchronous background queue with strict watchdog timers.
- Safety: Includes an emergency cancellation shortcut (Escape / Stop button) and automatic release of all keys on cancel or error.

### 3.5 Persistence & Profile Management (`Services/Persistence`, `Services/Profiles`)
- Persists all settings, profiles, key mappings, and macros as Codable JSON files in `~/Library/Application Support/RazerControl/`.
- Uses atomic file replacement (`write(to:options: .atomic)`) to guarantee data integrity against system crashes or sudden termination.
- Schema versioning ensures backwards compatibility and migration safety.

### 3.6 Permissions & Privacy (`Services/Permissions`)
- Inspects macOS Accessibility permissions using `AXIsProcessTrustedWithOptions`.
- Verifies Input Monitoring authorization.
- Provides an onboarding banner and direct deep-links to System Settings > Privacy & Security.
- Zero remote telemetry, zero external tracking, zero cloud dependencies. Keystrokes are never logged to disk or transmitted over the network.
