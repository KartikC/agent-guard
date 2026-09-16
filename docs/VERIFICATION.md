# Verification — 0.2.1, build 8

Prepared 2026-09-16. Release preparation checks are listed below; no social post has been published.

## Completed

- Pure-policy tests pass: physical/software event handling, recovery shortcut, software Escape, bounded recovery, prompt cooldown, biometric-or-companion policy.
- Release app compiles for arm64, deployment target macOS 13, using the installed macOS 26 SDK.
- Ad-hoc app signature verified before packaging and again inside the read-only mounted DMG.
- DMG checksum verified. Mounted contents include Agent Guard.app, an `/Applications` symlink and Read Me.txt. App architecture is arm64 and version is 0.2.1. Image was detached afterward; app was not installed or launched from it.
- Actual controls and native glass pill inspected in light and dark appearance through a separate documentation-only build. Screenshot captures contain only app windows. Capture metadata was removed.
- Production defaults to inherited system appearance. Light/dark overrides exist only behind DOCS_PREVIEW; no global settings were changed.
- Video decoded successfully: 6 seconds, 1080×1080, 30 fps, H.264/yuv420p, fast-start MP4, no audio. Real native glass pill captured in light and dark mode over the requested wallpaper; no warning dialogue. Representative frames inspected.
- Local documentation links and download checksum verified. Text source checked for personal filesystem paths and common credential patterns; none found.

## Not claimed

This public package is not Developer ID signed, notarized or App Store reviewed. UI preview is not evidence of authentication, agent compatibility or physical input blocking in this build. Touch ID/Watch approval and hardware/system interruption tests remain the manual checks in SECURITY_REVIEW.md. Existing user-reported behavior from earlier builds is not a substitute for that acceptance pass.

The documentation build creates no input tap, authentication request or wake assertion. The user's running guard was not replaced during this preparation.

- First-run checklist confirmation persists in UserDefaults. Verified checked state after quitting and relaunching the isolated preview; production preferences and the running guard were not changed.
