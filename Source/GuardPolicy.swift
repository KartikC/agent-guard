import Foundation
import CoreGraphics
import LocalAuthentication

enum AuthenticationPolicy {
    static var current: LAPolicy {
        if #available(macOS 15.0, *) { return .deviceOwnerAuthenticationWithBiometricsOrCompanion }
        return .deviceOwnerAuthenticationWithBiometricsOrWatch
    }
}

enum InputDecision { case pass, consume, authenticate }
enum InputPolicy {
    static func decision(sourcePID: Int64, type: CGEventType, keyCode: Int64, flags: CGEventFlags) -> InputDecision {
        // Compatibility heuristic, not a security boundary or trusted-agent allowlist.
        // Check software provenance FIRST: an agent's Escape must not trigger Watch requests.
        if sourcePID > 0 { return .pass }
        if type == .keyDown && (keyCode == 53 || (keyCode == 32 && flags.contains([.maskControl, .maskAlternate, .maskCommand]))) { return .authenticate }
        if [.leftMouseDown, .rightMouseDown, .otherMouseDown].contains(type) { return .authenticate }
        return .consume
    }
}

struct RecoveryBudget {
    private var attempts: [TimeInterval] = []
    mutating func take(at now: TimeInterval) -> Bool {
        attempts.removeAll { now - $0 >= 60 }
        guard attempts.count < 3 else { return false }
        attempts.append(now)
        return true
    }
}

struct PromptGate {
    private var nextAllowed: TimeInterval = -.infinity
    mutating func take(at now: TimeInterval) -> Bool {
        guard now >= nextAllowed else { return false }
        nextAllowed = now + 10
        return true
    }
}
