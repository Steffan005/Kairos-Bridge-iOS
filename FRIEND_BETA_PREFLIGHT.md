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

This is Simulator evidence, not a physical TestFlight result. The build-8
archive is waiting for macOS Keychain permission to use the existing Apple
signing certificate. No build-8 export, upload, Apple processing, external Beta
App Review approval or friend installation is claimed. Build 7 remains the
latest previously accepted owner TestFlight build. Invitations stay on hold
until distribution and live/native acceptance gates pass.
