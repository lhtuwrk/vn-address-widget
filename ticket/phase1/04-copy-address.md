# Copy-address (single format, M1)

**Phase:** 1 — M1 MVP core geocoder
**Ticket:** phase1/04-copy-address
**Depends on:** [phase1/03-lookup-screens](03-lookup-screens.md)
**Blocks:** none
**Status:** Not Started

## Problem / Value

One-tap copy of the resolved address, matching the single "Copy địa chỉ" button actually shown in the Home mockup (`plans/map_proposal.html:791-794`). The proposal's broader claim of "multiple output formats" and "per-level copy" (§02, line 649-650) is not reflected in any mockup and is an unanswered product question — explicitly deferred out of M1, not silently dropped.

## Acceptance Criteria

- A single "Copy địa chỉ" action on the Home/manual-entry result screen copies one fixed-template full-address string (Tỉnh, Huyện, Xã) to the system clipboard.
- Tapping copy shows visible confirmation of success (toast/snackbar or equivalent state change).
- The copy control is available only when a valid address result is on screen — disabled or hidden during loading, no-match, or error states.
- Copy works with no network call.
- Behavior when the near-boundary state is showing 2 candidate results is explicitly defined (see open question) rather than left ambiguous.

## Out of scope

- Per-level copy (copying just one administrative level), multiple selectable output formats or a format picker UI, copy-from-widget (phase2 — the 4×2 widget mockup shows a copy affordance, but that belongs to the widget ticket), history-list export (phase3).

## Open questions

- The exact copied string template (level order, separators, abbreviations — e.g. "Phường X, Quận Y, TP. Hồ Chí Minh" vs some other arrangement) is not specified anywhere; no mockup shows the resulting string, only the button. Needs a product decision.
- When 2 near-boundary results are shown, does copy act on one specific result (which?) or produce a combined string? No existing rule covers this.
- Confirm "multiple output formats / per-level copy" (line 649-650) is intentionally deferred rather than dropped, and note where it resurfaces (a later ticket) so it isn't lost.

## Sizing sense-check

Small. The clipboard mechanism itself is trivial; nearly all the remaining work is pinning down the format string, which is a product decision rather than engineering effort.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `ba` research, 2026-09-23.
