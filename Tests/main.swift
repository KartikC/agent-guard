import Foundation
import CoreGraphics
import LocalAuthentication

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}
// No application, event tap, authentication, power assertion or GUI is started.
for pid: Int64 in [1, 12345] {
    for type: CGEventType in [.keyDown, .keyUp, .leftMouseDown, .mouseMoved, .scrollWheel] {
        expect(InputPolicy.decision(sourcePID: pid, type: type, keyCode: 53, flags: []) == .pass, "software event blocked")
    }
}
for pid: Int64 in [0, -1] {
    expect(InputPolicy.decision(sourcePID: pid, type: .keyDown, keyCode: 53, flags: []) == .authenticate, "Escape must request approval")
    expect(InputPolicy.decision(sourcePID: pid, type: .leftMouseDown, keyCode: 0, flags: []) == .authenticate, "click must request approval")
    expect(InputPolicy.decision(sourcePID: pid, type: .keyDown, keyCode: 32, flags: [.maskControl, .maskAlternate, .maskCommand]) == .authenticate, "backup shortcut")
    for type: CGEventType in [.keyDown, .keyUp, .flagsChanged, .mouseMoved, .leftMouseDragged, .scrollWheel, .tabletPointer] {
        expect(InputPolicy.decision(sourcePID: pid, type: type, keyCode: 12, flags: [.maskCommand]) == .consume, "physical event escaped")
    }
    for raw: UInt32 in [14, 29, 30] {
        if let type = CGEventType(rawValue: raw) {
            expect(InputPolicy.decision(sourcePID: pid, type: type, keyCode: 0, flags: []) == .consume, "extended physical event escaped")
        }
    }
}
var budget = RecoveryBudget()
expect(budget.take(at: 100), "first recovery")
expect(budget.take(at: 101), "second recovery")
expect(budget.take(at: 102), "third recovery")
expect(!budget.take(at: 103), "unbounded recovery")
expect(!budget.take(at: 159), "premature recovery budget reset")
expect(budget.take(at: 160), "rolling recovery expiry")
expect(!budget.take(at: 160), "rolling window must retain remaining attempts")
var prompts = PromptGate()
expect(prompts.take(at: 1), "initial prompt")
expect(!prompts.take(at: 1), "same-tick click burst")
expect(!prompts.take(at: 10.99), "prompt cooldown")
expect(prompts.take(at: 11), "prompt retry")
expect(AuthenticationPolicy.current.rawValue == 4, "must require biometrics or companion; no password fallback")
print("PASS: input provenance, recovery requests, event classes, bounded recovery, prompt cooldown, biometric/companion policy. No GUI or authentication session started.")
