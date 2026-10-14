import Foundation
import IOKit
import IOKit.hid

public protocol RazerDeviceSessionProtocol: AnyObject {
    var isConnected: Bool { get }
    func sendCommand(cmdClass: UInt8, cmdId: UInt8, dataSize: UInt8, args: [UInt8]) -> Result<[UInt8], Error>
    func sendReport(_ report: [UInt8]) -> Result<[UInt8], Error>
}

public enum RazerHIDError: LocalizedError {
    case deviceNotConnected
    case deviceOpenFailed(IOReturn)
    case setReportFailed(IOReturn)
    case getReportFailed(IOReturn)
    case commandFailed(UInt8)
    case invalidReportLength(Int)
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotConnected:
            return "Razer keyboard is not connected."
        case .deviceOpenFailed(let code):
            return "Failed to open HID device (error 0x\(String(format: "%08X", code)))."
        case .setReportFailed(let code):
            return "Failed to write HID feature report (error 0x\(String(format: "%08X", code)))."
        case .getReportFailed(let code):
            return "Failed to read HID feature report (error 0x\(String(format: "%08X", code)))."
        case .commandFailed(let status):
            return "Device rejected command (status 0x\(String(format: "%02X", status)))."
        case .invalidReportLength(let len):
            return "Invalid report length returned: \(len) bytes."
        case .timeout:
            return "Device communication timed out."
        }
    }
}

public final class RazerDeviceSession: RazerDeviceSessionProtocol {
    private let queue = DispatchQueue(label: "app.momentoid.razercontrol.hid", qos: .userInitiated)
    private var hidDevice: IOHIDDevice?
    private var isOpen = false
    
    public var isConnected: Bool {
        return hidDevice != nil && isOpen
    }
    
    public init() {}
    
    public func attachDevice(_ device: IOHIDDevice) -> Bool {
        return queue.sync {
            self.hidDevice = device
            let ret = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
            if ret == kIOReturnSuccess {
                self.isOpen = true
                return true
            } else {
                self.isOpen = false
                return false
            }
        }
    }
    
    public func detachDevice() {
        queue.sync {
            if let dev = hidDevice, isOpen {
                IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
            }
            self.hidDevice = nil
            self.isOpen = false
        }
    }
    
    public func sendCommand(cmdClass: UInt8, cmdId: UInt8, dataSize: UInt8, args: [UInt8]) -> Result<[UInt8], Error> {
        let report = RazerHIDProtocol.createReport(
            cmdClass: cmdClass,
            cmdId: cmdId,
            dataSize: dataSize,
            args: args
        )
        return sendReport(report)
    }
    
    public func sendReport(_ report: [UInt8]) -> Result<[UInt8], Error> {
        return queue.sync {
            guard let dev = hidDevice, isOpen else {
                return .failure(RazerHIDError.deviceNotConnected)
            }
            
            // Send the 90-byte Feature Report
            let setRes = IOHIDDeviceSetReport(
                dev,
                kIOHIDReportTypeFeature,
                0,
                report,
                report.count
            )
            
            guard setRes == kIOReturnSuccess else {
                return .failure(RazerHIDError.setReportFailed(setRes))
            }
            
            // Allow device hardware 15ms to process
            usleep(15000)
            
            // Read back response report
            var resp = [UInt8](repeating: 0, count: RazerHIDProtocol.reportLength)
            var respLen = resp.count
            let getRes = IOHIDDeviceGetReport(
                dev,
                kIOHIDReportTypeFeature,
                0,
                &resp,
                &respLen
            )
            
            guard getRes == kIOReturnSuccess else {
                return .failure(RazerHIDError.getReportFailed(getRes))
            }
            
            guard respLen == RazerHIDProtocol.reportLength else {
                return .failure(RazerHIDError.invalidReportLength(respLen))
            }
            
            let status = resp[0]
            if status == RazerHIDProtocol.statusSuccess {
                return .success(resp)
            } else {
                return .failure(RazerHIDError.commandFailed(status))
            }
        }
    }
}
