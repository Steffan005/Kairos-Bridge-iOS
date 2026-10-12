# Kairos iPhone — invited development build

Native SwiftUI companion to the existing Kairos Journal service. Created by Steffan Douglas Haskins.

Current status, October12, 2026: the owner updated through TestFlight to **0.1.0 build2**, compiled from `b5df0ee312c02cf2fa046a4e8354ac6ff02b71d1`, and reported all existing notes intact. Actual Claude, ChatGPT and Grok iPhone conversations now read/write the same owner journal. ChatGPT and Grok records were independently matched to the hosted owner API and the owner confirmed both visible in native Kairos. Grok setup was completed through iPhone Safari; the native app's existing guided connection screen still targets Claude. Updated-build failure cases, independent onboarding and customer signup/recovery/retention remain open. These are invited-owner results, not a public App Store release. [ACCEPTANCE.md](ACCEPTANCE.md) preserves chronology and evidence.

### Anamnesis UI increment — October12

Steffan authorized implementation after Grok's design handoff. Current development source prepares **0.1.0 build3**: Aegean/ivory/decorative bronze, Anamnesis heading/bridge mark, fixed labeled Remember/Connect/Your journal actions,15 initially visible memories and **Show more** in groups of15. Project/author views filter the already-loaded set before display pagination. The owner API remains capped at50; the UI exposes loaded/total counts and does not offer a fake full-history fetch.

The connection screen now represents Claude, ChatGPT and Grok read/write approval scopes using exact client identities. Browser links open provider settings; they do not guarantee one-click onboarding or enabled tools in a new chat. Compose offers existing recent project labels; arbitrary exact display-name storage and a complete project catalog are deferred. Save/auth/owner-control logic is preserved except the recovered-draft action label.

The signed Simulator build and rendered checks passed on iPhone17. Maximum accessibility text size exposed a clipped Anamnesis heading; its layout was repaired and the full heading, wrapping notes and fixed labeled controls were observed. On the existing shared owner journal, actual Show more taps displayed15,30 and all40 loaded records. Kitchen plus Grok showed the expected note; the Connect and owner-control shortcuts remained reachable. Original text size and default filters were restored. No AI approval was removed during inspection.

All33 model fixtures,26 API callback/storage fixtures and22 display-window checks passed. The last suite compiles the same `JournalWindow` used by the native list and reads a private existing journal snapshot. It checks ordering, reveal bounds, retained prefixes, no duplicate IDs and filtering before pagination; it is separate from the actual Simulator taps. To run it, use `python3 scripts/check_journal_window.py /path/to/private-snapshot.json`; do not commit journal data. These results do not establish physical failure behavior or full accessibility certification. **Build3 archive/upload/physical acceptance are next; installed owner beta remains0.1.0(2).**

[Reviewed design handoff](DESIGN_HANDOFF_2026-10-12.md) records scope and the full-history/project-catalog dependencies.

Historical build1 acceptance: on October11, signed archive, export, upload and processing passed for version0.1.0 build1. The owner installed through TestFlight and completed a native/Claude round trip with refresh/full close/reopen. Native Sign out preserved approved Claude access; native Disconnect removed approvals while retaining eight notes. Export reached Files and matched all eight records. Offline Refresh retained displayed notes and online recovery refreshed automatically. Historical source sections below preserve earlier preparation/repair states; they do not override the current status above.

## Scope

- Native sign-in, journal, dated/attributed notes and compose controls.
- Device-bound Keychain sessions; no password saved by the app; ephemeral HTTP transport, fixed HTTPS origin and refused redirects.
- Provider approval views for Claude, ChatGPT and Grok, with guided Claude setup in the system browser and a Copy connection address fallback. App, browser and Claude sessions are separate. Approval is not proof the connector is enabled in the current chat.
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

The earlier hosted and synthetic SDK checks remain separate evidence. Physical native display and actual Claude/ChatGPT/Grok phone read/write establish the recorded paths on one invited account. Independent customer onboarding remains open; support is limited to the tested clients and setup paths.

## Preliminary model checks

```sh
python3 scripts/check_models.py
```

Thirty-three synthetic model checks run on macOS without network requests or Keychain access. Twenty-six additional actual-API callback/storage checks run with simulated responses; neither suite establishes physical-device failure behavior. They cover preserving an uncertain or newer draft and warning, using the submitted note/project snapshot, distinguishing a confirmed write from a failed refresh, rejecting a queued second save, clearing known revoked approval while preserving notes, hiding notes after acknowledged deletion, recreation and sign-out. These checks do not establish native cookie parsing or physical-device behavior.

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

### Second invited beta upload

Repaired source `b5df0ee312c02cf2fa046a4e8354ac6ff02b71d1` archived and exported as **0.1.0 build 2**. Strict signature verification and the App Store beta profile checks passed. Apple acknowledged upload success and processing start at **2026-10-12T00:04:58Z** (October 11 evening ET), using the existing Xcode account; no API key was used. The earlier package from `0bb4d79` was superseded and never uploaded.

Processing completion, assignment to Kairos Owner Pilot and physical build-2 install/failure acceptance are still unverified. The physical results above remain build 1. Grok received the 7:30 PM review request; no fresh reply was captured. The focused local review found and repaired the defects described above. This is invited synthetic staging, not public release.

### Build2 processing and group assignment

The operator's October11 8:31PM ET App Store Connect screenshot shows **0.1.0 build2, Ready to Submit**, the existing Kairos Owner Pilot group badge, one invite and one install. Build1 remains listed. This establishes processing/group assignment by screenshot. The aggregate install metric does not establish the current owner-phone version or updated behavior; that physical confirmation is next. No new note or provider reauthorization is requested during the version/open check.

### Superseding build2 owner update and shared-provider milestone

The owner subsequently reported TestFlight's Update prompt, opening build2 and all existing notes retained. October12 actual ChatGPT phone note `534e5fc17915cd3a` and Grok phone note `c5bbceab828402c9` were independently matched to the same hosted journal, and the owner refreshed native Kairos and explicitly confirmed both visible. Another fresh Grok phone conversation recovered its write without reconnecting. A separate Mac Grok web-app conversation displayed an actual matching connector request/result.

Native/provider shared-journal acceptance now includes Claude, ChatGPT and Grok on the owner's iPhone. No native executable change, new build or TestFlight upload was needed for those added provider connections. The33 model/26 API callback fixtures are earlier synthetic evidence; physical ambiguous-write/session-expiry cases remain untested. Grok-specific native Sign out/Disconnect and an independent tester remain open.
