# Agent Guard: shared-space review

Review date: 2026-09-16. Scope: macOS only, with deliberate support for agent desktop clicks and screenshots. Intended users are stepping away at home or among trusted coworkers, not protecting an unlocked laptop from a determined attacker.

## Product judgment

The useful promise is “casual local interaction is discouraged, and approval is needed to stop the guard.” Do not promise “securely locked.” An unlocked session and agent-compatible software input leave intentional access paths. Privacy from nearby eyes is also outside the promise: a fullscreen privacy curtain would defeat the user's desktop-agent requirement.

The biggest practical improvements are Watch approval, recovering from accidental filter interruptions without automatically disarming, and making degraded protection conspicuous. Those are implemented in this version. Settings changes are described below, not performed automatically or claimed as implemented protection.

## Interaction paths

| Path | Current treatment | Remaining action or limit |
| --- | --- | --- |
| Built-in and external typing, clicks, dragging, scrolling | PID-zero/unknown session events are consumed | Test every physical device. Event-source PID is a heuristic, not proof of origin. |
| Command-Tab, Spotlight, screenshots, Dock shortcuts | Physical key events that reach the tap are consumed | Test OS shortcuts; some system actions can be handled outside the app's filter. Software shortcuts remain allowed for agents. |
| Notification Center swipe | Known escape in the working version | No claim of a fix. Turn off the relevant system gesture manually if needed. The app requests all session event classes but cannot capture events handled upstream. |
| Mission Control, App Exposé, Spaces, Show Desktop, mouse gestures | Same system-gesture risk | Review Trackpad and Mouse settings. Disabling these may also change agent workflows that rely on them. |
| Hot Corners | Physical pointer movement normally consumed | An agent can still move into a corner, and system handling varies. Review Hot Corners manually. |
| Notification content, widgets, desktop documents | Desktop remains visible | For a shared office, set sensitive app previews to Never or suppress notifications with Focus. “When unlocked” is insufficient because this session is unlocked. Focus does not erase Notification Center history or hide the desktop. |
| Secure Input/password fields | Refuse initial arming; warn if observed mid-session | A tap can remain enabled while keyboard events are unavailable. A warning is not blocking. Quit secure-input mode or use the real lock screen for sensitive activity. |
| Filter timeout or OS-disabled tap | Bounded re-enable attempts, warning persists after recovery, auth gate remains | An input gap is possible. Keeping the app's auth gate is not OS-level fail-closed protection. |
| Accessibility permission removed | Health warning | The app cannot veto removal of its own permission. |
| Screen Sharing, Remote Management, remote-control apps, SSH | Not blocked | Retain only the access you actually use. Blanket blocking would also break agents. No settings or network rules are modified. |
| Universal Control and other-device input | No guarantee | Disable manually if unused; macOS can classify these differently from local hardware. |
| Siri, Voice Control, Switch Control, accessibility automation | Not reliably blocked | These can invoke actions without a local physical key event. Review enabled features; do not silently disable accessibility features. |
| Keyboard remappers/virtual HID/automation tools | May appear as software and pass | Test your actual setup. A future explicit trusted-input-process mode would improve control, but reliable attribution is not guaranteed and could break existing agents. Not implemented here. |
| USB/Bluetooth HID additions and media/brightness/Touch Bar controls | Best-effort session filtering, including additional event classes | Test hot-plugged devices and media keys. Hardware/firmware controls and virtual-input injection are not a solved boundary. |
| Dock Stop/Quit, Command-Q, window close | Stop and normal Quit require approval while guarded; close does not stop guard | Force Quit, signals, crashes, power button and restart can bypass a user-space app. No root helper, persistence trick or attempt to disable recovery is included. |
| Fast user switching, sleep, resume, display changes | Session/sleep hooks and display-indicator rebuilding | Pending verification on real hardware. No auto-unlock of the macOS lock screen and no claim of observing every lock transition. |
| Repeated click-to-unlock attempts | One request start per 10 seconds, one active authentication at a time | Reduces accidental/annoying Watch requests. Not a defense against denial of service. |
| Anyone else's enrolled fingerprint or paired eligible companion | macOS decides authorized identities | The app cannot identify which enrolled finger approved or override macOS enrollment. |
| Malicious code in the existing user session | Outside this guard | Software input is intentionally allowed, and the agent has the session's existing privileges. |

## Apple authentication choice

Use `deviceOwnerAuthenticationWithBiometricsOrCompanion` on macOS 15+, and `deviceOwnerAuthenticationWithBiometricsOrWatch` on macOS 13–14. Apple's installed SDK headers describe biometric/companion authentication and Watch side-button approval. The plain `deviceOwnerAuthentication` policy was deliberately not chosen because it permits account-password fallback. Neither a custom proximity signal nor wrist detection is used to stop the guard.

A fresh LAContext is evaluated each time. Cancellation, unavailable methods and failure do not restore input. If an auth request is invalidated during a test expiry or session transition, its callback is consumed once; late replies are ignored. The 15-second test is intentionally a timed release and is labeled as such.

No iPhone unlock, Face ID relay, custom Watch app, Bluetooth scanning, credential prompt broker, or stored credential is needed: macOS handles approval on its trusted system UI.

## Later acceptance matrix — not executed in this iteration

- Touch ID: success, cancel, repeated failure, unavailable/locked-out state.
- Watch: Watch-only Mac configuration, Touch ID+Watch, Watch absent/locked/out of range, approve, deny, timeout. Mere proximity must not release input.
- Agent: native synthetic mouse and key events, browser tools, accessibility actions, Escape, scrolling and drag operations. No unexpected approval prompts.
- Hardware: built-in trackpad, external mouse/keyboard, system gestures, hot corners, media keys, a newly connected device, remapper enabled/disabled.
- Integrity: disable/revoke the tap during a timed test, observe orange status, recover within budget, exceed budget, verify normal Quit still needs approval.
- Lifecycle: expire test during auth/quit, cancel pending auth, sleep/wake, session switch, display attach/detach, normal quit cleanup.
- Privacy: check actual notification previews and verify there is no misleading “securely locked” state.

## Sources

- [Apple Watch approval setup and explicit approval](https://support.apple.com/en-gb/guide/mac-help/mchl4f800a42/mac)
- [Watch/Mac requirements](https://support.apple.com/en-gb/102442)
- [LocalAuthentication policy](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithbiometricsorcompanion)
- [System gestures and turning them off](https://support.apple.com/en-gb/102482)
- [Screen Sharing grants remote desktop control](https://support.apple.com/en-nz/guide/mac-help/-mh11848/mac)
- Installed macOS SDK: LocalAuthentication/LAContext.h and Carbon/HIToolbox/CarbonEventsCore.h; used to verify version availability, Watch approval semantics, password fallback distinction and Secure Input API.
