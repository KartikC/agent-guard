import AppKit
import SwiftUI

/// Passive status chrome. The containing nonactivating panel ignores mouse events.
final class GuardView: NSView {
    let title = NSTextField(labelWithString: "Agents are working…")
    let hint = NSTextField(labelWithString: "Click or Esc · Touch ID / Apple Watch")
    private let content = NSView()
    private var surface: NSView?
    private let orb = NSHostingView(rootView:
        ThinkingOrb(state: .solving, size: .px64, theme: .auto, displaySize: 48)
    )

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.textColor = .labelColor
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .secondaryLabelColor
        for field in [title, hint] {
            field.isSelectable = false
            field.lineBreakMode = .byTruncatingTail
            field.maximumNumberOfLines = 1
            content.addSubview(field)
        }
        content.addSubview(orb)
        configureSurface()
        NSWorkspace.shared.notificationCenter.addObserver(self,
            selector: #selector(accessibilityChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { NSWorkspace.shared.notificationCenter.removeObserver(self) }

    @objc private func accessibilityChanged() { configureSurface() }

    private func configureSurface() {
        content.removeFromSuperview()
        surface?.removeFromSuperview()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
            let opaque = NSView(frame: bounds)
            opaque.wantsLayer = true
            opaque.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            opaque.layer?.cornerRadius = bounds.height / 2
            opaque.addSubview(content)
            surface = opaque
        } else if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: bounds)
            glass.style = .regular
            glass.cornerRadius = bounds.height / 2
            glass.contentView = content
            surface = glass
        } else {
            let material = NSVisualEffectView(frame: bounds)
            material.material = .hudWindow
            material.blendingMode = .behindWindow
            material.state = .active
            material.wantsLayer = true
            material.layer?.cornerRadius = bounds.height / 2
            material.layer?.masksToBounds = true
            material.addSubview(content)
            surface = material
        }
        if let surface = surface { addSubview(surface) }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        surface?.frame = bounds
        content.frame = bounds
        if #available(macOS 26.0, *), let glass = surface as? NSGlassEffectView {
            glass.cornerRadius = bounds.height / 2
        } else { surface?.layer?.cornerRadius = bounds.height / 2 }
        orb.frame = NSRect(x: 14, y: (bounds.height - 48) / 2, width: 48, height: 48)
        title.frame = NSRect(x: 76, y: 37, width: bounds.width - 96, height: 19)
        hint.frame = NSRect(x: 76, y: 19, width: bounds.width - 96, height: 16)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
            effectiveAppearance.performAsCurrentDrawingAppearance {
                surface?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            }
        }
    }
}
