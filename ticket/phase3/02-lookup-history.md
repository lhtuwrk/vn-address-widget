# Lookup history: storage, date-grouped list, clear-all

**Phase:** 3 — M3 Map picker + History
**Ticket:** phase3/02-lookup-history
**Depends on:** [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), [phase3/01-map-picker](01-map-picker.md) (if map-tap lookups populate history — see open questions)
**Blocks:** phase3/03
**Status:** Not Started

## Problem / Value

Users who look up multiple points (via map tap or manual lat/lng entry) want to revisit past results without re-entering coordinates — "tìm lại không cần nhập lại tọa độ" (`plans/map_proposal.html:664`). This ticket covers the history list screen shown in the mockup at lines 872-931.

## Acceptance Criteria

- Every successful lookup (source: manual lat/lng entry and/or map tap — see Open questions) is persisted locally as a history entry containing at minimum Tỉnh/Huyện/Xã and the coordinate.
- The history list groups entries under date-section headers matching the mockup pattern: "Hôm nay" (Today) and "Hôm qua" (Yesterday) as the two headers shown (lines 893, 911); older entries need a defined grouping rule (see Open questions).
- Each list item displays the resolved address (top-level name + secondary line, per mockup rows at lines 904-909, e.g. "P. Thảo Điền" / "Thủ Đức · TP.HCM").
- A "Xoá tất cả" (clear all) action is present in the header (lines 885-887) and, when triggered, removes all history entries and leaves the list in an empty state.
- The clear-all action requires a confirmation step before deleting (standard for destructive bulk actions; exact confirmation UI is a UI-review detail).
- History storage enforces a maximum of 20 entries per the M3 roadmap line "Lịch sử 20 điểm gần nhất" (line 1305). When a 21st entry would be added, the oldest entry is evicted (FIFO) — this eviction rule is this ticket's working assumption and is called out explicitly in Open questions below because it is not written anywhere in the source document.
- An empty-history state (no entries yet) is shown when the list has zero items.

## Out of scope

- Single-item deletion (swipe-to-delete, long-press, or per-item delete icon) — the mockup shows no such affordance on either history item variant (lines 895-902, 904-918); not building it without a design/decision (see Open questions).
- Search bar behavior — the mockup shows an empty search bar (line 890) but this ticket only reserves the UI slot; filtering logic is a separate ticket once the behavior (text match on address? date range? both?) is decided (see Open questions).
- The "active" item highlighted state (border + extra coordinate line, lines 895-902) — not implementing this visual distinction until its meaning is confirmed (see Open questions).
- Export (covered in [phase3/03](03-history-export.md)).
- Tapping a history item to re-open/re-view that point on the map or lookup screen — plausible next step but not described anywhere in the source doc; flagging as a likely-needed follow-up rather than assuming it into this ticket's scope.

## Open questions

- Eviction rule on the 21st lookup: this ticket assumes FIFO (oldest evicted) as the only reasonable inference, but the doc states no rule at all (feature card at line 664 says "recent points" with no count; roadmap at line 1305 says "20 most recent" with no eviction behavior). Needs explicit confirmation before building.
- Which lookups populate history — manual lat/lng entry only, map-tap lookups only, or both? Affects both this ticket and [phase3/01](01-map-picker.md).
- Grouping rule beyond "Today"/"Yesterday" — mockup shows only two section headers; is there a third bucket ("This week", "Older", exact date, etc.) for entries beyond yesterday, or does the list simply stop showing section headers?
- Is single-item deletion in scope at all for M3? The mockup's only delete affordance is clear-all; no swipe/long-press/icon is shown on either item state. Needs a product decision.
- What does the search bar filter on (address text, date, both) and does it filter within the date-grouped list or flatten it? No prose describes this anywhere in the document.
- What does the "active" item state mean (currently selected point? most recently added? something else), and does it need to be built for M3 or deferred?

## Sizing sense-check

Medium. Local storage + a capped, date-grouped list is straightforward on its own, but three UI elements visible in the mockup (search bar, active-item state, and the ambiguous eviction rule) all need product/design decisions before their surrounding code can be written correctly.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `ba` research, 2026-09-23.
