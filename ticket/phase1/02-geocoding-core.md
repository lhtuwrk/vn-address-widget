# Geocoding core: lookup, parent resolution, near-boundary, cache

**Phase:** 1 — M1 MVP core geocoder
**Ticket:** phase1/02-geocoding-core
**Depends on:** [phase1/01-boundary-dataset-build](01-boundary-dataset-build.md), [phase0/02-architecture-system-design](../phase0/02-architecture-system-design.md)
**Blocks:** phase1/03, phase1/04, phase2/01, phase2/02, phase2/03, phase3/01
**Status:** Not Started

## Problem / Value

This is the actual product value: deterministic, fully offline, correct hierarchy lookup from a coordinate, fast enough for both interactive use and (later) widget refresh.

## Acceptance Criteria

- Given a lat/lng, the engine returns the Xã polygon containing the point (if any), plus Huyện and Tỉnh names/codes read from that feature's own attributes — not independently queried per level.
- Lookup executes in the shared core (per [phase0/02](../phase0/02-architecture-system-design.md)'s ADR) via FFI against the mmap'd FlatGeobuf, using a spatial index to shortlist candidates before the point-in-polygon test (not a linear scan of the full file per query).
- A point with no containing polygon returns a distinct, explicit "no match" result rather than an exception or a wrong nearest-guess.
- **Near-boundary rule:** if the point is <100m from the nearest Xã boundary edge, the result includes both adjacent Xã units with their respective parent chains (`plans/map_proposal.html:1349`). This rule applies only at the Xã level per the confirmed reading of the proposal — it is not applied at Huyện/Tỉnh boundaries.
- **Caching is correct-by-construction:** a repeat query is served from cache only when the new point still falls inside the previously matched polygon's actual geometry — not a fixed bbox/grid-cell lookup. A test case using two points that would sit in the same fixed grid cell but on opposite sides of a real boundary must return correct, different results for both.
- Median single-lookup latency is measured on a representative mid-range test device (cold cache and warm cache) and recorded against an agreed threshold (see open questions).
- The core is callable from Flutter via FFI and returns one structured result type (Xã + Huyện + Tỉnh + optional near-boundary alternates + no-match flag) that the UI and (later) widget layers consume directly, with no duplicate geometry logic in Dart.

## Out of scope

- Cache persistence across app restarts (unless [phase0/02](../phase0/02-architecture-system-design.md) decides otherwise — flagged below).
- Street/house-number Nominatim fallback, batch/bulk lookup API, runtime boundary-data updates, GPS polling/background refresh logic (that's phase2's widget concern; only the shared lookup call belongs here).

## Open questions

- Target latency SLA for one lookup — the proposal's "<5ms" figure was scoped to a Dart R-tree design that's being replaced by the Rust/FFI approach; needs a fresh number.
- Must the cache survive process restarts, or is in-memory-per-session sufficient for M1?
- Is a legitimate in-country point ever expected to return "no match" (e.g. coastline/island data gaps), and if so, is that acceptable for M1 or does it need special handling?
- Is the 100m near-boundary threshold validated against the chosen dataset's own boundary-line precision (GADM/OSM lines can themselves carry more than 100m of error), or is 100m being carried forward as-is without re-checking?

## Sizing sense-check

Medium-Large. Rust/FFI plumbing, correct-by-construction caching, and near-boundary geometry are genuine engineering.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research, 2026-09-23.
