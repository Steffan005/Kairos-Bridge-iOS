# Kairos-Bridge app icon

Steffan selected the original black-and-gold bridge on October 14, 2026 after reviewing Unalome-inspired and spiral alternatives. The broad double arch and returning Greek-key turns support the slogan, **The bridge to remembrance**. Carrying memory across a gap and returning to what matters are our intended design meanings.

`AppIcon-master.png` preserves the original 1254 × 1254 opaque artwork generated with the built-in image tool. Master SHA-256: `48fe5ed4295685d0723d8a1676d016be136b35bff66f7f8a9e5ded696059b38f`.

`swift scripts/generate_icon.swift` packages that master into an opaque 1024 × 1024 sRGB PNG in the app icon catalog. It performs dimension/color-space conversion only, without cropping, redrawing, adding corners, or changing the composition. iOS applies its own icon mask. The master remains unchanged.

The original concept prompt and other candidates are preserved in the owner's product plan. Native build 6 carries the selected icon; a source version alone does not establish TestFlight availability or phone installation.
