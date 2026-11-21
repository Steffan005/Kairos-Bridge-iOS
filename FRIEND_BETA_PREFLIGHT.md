# Friend beta preflight — November 21, 2026

Candidate: **0.1.0 build 8**, executable source `30a26570ce724b7177c4b086a794580a667fc56c`.
Server: `e2cb8c6d77b1e2367898c7c16b394fb670284ac8`, deployed on the existing invited service.

A fresh iOS 26 iPhone Simulator, with its own empty device storage and Keychain,
used an independent disposable Kairos account. No operator account or staging
secret was used in the app. The account had completed live email confirmation
and password recovery; the old browser session was refused and its practice
note remained.

Observed in native UI:

- Signup and beta privacy links were visible on Sign in.
- Sign in with the recovered account password loaded only that account's one
  synthetic note.
- A short fictional note, `Blue`, was entered using the on-screen keyboard and
  saved once. The app showed two memories; the independent live API matched the
  saved note.
- After terminating and reopening the app, the session and both notes remained.
- Your account displayed the test account's verified email and clearly named
  Manage email and password, Delete my account, and Beta privacy notice links.

The disposable account was deleted through the password-confirmed account API
when testing ended. Its old login and session were refused. The separate Apple
review account remains active with fictional notes only.

Other validation: signed Simulator target compilation, 50 synthetic model checks,
41 API-response checks, 27 search checks, and 44 display-window checks against
100 existing read-only records. Server acceptance passed separately, including
owner-record and approved-access preservation after deployment.

The checks above are direct Simulator evidence. After the owner completed the
protected Keychain prompt, the device archive and App Store Connect export
succeeded. Strict signature verification passed; the distribution profile
has beta-reports-active enabled, get-task-allow disabled, no provisioned-device
list and no enterprise all-device grant. The checked local IPA SHA-256 is
`7f1069ed852a6bad194e15446ecf0c4232b23cab67a7bfa6caa72aa0b76a633c`.
Upload re-exports the same archive and may re-sign its bytes; this hash identifies
the inspected local export only.

Xcode acknowledged Upload succeeded at **2026-11-21T21:09:03.054Z**. Apple
processing completed and build 8 was added to the existing Kairos Owner Pilot,
with one owner tester and earlier builds retained. Steffan then explicitly
reported that build 8 updated through TestFlight, existing notes remained
visible, and Delete my account / Beta privacy notice links were present. This
is scoped owner-reported physical acceptance, without a separate phone trace;
it is not an independent friend's first provider setup or physical fault test.

The complete review contact, dedicated synthetic reviewer login, privacy URL
and review notes were saved in App Store Connect. What to Test was saved for
build 8. It was submitted to Kairos Friends Pilot for external Beta App Review;
the observed status is **Waiting for Review**, with zero external testers,
no public link, and automatic tester notifications disabled. Apple external
approval is still required. No friend invitation or personal friend signup code
has been issued at this checkpoint.

The hosted service's final interruption safeguard is deployed at
`6cb45faa7865274c40f7a1f14355d57b5672ab9a`. Its final owner-record preservation
and reviewer-login checks passed. The guard changes no stored schema from the
post-preflight protected capture. These later server/documentation revisions
do not change the native executable source identified above.
