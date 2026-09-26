# Administrative hierarchy epoch & boundary data source decision

**Phase:** 0 — Architecture & Foundation
**Ticket:** phase0/01-admin-hierarchy-data-source-decision
**Depends on:** none
**Blocks:** phase1/01, phase1/02, phase1/03, phase1/04, phase2/01, phase2/02, phase2/03, phase3/01, phase3/02, phase4/01, phase4/02
**Status:** Done

## Decision (resolved 2026-09-23)

Vietnam abolished the district (Huyện) level of local government nationwide effective 1 July 2025 (Resolution 202/2025/QH15) — provinces cut from 63 to 34, communes restructured from ~10.6k to ~3.3k (now called xã/phường/đặc khu). Every screen mockup, widget mockup and data-source table in `plans/map_proposal.html` (lines 639, 689-697, 720, 1193-1210) assumes the old 3-level Tỉnh/Huyện/Xã hierarchy, which may now be legally out of date.

**Decision, made by the user:** implement the **old 3-level hierarchy (Tỉnh/Huyện/Xã)** first, sourced from GADM, because GADM currently only returns the pre-reform data structure. The post-2025-reform (2-level) hierarchy will be collected and migrated in later once a usable data source for it exists — this migration is expected to run through the versioned dataset/OTA-update tooling being built in [phase4/03-ota-dataset-update](../phase4/03-ota-dataset-update.md), using the `admin_epoch` field already scoped there.

This resolves the "which hierarchy epoch" question for all downstream tickets. Where other tickets referred to "the administrative levels decided in Phase 0," that now concretely means **Tỉnh → Huyện → Xã, 3 levels, GADM-sourced**.

## Problem / Value

Even with the epoch decided, the data source's legitimacy and reconciliation approach are not yet settled: GADM's boundaries carry a non-commercial-use license, OSM Geofabrik (used for the Xã level in the original proposal) carries an ODbL share-alike obligation, and neither source is guaranteed to be internally self-consistent (parent/child mismatches at boundary slivers when different levels come from different sources). This ticket also covers those remaining decisions, plus establishing the authority (GSO/Bộ Nội vụ) that codes and names are checked against.

## Acceptance Criteria

- A written decision record states: hierarchy = old 3-level (Tỉnh/Huyện/Xã), source = GADM, and that this is a deliberate interim choice pending future migration to post-2025-reform data — not a permanent design assumption baked into field names elsewhere.
- The record states whether GADM alone is used for all 3 levels, or whether Xã still comes from a second source (e.g. OSM Geofabrik) as in the original proposal — and if a second source is used, names the specific reconciliation method against GADM's own parent boundaries, since mixed-source levels can disagree at boundary slivers (see [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), which requires a single reconciled source for point-in-polygon lookups).
- A named individual/team has recorded a yes/no compliance answer for GADM's non-commercial-use restriction (and OSM's ODbL terms, if used) against this tool's actual internal-only distribution — explicitly flagged as legal's call, not engineering's.
- The record states which entity is authoritative for admin codes/names under the old hierarchy (GSO's pre-2025 list) for QA/spot-check purposes.
- The record documents the migration trigger and rough plan for moving to post-2025-reform data later (even if just "revisit once an official post-reform GADM-equivalent or GSO release is available") so this isn't silently forgotten once M1 ships.
- The record is dated, versioned, and linked from [phase0/02-architecture-system-design](../phase0/02-architecture-system-design.md) and [phase1/01-boundary-dataset-build](../phase1/01-boundary-dataset-build.md).

## Out of scope

- Building the actual boundary dataset file or merge pipeline (executed in phase1/01 and phase4/01, informed by this decision).
- Any geocoding logic, UI copy, or screen rework — those are downstream tickets that now consume "3-level, Tỉnh/Huyện/Xã" as a given.
- Sourcing or building the future post-2025-reform dataset itself (tracked as a future migration, not scoped here).

## Open questions

- Is GADM's non-commercial license actually compliant with this tool's internal distribution model? Needs legal sign-off before the dataset ships even internally.
- Is Xã-level data coming from GADM directly, or is OSM Geofabrik still used for that level as in the original proposal? If OSM, the ODbL share-alike question needs its own legal answer.
- No concrete trigger date/event exists yet for the future migration to post-2025-reform data — flagged so it doesn't get lost as "later" indefinitely.

## Sizing sense-check

Small now that the epoch itself is decided — what remains is mostly a licensing/compliance check and documenting the reconciliation approach, not open-ended research.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect` and `ba` research passes; hierarchy decision made by user, 2026-09-23.
