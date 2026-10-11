# Kairos iPhone — invited development build

Native SwiftUI companion to the existing Kairos Journal service. Created by Steffan Douglas Haskins.

Status: on October 11, 2026, a signed build was installed and opened on a physical iPhone. A note saved in that native app was retrieved in a fresh actual Claude iPhone conversation, which wrote a reply into the same journal. A separate owner API read confirmed both exact records. Signed archive, App Store distribution export and Apple upload succeeded for version 0.1.0, build 1. Apple reported the package processing. The store record is Kairos-Bridge; TestFlight processing completion, invitation and installation remain unconfirmed. See [ACCEPTANCE.md](ACCEPTANCE.md) for the separate Simulator results and remaining gates. Customer signup, identity recovery and retention remain unfinished.

## Scope

- Native sign-in, journal, dated/attributed notes and compose controls.
- Device-bound Keychain sessions; no password saved by the app; ephemeral HTTP transport, fixed HTTPS origin and refused redirects.
- Guided Claude setup in the system browser, with a Copy connection address fallback. App, browser and Claude sessions are separate. Approval is not proof the connector is enabled in the current chat.
- Owner export/share, explicit Disconnect, sign-out and confirmed active-journal deletion with the actual retention notice.
- Visible stale/offline/error states. Drafts survive view dismissal in memory, not app termination. No automatic note retry or idempotent-write guarantee.

The Journal and existing App repositories remain separate. This native target owns the iPhone UI only. It does not host MCP on the phone, run an AI model or read arbitrary provider conversations.

## Build

Install Apple's full Xcode and iOS platform support. Accept the Apple license yourself if prompted. No App Store Connect API key is needed for a first Simulator build.

```sh
python3 scripts/generate_project.py
# Compilation only; this unsigned build is not the runtime acceptance build.
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Kairos.xcodeproj -scheme Kairos \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

For Simulator runtime, select an installed iPhone Simulator in Xcode, or supply its UDID to the following command:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Kairos.xcodeproj -scheme Kairos \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- build
```

The runtime check used Xcode's ad hoc Simulator signature and generated application-identifier entitlement. The unsigned app compiled but reported a secure-storage error on launch; the Simulator-signed build loaded and persisted its session. This is not Apple Developer team signing for a device or TestFlight.

Open `Kairos.xcodeproj` in Xcode for the Simulator. Use only the disposable account provided privately by the operator. Credentials, invitation codes, exports and actual journals must not enter Git or public screenshots.

`com.steffanhaskins.kairos` was registered through Xcode automatic provisioning and used for the signed physical-device build, App Store distribution export and successful upload to the Kairos-Bridge app record. Put your local `DEVELOPMENT_TEAM` and any alternate `PRODUCT_BUNDLE_IDENTIFIER` in the ignored `Config/Signing.local.xcconfig` so project regeneration preserves them. No team is configured in the public source. Customer account deletion and store privacy disclosures remain ahead.

The included original beta icon is an opaque 1024-pixel PNG compiled through `Assets.xcassets`. Regenerate its artwork with `swift scripts/generate_icon.swift` on macOS. The project generator includes the catalog and the signing configuration; normal users do not run these developer scripts.

## Acceptance still required

1. Repeat the remaining Simulator-only checks on a physical iPhone. Physical installation, sign-in, owner save and actual Claude retrieval/write have passed on the author's phone.
2. Confirm secure-cookie handling and device-bound session persistence on that physical device.
3. Explicitly confirm display of Claude's reply after native refresh, then repeat the native/provider round trip with an independent tester. The physical Claude test used keyword search because the owner left the optional project field empty; exact project-tag retrieval of that owner note was not tested.
4. Observe loss of network, expired session and ambiguous save status; avoid inventing a successful fetch or silently duplicating a note.
5. Repeat export, sign-out and Disconnect on a physical device; complete export delivery to Files. Simulator export preparation/share-sheet and access-control checks passed. The delete warning was inspected and cancelled; final active deletion requires explicit operator confirmation.
6. Use a clean provider account and independent tester for guided setup.
7. Confirm Apple processing, invite the owner to an internal TestFlight group, and complete TestFlight installation before release automation. The upload receipt is not a TestFlight installation receipt.

The earlier hosted and synthetic SDK checks remain separate evidence. The physical native/Claude read-write result now establishes this client path on one invited account, not clean customer onboarding or support for other providers.

## Preliminary model checks

```sh
python3 scripts/check_models.py
```

Fourteen synthetic checks run on macOS without network requests or Keychain access. They cover preserving an uncertain draft, distinguishing a confirmed write from a failed refresh, rejecting a queued second save, clearing known revoked approval while preserving notes, hiding notes after acknowledged deletion, recreation and sign-out. These checks do not establish native cookie parsing, iOS SDK compilation or physical-device behavior.

License: AGPL-3.0-or-later, matching the existing Journal source. See LICENSE.
