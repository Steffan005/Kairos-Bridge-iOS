# Anamnesis — reviewed product design handoff

October12, 2026. Scope kairos_bridge. Grok owns design proposal; ChatGPT owns feasibility review and native implementation. Steffan selected this phase. Status: proposed interface reviewed for the next native increment; not implemented or deployed.

**Kairos-Bridge — The bridge to remembrance.**
**Anamnesis — Your journal.**

## Source and review

Grok's completed proposal and revised text wireframes are in [the design conversation](https://grok.com/c/c25ef2d3-1cb3-46e7-b3e2-782d01a34497). Its summary5066f83320c1c279 was independently retrieved from the shared hosted journal. Three generated image cards are observed. They are mood studies; their copy and interaction geometry are not implementation specifications.

Grok inspected repository trees, READMEs and acceptance material; its specific Swift source inspection was partial. ChatGPT read the actual native Views, Models, model runtime and owner GET handler. ChatGPT's corrections were delivered in the same conversation and included in the revised proposal. No claim of rendered accessibility or independent usability acceptance is made.

## Recommended first increment

1. Fixed, labeled access to **Remember**, **Connect** and **Your journal** above the scrolling history. At narrow width/large text use a wrapping action band with visible labels, rather than forcing three items into a native single-row toolbar. Owner actions must remain reachable independently of note count.
2. Calm recent-note surface:15 initially visible, clear author/date/project labels, and local **Show more recent notes** revealing more of the already-loaded window.
3. Project and author selections are views of the same shared journal. Explicitly label them **Showing recent notes**. Filtering occurs before the15-note display window so a match elsewhere among the loaded notes is not accidentally hidden.
4. Connection screen represents Claude, ChatGPT and Grok grants from the owner response. Copy: **Approved for this journal. Enable Kairos in a new [provider] chat.** Approved access is not a claim that tools are enabled in every chat. Preserve the current supported provider setup paths; do not invent a one-click setup link.
5. Familiar, owner-controlled export, Sign out, Disconnect all and active-journal deletion remain available with distinct descriptions/confirmation scope. Move access to the labeled Your journal menu; sign-out must retain approved AI access.

## Proposed wireframes

```text
Kairos-Bridge
Anamnesis — Your journal
[Remember] [Connect] [Your journal]

[Project: All] [Author: All]
Showing recent notes

Author · date/time · Project
Readable saved text...

[Show more recent notes]
15 of42 loaded ·42 notes total
```

```text
Remember
What would you like to remember?
[Multiline note]
Project [Kitchen / No project / Choose...]
[Save note] [Keep draft]
Save uncertainty remains visible next to the draft.
```

```text
AI connections
Claude   Approved for this journal
Enable Kairos in a new Claude chat.
ChatGPT  Approved for this journal
Enable Kairos in a new ChatGPT chat.
Grok     Approved for this journal
Enable Kairos in a new Grok chat.
Approval and current-chat enablement are distinct.
```

```text
Your journal, your choice
Export / Share export
Sign out — approved AI access continues
Disconnect all AI access — notes stay
Delete active journal — confirmation required
```

## Recent window versus complete history

Current owner GET returns at most50 entries and a total count, without a cursor. Local reveal within that loaded window is UI work. Once exhausted, say **These are the most recent notes we have loaded.** If total count exceeds loaded count, display the difference. Do not show a working-looking whole-history search or Show older control without a real query.

A later owner-authorized cursor/filter endpoint is needed for complete history and complete project discovery. Cursor ordering must be stable and account-scoped, including refresh/deletion boundaries. No arbitrary provider or permission expansion follows from pagination.

## Plain project names — final feasibility qualification

Grok proposes a project picker and plain-name-to-tag conversion. Existing records only store tags, with no authoritative display-name catalog. Deriving “Kitchen” from project-kitchen is possible; restoring arbitrary original names, case, punctuation or non-Latin text is not.

First UI increment may offer existing loaded project labels, **No project**, and a narrowly supported new-name flow that previews the resulting label and confirms use of an existing matching tag. It must not claim complete project discovery or silently merge two differently named projects. Preserve existing tags. Durable exact plain-name/collision handling belongs with a small project catalog/query design; do not silently invent it in client-only memory. This remains the main design qualification before coding project creation.

## Greek tokens and readable pairings

| Role | Value / behavior |
|---|---|
| Aegean primary | #0A2540 |
| Ivory light surface | #F8F4EF |
| Bronze motif | #B08D57; decoration only on ivory |
| Light body | #1A1A1A on ivory |
| Light secondary | #3D3D3D on ivory |
| Dark surface | #1C1C1E |
| Dark body / secondary | #F2F2F2 / #A0A0A0 |
| Primary button | Ivory label on Aegean; distinct high-contrast boundary in dark mode |
| Typography | Scalable system body; restrained system serif headings |
| Spacing / radius |16pt base,8pt gaps,12pt cards;44pt minimum targets |
| Motion | Quiet actual-result transition; no decorative movement under Reduce Motion |

Declared solid-color calculations: bronze/ivory2.823:1; ivory/Aegean14.189:1; #5C5C5C/ivory6.107:1; #A0A0A0/dark6.507:1. These are color calculations, not rendered interface acceptance. Never use bronze as normal-size essential text or the sole insufficient control boundary on ivory.

## Honest state copy

- Empty: **No notes yet. Tap Remember to begin.**
- Loading: **Loading your journal…**
- Acknowledged save: **Saved.** A subsequent failed refresh does not revoke that acknowledgment.
- Offline/stale: **Can't reach Kairos right now. Showing your last notes.** Keep displayed notes and last-update information.
- Unconfirmed save: **We could not confirm whether this note was saved. Your draft is still here. Refresh your journal before saving again to avoid a duplicate.** No automatic retry.
- No AI approvals: **No AI access is approved. Your notes remain.**
- Disconnect confirmation: **Disconnect all AI access? Your notes will stay.**
- Delete confirmation preserves actual semantics: active journal removed, AIs disconnected, sign-in account retained, host snapshots may retain data. Full customer account deletion is not implemented.

Drafts currently live in memory. Do not promise survival after app termination. Project/author filters are attribution views, not private access or authenticated vendor identity.

## Accessibility intentions

Scalable text, wrapping labels at320pt and accessibility sizes, VoiceOver author/date/project/text, meaningful focus after save/errors,44pt targets, non-color-only status, Reduce Motion. No fixed-height truncated memory body; long notes can expand/read in detail. These must be observed on the next built slice before calling them accepted.

## Build sequence and receipt

1. Implement the fixed action band, recent-note presentation, Greek theme and exact owner/connection semantics.
2. Introduce honest loaded-set author/project views with state/cap/count handling. Resolve plain-name catalog behavior before shipping new-project creation.
3. Check the new slice under the requested build acceptance; only then prepare a new TestFlight build and exact owner steps.
4. Add owner-authorized full-history retrieval as a separately scoped increment.

No new phone action is pending now. Installed TestFlight0.1.0(2), native executable b5df0ee and hosted executable f7467b1 remain. Existing three approvals stay intact. Gemini, documents, crypto, private lanes, customer auth overhaul and public release are outside this increment.


## Implementation update — October12

Steffan explicitly authorized the first native increment after the review. Development source now implements fixed labeled controls,15-note display pagination/Show more, loaded-set project/author views, recent-project selection, three-provider scope status and the Greek theme. Existing project-tag input remains for new projects; exact arbitrary name storage and catalog/disambiguation remain deferred. The native home was compacted after actual capture review. Generic and signed Simulator builds passed; existing session/notes and Connect navigation were directly observed. Larger-text/narrow-width and >15-note interaction acceptance remain pending. No build3 TestFlight upload occurred; phone beta2/hostedf7467b1 remain. The scope/constraints above continue to govern the next increment.
