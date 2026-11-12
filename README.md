# Kairos for iPhone

**The bridge to remembrance.**

Your journal, across your AI apps. Save a note, find what matters, and manage the AI connections you approve from one iPhone app.

Kairos for iPhone is the native SwiftUI companion to the [Kairos Journal service](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/tree/chatgpt/private-journal-service/hosted). The service gives approved AI apps a shared place to read notes and, with write permission, save them; this app puts that journal and its owner controls on your phone.

Created by **Steffan Douglas Haskins**.

## What you can do

- **Remember:** save a note for a later conversation, with an optional project label.
- **Find:** search the whole journal by Words, Exact phrase or Note ID, filter by recorded author or project, and load older matching notes with Show more.
- **Read:** see saved text with its date, recorded author and project labels. The journal view is named **Anamnesis — Your journal**.
- **Connect:** review approved Claude, ChatGPT and Grok connections and open their setup pages. Approval and enabling Kairos in a particular AI chat are separate steps.
- **Keep control:** export your journal, sign out of the app, disconnect all AI access while keeping notes, or delete the active journal with confirmation.

The Journal engine can run locally with records on an owner-operated computer. The native pilot uses the invited account service. Using the iPhone app with a self-hosted service remains unverified. Approved AI providers receive the notes they retrieve and handle them under their own policies. Signing out of the iPhone app preserves separately approved AI access; **Disconnect all AI access** stops it. Active-journal deletion leaves the sign-in account in place, and hosting snapshots or protected recovery copies may retain deleted data. See the [service's storage and owner-control details](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/blob/chatgpt/private-journal-service/hosted/README.md).

## Availability

See the [October 15 acceptance record](ACCEPTANCE.md#october-15--owner-accepts-build-7) for the latest documented beta result.

| Component | Latest documented status |
| --- | --- |
| Invited iPhone beta | **0.1.0 build 7**, accepted by the existing owner on October 15, 2026. The owner updated through TestFlight, reopened the journal with existing notes visible, and confirmed the verified email display and account page navigation. |
| Public distribution | This repository provides invited-beta development source. A public App Store release is not documented here. Existing pilot participants use their TestFlight invitation. |
| Account recovery | An email-delivery trial passed on a disposable account. The owner’s account kept its prior notes and AI approvals through email change and password recovery. An approved ChatGPT connection read and wrote to the same journal without reconnection. [Account recovery details](ACCOUNT_RECOVERY.md). |
| Broader acceptance | Independent customer onboarding, physical failure cases and customer recovery/retention work remain open. |

The current source can contain changes newer than the accepted beta. A source commit, successful compilation and an installed TestFlight build are distinct records.

## Shared-journal evidence

The owner pilot demonstrated notes written through approved AI connections appearing in the native journal. Source/date/record matching and the limits of each check are retained in [ACCEPTANCE.md](ACCEPTANCE.md).

| AI connection | Documented path and scope |
| --- | --- |
| Claude | Owner-phone read/write and native refresh/reopen, plus native Sign out and Disconnect checks on the invited account. Clean first-time setup with an independent tester remains open. |
| ChatGPT and Grok | Actual phone conversations read and wrote the same hosted journal, and the owner confirmed their notes visible in native Kairos. Grok also recovered its note in a fresh conversation. Provider-specific control/failure cases and independent onboarding remain separate checks. |
| Gemini | An initial owner-phone round trip was accepted, followed by Kairos disappearing from Gemini on the phone after an app update. Further mobile troubleshooting and live renewal are on hold; current use is scoped to the computer browser. No native Gemini setup row has shipped. |

These are recorded results on an invited owner account, with support limited to the documented clients and setup paths. The native app owns the iPhone interface; it does not run an AI model, host MCP on the phone, or read arbitrary conversations from AI providers.

## For developers

The [Journal repository](https://github.com/Steffan005/Kairos-Bridge-AI-Journal) owns the memory engine and AI connection service. The [hosted adapter source](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/tree/chatgpt/private-journal-service/hosted) is on its public `chatgpt/private-journal-service` branch. A local desktop Journal and this hosted service are separate deployment options; the native client uses the hosted service. The existing App repository remains a separate web/account surface.

Useful service references:

- [Hosted setup and owner controls](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/blob/chatgpt/private-journal-service/hosted/README.md).
- [Whole-journal search contract](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/blob/chatgpt/private-journal-service/hosted/OWNER_SEARCH.md).
- [Project briefings and addressed handoffs](https://github.com/Steffan005/Kairos-Bridge-AI-Journal/blob/chatgpt/private-journal-service/hosted/CONTINUE.md). A native briefing screen is separate work; the iPhone app currently browses notes.

### Build

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

The owner-selected black-and-gold bridge icon is an opaque 1024-pixel PNG compiled through `Assets.xcassets`. Its original artwork is preserved in `Design/AppIcon-master.png`; `swift scripts/generate_icon.swift` packages that master for iOS without redrawing it. [Icon provenance](Design/APP_ICON.md). The project generator includes the catalog and the signing configuration; normal users do not run these developer scripts.

## Evidence and development history

- [ACCEPTANCE.md](ACCEPTANCE.md): dated native, provider, distribution and owner-control results, including open acceptance work.
- [BUILD_HISTORY.md](BUILD_HISTORY.md): the previous README preserved unchanged, including exact source revisions, build receipts, repairs, search details and preliminary check commands. Its older “current” statements describe their original checkpoints; use the dated acceptance records and availability table above to identify the latest documented status.
- [ACCOUNT_RECOVERY.md](ACCOUNT_RECOVERY.md): the account controls introduced in build 7 and the scope of the recovery checks.
- [Reviewed Anamnesis design handoff](DESIGN_HANDOFF_2026-10-12.md) and [icon provenance](Design/APP_ICON.md).

The app uses device-bound Keychain sessions and shows stale/offline/error states. Drafts are held in memory and do not survive app termination; save or copy an unsent draft before updating. An unconfirmed save is not automatically retried. Physical failure and recovery acceptance is tracked separately from synthetic checks.

## License

Copyright (C) 2026 Steffan Douglas Haskins. Licensed under **AGPL-3.0-or-later**, matching the existing Journal source. See [LICENSE](LICENSE).
