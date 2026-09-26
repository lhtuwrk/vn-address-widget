# Lookup screens — GPS current-location (Home) + manual lat/lng entry

**Phase:** 1 — M1 MVP core geocoder
**Ticket:** phase1/03-lookup-screens
**Depends on:** [phase1/02-geocoding-core](02-geocoding-core.md)
**Blocks:** phase1/04
**Status:** Not Started

## Problem / Value

The user-facing half of M1: see the current location's address without a map, or type any coordinate to look one up (mockup Home screen, `plans/map_proposal.html:754-809`; manual entry named as a feature at lines 658-659 but never mocked anywhere in §04).

Scope note: §02 (line 651-655) describes "Vị trí hiện tại" as working "không cần mở app" (i.e., widget-level, no app open needed) — that's phase2's widget deliverable. This ticket covers only the **in-app** Home screen's foreground GPS fetch on screen open, matching the actual M1 mockup.

## Acceptance Criteria

**Home / current-location screen (per mockup lines 754-809):**
- On screen open, app requests foreground location and shows a GPS status pill reflecting state: fetching / "just updated" / permission denied / location unavailable.
- On a successful fix, the address card shows Tỉnh, Huyện and Xã plus the raw coordinate.
- A "no match" core result renders a distinct empty/error state, never a blank or broken card.
- A near-boundary result (2 candidate units) is rendered in a defined UI state — see open question, since no mockup covers this.
- Denied location permission shows an actionable state (why it's needed, path to enable) rather than an indefinite spinner.
- No network call is required to produce a result once a GPS fix exists.

**Manual lat/lng entry screen (no existing mockup — design work is part of this ticket):**
- User enters latitude and longitude in the format decided (see open question) and submits to get the same address-card result as the Home screen, via the geocoding core.
- Out-of-range or malformed input is rejected with a visible inline error before any lookup runs.
- A valid submission with no match shows the same "no match" state as the GPS path.
- The screen has a defined entry point in app navigation (exact placement to be decided as part of this ticket, since the mockup set has no entry point for it).

## Out of scope

- Map-tap picker (phase3), history list (phase3), widgets (phase2), background/auto-refresh GPS, any Nominatim street/house-number fallback UI.

## Open questions

- Manual-entry coordinate format is entirely unspecified: decimal degrees (signed) vs DMS, and whether N/S/E/W suffix notation is supported — this blocks screen design and must be decided before build.
- Where does the manual-entry screen live in navigation (its own tab, a link from Home, an "advanced/debug" menu)? Not shown anywhere in the mockups.
- The near-boundary "2 results" UI state needs real design (per BA finding) — is designing it in scope for this ticket, or should it be split out to a design pass with `ui-reviewer` before implementation starts?
- Is a minimal/placeholder treatment acceptable for the "no match" and "permission denied" states in M1, or do these need their own mockup?

## Sizing sense-check

Medium. Home screen has a mockup to build against; the manual-entry screen needs design from scratch (and is blocked on the format decision), and the near-boundary state needs new UI regardless of which screen shows it.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `ba` research, 2026-09-23.
