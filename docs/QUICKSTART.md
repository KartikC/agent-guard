# Using Agent Guard

1. Open the DMG and drag Agent Guard into Applications. Quit older copies before opening it. Keep one version running.
2. Grant the app Accessibility access in System Settings. Reopen it if macOS requests this.
3. Run the 15-second test. Approve with Touch ID or Apple Watch. Try your physical keyboard, mouse/trackpad and your real agent. Physical input should be blocked; software agent actions should continue.
4. During another test, click or press Escape and approve to restore input early. The backup shortcut is Control–Option–Command–U. After cancelling a prompt, wait 10 seconds before trying again.
5. Confirm the test checkbox and start the guard. This confirmation is saved on this Mac for your user account; future launches do not require another test. You can still rerun the timed test whenever you want.

While guarded, a small glass pill appears in each display's bottom-right corner. It does not take focus and clicks from software reach the apps beneath it. Click or Escape requests approval. Dock Stop and normal Quit also require approval.

Closing the controls leaves the app running. Quit to release keep-awake and input filtering. The app follows system light/dark appearance automatically. Reduce Motion freezes the orb; Reduce Transparency uses a solid native surface.

Apple Watch must be configured for macOS app approval. It needs the appropriate paired/account setup and an unlocked worn Watch; follow [Apple's setup instructions](https://support.apple.com/en-gb/102442). Being nearby is not approval. This app does not add iPhone Face ID unlocking.

If neither Touch ID nor Watch approval is available, the app does not offer password fallback. The timed test still expires. For recovery from a stuck indefinite session, normal system recovery or a restart remains possible; a restart can lose unsaved work. Test recovery before relying on the guard.

An orange warning means input may have passed or protection is unreliable. Review the workspace and use the real macOS lock screen when security matters. Notification Center gestures are a known gap. Manual locking, lid closure, restart and managed policies can also stop agent work; this app cannot unlock macOS afterward.

The downloaded initial build is ad-hoc signed, not notarized. macOS may block opening it. Follow macOS's own software approval flow only if you trust the source; do not disable Gatekeeper globally. See [Apple's guidance](https://support.apple.com/en-us/102445).
