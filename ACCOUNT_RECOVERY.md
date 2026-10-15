# Account email and password recovery — build 7 candidate, not released

The account upgrade keeps the same server user ID, journal and approved AI
connections. It adds web account links and lets the app refresh the display email
without treating it as a new owner.

- **Forgot password?** opens the public recovery page in the browser.
- **Your journal → Your account → Manage email and password** opens `/account`.
  Browser sign-in is separate from the native session; use the existing Kairos
  account. Real email delivery must be configured on the hosted service first.
- A verified email change keeps the account ID. The next native refresh updates
  the displayed email. Search/draft ownership uses the stable ID.
- A password reset signs out native/browser sessions. Sign in with the verified
  email and new password. Approved AI apps retain their separately granted access.
- Legacy Keychain sessions without an ID recover it from the authenticated server,
  using `/api/account` or the old server's `/api/auth/get-session` on a 404.
  Matching email strings alone never establishes ownership.

## Before installing an update

Save or copy any unsent draft. Build 6 and this candidate keep drafts in app memory
only; app replacement or termination cannot preserve an unsaved in-memory draft.
Within a running candidate session, a held draft can be recovered by the same
immutable account ID after email change and reauthentication. A different account
that happens to use the old email must never receive it.

## Evidence required before release acceptance

- Focused model, API/storage, search and journal-window checks.
- Unsigned simulator build and account-link/accessibility inspection.
- Signed archive/upload/TestFlight group assignment, recorded independently.
- Owner update and same-account email confirmation using actual delivered mail.
- Existing notes present, display email refreshed, new sign-in works, recovery
  signs out the old native session, and existing AI approvals still work.

Synthetic checks are not proof of delivered email, a physical-device update or
live account migration. These checks alone do not establish release acceptance.

## October 15 isolated validation

140 assertions passed: 50 model, 41 API/storage, 27 search, and 22 journal-window
checks. The unsigned generic iOS Simulator target compiled. An independent
reproduction confirmed that a delayed response from a previous account is
discarded even when the next account's refresh fails. The new account rows use
semantic fonts and unrestricted wrapping; actual maximum-text and VoiceOver
inspection remain pending.

The source is prepared as 0.1.0 (7). Archive, upload, processing, group assignment,
and owner installation must each be recorded before declaring it delivered.
