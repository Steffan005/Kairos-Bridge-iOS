# Kairos iPhone — invited development build

Native SwiftUI companion to the existing Kairos Journal service. Created by Steffan Douglas Haskins.

Status: on October 11, 2026, signed archive, export, upload and processing passed for version 0.1.0, build 1. The operator installed Kairos-Bridge through Apple's TestFlight invitation and opened its journal. A new tagged native note was retrieved in a fresh actual Claude iPhone chat, which saved a reply. An independent owner API read confirmed both exact records; the operator confirmed the reply remained visible after native refresh/full close/reopen. Native Sign out preserved approved Claude access. Native Disconnect removed every approved connection while retaining all eight notes, independently confirmed through the owner API. The actual native export reached Files and matched all eight records. Offline Refresh reported failure, then the app refreshed automatically when connectivity returned. See [ACCEPTANCE.md](ACCEPTANCE.md) for evidence and remaining gates. Other physical failure checks, clean onboarding, customer signup/recovery and retention remain unfinished.

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
3. Repeat the passed TestFlight native/provider/reopen path with an independent tester. The original development-install owner note was untagged and found by keyword; the later TestFlight owner and Claude notes both carry project-kitchen.
4. Complete expired-session and lost-response-after-commit checks; avoid inventing a successful fetch or silently duplicating a note. Physical offline Refresh/error, visible loaded-note retention, draft retention and automatic online recovery passed. The operator manually saved after reconnecting; one resulting note was independently confirmed. The exact offline Save warning/dispatch was not captured.
5. Repeat passed physical export, Sign out and Disconnect with an independent tester. All eight delivered export records matched the live owner API and their hashes/links recomputed correctly. The delete warning was inspected and cancelled; final active deletion requires explicit operator confirmation.
6. Use a clean provider account and independent tester for guided setup.
7. Complete physical TestFlight owner-control/failure checks before release automation or a wider pilot. Invitation/install and native/provider read-write/reopen have passed on one invited account with an existing approved connector.

The earlier hosted and synthetic SDK checks remain separate evidence. The physical native/Claude read-write result now establishes this client path on one invited account, not clean customer onboarding or support for other providers.

## Preliminary model checks

```sh
python3 scripts/check_models.py
```

Twenty synthetic checks run on macOS without network requests or Keychain access. They cover preserving an uncertain or newer draft and warning, using the submitted note/project snapshot, distinguishing a confirmed write from a failed refresh, rejecting a queued second save, clearing known revoked approval while preserving notes, hiding notes after acknowledged deletion, recreation and sign-out. These checks do not establish native cookie parsing or physical-device behavior.

### Source change after TestFlight build 1

A focused check reproduced loss of newer text when an earlier asynchronous save succeeded. The updated source snapshots the submitted note/project, clears only unchanged values, and explains when a newer draft is kept. Compose fields and interactive dismissal are disabled during a request. A second fixture reproduced refresh replacing an unconfirmed-save warning; that warning now survives both failed and successful reads until a confirmed save or session/journal reset. All twenty model checks and unsigned iOS Simulator SDK compilation passed. These changes have **not** been uploaded or installed through TestFlight; the physical results above belong to build 1.

Updated source `ade8045` subsequently passed Simulator-signed install, native sign-in, owner save and full termination/relaunch. A separate owner API confirmed the new tagged note; the reopened native app retrieved it without another sign-in. Fault injection and updated physical acceptance remain open. The generated project now prepares version **0.1.0, build 2**; that version change is preparation, not an Apple upload receipt.

License: AGPL-3.0-or-later, matching the existing Journal source. See LICENSE.

### Acknowledged response versus local session storage

An injected HTTP 201 reproduced a confirmed note write being reported as failed when secure cookie persistence threw. The client now preserves the server acknowledgement and separately warns that this device may need a new sign-in. Unchanged cookies no longer trigger a redundant vault write. Initial sign-in still requires secure persistence; acknowledged sign-out distinguishes local cleanup failure.

`python3 scripts/check_api_responses.py` passed sixteen synthetic checks of the actual API client with injected HTTP callbacks and storage: acknowledged save, unchanged cookies, strict sign-in, known sign-out cleanup, and acknowledged Disconnect preserving notes and clearing approval. No live network or physical Keychain fault was used. Twenty existing synthetic model checks and actual signed Simulator SDK compilation also passed.

The earlier exported 0.1.0 build-2 candidate is superseded and was not uploaded. This source repair still requires normal native runtime acceptance and a freshly archived candidate before another upload. Session-expiry and ambiguous-response checks remain open; build 1 remains the physical TestFlight evidence.

### Expired sign-in and ambiguous save response repairs

Focused failing fixtures reproduced expiry erasing an unsent draft and an ambiguous server failure omitting the uncertainty warning. The model holds the expired account's draft in app memory, hides the journal/active draft after 401, and restores it only when the same server-reported account email signs in again. A different account does not receive it. Explicit session reset discards the held draft. The message explains that it survives only while Kairos stays open; there is no durable draft storage across process termination.

Save outcomes from transport/cancellation, invalid responses, 408 and 5xx remain unconfirmed. Later reads retain the warning, and mutations are not automatically retried. Known validation rejection remains distinct. Thirty-three synthetic model checks and twenty-six actual-API callback checks passed, including simulated commit followed by 503 or a dropped reply. These are injected macOS faults, not physical iPhone/Keychain faults.

The signed Simulator SDK target passed and the repaired app installed/launched, restored the existing session and retrieved the exact amber note with its actor/date/project and fresh timestamp. No new native save or native-UI fault injection is claimed for this revision. The previous build-2 package remains superseded; a fresh exact archive is required. Physical TestFlight remains build 1.
