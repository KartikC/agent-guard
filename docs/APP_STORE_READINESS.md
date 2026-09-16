# Mac App Store readiness

Assessed 2026-09-16 for version 0.2.1. Status: **blocked; no App Store build or submission produced**. The working app and direct-download DMG are unchanged.

## Technical blocker

The guard in `Source/main.swift` checks Accessibility trust and installs an active `CGEvent.tapCreate` session event tap with `.defaultTap`. It suppresses physical input across applications while permitting software events. This is the core product behavior, not an optional feature.

[App Review guideline 2.4.5(i)](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility) requires Mac App Store apps to be sandboxed. Apple's [App Sandbox documentation](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox) lists Accessibility APIs in assistive apps among incompatible functionality. The current implementation therefore has no established supported sandbox-compatible distribution path. Simply adding the sandbox entitlement or changing the signature does not establish a working store build.

This assessment is based on source inspection and Apple's documentation, not an App Review decision or a sandboxed runtime test. Apple technical guidance and a working sandboxed prototype preserving physical-input filtering would be required to revisit it. Guideline 2.5.9 on disabling native behaviors is a separate review concern to discuss transparently.

## Intended commercial configuration

- Product: Agent Guard, macOS, Apple silicon.
- Requested price: **US $0.99, one-time paid download**; no subscription or in-app purchase.
- Price is an App Store Connect setting, not embedded in the binary. Nothing has been configured in App Store Connect.
- If eligibility is resolved, choose the United States base storefront and $0.99 price point; review regional equivalents before release. The account holder must have the required paid-app agreement and completed financial setup. See [Apple's pricing instructions](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price).
- Remaining release work includes developer-owned bundle ID, distribution signing/provisioning, validated archive, privacy/support URLs, store-sized screenshots, privacy and age-rating declarations, and actual hardware acceptance tests. Existing social video and cropped documentation screenshots are not validated App Store assets.

## Technical inquiry draft — not sent

Agent Guard is an opt-in macOS convenience input guard for trusted environments. It keeps an already-unlocked desktop awake for agent automation, passes software-generated events, and suppresses ordinary physical keyboard and pointer events using an active session CGEvent tap with Accessibility approval. Touch ID or Apple Watch approval ends the guard through LocalAuthentication. It does not claim to be a macOS lock screen or security boundary.

Is there a supported App Sandbox-compatible API or approved entitlement for this cross-application input suppression while preserving software automation? We understand guideline 2.4.5 requires sandboxing and the sandbox documentation excludes assistive Accessibility APIs. We would also like guidance on whether this explicitly user-enabled behavior is acceptable under guideline 2.5.9.

## Recommended distribution

Preserve the full product through direct distribution, with Developer ID signing and notarization as the next release milestone. The existing DMG is only ad-hoc signed and is not notarized. A sandboxed keep-awake utility without physical-input filtering would be a different product and should not be sold as this guard.
