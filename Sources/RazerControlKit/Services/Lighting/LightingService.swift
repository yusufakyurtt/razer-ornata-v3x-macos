import Foundation
import Combine

public protocol LightingServiceProtocol: AnyObject {
    func applyConfiguration(_ config: LightingConfiguration) -> Result<Void, Error>
    func setBrightness(_ level: UInt8) -> Result<Void, Error>
    func getBrightness() -> Result<UInt8, Error>
    func setStaticColor(r: UInt8, g: UInt8, b: UInt8) -> Result<Void, Error>
    func setBreathingSingle(r: UInt8, g: UInt8, b: UInt8) -> Result<Void, Error>
    func setBreathingDual(r1: UInt8, g1: UInt8, b1: UInt8, r2: UInt8, g2: UInt8, b2: UInt8) -> Result<Void, Error>
    func setBreathingRandom() -> Result<Void, Error>
    func setSpectrumCycling() -> Result<Void, Error>
    func setWave(direction: UInt8) -> Result<Void, Error>
    func turnOff() -> Result<Void, Error>
    func setGameModeLED(enabled: Bool) -> Result<Void, Error>
    func setMacroModeLED(enabled: Bool) -> Result<Void, Error>
}

public final class LightingService: LightingServiceProtocol {
    private let session: RazerDeviceSessionProtocol
    
    public init(session: RazerDeviceSessionProtocol) {
        self.session = session
    }
    
    public func applyConfiguration(_ config: LightingConfiguration) -> Result<Void, Error> {
        // 1. Set brightness
        let brRes = setBrightness(config.brightness)
        if case .failure(let err) = brRes { return .failure(err) }
        
        // 2. Set effect
        let effectRes: Result<Void, Error>
        switch config.effect {
        case .static:
            effectRes = setStaticColor(
                r: config.primaryColor.red,
                g: config.primaryColor.green,
                b: config.primaryColor.blue
            )
        case .breathingSingle:
            effectRes = setBreathingSingle(
                r: config.primaryColor.red,
                g: config.primaryColor.green,
                b: config.primaryColor.blue
            )
        case .breathingDual:
            effectRes = setBreathingDual(
                r1: config.primaryColor.red,
                g1: config.primaryColor.green,
                b1: config.primaryColor.blue,
                r2: config.secondaryColor.red,
                g2: config.secondaryColor.green,
                b2: config.secondaryColor.blue
            )
        case .breathingRandom:
            effectRes = setBreathingRandom()
        case .spectrum:
            effectRes = setSpectrumCycling()
        case .wave:
            effectRes = setWave(direction: config.waveDirection)
        case .off:
            effectRes = turnOff()
        }
        
        if case .failure(let err) = effectRes { return .failure(err) }
        
        // 3. Set Indicator LEDs
        _ = setGameModeLED(enabled: config.gameModeLED)
        _ = setMacroModeLED(enabled: config.macroModeLED)
        
        return .success(())
    }
    
    public func setBrightness(_ level: UInt8) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setBrightnessReport(brightness: level)
        return session.sendReport(report).map { _ in () }
    }
    
    public func getBrightness() -> Result<UInt8, Error> {
        let report = RazerHIDProtocol.getBrightnessReport()
        let result = session.sendReport(report)
        switch result {
        case .success(let resp):
            if resp.count > 10 {
                return .success(resp[10])
            }
            return .failure(RazerHIDError.invalidReportLength(resp.count))
        case .failure(let err):
            return .failure(err)
        }
    }
    
    public func setStaticColor(r: UInt8, g: UInt8, b: UInt8) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setStaticEffectReport(r: r, g: g, b: b)
        return session.sendReport(report).map { _ in () }
    }
    
    public func setBreathingSingle(r: UInt8, g: UInt8, b: UInt8) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setBreathingSingleReport(r: r, g: g, b: b)
        return session.sendReport(report).map { _ in () }
    }
    
    public func setBreathingDual(r1: UInt8, g1: UInt8, b1: UInt8, r2: UInt8, g2: UInt8, b2: UInt8) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setBreathingDualReport(r1: r1, g1: g1, b1: b1, r2: r2, g2: g2, b2: b2)
        return session.sendReport(report).map { _ in () }
    }
    
    public func setBreathingRandom() -> Result<Void, Error> {
        let report = RazerHIDProtocol.setBreathingRandomReport()
        return session.sendReport(report).map { _ in () }
    }
    
    public func setSpectrumCycling() -> Result<Void, Error> {
        let report = RazerHIDProtocol.setSpectrumEffectReport()
        return session.sendReport(report).map { _ in () }
    }
    
    public func setWave(direction: UInt8) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setWaveEffectReport(direction: direction)
        return session.sendReport(report).map { _ in () }
    }
    
    public func turnOff() -> Result<Void, Error> {
        let report = RazerHIDProtocol.setTurnOffReport()
        return session.sendReport(report).map { _ in () }
    }
    
    public func setGameModeLED(enabled: Bool) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setGameModeLEDReport(enabled: enabled)
        return session.sendReport(report).map { _ in () }
    }
    
    public func setMacroModeLED(enabled: Bool) -> Result<Void, Error> {
        let report = RazerHIDProtocol.setMacroModeLEDReport(enabled: enabled)
        return session.sendReport(report).map { _ in () }
    }
}
