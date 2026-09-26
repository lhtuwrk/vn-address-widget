# Initial boundary dataset build & bundling (M1 slice)

**Phase:** 1 — M1 MVP core geocoder
**Ticket:** phase1/01-boundary-dataset-build
**Depends on:** [phase0/01-admin-hierarchy-data-source-decision](../phase0/01-admin-hierarchy-data-source-decision.md), [phase0/03-repo-scaffolding](../phase0/03-repo-scaffolding.md)
**Blocks:** phase1/02
**Status:** Not Started

## Problem / Value

M1's geocoder has nothing to query against without a bundled boundary dataset. This ticket is the minimal M1-scoped slice — get one usable, correct finest-level boundary file bundled into the app — not the full data pipeline (merge tooling, OTA updates, automated validation are phase4).

Per [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md)'s resolved decision, this dataset targets the **old 3-level hierarchy (Tỉnh/Huyện/Xã)**, sourced from **GADM**.

## Acceptance Criteria

- A single FlatGeobuf file contains polygon boundaries for the **Xã** level (the finest level), with Tỉnh and Huyện name/code carried as attributes on each Xã feature, covering all of Vietnam.
- File is bundled as an app asset and successfully loads/mmaps on both Android and iOS; resulting app size increase is measured and documented.
- Attribute schema includes, at minimum, geometry plus name + admin code for Tỉnh, Huyện, and Xã.
- A documented source and generation process exists for how the file was produced (script or documented manual steps acceptable for M1), so data QA can trace provenance.
- Spot check: for at least 20 known lat/lng points spanning at least 10 different provinces (including Hanoi, HCMC, and at least 2 points deliberately near a known ward/commune boundary), the returned Xã polygon matches the real-world unit, verified manually against an authoritative (pre-2025) source.
- A single, reconciled boundary source is used across all 3 levels (per [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md)'s decision on whether GADM alone or GADM+OSM is used) — not independently-queried per-level sets that can disagree at boundary slivers.
- Display names are restored per [ADR 0001's "Data quality caveat"](../../docs/decisions/0001-admin-hierarchy-data-source.md) (GSO pre-2025 list join + manual fixups) before the file ships — zero space-stripped/concatenated names (e.g. `"BàRịa-VũngTàu"`, `"Thịtrấn"`) in the output attributes.

## Out of scope

- OTA update mechanism, merge/union tooling for future administrative changes (phase4), automated data validation (phase4), street/house-number Nominatim fallback data, the future migration to post-2025-reform (2-level) data.

## Open questions

- Exact bundle size ceiling — the proposal's ~30MB figure (line 1180) was for three separately-sourced level files; a single Xã-level file with embedded parent attributes may size differently and needs its own target.
- Licensing/attribution obligations for GADM bundling into an internal tool — tracked in [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md), needs to close before this ships even internally.

## Sizing sense-check

Medium. Even as a "just get something usable" slice, sourcing, cleaning, and spot-verifying a country-wide boundary dataset is real work.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research and the user's hierarchy decision, 2026-09-23.
