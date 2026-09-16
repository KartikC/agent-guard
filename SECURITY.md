# Security model

Agent Guard is for discouraging casual local interaction in a trusted environment while an agent uses an unlocked Mac. It is not a lock screen, kiosk boundary, endpoint security product, or defense against a determined person with access to the session.

The desktop remains readable. Software input is intentionally allowed based on event source PID. System gestures, remote control, accessibility automation, remappers, virtual input devices and process termination can bypass the guard. Secure Input and disabled event taps can prevent filtering. An orange warning reports degraded protection; recovery cannot undo events that already passed.

Touch ID/Apple Watch approval gates the app’s normal Stop and Quit actions. Apple decides which enrolled biometrics/companions are authorized. Watch approval is explicit, not a proximity trigger. The 15-second test deliberately releases input without approval at expiry.

No custom credentials, biometric data, keystroke contents, analytics or network service are used. The app needs Accessibility to filter input. It does not need root, Full Disk Access, Screen Recording or a background helper.

[Detailed interaction paths and manual checks](docs/SECURITY_REVIEW.md).

## Reporting

Report vulnerabilities privately through [GitHub security advisories](https://github.com/KartikC/agent-guard/security/advisories/new). Ordinary compatibility issues can use [GitHub Issues](https://github.com/KartikC/agent-guard/issues); omit sensitive data and include macOS version, hardware and reproduction steps.

## Distribution

The included initial DMG is ad-hoc signed and checksum-verified, but **not notarized**. A checksum detects an accidental change; it does not establish a publisher’s identity. Production signing and notarization remain release work.
