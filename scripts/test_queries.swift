import Foundation
import IOKit
import IOKit.hid

print("=== Testing Hardware Queries on Physical Ornata V3 X ===")

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchingDict: [String: Any] = [
    kIOHIDVendorIDKey as String: 0x1532,
    kIOHIDProductIDKey as String: 0x02A2
]
IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
_ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
      let dev = devices.first(where: {
          (IOHIDDeviceGetProperty($0, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0) >= 90
      }) else {
    print("Could not find feature device")
    exit(1)
}

_ = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))

func calcCrc(_ buf: inout [UInt8]) -> UInt8 {
    var crc: UInt8 = 0
    for i in 2..<88 {
        crc ^= buf[i]
    }
    return crc
}

func sendReport(cmdClass: UInt8, cmdId: UInt8, dataSize: UInt8, args: [UInt8] = []) -> [UInt8]? {
    var req = [UInt8](repeating: 0, count: 90)
    req[0] = 0x00
    req[1] = 0x1F // Transaction ID for Ornata V3 X
    req[2] = 0x00
    req[3] = 0x00
    req[4] = 0x00
    req[5] = dataSize
    req[6] = cmdClass
    req[7] = cmdId
    for (i, b) in args.enumerated() {
        if i < 80 { req[8 + i] = b }
    }
    req[88] = calcCrc(&req)
    req[89] = 0x00
    
    let setRes = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, 0, req, req.count)
    if setRes != kIOReturnSuccess {
        print("  SetReport error: 0x\(String(format: "%08X", setRes))")
        return nil
    }
    
    usleep(10000) // 10ms
    
    var resp = [UInt8](repeating: 0, count: 90)
    var respLen = resp.count
    let getRes = IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, 0, &resp, &respLen)
    if getRes != kIOReturnSuccess {
        print("  GetReport error: 0x\(String(format: "%08X", getRes))")
        return nil
    }
    return resp
}

// 1. Query Firmware Version (0x00, 0x81, 0x02)
if let fwResp = sendReport(cmdClass: 0x00, cmdId: 0x81, dataSize: 0x02) {
    print("Firmware Version Query Status: 0x\(String(format: "%02X", fwResp[0]))")
    print("Firmware bytes: major=\(fwResp[8]), minor=\(fwResp[9]) (v\(fwResp[8]).\(fwResp[9]))")
}

// 2. Query Serial (0x00, 0x82, 0x16)
if let serResp = sendReport(cmdClass: 0x00, cmdId: 0x82, dataSize: 0x16) {
    let serialBytes = Array(serResp[8..<30])
    let serialStr = String(bytes: serialBytes.prefix(while: { $0 != 0 }), encoding: .utf8) ?? "None"
    print("Serial Number: '\(serialStr)'")
}

// 3. Query Device Mode (0x00, 0x84, 0x02)
if let modeResp = sendReport(cmdClass: 0x00, cmdId: 0x84, dataSize: 0x02) {
    print("Device Mode Query Status: 0x\(String(format: "%02X", modeResp[0])), mode: 0x\(String(format: "%02X", modeResp[8])), param: 0x\(String(format: "%02X", modeResp[9]))")
}

// 4. Query Backlight Brightness (0x03, 0x83, 0x03, args: [VARSTORE(0x01), BACKLIGHT_LED(0x05), 0x00])
if let brResp = sendReport(cmdClass: 0x03, cmdId: 0x83, dataSize: 0x03, args: [0x01, 0x05, 0x00]) {
    print("Backlight Brightness Query Status: 0x\(String(format: "%02X", brResp[0]))")
    print("Backlight Brightness value: \(brResp[10]) / 255 (\(Int(Double(brResp[10]) / 255.0 * 100))%)")
    print("Backlight raw args: \(brResp[8..<14].map { String(format: "%02X", $0) }.joined(separator: " "))")
}

// 5. Query LED Effect (0x03, 0x82, 0x03, args: [VARSTORE(0x01), BACKLIGHT_LED(0x05), 0x00])
if let effResp = sendReport(cmdClass: 0x03, cmdId: 0x82, dataSize: 0x03, args: [0x01, 0x05, 0x00]) {
    print("Backlight Effect Query Status: 0x\(String(format: "%02X", effResp[0]))")
    print("Backlight Effect ID: \(effResp[10])")
    print("Backlight Effect raw args: \(effResp[8..<14].map { String(format: "%02X", $0) }.joined(separator: " "))")
}

IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
print("=== Queries Complete ===")
