# Core architecture & system design decision

**Phase:** 0 — Architecture & Foundation
**Ticket:** phase0/02-architecture-system-design
**Depends on:** [phase0/01-admin-hierarchy-data-source-decision](01-admin-hierarchy-data-source-decision.md)
**Blocks:** phase0/03, all of phase1, phase2, phase3, phase4
**Status:** Done

## Problem / Value

The proposal's stack (`plans/map_proposal.html:1218-1264`) doesn't work as written: Flutter has no home-screen-widget runtime (Android and iOS widgets must be native — Glance/Kotlin and WidgetKit/Swift respectively), and the proposed GEOS-via-FFI with a fully-in-RAM R-tree would exceed iOS's ~30MB widget-extension memory ceiling. The proposal also contradicts itself on load strategy: "R-tree... loaded vào RAM lúc app khởi động" (line 1156-1157) versus "FlatGeobuf... đọc lazy theo viewport" (lines 1259-1262, 1356). Every later ticket that says "the geocoder" or "the widget" needs one implementable, written architecture decision first — this is the ticket that chooses the language and system design.

## Recommended direction (from architect research pass — to be ratified, not re-derived from scratch)

- **Framework split:** Flutter for the app's 4 screens + map (presentation only). A single shared **Rust core**, compiled once, linked via Dart FFI (app) / a JNI shim (Android widget, same process) / a C header (iOS widget extension, its own process) owns ALL logic: lookup, hierarchy resolution, near-boundary confidence radius, address formatting, dataset install/verify. Rejected alternatives: fully native (2x UI cost), Kotlin Multiplatform (viable fallback if the team is Kotlin-first — no mature FlatGeobuf/JTS-equivalent for KMP today), React Native (same widget problem as Flutter, no upside).
- **Engine:** point-in-polygon runs once against the finest level (Xã, per [phase0/01](01-admin-hierarchy-data-source-decision.md)'s 3-level decision) and reads parent names/codes from that feature's own attributes — not three independent per-level lookups, which would let mismatched sources disagree at boundary slivers.
- **Storage/format:** FlatGeobuf, mmap'd, read lazily — no SQLite/SpatiaLite/GEOS on device for boundary data. Nothing is ever fully loaded into RAM; this explicitly resolves the RAM-vs-lazy contradiction above. Historical UI-only "lazy load on zoom" language (line 1356) referred to map *rendering*, not lookup, and should be dropped from any restated design.
- **App↔widget data sharing:** boundary file lives in a location both the app and widget process can read (Android `filesDir`; iOS App Group container), accessed via mmap — no live shared SQLite connection across processes (risks iOS's `0xdead10cc` suspension crash). The app writes a small atomically-updated `widget/last_result.json` snapshot; widgets read it rather than re-running GPS/geocode themselves by default (see [phase2/03](../phase2/03-app-widget-data-bridge.md) for the open question on whether widgets ever need their own independent lookup).

## Acceptance Criteria

- A written ADR (or set) names the language/framework per component — app UI, Android widget, iOS widget, shared geocoding core — and states which option was chosen among Flutter-only, Flutter+native-widgets+shared-core, fully-native, or Kotlin Multiplatform, listing rejected alternatives and why.
- The ADR explicitly resolves the RAM-vs-lazy-load contradiction cited above by stating the actual load strategy and a target memory ceiling (in MB) for the widget process specifically, showing it fits under iOS's ~30MB widget-extension limit.
- The ADR states the on-device storage/data format (e.g. FlatGeobuf via mmap vs SQLite/SpatiaLite) with a one-line reason for the rejected option.
- The ADR states how the app process and widget process(es) share geocoding logic and boundary data without duplicating the full dataset per process.
- The ADR states where and how near-boundary confidence-radius logic (<100m → show both adjacent units, line 1349) is computed, naming the owning component.
- The ADR includes a system/component diagram (input sources → shared core → app screen / Android widget / iOS widget), attached or linked.
- The ADR states minimum supported OS versions per platform, flagging any feature (e.g. interactive widget copy buttons, which need iOS 17+) that pushes the floor higher than the rest of the app.
- The ADR states whether Android background-location permission is required for widget auto-refresh, and records that as needing org device-policy sign-off rather than deciding it unilaterally.
- The ADR is reviewed and approved by `tech-lead` (and `ui-reviewer` for anything touching widget/screen behavior) before [phase0/03](03-repo-scaffolding.md) starts.

## Out of scope

- Repo scaffolding itself ([phase0/03](03-repo-scaffolding.md)).
- The data pipeline (informed by [phase0/01](01-admin-hierarchy-data-source-decision.md), executed in phase4).
- Any geocoding logic implementation.
- On-device memory benchmarking (a follow-up validation task once scaffolding exists; the ADR's numbers should be falsifiable by that later test, not proven here).

## Open questions

- Is the team Kotlin-first, Rust-comfortable, or neither? Determines whether a shared native core is realistically staffable — a staffing/business call, not purely technical.
- What is the org's actual minimum iOS/Android OS version requirement? Needed to confirm the iOS 17+ widget-interactivity implication is acceptable.
- Is Android background-location permission for widget auto-refresh acceptable under org device policy? Needs an answer from whoever owns device policy.
- Does this ADR also need to fix the offline basemap source for the M3 map picker (online tiles would break "fully offline"; VN vector tiles may exceed the same size/memory budget), or is that deferred to the M3 ticket? Flag either way in the ADR.

## Sizing sense-check

Medium — it's a decision-and-documentation ticket, but proving the mmap/shared-core approach actually fits the iOS memory ceiling requires real technical investigation, plus cross-functional sign-off (device policy, min OS version). Treat as a multi-day spike, not a same-day write-up.

---
Source: `plans/map_proposal.html` sections 06-08 (lines 1148-1264); scoped via `po` agent from an `architect` research pass, 2026-09-23.
