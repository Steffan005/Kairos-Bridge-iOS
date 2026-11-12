# Account email and password recovery

The invited owner accepted TestFlight **0.1.0 (7)** on October 15, 2026. [The acceptance record](ACCEPTANCE.md#october-15--owner-accepts-build-7) documents the phone update, the separate real-mail trial and the combined owner account comparison.

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
  email and new password. The service keeps existing AI approval records in place.
- Legacy Keychain sessions without an ID recover it from the authenticated server,
  using `/api/account` or the old server's `/api/auth/get-session` on a 404.
  Matching email strings alone never establishes ownership.

## Before installing an update

Save or copy any unsent draft. Builds 6 and 7 keep drafts in app memory. Installing
an update or closing the app process discards an unsaved draft. While the app is
running, a held draft can be restored after email change and reauthentication
when the account ID matches. The account ID controls restoration even if the
previous email is later used by another account.

## October 15 fixture checks

140 assertions passed: 50 model, 41 API/storage, 27 search, and 22 journal-window
checks. The unsigned generic iOS Simulator target compiled. An independent
reproduction confirmed that a delayed response from a previous account is
discarded even when the next account's refresh fails. The new account rows use
semantic fonts and unrestricted wrapping; actual maximum-text and VoiceOver
inspection remain pending.

Independent onboarding, broader recovery and retention checks, and public App
Store release remain open.
