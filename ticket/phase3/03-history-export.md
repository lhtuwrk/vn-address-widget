# History export (blocked/partially specified)

**Phase:** 3 — M3 Map picker + History
**Ticket:** phase3/03-history-export
**Depends on:** [phase3/02-lookup-history](02-lookup-history.md)
**Blocks:** none
**Status:** Not Started

## Problem / Value

The roadmap lists "Export danh sách" (export the list) as an M3 deliverable (`plans/map_proposal.html:1306`) alongside the history feature, presumably so users can get their lookup history out of the app for reporting or sharing. However, no format, destination, or trigger UI is specified anywhere in the source document, and the History mockup itself (lines 872-931) shows no export icon or button at all — only "Xoá tất cả" is present in the header. This ticket captures what can be committed to now and blocks the rest on a product decision.

## Acceptance Criteria

- An export action is reachable from the history screen (exact placement/icon is undecided — see Open questions — but the action must exist somewhere on that screen once built).
- Triggering export produces a file or output covering all history entries currently stored (up to the 20-entry cap from [phase3/02](02-lookup-history.md)), not just the currently visible/filtered subset — unless the search/filter behavior from that ticket is resolved to say otherwise.
- Export includes, at minimum, the same data shown in each history list item: Tỉnh/Huyện/Xã and coordinates.
- Everything beyond the above (file format, delivery mechanism, and exact trigger UI) is explicitly undecided and listed below — this ticket should not proceed to implementation until those are resolved.

## Out of scope

- Any specific file format (CSV, JSON, plain text, etc.) — not named anywhere in the source document; do not default to one without a decision.
- Any specific destination mechanism (OS share sheet, save-to-file, clipboard, email) — likewise unnamed.
- Export of a single history item (as opposed to the full/filtered list) — not mentioned anywhere; only "danh sách" (the list) is referenced.
- Any export triggered from screens other than History (e.g. exporting a single map-picker result) — not described in the source document.

## Open questions

- File format for export: CSV, JSON, plain text, or something else? Needed before any implementation can start.
- Export destination: native share sheet, save-to-device-storage, copy-to-clipboard, or another mechanism? Needed before implementation.
- Trigger UI/placement: the History mockup (lines 872-931) has no export icon or button anywhere — where should it live (header, per the clear-all pill area, overflow menu, etc.)?
- Does export respect the search/filter state from [phase3/02](02-lookup-history.md) (export only what's currently filtered) or always export the full stored history regardless of what's on screen?
- Is this M3-blocking (i.e. M3 can't be called done without export shipping) or can it slip to a later milestone once the above are decided, given the roadmap only allots "1 tuần" (1 week) total for all of M3's three listed items (line 1302)?

## Sizing sense-check

Small in isolated effort once format/destination/trigger are decided (it's a serialize-and-hand-off operation over already-stored data from [phase3/02](02-lookup-history.md)), but currently unstartable — most of this ticket's actual scope is the missing product decision, not the code. Recommend resolving the open questions before this enters a sprint.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `ba` research, 2026-09-23.
