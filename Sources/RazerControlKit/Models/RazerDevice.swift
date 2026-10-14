import Foundation

public struct RazerDevice: Identifiable, Codable, Equatable {
    public var id: String { serialNumber.isEmpty ? "\(String(format: "0x%04X", productId))-\(locationId)" : serialNumber }
    
    public var name: String
    public var modelFamily: String
    public var vendorId: UInt16
    public var productId: UInt16
    public var serialNumber: String
    public var firmwareVersion: String
    public var physicalLayout: String
    public var locationId: UInt32
    public var isConnected: Bool
    public var capabilities: [DeviceCapability]
    
    public init(
        name: String = "Razer Ornata V3 X",
        modelFamily: String = "RZ03-0447",
        vendorId: UInt16 = 0x1532,
        productId: UInt16 = 0x02A2,
        serialNumber: String = "",
        firmwareVersion: String = "",
        physicalLayout: String = "ANSI / ISO",
        locationId: UInt32 = 0,
        isConnected: Bool = false,
        capabilities: [DeviceCapability] = []
    ) {
        self.name = name
        self.modelFamily = modelFamily
        self.vendorId = vendorId
        self.productId = productId
        self.serialNumber = serialNumber
        self.firmwareVersion = firmwareVersion
        self.physicalLayout = physicalLayout
        self.locationId = locationId
        self.isConnected = isConnected
        self.capabilities = capabilities
    }
}
