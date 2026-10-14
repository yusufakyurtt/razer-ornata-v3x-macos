import Foundation

public struct RazerHIDProtocol {
    public static let reportLength = 90
    public static let transactionId: UInt8 = 0x1F // Verified for Razer Ornata V3 X
    
    // Command Classes
    public static let cmdClassDevice: UInt8 = 0x00
    public static let cmdClassStandardLED: UInt8 = 0x03
    public static let cmdClassExtendedMatrix: UInt8 = 0x0F
    
    // LED Storage Types
    public static let noStore: UInt8 = 0x00
    public static let varStore: UInt8 = 0x01
    
    // LED IDs
    public static let ledZero: UInt8 = 0x00
    public static let ledBacklight: UInt8 = 0x05
    public static let ledMacro: UInt8 = 0x07
    public static let ledGame: UInt8 = 0x08
    
    // Status Responses
    public static let statusBusy: UInt8 = 0x01
    public static let statusSuccess: UInt8 = 0x02
    public static let statusFailure: UInt8 = 0x03
    public static let statusTimeout: UInt8 = 0x04
    public static let statusNotSupported: UInt8 = 0x05
    
    public static func calculateCRC(_ buffer: [UInt8]) -> UInt8 {
        var crc: UInt8 = 0
        for i in 2..<88 {
            crc ^= buffer[i]
        }
        return crc
    }
    
    public static func createReport(
        cmdClass: UInt8,
        cmdId: UInt8,
        dataSize: UInt8,
        args: [UInt8] = []
    ) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: reportLength)
        report[0] = 0x00 // Status (0 in request)
        report[1] = transactionId
        report[2] = 0x00 // Remaining packets high
        report[3] = 0x00 // Remaining packets low
        report[4] = 0x00 // Protocol type
        report[5] = dataSize
        report[6] = cmdClass
        report[7] = cmdId
        
        for (idx, byte) in args.enumerated() {
            if idx < 80 {
                report[8 + idx] = byte
            }
        }
        
        report[88] = calculateCRC(report)
        report[89] = 0x00 // Reserved
        return report
    }
    
    // MARK: - Device Info Commands
    
    public static func getFirmwareVersionReport() -> [UInt8] {
        createReport(cmdClass: cmdClassDevice, cmdId: 0x81, dataSize: 0x02)
    }
    
    public static func getSerialNumberReport() -> [UInt8] {
        createReport(cmdClass: cmdClassDevice, cmdId: 0x82, dataSize: 0x16)
    }
    
    public static func getDeviceModeReport() -> [UInt8] {
        createReport(cmdClass: cmdClassDevice, cmdId: 0x84, dataSize: 0x02)
    }
    
    public static func getKeyboardLayoutReport() -> [UInt8] {
        createReport(cmdClass: cmdClassDevice, cmdId: 0x86, dataSize: 0x02)
    }
    
    // MARK: - Extended Matrix Lighting Commands (Class 0x0F)
    
    public static func getBrightnessReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x84,
            dataSize: 0x03,
            args: [varStore, ledZero, 0x00]
        )
    }
    
    public static func setBrightnessReport(brightness: UInt8) -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x04,
            dataSize: 0x03,
            args: [varStore, ledZero, brightness]
        )
    }
    
    public static func setStaticEffectReport(r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x09,
            args: [varStore, ledBacklight, 0x01, 0x00, 0x00, 0x01, r, g, b]
        )
    }
    
    public static func setBreathingSingleReport(r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x09,
            args: [varStore, ledBacklight, 0x02, 0x01, 0x00, 0x01, r, g, b]
        )
    }
    
    public static func setBreathingDualReport(r1: UInt8, g1: UInt8, b1: UInt8, r2: UInt8, g2: UInt8, b2: UInt8) -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x0C,
            args: [varStore, ledBacklight, 0x02, 0x02, 0x00, 0x02, r1, g1, b1, r2, g2, b2]
        )
    }
    
    public static func setBreathingRandomReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x06,
            args: [varStore, ledBacklight, 0x02, 0x00, 0x00, 0x00]
        )
    }
    
    public static func setSpectrumEffectReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x06,
            args: [varStore, ledBacklight, 0x03, 0x00, 0x00, 0x00]
        )
    }
    
    public static func setWaveEffectReport(direction: UInt8 = 1) -> [UInt8] {
        // direction: 1 = left, 2 = right
        let clampedDir = (direction == 2) ? 0x02 : 0x01
        return createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x06,
            args: [varStore, ledBacklight, 0x04, UInt8(clampedDir), 0x28, 0x00]
        )
    }
    
    public static func setTurnOffReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassExtendedMatrix,
            cmdId: 0x02,
            dataSize: 0x06,
            args: [varStore, ledBacklight, 0x00, 0x00, 0x00, 0x00]
        )
    }
    
    // MARK: - Indicator LEDs (Class 0x03)
    
    public static func setGameModeLEDReport(enabled: Bool) -> [UInt8] {
        createReport(
            cmdClass: cmdClassStandardLED,
            cmdId: 0x00,
            dataSize: 0x03,
            args: [varStore, ledGame, enabled ? 0x01 : 0x00]
        )
    }
    
    public static func setMacroModeLEDReport(enabled: Bool) -> [UInt8] {
        createReport(
            cmdClass: cmdClassStandardLED,
            cmdId: 0x00,
            dataSize: 0x03,
            args: [varStore, ledMacro, enabled ? 0x01 : 0x00]
        )
    }
    
    public static func getGameModeLEDReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassStandardLED,
            cmdId: 0x80,
            dataSize: 0x03,
            args: [varStore, ledGame, 0x00]
        )
    }
    
    public static func getMacroModeLEDReport() -> [UInt8] {
        createReport(
            cmdClass: cmdClassStandardLED,
            cmdId: 0x80,
            dataSize: 0x03,
            args: [varStore, ledMacro, 0x00]
        )
    }
}
