# Agent Guard icon

Generated with the built-in image-generation tool, then resized with macOS `sips` and packaged with `iconutil`. The original RGBA master is `AgentGuard.png`. `build-icon.sh` produces all standard iconset representations from 16 through 1024 pixels. `AgentGuard.icns` is embedded in the application bundle via `CFBundleIconFile`.

Design: one graphite rounded-square tile, a clear silver shield and a single orbital ring. No text, interface screenshots or tiny ornaments. The transparent outer margin is retained at every size. The concept follows Apple's guidance to express the app through a simple, unique idea with minimal shapes and avoid text. This is a conventional static macOS icon supporting this app's macOS 13+ target, not a multilayer Icon Composer/Liquid Glass asset.

References:
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer

Generation prompt:

> Create one production macOS application icon for Agent Guard. Square 1024x1024 image with a truly transparent background outside the icon. Centered classic macOS continuous rounded-square tile occupying approximately 824x824 pixels centered on the 1024 canvas (roughly 100 px transparent margin each side). Graphite almost-black subtly blue tile with restrained soft depth, clean bevel and subtle drop shadow. Center a bold simple pearlescent silver-white shield silhouette with softly rounded corners, minimal elegant 3D material; integrate one clean tilted orbital ring around the shield to suggest continuous agent activity. One unified emblem, unmistakable readable silhouette at small sizes. Calm sophisticated native Mac utility design, not gaming or cybersecurity clip art. Front-facing orthographic composition, no perspective on the tile. Excellent negative space. No letters, no text, no watermark, no fingerprint, no tiny ornaments, no stars, no excessive glow. A finished isolated application icon, not a mockup or presentation board.

The generator returned a 1254-pixel square RGBA master; packaging explicitly resizes to the standard macOS representations.
