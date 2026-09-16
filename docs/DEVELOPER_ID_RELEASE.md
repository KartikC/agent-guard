# Developer ID release

The current downloadable DMG remains ad-hoc signed until the following release is completed. Preparing these scripts does not sign or notarize the existing download.

1. Install a valid Developer ID Application certificate with its private key in the login keychain. Never put private keys or credentials in this repository.
2. Run `bash test.sh`, then set the non-secret `AGENTGUARD_SIGN_IDENTITY` environment variable to that identity's SHA-1 fingerprint and run `bash scripts/package-dmg.sh`. The app gets Hardened Runtime and a secure timestamp; both app and DMG are signed. The default build remains ad-hoc for contributors.
3. Submit the DMG with `xcrun notarytool submit downloads/AgentGuard-0.2.1-arm64.dmg --keychain-profile PROFILE --output-format json`. PROFILE must be an existing authorized notarization keychain profile. Record the submission ID and poll `notarytool info`; inspect `notarytool log` if rejected. Do not treat upload as acceptance.
4. Once Apple returns Accepted, run `xcrun stapler staple downloads/AgentGuard-0.2.1-arm64.dmg` and `xcrun stapler validate downloads/AgentGuard-0.2.1-arm64.dmg`. Verify the DMG with `hdiutil verify` and Gatekeeper with `spctl --assess --type open --context context:primary-signature --verbose=2 downloads/AgentGuard-0.2.1-arm64.dmg`.
5. Mount read-only, verify the enclosed app's Developer ID signature, Hardened Runtime, arm64 architecture and Gatekeeper assessment, then detach. This does not require launching the app.
6. Recompute downloads/SHA256SUMS after stapling. Update README, SECURITY, INSTALL, QUICKSTART, APP_STORE_READINESS and VERIFICATION to match verified release status. If INSTALL content changes, rebuild and notarize the final DMG containing that content. Refresh the source archive last.

Developer ID signing and notarization do not establish Mac App Store eligibility and do not change the app's input-guard security model. Do not replace the running app during release preparation.
