import AppKit
import LocalAuthentication
import ApplicationServices
import IOKit.pwr_mgt
import QuartzCore
import Carbon

final class WakeKeeper {
    var assertions: [IOPMAssertionID] = []
    var activity: IOPMAssertionID = 0
    var timer: Timer?
    var healthy = true
    func start() {
        stop()
        healthy = true
        for kind in [kIOPMAssertionTypePreventUserIdleSystemSleep, kIOPMAssertionTypePreventUserIdleDisplaySleep] {
            var id: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(kind as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Agent Guard is keeping this agent workspace awake" as CFString, &id)
            if result == kIOReturnSuccess { assertions.append(id) } else { healthy = false }
        }
        pulse()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.pulse() }
        if let timer = timer { RunLoop.main.add(timer, forMode: .common) }
    }
    func pulse() {
        let result = IOPMAssertionDeclareUserActivity("Agent Guard active workspace" as CFString, kIOPMUserActiveLocal, &activity)
        if result != kIOReturnSuccess { healthy = false }
    }
    func stop() {
        timer?.invalidate()
        assertions.forEach { IOPMAssertionRelease($0) }
        assertions.removeAll()
        if activity != 0 { IOPMAssertionRelease(activity); activity = 0 }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let wake = WakeKeeper()
    var status: NSStatusItem!
    var window: NSWindow!
    var label: NSTextField!
    var verified: NSButton!
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var guarded = false
    var authenticating = false
    var context: LAContext?
    var testTimer: Timer?
    var healthTimer: Timer?
    var blocked = 0
    var allowed = 0
    var testMode = false
    var indicators: [NSPanel] = []
    var recoveryBudget = RecoveryBudget()
    var promptGate = PromptGate()
    var interrupted = false
    var sessionActive = true
    var protectionWarning: String?
    var authenticationCompletion: ((Bool) -> Void)?
    var terminationPending = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // nil inherits the user's system appearance, including automatic changes.
        NSApp.appearance = nil
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Show Agent Guard", action: #selector(show), keyEquivalent: "0").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Agent Guard", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Agent Guard", action: #selector(quit), keyEquivalent: "q").target = self
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
        #if DOCS_PREVIEW
        makeWindow()
        label.stringValue = "Guard off · Documentation preview"
        show()
        let previewMenu = NSMenuItem(title: "Preview", action: nil, keyEquivalent: "")
        let previewItems = NSMenu()
        previewItems.addItem(withTitle: "System Appearance", action: #selector(previewSystem), keyEquivalent: "1").target = self
        previewItems.addItem(withTitle: "Light Appearance", action: #selector(previewLight), keyEquivalent: "2").target = self
        previewItems.addItem(withTitle: "Dark Appearance", action: #selector(previewDark), keyEquivalent: "3").target = self
        previewItems.addItem(withTitle: "Status Pill", action: #selector(previewPill), keyEquivalent: "4").target = self
        previewItems.addItem(withTitle: "Pill Close-up", action: #selector(previewPillCloseUp), keyEquivalent: "5").target = self
        previewMenu.submenu = previewItems
        mainMenu.addItem(previewMenu)
        return
        #endif
        wake.start()
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(sessionResigned), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionResumed), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatus()
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Agent Guard", action: #selector(show), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Restore input with Touch ID or Apple Watch", action: #selector(unlock), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Agent Guard…", action: #selector(quit), keyEquivalent: "q").target = self
        status.menu = menu
        makeWindow()
        NotificationCenter.default.addObserver(self, selector: #selector(displaysChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        show()
        if CommandLine.arguments.contains("--timed-test") {
            DispatchQueue.main.async { [weak self] in self?.test() }
        }
        healthTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkProtection()
            self.updateStatus()
        }
        if let healthTimer = healthTimer { RunLoop.main.add(healthTimer, forMode: .common) }
    }

    func makeWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 610, height: 610), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Agent Guard"
        window.isReleasedWhenClosed = false
        window.center()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 17
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 28)
        ])
        func text(_ value: String, size: CGFloat = 13, bold: Bool = false) -> NSTextField {
            let field = NSTextField(wrappingLabelWithString: value)
            field.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
            stack.addArrangedSubview(field)
            field.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            return field
        }
        let heading = NSStackView()
        heading.spacing = 14
        heading.alignment = .centerY
        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        icon.setAccessibilityLabel("Agent Guard app icon")
        heading.addArrangedSubview(icon)
        let headingText = NSTextField(labelWithString: "Step away. Keep agents working.")
        headingText.font = .boldSystemFont(ofSize: 25)
        heading.addArrangedSubview(headingText)
        stack.addArrangedSubview(heading)
        _ = text("Keep your Mac awake while agents work. Start the guard to block casual keyboard and mouse input while software agents keep using the desktop.")
        _ = text("A small glass pill shows when the guard is active. It stays out of your agent’s way and follows your Mac’s light or dark appearance.")
        _ = text("Click or press Esc to restore control with Touch ID or Apple Watch.", bold: true)
        _ = text("For home and trusted shared spaces. Your Mac remains unlocked and visible; system gestures, remote input and software can bypass this guard.")
        let row = NSStackView()
        row.spacing = 10
        for (title, action) in [("1. Grant Accessibility", #selector(permission)), ("2. Test for 15 seconds", #selector(test))] {
            row.addArrangedSubview(NSButton(title: title, target: self, action: action))
        }
        stack.addArrangedSubview(row)
        stack.addArrangedSubview(NSButton(title: "What this protects…", target: self, action: #selector(reviewGaps)))
        _ = text("Apple Watch uses macOS app approval. Being nearby doesn’t automatically unlock the guard.")
        verified = NSButton(checkboxWithTitle: "I tested input blocking, my agent, and Touch ID or Watch recovery.", target: self, action: #selector(verificationChanged))
        verified.state = UserDefaults.standard.bool(forKey: "hasConfirmedInitialTest") ? .on : .off
        stack.addArrangedSubview(verified)
        let actions = NSStackView()
        actions.spacing = 10
        actions.addArrangedSubview(NSButton(title: "Start Guard", target: self, action: #selector(arm)))
        actions.addArrangedSubview(NSButton(title: "Quit Agent Guard", target: self, action: #selector(quit)))
        stack.addArrangedSubview(actions)
        label = text("Guard off · Keep-awake is on until you quit.")
        label.textColor = .secondaryLabelColor
    }

    #if DOCS_PREVIEW
    @objc func previewSystem() { NSApp.appearance = nil }
    @objc func previewLight() { NSApp.appearance = NSAppearance(named: .aqua) }
    @objc func previewDark() { NSApp.appearance = NSAppearance(named: .darkAqua) }
    @objc func previewPill() {
        let sample = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 152), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        sample.title = "Agent Guard — Status"
        sample.isReleasedWhenClosed = false
        let pill = GuardView(frame: NSRect(x: 40, y: 40, width: 320, height: 72))
        sample.contentView?.addSubview(pill)
        sample.center()
        indicators.append(sample)
        sample.makeKeyAndOrderFront(nil)
    }
    @objc func previewPillCloseUp() {
        let sample = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 1000), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        sample.title = "Agent Guard — Pill Close-up"
        sample.isReleasedWhenClosed = false
        let backdrop = PillPreviewBackdrop(frame: NSRect(x: 0, y: 0, width: 1000, height: 1000))
        sample.contentView = backdrop
        let pill = GuardView(frame: NSRect(x: 20, y: 392, width: 960, height: 216))
        pill.bounds = NSRect(x: 0, y: 0, width: 320, height: 72)
        backdrop.addSubview(pill)
        sample.center()
        indicators.append(sample)
        sample.makeKeyAndOrderFront(nil)
    }
    #endif

    func updateStatus() {
        status?.button?.title = guarded ? (testMode ? "◈ Guard TEST" : "◈ Guard ON") : "◇ Guard OFF"
        status?.button?.toolTip = "Keep-awake: \(wake.healthy ? "active" : "failed") · blocked \(blocked) · allowed \(allowed) · ⌃⌥⌘U for Touch ID or Apple Watch"
        if !wake.healthy { status?.button?.title = "⚠ Wake failed" }
        if guarded && !sessionActive { status?.button?.title = "◈ Guard paused" }
        if let warning = protectionWarning {
            status?.button?.title = "⚠ Guard interrupted"
            status?.button?.toolTip = warning
        }
    }
    @objc func show() {
        if guarded { unlock(); return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return false
    }
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        if guarded {
            menu.addItem(withTitle: "Stop Guard with Touch ID or Apple Watch…", action: #selector(unlock), keyEquivalent: "").target = self
        } else {
            menu.addItem(withTitle: "Start Guard…", action: #selector(startFromDock), keyEquivalent: "").target = self
        }
        menu.addItem(withTitle: "Show Controls", action: #selector(show), keyEquivalent: "").target = self
        return menu
    }
    @objc func startFromDock() {
        show()
        arm()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Closing the controls must not silently stop an active guard or its wake assertions.
        // Dock click reopens controls; Dock Quit and Command-Q take the explicit quit path.
        return false
    }
    @objc func permission() {
        #if DOCS_PREVIEW
        return
        #endif
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc func verificationChanged() {
        UserDefaults.standard.set(verified.state == .on, forKey: "hasConfirmedInitialTest")
    }
    @objc func test() { begin(test: true) }
    @objc func arm() {
        guard verified.state == .on else { label.stringValue = "Run the timed test and confirm the checklist first."; return }
        begin(test: false)
    }
    func begin(test: Bool) {
        #if DOCS_PREVIEW
        return
        #endif
        guard !guarded, !authenticating else { return }
        guard wake.healthy else { label.stringValue = "Keep-awake failed. Quit and reopen before arming."; return }
        guard !IsSecureEventInputEnabled() else { label.stringValue = "Close password fields or secure-input apps before starting the guard."; return }
        guard AXIsProcessTrusted() else { label.stringValue = "Grant Accessibility to Agent Guard, then retry. You may need to quit and reopen."; return }
        authenticate(reason: "verify Touch ID or Apple Watch before blocking physical input") { [weak self] success in
            guard let self = self, success else { return }
            self.installTap(test: test)
        }
    }
    func installTap(test: Bool) {
        // Session tap requires Accessibility, not root privileges.
        // Request all event classes delivered to the session tap, including media/gesture events.
        // System gestures handled upstream can still bypass this tap.
        let mask = CGEventMask.max
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, info in
            guard let info = info else { return Unmanaged.passUnretained(event) }
            return Unmanaged<AppDelegate>.fromOpaque(info).takeUnretainedValue().filter(type: type, event: event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            label.stringValue = "Cannot create input filter. Check Accessibility permission and reopen the app. Guard is OFF."
            return
        }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        testMode = test
        blocked = 0; allowed = 0
        guarded = true
        interrupted = false
        protectionWarning = nil
        recoveryBudget = RecoveryBudget()
        promptGate = PromptGate()
        CGEvent.tapEnable(tap: tap, enable: true)
        window.orderOut(nil)
        showIndicators()
        updateStatus()
        if test {
            testTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
                self?.stopGuard(message: "Timed test finished. Check that physical input was blocked and your agent continued. Use another test to verify ⌃⌥⌘U and Touch ID or Apple Watch.")
                if self?.sessionActive == true { self?.show() }
            }
            if let testTimer = testTimer { RunLoop.main.add(testTimer, forMode: .common) }
        }
    }
    func filter(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            guard guarded && sessionActive else { return Unmanaged.passUnretained(event) }
            // Do not disarm or waive authentication because the OS disabled a tap.
            interrupted = true
            if let tap = tap, recoveryBudget.take(at: ProcessInfo.processInfo.systemUptime) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            DispatchQueue.main.async { [weak self] in self?.checkProtection() }
            return Unmanaged.passUnretained(event)
        }
        guard guarded && sessionActive else { return Unmanaged.passUnretained(event) }
        let decision = InputPolicy.decision(sourcePID: event.getIntegerValueField(.eventSourceUnixProcessID),
                                            type: type, keyCode: event.getIntegerValueField(.keyboardEventKeycode), flags: event.flags)
        switch decision {
        case .pass:
            allowed += 1
            return Unmanaged.passUnretained(event)
        case .consume:
            blocked += 1
            return nil
        case .authenticate:
            blocked += 1
            DispatchQueue.main.async { [weak self] in self?.unlock() }
            return nil
        }
    }
    @discardableResult
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) -> Bool {
        guard !authenticating, sessionActive else { return false }
        if guarded && !promptGate.take(at: ProcessInfo.processInfo.systemUptime) {
            setIndicatorHint("Please wait a moment, then click or Esc")
            return false
        }
        let ctx = LAContext()
        ctx.localizedFallbackTitle = ""
        ctx.touchIDAuthenticationAllowableReuseDuration = 0
        var error: NSError?
        let policy = AuthenticationPolicy.current
        guard ctx.canEvaluatePolicy(policy, error: &error) else {
            label.stringValue = "Touch ID or Apple Watch unavailable: \(error?.localizedDescription ?? "Set up Touch ID or Apple Watch in System Settings.")"
            status.button?.toolTip = label.stringValue
            setIndicatorHint("Authentication unavailable · Use system login")
            completion(false)
            return false
        }
        authenticating = true
        context = ctx
        authenticationCompletion = completion
        NSApp.activate(ignoringOtherApps: true)
        ctx.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self, self.context === ctx else { return }
                self.authenticating = false
                self.context = nil
                let callback = self.authenticationCompletion
                self.authenticationCompletion = nil
                if !success { self.label.stringValue = "Touch ID or Apple Watch did not succeed. \(error?.localizedDescription ?? "Try again.")" }
                if !success { self.setIndicatorHint("Not approved · Wait 10s, then click or Esc") }
                callback?(success)
            }
        }
        return true
    }
    @objc func unlock() {
        guard guarded else { return }
        authenticate(reason: "restore physical keyboard and pointer control") { [weak self] success in
            if success {
                self?.stopGuard(message: "Input restored with Touch ID or Apple Watch. Keep-awake remains active until you quit.")
                self?.show()
            }
        }
    }
    func stopGuard(message: String) {
        guarded = false
        hideIndicators()
        testTimer?.invalidate(); testTimer = nil
        cancelAuthentication()
        protectionWarning = nil
        interrupted = false
        if let tap = tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil
        label.stringValue = "\(message) Blocked: \(blocked); software events passed: \(allowed)."
        updateStatus()
    }
    func setIndicatorHint(_ text: String) {
        indicators.forEach { ($0.contentView as? GuardView)?.hint.stringValue = text }
    }
    func cancelAuthentication() {
        let callback = authenticationCompletion
        authenticationCompletion = nil
        let oldContext = context
        context = nil
        authenticating = false
        oldContext?.invalidate()
        callback?(false)
    }
    func checkProtection() {
        guard guarded && sessionActive else { return }
        if let tap = tap, !CGEvent.tapIsEnabled(tap: tap) {
            interrupted = true
            if recoveryBudget.take(at: ProcessInfo.processInfo.systemUptime) { CGEvent.tapEnable(tap: tap, enable: true) }
        }
        if !AXIsProcessTrusted() {
            protectionWarning = "Accessibility permission was lost. Physical input may reach apps."
        } else if tap == nil || !CGEvent.tapIsEnabled(tap: tap!) {
            protectionWarning = "Input filtering is unavailable. Physical input may reach apps."
        } else if IsSecureEventInputEnabled() && !authenticating {
            protectionWarning = "Secure Input is active. Keyboard filtering may be unavailable."
        } else if !wake.healthy {
            protectionWarning = "Keep-awake failed. Agent work may be interrupted by idle sleep."
        } else if interrupted {
            protectionWarning = "Input filtering recovered after interruption. Check your workspace before continuing."
        } else {
            protectionWarning = nil
        }
        for panel in indicators {
            guard let view = panel.contentView as? GuardView else { continue }
            view.title.stringValue = protectionWarning == nil ? (testMode ? "Agents are working… · TEST" : "Agents are working…") : "Protection needs attention"
            view.title.textColor = protectionWarning == nil ? .labelColor : .systemOrange
            if protectionWarning != nil { view.hint.stringValue = "Input may have passed · Click or Esc to review" }
        }
    }
    @objc func sessionResigned() {
        sessionActive = false
        cancelAuthentication()
        if let tap = tap { CGEvent.tapEnable(tap: tap, enable: false) }
        hideIndicators()
        wake.stop()
        updateStatus()
    }
    @objc func sessionResumed() {
        sessionActive = true
        wake.start()
        if guarded {
            if let tap = tap { CGEvent.tapEnable(tap: tap, enable: true) }
            showIndicators()
            checkProtection()
        }
        updateStatus()
    }
    @objc func willSleep() {
        cancelAuthentication()
        wake.stop()
    }
    @objc func didWake() {
        if sessionActive { wake.start(); checkProtection() }
    }
    @objc func reviewGaps() {
        let alert = NSAlert()
        alert.messageText = "For homes and trusted shared spaces"
        alert.informativeText = "This guard deters casual local interaction while your agent uses the desktop. It does not secure an unlocked session against a determined person.\n\nBefore stepping away:\n• Review trackpad and mouse system gestures (Notification Center, Mission Control, Spaces). These can bypass the filter.\n• Review Hot Corners and notification previews. The desktop remains readable.\n• Review Screen Sharing, Remote Management, Universal Control, Voice Control and input remappers. Software input is allowed so agents can work.\n• Try external keyboards, mice, media keys and your actual agent during the timed test.\n\nA failed filter shows an orange warning; the app cannot guarantee blocking during that failure. Use the macOS lock screen when access must be prevented. No settings are changed by this review."
        alert.addButton(withTitle: "Done")
        alert.runModal()
    }
    @objc func displaysChanged() {
        if guarded && sessionActive { rebuildIndicators(); checkProtection() }
    }
    func showIndicators() { rebuildIndicators() }
    func rebuildIndicators() {
        hideIndicators()
        for screen in NSScreen.screens {
            let area = screen.visibleFrame
            let frame = NSRect(x: area.maxX - 338, y: area.minY + 18, width: 320, height: 72)
            let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            let view = GuardView(frame: NSRect(origin: .zero, size: frame.size))
            if testMode { view.title.stringValue = "Agents are working… · TEST" }
            panel.contentView = view
            indicators.append(panel)
            panel.orderFrontRegardless()
        }
    }
    func hideIndicators() {
        indicators.forEach { $0.orderOut(nil) }
        indicators.removeAll()
    }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard guarded else { return .terminateNow }
        guard !authenticating else { return .terminateCancel }
        let started = authenticate(reason: "quit Agent Guard and restore physical input") { [weak self] success in
            guard let self = self, self.terminationPending else { return }
            self.terminationPending = false
            NSApp.reply(toApplicationShouldTerminate: success)
        }
        terminationPending = started
        return started ? .terminateLater : .terminateCancel
    }
    func applicationWillTerminate(_ notification: Notification) {
        healthTimer?.invalidate()
        stopGuard(message: "Stopped")
        wake.stop()
    }
}

#if DOCS_PREVIEW
final class PillPreviewBackdrop: NSView {
    private lazy var wallpaper: NSImage? = {
        guard let screen = NSScreen.main,
              let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        return NSImage(contentsOf: url)
    }()
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        if let image = wallpaper {
            let scale = max(bounds.width / image.size.width, bounds.height / image.size.height)
            let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: NSRect(x: (bounds.width-size.width)/2, y: (bounds.height-size.height)/2,
                                 width: size.width, height: size.height))
        }
    }
}
#endif

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
