import XCTest
@testable import RazerControlKit

final class RazerControlTests: XCTestCase {
    
    // MARK: - Protocol & CRC Tests
    
    func testChecksumCalculation() {
        var report = [UInt8](repeating: 0, count: 90)
        report[1] = 0x1F
        report[5] = 0x16
        report[6] = 0x00
        report[7] = 0x82
        
        let crc = RazerHIDProtocol.calculateCRC(report)
        XCTAssertEqual(crc, 0x16 ^ 0x00 ^ 0x82) // XOR of non-zero payload bytes
    }
    
    func testPacketLengthAlways90Bytes() {
        let fwReport = RazerHIDProtocol.getFirmwareVersionReport()
        XCTAssertEqual(fwReport.count, 90)
        
        let serialReport = RazerHIDProtocol.getSerialNumberReport()
        XCTAssertEqual(serialReport.count, 90)
        
        let brReport = RazerHIDProtocol.getBrightnessReport()
        XCTAssertEqual(brReport.count, 90)
        
        let setBrReport = RazerHIDProtocol.setBrightnessReport(brightness: 200)
        XCTAssertEqual(setBrReport.count, 90)
        
        let staticReport = RazerHIDProtocol.setStaticEffectReport(r: 255, g: 0, b: 0)
        XCTAssertEqual(staticReport.count, 90)
        
        let breathReport = RazerHIDProtocol.setBreathingSingleReport(r: 0, g: 255, b: 0)
        XCTAssertEqual(breathReport.count, 90)
        
        let specReport = RazerHIDProtocol.setSpectrumEffectReport()
        XCTAssertEqual(specReport.count, 90)
        
        let waveReport = RazerHIDProtocol.setWaveEffectReport(direction: 1)
        XCTAssertEqual(waveReport.count, 90)
        
        let offReport = RazerHIDProtocol.setTurnOffReport()
        XCTAssertEqual(offReport.count, 90)
    }
    
    func testTransactionIdIs1F() {
        let report = RazerHIDProtocol.getFirmwareVersionReport()
        XCTAssertEqual(report[1], 0x1F)
    }
    
    // MARK: - Profile & Persistence Tests
    
    func testProfileSerialization() throws {
        let profile = Profile(
            name: "Competitive FPS",
            lighting: LightingConfiguration(
                effect: .static,
                primaryColor: RGBColor(red: 255, green: 0, blue: 0),
                brightness: 255
            ),
            keyMappings: [
                KeyMapping(
                    sourceKeyCode: 122,
                    sourceKeyName: "F1",
                    actionType: .mediaControl,
                    mediaAction: .playPause
                )
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Profile.self, from: data)
        
        XCTAssertEqual(profile.id, decoded.id)
        XCTAssertEqual(profile.name, decoded.name)
        XCTAssertEqual(decoded.lighting.effect, .static)
        XCTAssertEqual(decoded.lighting.primaryColor.red, 255)
        XCTAssertEqual(decoded.keyMappings.count, 1)
        XCTAssertEqual(decoded.keyMappings.first?.actionType, .mediaControl)
    }
    
    func testSettingsPersistence() {
        let persistence = PersistenceService()
        var settings = persistence.loadSettings()
        settings.theme = .dark
        settings.language = .turkish
        settings.launchAtLogin = false
        
        let saved = persistence.saveSettings(settings)
        XCTAssertTrue(saved)
        
        let reloaded = persistence.loadSettings()
        XCTAssertEqual(reloaded.theme, .dark)
        XCTAssertEqual(reloaded.language, .turkish)
    }
    
    // MARK: - Key Mapping & Modifiers Tests
    
    func testKeyMappingModifiers() {
        let mapping = KeyMapping(
            sourceKeyCode: 101,
            sourceKeyName: "F9",
            actionType: .modifierCombo,
            targetKeyCode: 0,
            targetKeyName: "A",
            targetModifiers: [.command, .shift]
        )
        
        XCTAssertTrue(mapping.targetModifiers.contains(.command))
        XCTAssertTrue(mapping.targetModifiers.contains(.shift))
        XCTAssertFalse(mapping.targetModifiers.contains(.control))
        XCTAssertFalse(mapping.targetModifiers.contains(.option))
    }
    
    // MARK: - Macro Tests
    
    func testMacroEventSequence() {
        let macro = Macro(
            name: "Quick Cast",
            events: [
                MacroEvent(type: .keyDown, keyCode: 0, keyName: "A"),
                MacroEvent(type: .delay, delayMs: 40),
                MacroEvent(type: .keyUp, keyCode: 0, keyName: "A")
            ],
            repeatCount: 2
        )
        
        XCTAssertEqual(macro.events.count, 3)
        XCTAssertEqual(macro.repeatCount, 2)
        XCTAssertEqual(macro.events[0].type, .keyDown)
        XCTAssertEqual(macro.events[1].delayMs, 40)
        XCTAssertEqual(macro.events[2].type, .keyUp)
    }
}
