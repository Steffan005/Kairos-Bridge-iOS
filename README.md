# Kairos iPhone — invited development build

Native SwiftUI companion to the existing Kairos Journal service. Created by Steffan Douglas Haskins.

Status: first source target, not a signed TestFlight or App Store release. Build and physical-device acceptance must be recorded separately. This consumes the invited staging service; customer signup, identity recovery and retention remain unfinished.

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
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Kairos.xcodeproj -scheme Kairos \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

Open `Kairos.xcodeproj` in Xcode for the Simulator. Use only the disposable account provided privately by the operator. Credentials, invitation codes, exports and actual journals must not enter Git or public screenshots.

`com.steffanhaskins.kairos` is a provisional development identifier, not a registered App Store identity. Select the correct signing team and settle the identifier before a device archive. Icons, signing, customer account deletion and store privacy disclosures are release work still ahead.

## Acceptance still required

1. Compile the actual target with the installed iOS SDK.
2. Sign in through the native transport; prove secure-cookie parsing and app relaunch persistence.
3. Retrieve a dated note, save a note, retrieve it from Claude, and read the AI's saved note in the app.
4. Observe loss of network, expired session and ambiguous save status; avoid inventing a successful fetch or silently duplicating a note.
5. Check export, sign-out and Disconnect using a disposable account; active deletion requires explicit operator confirmation.
6. Use a clean provider account and independent tester for guided setup.
7. Produce a signed manual archive and internal TestFlight install before release automation.

The hosted provider round trip has already been tested separately. That does not establish acceptance of this native client.

License: AGPL-3.0-or-later, matching the existing Journal source. See LICENSE.
