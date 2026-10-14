import Foundation
import IOKit
import IOKit.hid

print("=== Testing Direct IOHID Communication with Ornata V3 X ===")

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchingDict: [String: Any] = [
    kIOHIDVendorIDKey as String: 0x1532,
    kIOHIDProductIDKey as String: 0x02A2
]
IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
let openRes = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print("IOHIDManagerOpen:", openRes)

guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
    print("No devices found")
    exit(1)
}

print("Found \(devices.count) matching IOHID devices")

func calcCrc(_ buf: inout [UInt8]) -> UInt8 {
    var crc: UInt8 = 0
    for i in 2..<88 {
        crc ^= buf[i]
    }
    return crc
}

for (idx, dev) in devices.enumerated() {
    let maxFeature = IOHIDDeviceGetProperty(dev, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0
    let primaryUsagePage = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
    let primaryUsage = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? Int ?? 0
    
    print("\nDevice [\(idx)]: UsagePage=0x\(String(format: "%04X", primaryUsagePage)), Usage=0x\(String(format: "%04X", primaryUsage)), MaxFeature=\(maxFeature)")
    
    if maxFeature >= 90 {
        print("-> Target device with 90-byte Feature Report!")
        
        let openDev = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        print("  IOHIDDeviceOpen:", openDev == kIOReturnSuccess ? "SUCCESS" : String(format: "0x%08X", openDev))
        
        // Build get serial request (Class: 0x00, CMD: 0x82, Size: 0x16)
        var req = [UInt8](repeating: 0, count: 90)
        req[0] = 0x00 // status
        req[1] = 0x1F // transaction id for Ornata V3 series
        req[2] = 0x00 // remaining packets
        req[3] = 0x00
        req[4] = 0x00 // protocol type
        req[5] = 0x16 // data size (22 bytes)
        req[6] = 0x00 // command class (device info)
        req[7] = 0x82 // command id (get serial)
        req[88] = calcCrc(&req)
        req[89] = 0x00
        
        print("  Sending get_serial request (90 bytes, CRC=0x\(String(format: "%02X", req[88])))...")
        let setRes = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, 0, req, req.count)
        print("  IOHIDDeviceSetReport result: \(setRes) (\(setRes == kIOReturnSuccess ? "SUCCESS" : String(format: "0x%08X", setRes)))")
        
        // Wait 10ms
        usleep(10000)
        
        var resp = [UInt8](repeating: 0, count: 90)
        var respLen = resp.count
        let getRes = IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, 0, &resp, &respLen)
        print("  IOHIDDeviceGetReport result: \(getRes) (\(getRes == kIOReturnSuccess ? "SUCCESS" : String(format: "0x%08X", getRes))), returned length: \(respLen)")
        
        if getRes == kIOReturnSuccess {
            print("  Response status: 0x\(String(format: "%02X", resp[0])) (0x02 = Success)")
            print("  Response transaction ID: 0x\(String(format: "%02X", resp[1]))")
            print("  Response class: 0x\(String(format: "%02X", resp[6]))")
            print("  Response cmd: 0x\(String(format: "%02X", resp[7]))")
            let serialBytes = Array(resp[8..<30])
            let serialStr = String(bytes: serialBytes.prefix(while: { $0 != 0 }), encoding: .utf8) ?? "None"
            print("  Received Serial Number: '\(serialStr)'")
            print("  Raw response bytes (first 32): \(resp.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " "))")
        }
        
        IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}
