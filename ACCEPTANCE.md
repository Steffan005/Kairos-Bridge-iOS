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

- Physical device session persistence, explicit native display of the provider reply, and independent repetition of the completed physical native/Claude read-write path.
- A clean provider setup and independent tester for the guided connection path. Prior hosted Claude iPhone tests are separate evidence.
- Native network loss, expired-session handling, ambiguous save outcomes and control-request failures. Existing synthetic model checks do not establish those runtime conditions.
- Completed export delivery to Files and final deletion/recreation with explicit operator confirmation.
- Matching App Store Connect app record, successful Apple upload/processing and internal TestFlight install. Bundle registration, Developer team signing, signed archive and App Store distribution export passed; acceptance of the icon in an Apple upload is not yet established.
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

These results supersede the signing, physical-installation and actual-provider-pending statements in the earlier Simulator section. They do not establish physical failure handling, complete owner-control acceptance, customer onboarding, iPad behavior or other provider support.
