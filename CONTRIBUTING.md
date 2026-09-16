# Contributing

Use Xcode with the macOS 26 SDK. The app runs on Apple silicon with macOS 13 or later.

```sh
bash test.sh                 # pure logic; no app launch or system changes
bash build.sh               # build/Agent Guard.app and .zip
bash build.sh --preview     # separate documentation-only UI
bash scripts/package-dmg.sh # downloads/AgentGuard-0.2.0-arm64.dmg
```

The preview app's Preview menu has System, Light, Dark and Status Pill options. These affect only that app, never the system preference. Screenshot the app window alone; do not include personal desktop content or authentication dialogs.

Keep changes small and include what changed, why, and the checks performed. Report OS/device/agent combinations when filing input compatibility bugs. Do not attach typed content, credentials or unredacted desktop screenshots. Hardware checks are listed in [the security review](docs/SECURITY_REVIEW.md).

Rebuilds change the local ad-hoc signature; macOS may require Accessibility permission again. Quit a running copy before replacing it. Publishing is a separate step from building. A public release intended for frictionless installation should use Developer ID signing and notarization; the bundled initial artifact does not claim either.
