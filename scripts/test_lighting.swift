import Foundation
import IOKit
import IOKit.hid

print("=== Physical Lighting Test on Razer Ornata V3 X ===")

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

func sendReport(cmdClass: UInt8, cmdId: UInt8, dataSize: UInt8, args: [UInt8] = []) -> (status: UInt8, resp: [UInt8]) {
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
        return (0xFF, [])
    }
    
    usleep(20000) // 20ms
    
    var resp = [UInt8](repeating: 0, count: 90)
    var respLen = resp.count
    let getRes = IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, 0, &resp, &respLen)
    if getRes != kIOReturnSuccess {
        print("  GetReport error: 0x\(String(format: "%08X", getRes))")
        return (0xFE, [])
    }
    return (resp[0], resp)
}

// 1. Get original brightness
let origBr = sendReport(cmdClass: 0x0F, cmdId: 0x84, dataSize: 0x03, args: [0x01, 0x00, 0x00])
print("Original Brightness: Status=0x\(String(format: "%02X", origBr.status)), Value=\(origBr.resp.count > 10 ? origBr.resp[10] : 0)")

// 2. Test Setting Static Green (R:0, G:255, B:0)
print("\n[TEST 1] Setting Static Razer Green (0, 255, 0)...")
// args: [VARSTORE(0x01), BACKLIGHT_LED(0x05), Static(0x01), 0x00, 0x00, 0x01, R, G, B]
let greenArgs: [UInt8] = [0x01, 0x05, 0x01, 0x00, 0x00, 0x01, 0x00, 0xFF, 0x00]
let setGreen = sendReport(cmdClass: 0x0F, cmdId: 0x02, dataSize: 0x09, args: greenArgs)
print("  Static Green response status: 0x\(String(format: "%02X", setGreen.status)) (\(setGreen.status == 0x02 ? "SUCCESS - HARDWARE ACCEPTED" : "FAILED"))")
sleep(1)

// 3. Test Setting Static Red (R:255, G:0, B:0)
print("\n[TEST 2] Setting Static Bright Red (255, 0, 0)...")
let redArgs: [UInt8] = [0x01, 0x05, 0x01, 0x00, 0x00, 0x01, 0xFF, 0x00, 0x00]
let setRed = sendReport(cmdClass: 0x0F, cmdId: 0x02, dataSize: 0x09, args: redArgs)
print("  Static Red response status: 0x\(String(format: "%02X", setRed.status)) (\(setRed.status == 0x02 ? "SUCCESS - HARDWARE ACCEPTED" : "FAILED"))")
sleep(1)

// 4. Test Setting Static Blue (R:0, G:128, B:255)
print("\n[TEST 3] Setting Static Cyan/Blue (0, 128, 255)...")
let blueArgs: [UInt8] = [0x01, 0x05, 0x01, 0x00, 0x00, 0x01, 0x00, 0x80, 0xFF]
let setBlue = sendReport(cmdClass: 0x0F, cmdId: 0x02, dataSize: 0x09, args: blueArgs)
print("  Static Blue response status: 0x\(String(format: "%02X", setBlue.status)) (\(setBlue.status == 0x02 ? "SUCCESS - HARDWARE ACCEPTED" : "FAILED"))")
sleep(1)

// 5. Test Breathing Effect (Single Color Green)
print("\n[TEST 4] Setting Breathing Effect (Green)...")
// args: [VARSTORE(0x01), BACKLIGHT_LED(0x05), Breathing(0x02), 0x01, 0x00, 0x01, R, G, B]
let breathArgs: [UInt8] = [0x01, 0x05, 0x02, 0x01, 0x00, 0x01, 0x00, 0xFF, 0x00]
let setBreath = sendReport(cmdClass: 0x0F, cmdId: 0x02, dataSize: 0x09, args: breathArgs)
print("  Breathing response status: 0x\(String(format: "%02X", setBreath.status)) (\(setBreath.status == 0x02 ? "SUCCESS - HARDWARE ACCEPTED" : "FAILED"))")
sleep(1)

// 6. Test Spectrum Cycling Effect
print("\n[TEST 5] Setting Spectrum Cycling Effect...")
// args: [VARSTORE(0x01), BACKLIGHT_LED(0x05), Spectrum(0x03), 0x00, 0x00, 0x00]
let specArgs: [UInt8] = [0x01, 0x05, 0x03, 0x00, 0x00, 0x00]
let setSpec = sendReport(cmdClass: 0x0F, cmdId: 0x02, dataSize: 0x06, args: specArgs)
print("  Spectrum response status: 0x\(String(format: "%02X", setSpec.status)) (\(setSpec.status == 0x02 ? "SUCCESS - HARDWARE ACCEPTED" : "FAILED"))")
sleep(1)

// 7. Test Brightness Setting
print("\n[TEST 6] Testing Brightness Adjustment (Setting to 150)...")
// args: [VARSTORE(0x01), ZERO_LED(0x00), Brightness(150)]
let setBr = sendReport(cmdClass: 0x0F, cmdId: 0x04, dataSize: 0x03, args: [0x01, 0x00, 150])
print("  Set Brightness response status: 0x\(String(format: "%02X", setBr.status))")
let checkBr = sendReport(cmdClass: 0x0F, cmdId: 0x84, dataSize: 0x03, args: [0x01, 0x00, 0x00])
print("  Verified new brightness: \(checkBr.resp.count > 10 ? checkBr.resp[10] : 0)")

// Restore original brightness
let origVal = origBr.resp.count > 10 ? origBr.resp[10] : 224
_ = sendReport(cmdClass: 0x0F, cmdId: 0x04, dataSize: 0x03, args: [0x01, 0x00, origVal])
print("\nRestored original brightness: \(origVal)")

IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
print("=== Lighting Tests Complete ===")
