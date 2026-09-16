# Agent Guard — instructions for coding agents

Read README.md and SECURITY.md first. This is a macOS-only Swift/AppKit app. Preserve the distinction between a convenience input guard and an OS security lock.

## Work safely

- Building and pure-policy tests do not require launching the app.
- Do not launch or arm the real guard without user authorization: it can block physical input and prevent idle sleep.
- Use `bash build.sh --preview` for UI work. This compiles a separate `Agent Guard Preview.app` with a distinct bundle ID and no guard/permission/authentication/wake startup. Its Preview menu switches only the preview app’s appearance.
- Keep production appearance inherited from macOS (`NSApp.appearance = nil`). Do not write global defaults or force light/dark mode. Preview-only overrides are allowed behind `DOCS_PREVIEW`.
- Do not change user permissions, lock-screen settings, system gestures, remote access, or accessibility features automatically.
- Never collect passwords, fingerprint data, Watch secrets, event contents, or private screenshots. Native LocalAuthentication owns approval.
- Do not publish, push, upload a release, or notarize with an account unless explicitly authorized.

## Map

- `Source/main.swift`: AppKit lifecycle, wake assertions, input tap, authentication, Dock controls and health reporting.
- `Source/GuardPolicy.swift`: pure input decisions, auth policy selection, prompt cooldown and recovery budget.
- `Source/IndicatorView.swift`: click-through pill content, native glass/material, system appearance and accessibility behavior.
- `Vendor/ThinkingOrbsKit`: pinned upstream Swift renderer. Preserve LICENSE and PROVENANCE; avoid unrelated edits.
- `Assets`: icon master and ICNS. `Assets/build-icon.sh` regenerates icon sizes with Apple tools.
- `Tests/main.swift`: isolated policy tests. They must never create a GUI, input tap, authentication prompt or power assertion.
- `build.sh`: arm64 compile and local ad-hoc signing; never launches the result.
- `scripts/package-dmg.sh`: reproducible packaging procedure, Applications link, SHA-256; not notarization.

## Invariants

1. A software event with a positive source PID may pass. This preserves agents but is not an identity or trust check.
2. Physical clicks/Escape request approval without reaching underlying apps. Software Escape must not trigger Watch prompts.
3. Use biometric-or-companion authentication, with the older Watch API on macOS 13–14. Never silently add password fallback or proximity-based approval.
4. Cancelled, stale or failed authentication must not release the guard. The explicitly timed test is the only automatic release.
5. Tap failure may allow input. Warn honestly, bound recovery attempts, and retain the app’s normal Stop/Quit authentication requirement. Never call this fail-closed security.
6. Keep the indicator nonactivating and click-through. Do not add a fullscreen curtain or block software input without revisiting desktop-agent compatibility.
7. Quit releases wake assertions and the tap. Closing controls does not quit. Reopening from Dock must work.
8. macOS 13 is the runtime minimum; macOS 26-only APIs need availability checks. Ship arm64 unless another architecture is deliberately added and tested.

## Checks

Run `bash test.sh` and `bash build.sh`. For UI changes, build the preview and inspect app-window-only light/dark screenshots. Do not claim live authentication or device coverage from compilation. Keep the manual acceptance list in docs/SECURITY_REVIEW.md accurate.

For packaging, run `bash scripts/package-dmg.sh`, verify the image and embedded signature, inspect its arm64 architecture and Applications link, and refresh downloads/SHA256SUMS. Inspect archives for credentials, user paths and build debris before sharing. Update README download paths when the release version changes.
