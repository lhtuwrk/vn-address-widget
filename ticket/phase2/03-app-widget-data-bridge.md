# App↔widget data bridge (dataset access + last_result.json + refresh nudge)

**Phase:** 2 — M2 Widgets
**Ticket:** phase2/03-app-widget-data-bridge
**Depends on:** [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), [phase0/02-architecture-system-design](../phase0/02-architecture-system-design.md)
**Blocks:** phase2/01, phase2/02
**Status:** Not Started

## Problem / Value

Both widget processes need a way to (a) read boundary/geocode data at all, and (b) learn the latest resolved address without a live shared database connection, which risks the iOS `0xdead10cc` suspension crash on concurrent SQLite writers across processes and blows the ~30MB widget-extension memory budget if it re-loads the full dataset. This ticket is the shared infrastructure both widget tickets depend on.

## Acceptance Criteria

- The boundary dataset (FlatGeobuf + index) is placed somewhere both the app and each widget process can read: Android app `filesDir` (Glance runs in-process, no extra sharing needed); iOS App Group shared container (widget extension is a separate sandboxed process — requires the App Group entitlement).
- The app writes a `widget/last_result.json` snapshot atomically (write-to-temp then rename, or platform-equivalent) on every new geocode result (foreground GPS fix or a lookup explicitly marked "current location") — no reader ever observes a partially-written file.
- `last_result.json`'s schema includes at minimum: lat, lng, Tỉnh/Huyện/Xã name+code, a resolved-at timestamp, and a near-boundary/confidence flag (to carry the "<100m shows both adjacent wards" case, line 1349).
- Android: after writing a new snapshot, the app triggers an immediate Glance widget update (e.g. via `GlanceAppWidgetManager`/a one-off `WorkManager` enqueue) so the home-screen widget reflects the new value without waiting for the periodic cycle.
- iOS: after writing a new snapshot while the app is foregrounded, the app calls WidgetKit's `reloadTimelines` — with an explicit note that iOS itself throttles how promptly this actually re-renders; this ticket cannot promise an off-cycle refresh, only that the call is correctly made.
- Multiple widget instances (both sizes, both platforms) can read the dataset file and the snapshot file concurrently without corrupting or blocking each other (readers are read-only; only the app process ever writes).
- No component ever opens a live, shared, write-capable SQLite connection across the app and a widget process simultaneously.

## Out of scope

- The geocoding/point-in-polygon engine logic itself ([phase1/02](../phase1/02-geocoding-core.md), prerequisite, not rebuilt here).
- Widget UI rendering and state matrices ([phase2/01](01-android-widgets.md), [phase2/02](02-ios-widgets.md) — they consume this bridge).
- The permission flow ([phase2/04](04-location-permission-flow.md)).
- Deciding *when* a background refresh should fire (owned by phase2/01, phase2/02's platform-specific scheduling; this ticket owns *how data moves*, not the schedule).

## Open questions

- Acceptable nudge latency (the "immediate" refresh above) isn't numerically specified anywhere in the proposal — needs a number from tech-lead/product, not assumed here.
- **Genuine architectural ambiguity worth surfacing:** the architecture diagram (line 1176) draws "App Screen" and "Home Widget" as sibling consumers of the same Cache Layer output, which could mean the widget process runs its *own* independent point-in-polygon lookup rather than only reading the app's last snapshot. If that's the intended design, this ticket's scope changes materially (widget needs direct engine + GPS access, not just a file read) — this needs an explicit architect call, not an inference made here.

## Sizing sense-check

Medium. Bounded in surface area (a file format + a couple of platform reload APIs) but foundational — both widget tickets are blocked on it, and the unresolved sibling-consumer ambiguity above could expand it if resolved the other way.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research, 2026-09-23.
