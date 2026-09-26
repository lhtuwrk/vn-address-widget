# Map picker: tap-to-geocode with result bottom sheet

**Phase:** 3 — M3 Map picker + History
**Ticket:** phase3/01-map-picker
**Depends on:** [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), [phase0/02-architecture-system-design](../phase0/02-architecture-system-design.md) (offline basemap decision)
**Blocks:** none
**Status:** Not Started

## Problem / Value

Users currently must know a lat/lng to get an address out of the app (M1's manual-entry screen). The map picker lets a user tap any point on a map and get the same offline administrative-hierarchy lookup without knowing coordinates first — this is the M3 roadmap's first line item, "Tap on map → lấy địa chỉ điểm đó" (`plans/map_proposal.html:1304`), and the mockup at lines 811-870 shows a full-screen map with a pin and a bottom-sheet result card.

## Acceptance Criteria

- A map screen is reachable from the app's tab bar (tab bar shown in mockup, lines 920-928; exact entry point/icon is a UI-review detail, not this ticket's concern).
- Tapping any point on the map drops/moves a single pin to the tapped coordinate and triggers a reverse-geocode call to the core engine ([phase1/02](../phase1/02-geocoding-core.md)).
- On successful lookup, a bottom sheet appears showing the tapped point's result: Tỉnh, Huyện, Xã (mockup lines 852-862).
- The bottom sheet includes a "Copy địa chỉ đầy đủ" (copy full address) action (lines 864-866) that copies the assembled address string to the clipboard for the tapped point.
- When the tapped point falls within the near-boundary confidence radius (<100m) defined at line 1349, the bottom sheet renders both adjacent results rather than a single-value field, consistent with the same confidence-radius rule used in [phase1/03](../phase1/03-lookup-screens.md).
- Tapping a new point while the sheet is open updates the pin position and replaces the sheet's contents with the new point's result (no stacking of old results).
- A tap that resolves to no match (e.g. point falls outside all bundled boundary data, such as international waters or areas outside Vietnam) shows an explicit no-match state in the sheet rather than a blank or stale result.

## Out of scope

- The basemap/tile rendering technology itself (online vs. offline vector tiles) — blocked on the [phase0/02](../phase0/02-architecture-system-design.md) offline-basemap decision. This ticket covers the picker interaction and result display, not the map surface implementation.
- Search-by-address-text on the map screen (the mockup shows a search-style pill at lines 833-836 next to the map, but no behavior is described for it here — separate from the History search bar covered in [phase3/02](02-lookup-history.md); if this is meant to be an address search on the map, it needs its own ticket).
- GPS "current location" flow — that's the Home screen, already covered in [phase1/03](../phase1/03-lookup-screens.md).
- Per-field copy (copying just the Xã or just the Tỉnh) — mockup only shows a single full-address copy action on this screen.
- Any new geocoding logic — this ticket only wires the UI to the engine built in phase1.

## Open questions

- What does the map surface show before the offline-basemap product/licensing decision lands ([phase0/02](../phase0/02-architecture-system-design.md))? Is a placeholder/stub map acceptable to unblock this ticket's UI work, or does the whole ticket wait?
- Exact copy format for "copy full address" — see [phase1/04](../phase1/04-copy-address.md)'s open question on the same unresolved template; this screen should reuse whatever's decided there.
- Confirm the near-boundary 2-result UI has no existing design anywhere (confirmed by architect/ba) — needs a design decision (stacked cards? tabs? side-by-side?) before this can be built, not just specified in prose.
- Does tapping the map also write an entry to History ([phase3/02](02-lookup-history.md)), or is History only populated by manual lat/lng lookups? The mockup doesn't say; this affects both tickets' scope.

## Sizing sense-check

Medium. The reverse-geocode wiring and copy action are small (reuse of phase1 engine), but the near-boundary dual-result UI state has no existing design to build from and the whole screen is blocked pending the offline-basemap decision.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `ba` research, 2026-09-23.
