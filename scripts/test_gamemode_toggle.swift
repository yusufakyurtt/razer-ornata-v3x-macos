import Foundation
import IOKit
import IOKit.hid

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
      }) else { exit(1) }
_ = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))

func calcCrc(_ buf: inout [UInt8]) -> UInt8 {
    var crc: UInt8 = 0
    for i in 2..<88 { crc ^= buf[i] }
    return crc
}

func sendReport(cmdClass: UInt8, cmdId: UInt8, dataSize: UInt8, args: [UInt8] = []) -> (status: UInt8, resp: [UInt8]) {
    var req = [UInt8](repeating: 0, count: 90)
    req[0] = 0x00
    req[1] = 0x1F
    req[5] = dataSize
    req[6] = cmdClass
    req[7] = cmdId
    for (i, b) in args.enumerated() { if i < 80 { req[8 + i] = b } }
    req[88] = calcCrc(&req)
    _ = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, 0, req, req.count)
    usleep(15000)
    var resp = [UInt8](repeating: 0, count: 90)
    var respLen = resp.count
    _ = IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, 0, &resp, &respLen)
    return (resp[0], resp)
}

print("Enabling Game Mode Indicator LED...")
let resOn = sendReport(cmdClass: 0x03, cmdId: 0x00, dataSize: 0x03, args: [0x01, 0x08, 0x01])
print("  Response: 0x\(String(format: "%02X", resOn.status))")

sleep(1)

print("Disabling Game Mode Indicator LED...")
let resOff = sendReport(cmdClass: 0x03, cmdId: 0x00, dataSize: 0x03, args: [0x01, 0x08, 0x00])
print("  Response: 0x\(String(format: "%02X", resOff.status))")

IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
print("Game Mode LED test finished successfully.")
