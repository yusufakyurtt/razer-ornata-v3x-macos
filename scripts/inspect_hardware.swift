import Foundation
import IOKit
import IOKit.hid

print("=== Razer Ornata V3 X Hardware Inspector ===")

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchingDict: [String: Any] = [
    kIOHIDVendorIDKey as String: 0x1532
]

IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print("IOHIDManagerOpen status: \(openStatus) (\(openStatus == kIOReturnSuccess ? "SUCCESS" : "ERROR: \(String(format: "0x%08x", openStatus))"))")

guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
    print("No matching Razer devices found via IOHIDManager!")
    exit(1)
}

print("Found \(deviceSet.count) matching IOHIDDevice(s):")

for (idx, device) in deviceSet.enumerated() {
    print("\n--- Device [\(idx + 1)/\(deviceSet.count)] ---")
    let getProp = { (key: String) -> Any? in
        return IOHIDDeviceGetProperty(device, key as CFString)
    }
    
    let product = getProp(kIOHIDProductKey as String) as? String ?? "Unknown"
    let manufacturer = getProp(kIOHIDManufacturerKey as String) as? String ?? "Unknown"
    let vendorId = getProp(kIOHIDVendorIDKey as String) as? Int ?? 0
    let productId = getProp(kIOHIDProductIDKey as String) as? Int ?? 0
    let serial = getProp(kIOHIDSerialNumberKey as String) as? String ?? "None"
    let locationId = getProp(kIOHIDLocationIDKey as String) as? Int ?? 0
    let transport = getProp(kIOHIDTransportKey as String) as? String ?? "Unknown"
    let primaryUsagePage = getProp(kIOHIDPrimaryUsagePageKey as String) as? Int ?? 0
    let primaryUsage = getProp(kIOHIDPrimaryUsageKey as String) as? Int ?? 0
    let maxInput = getProp(kIOHIDMaxInputReportSizeKey as String) as? Int ?? 0
    let maxOutput = getProp(kIOHIDMaxOutputReportSizeKey as String) as? Int ?? 0
    let maxFeature = getProp(kIOHIDMaxFeatureReportSizeKey as String) as? Int ?? 0
    
    print("  Product: \(product)")
    print("  Manufacturer: \(manufacturer)")
    print("  Vendor ID: \(String(format: "0x%04X", vendorId)) (\(vendorId))")
    print("  Product ID: \(String(format: "0x%04X", productId)) (\(productId))")
    print("  Serial Number: \(serial)")
    print("  Location ID: \(String(format: "0x%08X", locationId))")
    print("  Transport: \(transport)")
    print("  Usage Page: \(primaryUsagePage) (0x\(String(format: "%04X", primaryUsagePage)))")
    print("  Usage: \(primaryUsage) (0x\(String(format: "%04X", primaryUsage))")
    print("  Max Input Report Size: \(maxInput) bytes")
    print("  Max Output Report Size: \(maxOutput) bytes")
    print("  Max Feature Report Size: \(maxFeature) bytes")
    
    // Check report descriptor if available
    if let reportDescData = getProp(kIOHIDReportDescriptorKey as String) as? Data {
        print("  Report Descriptor: \(reportDescData.count) bytes: \(reportDescData.map { String(format: "%02x", $0) }.joined(separator: " "))")
    } else {
        print("  Report Descriptor: Not available via property")
    }
}
