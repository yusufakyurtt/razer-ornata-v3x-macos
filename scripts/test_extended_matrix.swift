import Foundation
import IOKit
import IOKit.hid

print("=== Testing Extended Matrix Commands on Physical Ornata V3 X ===")

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

// Test Extended Matrix Get Brightness: Class 0x0F, CMD 0x84, Size 0x03, args: [VARSTORE(0x01), ZERO_LED(0x00), 0x00]
print("\n1. Testing Class 0x0F (Extended Matrix) Get Brightness:")
for ledId in [UInt8(0x00), 0x01, 0x04, 0x05] {
    if let resp = sendReport(cmdClass: 0x0F, cmdId: 0x84, dataSize: 0x03, args: [0x01, ledId, 0x00]) {
        let status = resp[0]
        let val = resp[10]
        print("  LED ID 0x\(String(format: "%02X", ledId)): Status=0x\(String(format: "%02X", status)) (0x02=Success), Brightness=\(val)")
    }
}

// Test Keyboard Layout: Class 0x00, CMD 0x86, Size 0x02
print("\n2. Testing Keyboard Layout Query (0x00, 0x86):")
if let resp = sendReport(cmdClass: 0x00, cmdId: 0x86, dataSize: 0x02) {
    let status = resp[0]
    let layout = resp[8]
    print("  Status=0x\(String(format: "%02X", status)), Physical Layout code: 0x\(String(format: "%02X", layout))")
}

IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
