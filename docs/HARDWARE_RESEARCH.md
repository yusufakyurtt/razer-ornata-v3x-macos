# Razer Ornata V3 X Hardware Research & Protocol Specification

## 1. Executive Summary

This document records the exact hardware investigation and protocol reverse-engineering findings for the connected physical keyboard: **Razer Ornata V3 X (Model Family RZ03-0447)**. All findings in this document have been empirically validated against the physical device connected to the development Mac.

---

## 2. Verified Device Identification

| Property | Value | Notes |
|---|---|---|
| **Product Name** | Razer Ornata V3 X | Queried from USB Device Descriptor & IOHIDDevice |
| **Manufacturer** | Razer | Vendor String |
| **USB Vendor ID (VID)** | `0x1532` (5426) | Official Razer USA, Ltd. Vendor ID |
| **USB Product ID (PID)** | `0x02A2` (674) | Razer Ornata V3 X Alternate Hardware Variant (Base variant is `0x0294`) |
| **Device Serial Number** | `SI2418F72000990` | Directly queried from device firmware via report `(0x00, 0x82)` |
| **Firmware Version** | `v2.0` (Major: 2, Minor: 0) | Directly queried from device firmware via report `(0x00, 0x81)` |
| **Physical Layout Code** | `0x0A` | Queried via report `(0x00, 0x86)` |
| **Device Location ID** | `0x14500000` | USB 2.0 Port Location |
| **Device Speed** | Full Speed (12 Mbps) | Standard USB HID |

---

## 3. Enumerated HID Interfaces

The Razer Ornata V3 X exposes 3 HID device collections under macOS:

### Interface 0: Standard Keyboard
- **Primary Usage Page:** `0x0001` (Generic Desktop)
- **Primary Usage:** `0x0006` (Keyboard)
- **Max Input Report Size:** 8 bytes (Standard 6KRO boot protocol report)
- **Max Output Report Size:** 1 byte (Standard Keyboard LEDs: NumLock, CapsLock, ScrollLock)
- **Max Feature Report Size:** 0 bytes
- **Role:** Handles typing input keystrokes sent to macOS WindowServer.

### Interface 1: Consumer & System Control
- **Primary Usage Page:** `0x0001` (Generic Desktop)
- **Primary Usage:** `0x0006` (Keyboard / Consumer)
- **Max Input Report Size:** 16 bytes
- **Max Output Report Size:** 1 byte
- **Max Feature Report Size:** 1 byte
- **Role:** Handles consumer media keys (volume up/down, mute, play/pause, media navigation).

### Interface 2: Vendor Hardware Management Interface
- **Primary Usage Page:** `0x0001` (Generic Desktop)
- **Primary Usage:** `0x0002` (Mouse / Vendor Extension)
- **Report Descriptor Includes:** Vendor-defined collection (`UsagePage 0xFF00`, `Usage 0x02`)
- **Max Input Report Size:** 8 bytes
- **Max Output Report Size:** 0 bytes
- **Max Feature Report Size:** 90 bytes (`0x5A`)
- **Accessibility:** Accessible via native macOS `IOKit.hid` APIs (`IOHIDManager`, `IOHIDDeviceOpen`, `IOHIDDeviceSetReport`, `IOHIDDeviceGetReport`) without requiring kernel extensions, driver plugins, or root privileges.
- **Role:** Receives and responds to all Razer Chroma lighting, brightness, effect, indicator LED, and hardware telemetry commands.

---

## 4. Razer USB HID Feature Protocol Specification

Communication with Interface 2 is performed using **90-byte Feature Reports** (`kIOHIDReportTypeFeature`, Report ID `0x00`).

### 4.1 90-Byte Packet Structure

```
Offset (Bytes)  Size    Field Name              Description
---------------------------------------------------------------------------------------
0               1       status                  0x00 in request. Device returns status in response:
                                                0x01: Busy
                                                0x02: Successful / Command Acknowledged
                                                0x03: Command Failure
                                                0x04: Timeout
                                                0x05: Command Not Supported
1               1       transaction_id          For Ornata V3 X: 0x1F
2..3            2       remaining_packets       0x0000 (Big Endian)
4               1       protocol_type           0x00
5               1       data_size               Number of parameter bytes in arguments[]
6               1       command_class           Command category (0x00=Device, 0x03=Standard LED, 0x0F=Extended Matrix)
7               1       command_id              Specific command identifier
8..87           80      arguments               Payload parameters (zero-padded)
88              1       crc                     XOR checksum of bytes 2 through 87 inclusive
89              1       reserved                0x00
```

### 4.2 Checksum Calculation
The checksum byte at index 88 is computed as:
$$\text{crc} = \bigoplus_{i=2}^{87} \text{packet}[i]$$

---

## 5. Confirmed Command Set for Ornata V3 X

Empirically verified on physical device:

### 5.1 Device Information & Status
- **Get Firmware Version:** `Class 0x00`, `CMD 0x81`, `Size 0x02` $\rightarrow$ Returns `Major, Minor` at offset `8..9`.
- **Get Serial Number:** `Class 0x00`, `CMD 0x82`, `Size 0x16` $\rightarrow$ Returns ASCII string at offset `8..29`.
- **Get Device Mode:** `Class 0x00`, `CMD 0x84`, `Size 0x02` $\rightarrow$ Returns operational mode.
- **Get Keyboard Layout:** `Class 0x00`, `CMD 0x86`, `Size 0x02` $\rightarrow$ Returns layout byte `0x0A`.

### 5.2 Lighting & Brightness Control (Extended Matrix: Class `0x0F`)
The Ornata V3 X features a **single-zone Chroma lighting matrix** (1x1 LED matrix) controlled via the Extended Matrix protocol (Class `0x0F`).

- **Get Brightness:**
  - Request: `Class 0x0F`, `CMD 0x84`, `Size 0x03`, `Args: [0x01, 0x00, 0x00]`
  - Response: Returns brightness byte ($0..255$) at offset 10.
- **Set Brightness:**
  - Request: `Class 0x0F`, `CMD 0x04`, `Size 0x03`, `Args: [0x01, 0x00, Brightness(0..255)]`
  - Response: Status `0x02` (Success).
- **Set Static Color:**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x09`, `Args: [0x01, 0x05, 0x01, 0x00, 0x00, 0x01, R, G, B]`
  - Response: Status `0x02` (Success). Keyboard immediately displays chosen static color.
- **Set Breathing (Single Color):**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x09`, `Args: [0x01, 0x05, 0x02, 0x01, 0x00, 0x01, R, G, B]`
  - Response: Status `0x02` (Success). Keyboard pulses chosen color.
- **Set Breathing (Dual Color):**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x0C`, `Args: [0x01, 0x05, 0x02, 0x02, 0x00, 0x02, R1, G1, B1, R2, G2, B2]`
  - Response: Status `0x02` (Success). Keyboard pulses between color 1 and color 2.
- **Set Breathing (Random):**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x06`, `Args: [0x01, 0x05, 0x02, 0x00, 0x00, 0x00]`
  - Response: Status `0x02` (Success). Keyboard cycles randomly breathing.
- **Set Spectrum Cycling:**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x06`, `Args: [0x01, 0x05, 0x03, 0x00, 0x00, 0x00]`
  - Response: Status `0x02` (Success). Keyboard smoothly cycles through RGB rainbow spectrum.
- **Set Wave Effect:**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x06`, `Args: [0x01, 0x05, 0x04, direction(0x01=left, 0x02=right), 0x28, 0x00]`
  - Response: Status `0x02` (Success).
- **Set Lighting Off (None):**
  - Request: `Class 0x0F`, `CMD 0x02`, `Size 0x06`, `Args: [0x01, 0x05, 0x00, 0x00, 0x00, 0x00]`
  - Response: Status `0x02` (Success). Keyboard turns off backlighting.

### 5.3 Indicator LEDs (Class `0x03`)
- **Game Mode LED (Indicator 'G'):**
  - Query: `Class 0x03`, `CMD 0x80`, `Size 0x03`, `Args: [0x01, 0x08, 0x00]`
  - Set: `Class 0x03`, `CMD 0x00`, `Size 0x03`, `Args: [0x01, 0x08, 0x01 (ON) / 0x00 (OFF)]`
  - Response: Status `0x02` (Success). Physical LED toggles immediately.
- **Macro Mode LED (Indicator 'M'):**
  - Query: `Class 0x03`, `CMD 0x80`, `Size 0x03`, `Args: [0x01, 0x07, 0x00]`
  - Set: `Class 0x03`, `CMD 0x00`, `Size 0x03`, `Args: [0x01, 0x07, 0x01 (ON) / 0x00 (OFF)]`
  - Response: Status `0x02` (Success).

---

## 6. Hardware Architectural Constraints & Realities

1. **Single-Zone Lighting:** The Ornata V3 X is physically manufactured as a single-zone translucent lighting membrane keyboard. Unlike the higher-end Ornata V3 (non-X) or Huntsman series, it cannot illuminate individual keys independently.
2. **No Onboard Hardware Memory for Profiles:** The Ornata V3 X does not include onboard EEPROM/flash memory for storing user profiles, key remapping tables, or macros in device firmware. All profile switching, macro playback, and key remappings must be executed host-side via macOS event taps and software engines.
3. **Firmware Lighting Persistence:** The device does remember its last active lighting effect and brightness across soft reboots while USB power is maintained, but reverts to default spectrum cycling on cold power cycle if Synapse or Razer Control is not running.
