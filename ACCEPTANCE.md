# Native Kairos acceptance — October 11, 2026

Actor: ChatGPT / gpt_codex. Scope: Kairos native iPhone client.

## Environment and build

- Apple Xcode 27.0 (27A266a), iOS Simulator SDK 27.0; runtime iPhone 17 Simulator on iOS 26.0.
- Steffan accepted the separate Xcode and Apple SDKs Agreement himself.
- The actual target compiled successfully against the iOS SDK. The Simulator runtime used ad hoc signing (`CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`) with Xcode's generated application-identifier entitlement.
- A separate unsigned `generic/platform=iOS` build also passed for the physical-device target. This establishes device-target compilation, not installation or device signing.
- The initial unsigned app compiled but showed a secure-storage error. That error was absent after Simulator signing; native sign-in and session persistence then passed. No Apple Developer certificate, team provisioning or TestFlight signature is established by this result.
- The earlier six-file syntax/type checks, project/scheme parsing and fourteen macOS synthetic model checks remain separate preliminary evidence.

## Observed runtime checks

One disposable account on the existing invited HTTPS service was used. No personal journal or real customer data entered this check.

| Check | Observed result |
| --- | --- |
| Native sign-in and retrieval | Native HTTP transport signed in and displayed the fixture note with its source, date and project. |
| Native note save | The on-screen phone keyboard entered `synthetic native note`; Save completed, and a separate owner API read confirmed the exact text, actor `you`, timestamp and project tag. |
| Relaunch | After process termination and relaunch, the app recovered its saved session and fetched the journal without another password entry. |
| Synthetic MCP round trip | A separate MCP SDK client retrieved the native note and saved a `chatgpt` note. The reopened native app displayed all three records, newest first. Synthetic PKCE was used; no real provider callback was followed and no Claude/ChatGPT conversation took place. |
| Export | The native app prepared a JSON file containing all three notes, opened Apple's share sheet, and the file was independently checked. No external share or completed Save to Files was performed. |
| Sign-out | Native sign-out returned directly to the sign-in screen. A new MCP client process still retrieved the approved journal; all three notes and one grant remained. |
| Disconnect | The native confirmation was accepted. A separate request using the previously valid AI credential received HTTP 401; all three notes remained and approved connections became zero. |
| Delete warning | The irreversible warning was displayed and cancelled. No native deletion was performed. |
| Connection fallback | The native Copy connection address button displayed its acknowledgement on Simulator. Actual paste into a physical-phone provider setup remains open. |
| Beta icon | Original opaque 1024 x 1024 artwork compiled through the asset catalog in Simulator and unsigned device builds. Kairos appeared on the Simulator home screen and reopened its journal. |

The first sign-out attempt exposed a real navigation bug: the owner session ended but a pushed control screen remained visible. Resetting the navigation stack at the sign-in boundary corrected it; the rebuilt app passed the same sign-out path.

## Remaining acceptance

- Independent repetition of the passed TestFlight native/Claude read-write and refresh/reopen path. Owner session recovery/retrieval after full close/reopen is operator-confirmed.
- A clean provider setup and independent tester for the guided connection path. Prior hosted Claude iPhone tests are separate evidence.
- Native network loss, expired-session handling, ambiguous save outcomes and control-request failures. Existing synthetic model checks do not establish those runtime conditions.
- Completed export delivery to Files and final deletion/recreation with explicit operator confirmation.
- Physical TestFlight owner-control/failure checks. Invitation/install and native/provider read-write/reopen passed; App Store review remains separate.
- Customer signup, account recovery, complete account deletion and production retention/disclosure work.

The registered bundle ID is `com.steffanhaskins.kairos`. The app consumes the existing invited staging origin. No customer credentials, invitation values, private exports, actual journals or Apple signing keys are included in this repository.

## Physical iPhone and distribution follow-up

Compiled source: `acc89ce65003e2f2d88da341025ac2e3df675d1a`, version 0.1.0, build 1. Device: iPhone 18 Pro Max on iOS 27.0.1. The operator enabled Developer Mode and completed Apple's private sign-in steps himself.

- Xcode automatic provisioning produced a signed Release device build and registered the bundle identifier. Device installation and launch returned success, and the operator confirmed the native sign-in screen.
- A native owner save produced synthetic note `8447fbf4fef1733f`, actor `you`, timestamp `2026-10-11T12:17:59.009Z`. The operator confirmed that the optional project field was left empty, so its tags are empty.
- A fresh actual Claude iPhone conversation retrieved that note through `journal_search` using the word kitchen. It saved synthetic reply `e5c32c4d0627012d`, actor `claude`, timestamp `2026-10-11T12:18:58.077Z`, tag `project-kitchen`.
- An independent owner API read returned HTTP 200 and both exact records. The journal contained four notes. The operator reported the requested instructions complete; native display of the reply after refresh was not separately stated or captured.
- Signed Release archive and App Store distribution export succeeded. Both app signatures passed strict verification. The exported profile has no device list, permits beta reports, and disables `get-task-allow`. This proves package preparation, not TestFlight availability.
- The first upload attempt failed with Apple's explicit error that the matching App Store Connect app record was not found. There is no successful upload, processed build or TestFlight invitation receipt yet.

### Superseding upload receipt

The operator created the matching app record with name **Kairos-Bridge**, after Apple rejected **Kairos** as already in use. The repeated Xcode upload returned exit 0 and `EXPORT SUCCEEDED`. Apple logged `Upload succeeded` at `2026-10-11T12:31:51Z` and reported the package processing. This clears the missing-record/upload gate above. Processing completion, internal group invitation and TestFlight installation remain unconfirmed. No App Store Connect API key was used, and no public App Store release was submitted.

### Superseding processing and owner-group checkpoint

On October 11 evening ET, the operator's TestFlight screenshot and a fresh browser DOM/accessibility read agreed on version **0.1.0**, build **1**, status **Ready to Submit**, with the compiled beta icon. Processing is complete. Apple's separate Distribution page has a draft App Store version 1.0; this is distinct from the uploaded beta version.

The operator reports creating **Kairos Owner Pilot**, adding himself as an internal tester and adding the build. Browser tab metadata independently showed the created group URL, but its Builds/Testers panel was not captured. Computer-use mutation dispatch and native window controls failed during this workflow. The operator did not see a What to Test field; the prepared synthetic instructions are retained for build details. Invitation delivery, TestFlight installation and the return display in native Kairos remain open. No invitation credential is published here.

### First TestFlight installation

The operator subsequently reported receiving Apple's invitation in Gmail, opening its link, installing Kairos-Bridge through TestFlight and opening the app to **JOURNAL**. This completes the first owner invitation/install/open gate. The installation was reported from the physical phone; an install/version screenshot was not captured. No additional sign-in was reported.

A new TestFlight owner save with project `kitchen`, fresh actual Claude read/write, native refresh and close/reopen has been requested. That pending check remains separate from the passed development-install round trip. No separate redemption code or invitation URL has been received by the builder, and none is stored in public source.

### Passed TestFlight read/write/reopen

- Native owner note `0fd393260adc05f2`, actor `you`, `2026-10-11T22:14:44.327Z`, contains the synthetic copper-kettle note and `project-kitchen`.
- A NEW actual Claude iPhone conversation retrieved it and saved reply `0c2a77086997a5ff`, actor `claude`, `2026-10-11T22:17:35.991Z`, also `project-kitchen`.
- A separate owner API read returned HTTP 200 and both exact text/IDs/full timestamps/tags. That journal contained six notes.
- The operator explicitly confirmed Claude's reply was still visible after native refresh, full close and reopening. No additional sign-in was reported.

These results complete the first TestFlight native/provider/re-entry gate. They use one invited account and an already approved connector. Export delivery, failure handling, clean first-time setup and an independent tester remain open. Physical native Sign out/Disconnect passed subsequently, as recorded below. The earlier Simulator control checks remain distinct evidence.

### Passed native TestFlight Sign out and Disconnect

- The operator confirmed native Sign out returned to the Sign in screen. A NEW actual Claude chat used `journal_continue` to read the newest reply without reconnecting or writing. A separate owner API read retained six notes and one approval at observation.
- An old private credential/test file led to a repeated owner/Claude test. Owner note `c22475fea68a901e` at `2026-10-11T22:36:02.636Z` and Claude reply `87f8c23beea4b34d` at `2026-10-11T22:36:44.182Z` were independently confirmed; both carry `project-kitchen`. All eight notes were preserved.
- The operator reported native Disconnect made Claude ask to Reconnect / sign in, then explicitly reapproved the connection. The resulting one-approval snapshot did not certify the earlier revoked state and was not evidence of a defect.
- After a repeated native Disconnect with no further reauthorization, the existing owner session's independent API read returned HTTP 200, **eight notes and zero approved connections** at `2026-10-11T22:45:39.987516Z`. No new grant was created to perform this check.
- Private sign-in details were separated from historical test instructions. No credentials or exports are included in this repository.

This completes native Sign out/Disconnect on one invited account. The Claude reconnect prompt is operator-reported; a raw provider HTTP refusal was not captured. Further failure handling, customer signup/recovery, clean first-time setup and independent repetition remain open.

### Passed physical export and connection recovery

The operator used native Prepare journal export → Share export → Save to Files. The delivered JSON contained eight entries and exactly matched every complete record returned by the live owner API. Every entry hash and parent link was independently recomputed from genesis to the exported head. The service still showed zero approved AI connections. This proves the synthetic export was delivered intact; hashes do not prove factual truth or freshness by themselves.

With Airplane Mode on and Wi-Fi off, the operator reported the native message: “Can't reach Kairos. Check your connection and try again. Previously displayed notes haven't been refreshed.” When connectivity returned, the app automatically refreshed. The operator subsequently confirmed loaded notes stayed visible during the offline check.

An offline Save attempt reported the same generic connection message and retained the draft. The operator then manually saved after restoring connectivity. An independent owner API read found exactly one matching new entry, `5ec28153f6adabb6` at `2026-10-11T22:56:00.230Z`, actor `you`, tag `project-kitchen`. The account now contains nine notes and zero approved AI connections. There was no intermediate server snapshot; the exact offline Save dispatch/warning was not captured. A lost response after commit, expired session and control-request failures remain separate acceptance cases.

### Source draft repair after build 1

A deterministic fixture changed draft/project during a save. The original source failed with “Successful save erased a newer unsent draft.” The repair snapshots the submitted values and clears them only if unchanged; it preserves and acknowledges a newer draft. Compose editing and interactive dismissal are disabled while busy. Eighteen synthetic model checks and unsigned iOS Simulator SDK compilation passed for this change. No new native runtime, physical installation or TestFlight upload is claimed for the repair. The tested physical app remains compiled `acc89ce65003e2f2d88da341025ac2e3df675d1a`, version 0.1.0 build 1.

A second fixture reproduced refresh erasing the earlier unconfirmed-save warning. The model now retains that warning across failed and successful reads; a read is not a write receipt. A confirmed save or session/journal reset clears it. Twenty synthetic model checks and unsigned iOS Simulator SDK compilation passed for the combined source changes. The generic message in the phone report could have come from the foreground refresh; its exact cause was not captured, so this is a reproduced model defect and source repair, not a proven diagnosis of that phone event. Lost-response-after-commit and updated physical-build acceptance remain open.

These results supersede the signing, physical-installation and actual-provider-pending statements in the earlier Simulator section. They do not establish physical failure handling, complete owner-control acceptance, customer onboarding, iPad behavior or other provider support.
