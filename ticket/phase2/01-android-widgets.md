# Android home-screen widgets (Glance): small 2×2 + large 4×2

**Phase:** 2 — M2 Widgets
**Ticket:** phase2/01-android-widgets
**Depends on:** [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), [phase2/03-app-widget-data-bridge](03-app-widget-data-bridge.md), [phase2/04-location-permission-flow](04-location-permission-flow.md)
**Blocks:** none
**Status:** Not Started

## Problem / Value

Android users get the resolved current-location address glanceable on the home screen without opening the app, per M2's "Widget nhỏ: GPS auto-update / Widget lớn: 3 cấp + tọa độ" (`plans/map_proposal.html:1291-1292`).

## Acceptance Criteria

- Two Glance widgets are installable independently: small (2×2) and large (4×2).
- Both widgets render from a single data-binding point (not hardcoded fields), so the field-set decision below can land without a relayout.
- Small widget: tapping anywhere opens the app's current-location screen (table, line 721).
- Large widget: tapping the non-copy area opens the app's current-location screen; tapping a copy affordance copies the full address string to the clipboard in-process via a Glance `ActionCallback` — no app foregrounding required (confirmed technically viable on Android, unlike iOS).
- Widgets refresh via a periodic `WorkManager` request; interval is configurable in code but the actual product-chosen cadence is an open question below (Android's WorkManager floor is 15 minutes — a platform constraint, not a chosen value).
- Widget also updates immediately when nudged by the app after a foreground lookup (mechanism owned by [phase2/03](03-app-widget-data-bridge.md); this ticket only consumes the nudge).
- Distinct, visually different widget states exist for: (a) no data yet (first install, before any lookup has ever written a result), (b) fresh data, (c) stale cached data shown because a scheduled refresh couldn't complete, (d) location permission denied/not granted (state owned by [phase2/04](04-location-permission-flow.md); this ticket renders it), (e) point outside covered administrative boundaries.
- Widget never silently shows nothing on any of the above states — each has a rendered, testable UI.

## Out of scope

- iOS widgets ([phase2/02](02-ios-widgets.md)).
- The permission request flow itself and its dialog sequencing ([phase2/04](04-location-permission-flow.md)) — this ticket only renders whatever permission state it's told.
- The `last_result.json` format, dataset file placement, and refresh-nudge mechanism ([phase2/03](03-app-widget-data-bridge.md)) — this ticket is a consumer.
- Movement-based re-query caching (the M2 roadmap bullet "Cache tránh query lại khi ít di chuyển," line 1294 — this is a geocoder-engine/movement-delta concern; flagged as not covered by any current phase2 ticket, needs a home in [phase1/02](../phase1/02-geocoding-core.md) or its own ticket).
- Manual "refresh now" button — not specified anywhere in the proposal for either platform; not assumed here.

## Open questions

- **Small widget content contradiction (unresolved, doubly confirmed):** the feature table (line 720) says "Tỉnh + Huyện + tọa độ rút gọn" but both mockups (line 680-681 and line 943-946) show ward+district only, no tỉnh, and disagree with each other on whether coords show lat+lng or lat-only. This AC list deliberately keeps the field set abstract/configurable to avoid blocking on it, but the actual field list needs `ui-reviewer` sign-off.
- What refresh interval does product actually want for Android? The proposal specifies iOS's 15–30 min (line 1342) but never states an Android cadence at all.
- Does the large-widget copy tap need any user-visible confirmation (toast/haptic), or is silent copy acceptable? Not specified.

## Sizing sense-check

Medium. Two widget surfaces, Glance is a reasonably mature API, in-process copy is not technically risky on Android — but the state-matrix (5 distinct states × 2 sizes) and the unresolved content-field question add real work beyond "make a widget."

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research, 2026-09-23.
