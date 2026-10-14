import Foundation
import Combine
import IOKit
import IOKit.hid

public protocol DeviceDiscoveryServiceProtocol: ObservableObject {
    var currentDevice: RazerDevice? { get }
    var isConnected: Bool { get }
    var session: RazerDeviceSession { get }
    func startDiscovery()
    func stopDiscovery()
    func refreshDeviceState()
}

public final class DeviceDiscoveryService: DeviceDiscoveryServiceProtocol, ObservableObject {
    @Published public private(set) var currentDevice: RazerDevice?
    @Published public private(set) var isConnected: Bool = false
    
    public let session = RazerDeviceSession()
    private var hidManager: IOHIDManager?
    private var isRunning = false
    public static let defaultCapabilities: [DeviceCapability] = [
        DeviceCapability(
            id: "single_zone_lighting",
            name: "Single-Zone Chroma Lighting",
            status: .supportedVerified,
            discoveryMethod: "Extended Matrix Class 0x0F validated on physical device",
            notes: "Static, Breathing, Spectrum Cycling, Wave, Off"
        ),
        DeviceCapability(
            id: "hardware_brightness",
            name: "Hardware Brightness Control",
            status: .supportedVerified,
            discoveryMethod: "Extended Matrix report (0x0F, 0x84 / 0x04)",
            notes: "Direct 0..255 hardware level dimming"
        ),
        DeviceCapability(
            id: "indicator_leds",
            name: "Game & Macro Mode Indicators",
            status: .supportedVerified,
            discoveryMethod: "Standard LED report (0x03, 0x00 / 0x80)",
            notes: "Verified toggle on physical indicator LEDs"
        ),
        DeviceCapability(
            id: "software_remapping",
            name: "Software Key Remapping",
            status: .supportedVerified,
            discoveryMethod: "Native CGEventTap at kCGHeadInsertEventTap",
            notes: "Host-based remapping and shortcuts",
            requiresPermission: true
        ),
        DeviceCapability(
            id: "macro_engine",
            name: "Macro Studio & Playback",
            status: .supportedVerified,
            discoveryMethod: "CoreGraphics synthetic event generation",
            notes: "Safe keystroke sequence playback with watchdog timer",
            requiresPermission: true
        ),
        DeviceCapability(
            id: "per_key_rgb",
            name: "Per-Key Individually Addressable RGB",
            status: .unsupported,
            discoveryMethod: "Hardware architectural inspection",
            notes: "Physical hardware features single-zone translucent lighting"
        ),
        DeviceCapability(
            id: "onboard_profile_memory",
            name: "Onboard Flash Profile Memory",
            status: .unsupported,
            discoveryMethod: "Hardware protocol inspection",
            notes: "Hardware lacks flash EEPROM; profiles are stored locally in macOS"
        )
    ]
    
    public init() {}
    
    public func startDiscovery() {
        guard !isRunning else { return }
        isRunning = true
        
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager
        
        let matchingCriteria: [[String: Any]] = [
            [
                kIOHIDVendorIDKey as String: 0x1532,
                kIOHIDProductIDKey as String: 0x02A2 // Ornata V3 X (Alternate)
            ],
            [
                kIOHIDVendorIDKey as String: 0x1532,
                kIOHIDProductIDKey as String: 0x0294 // Ornata V3 X (Standard)
            ]
        ]
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingCriteria as CFArray)
        
        // Context pointer
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, sender, device in
            guard let context = context else { return }
            let service = Unmanaged<DeviceDiscoveryService>.fromOpaque(context).takeUnretainedValue()
            service.handleDeviceMatched(device)
        }, context)
        
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, sender, device in
            guard let context = context else { return }
            let service = Unmanaged<DeviceDiscoveryService>.fromOpaque(context).takeUnretainedValue()
            service.handleDeviceRemoved(device)
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if openStatus == kIOReturnSuccess {
            // Enumerate any currently connected matching devices
            refreshDeviceState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.refreshDeviceState()
            }
        }
    }
    
    public func stopDiscovery() {
        guard isRunning, let manager = hidManager else { return }
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = nil
        session.detachDevice()
        self.isConnected = false
        self.currentDevice = nil
        self.isRunning = false
    }
    
    public func refreshDeviceState() {
        guard let manager = hidManager else { return }
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            DispatchQueue.main.async {
                self.isConnected = false
                self.currentDevice = nil
            }
            return
        }
        
        // Find the device that has MaxFeatureReportSize >= 90 (Management Interface)
        for dev in devices {
            let maxFeature = IOHIDDeviceGetProperty(dev, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0
            if maxFeature >= RazerHIDProtocol.reportLength {
                handleDeviceMatched(dev)
                return
            }
        }
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.currentDevice = nil
        }
    }
    
    private func handleDeviceMatched(_ device: IOHIDDevice) {
        let maxFeature = IOHIDDeviceGetProperty(device, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0
        guard maxFeature >= RazerHIDProtocol.reportLength else {
            // Ignore non-management HID interfaces (e.g. typing or consumer reports)
            return
        }
        
        let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Razer Ornata V3 X"
        let vendorId = UInt16(IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0x1532)
        let productId = UInt16(IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0x02A2)
        let locationId = UInt32(IOHIDDeviceGetProperty(device, kIOHIDLocationIDKey as CFString) as? Int ?? 0)
        
        let attached = session.attachDevice(device)
        guard attached else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
            return
        }
        
        let initialDev = RazerDevice(
            name: productName,
            modelFamily: "RZ03-0447",
            vendorId: vendorId,
            productId: productId,
            serialNumber: "",
            firmwareVersion: "",
            physicalLayout: "ANSI / ISO",
            locationId: locationId,
            isConnected: true,
            capabilities: Self.defaultCapabilities
        )
        
        DispatchQueue.main.async {
            self.currentDevice = initialDev
            self.isConnected = true
        }
        
        // Query verified device properties directly from hardware
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var serial = ""
            var firmware = ""
            var layout = "ANSI / ISO"
            
            // 1. Serial Number Query
            let serReport = RazerHIDProtocol.getSerialNumberReport()
            if case .success(let resp) = self.session.sendReport(serReport) {
                let bytes = Array(resp[8..<30])
                serial = String(bytes: bytes.prefix(while: { $0 != 0 }), encoding: .utf8) ?? ""
            }
            
            // 2. Firmware Version Query
            let fwReport = RazerHIDProtocol.getFirmwareVersionReport()
            if case .success(let resp) = self.session.sendReport(fwReport) {
                firmware = "v\(resp[8]).\(resp[9])"
            }
            
            // 3. Layout Query
            let layReport = RazerHIDProtocol.getKeyboardLayoutReport()
            if case .success(let resp) = self.session.sendReport(layReport) {
                layout = "Layout Code: 0x\(String(format: "%02X", resp[8]))"
            }
            
            let caps = Self.defaultCapabilities
            
            let dev = RazerDevice(
                name: productName,
                modelFamily: "RZ03-0447",
                vendorId: vendorId,
                productId: productId,
                serialNumber: serial,
                firmwareVersion: firmware,
                physicalLayout: layout,
                locationId: locationId,
                isConnected: true,
                capabilities: caps
            )
            
            DispatchQueue.main.async {
                self.currentDevice = dev
                self.isConnected = true
            }
        }
    }
    
    private func handleDeviceRemoved(_ device: IOHIDDevice) {
        let maxFeature = IOHIDDeviceGetProperty(device, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0
        if maxFeature >= RazerHIDProtocol.reportLength {
            session.detachDevice()
            DispatchQueue.main.async {
                self.isConnected = false
                self.currentDevice = nil
            }
        }
    }
}
