# Kairos iPhone — invited development build

Native SwiftUI companion to the existing Kairos Journal service. Created by Steffan Douglas Haskins.

Status: the iOS SDK build and the first Simulator runtime checks passed on October 11, 2026. Native sign-in, note save, recovery after relaunch, export preparation, sign-out and Disconnect were exercised against the invited HTTPS service. See [ACCEPTANCE.md](ACCEPTANCE.md) for scope and remaining gates. Physical iPhone installation and TestFlight remain pending; customer signup, identity recovery and retention remain unfinished.

## Scope

- Native sign-in, journal, dated/attributed notes and compose controls.
- Device-bound Keychain sessions; no password saved by the app; ephemeral HTTP transport, fixed HTTPS origin and refused redirects.
- Guided Claude setup in the system browser. App, browser and Claude sessions are separate. Approval is not proof the connector is enabled in the current chat.
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

`com.steffanhaskins.kairos` is a provisional development identifier, not a registered App Store identity. Select the correct signing team and settle the identifier before a device archive. Icons, signing, customer account deletion and store privacy disclosures are release work still ahead.

## Acceptance still required

1. Repeat the completed SDK and Simulator checks on a physical iPhone.
2. Confirm secure-cookie handling and device-bound session persistence on that physical device.
3. Complete native app → actual Claude iPhone conversation → native app read/write. The completed synthetic MCP SDK round trip is a protocol check, not an actual Claude or ChatGPT conversation.
4. Observe loss of network, expired session and ambiguous save status; avoid inventing a successful fetch or silently duplicating a note.
5. Repeat export, sign-out and Disconnect on a physical device; complete export delivery to Files. Simulator export preparation/share-sheet and access-control checks passed. The delete warning was inspected and cancelled; final active deletion requires explicit operator confirmation.
6. Use a clean provider account and independent tester for guided setup.
7. Produce a signed manual archive and internal TestFlight install before release automation.

The hosted provider round trip has already been tested separately. That does not establish acceptance of this native client.

## Preliminary model checks

```sh
python3 scripts/check_models.py
```

Fourteen synthetic checks run on macOS without network requests or Keychain access. They cover preserving an uncertain draft, distinguishing a confirmed write from a failed refresh, rejecting a queued second save, clearing known revoked approval while preserving notes, hiding notes after acknowledged deletion, recreation and sign-out. These checks do not establish native cookie parsing, iOS SDK compilation or physical-device behavior.

License: AGPL-3.0-or-later, matching the existing Journal source. See LICENSE.
