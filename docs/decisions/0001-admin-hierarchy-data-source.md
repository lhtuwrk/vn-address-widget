# ADR 0001: Administrative hierarchy epoch & boundary data source

**Status:** Accepted (hierarchy epoch & source choice) — see §"Data quality caveat" for a follow-up item raised by `tech-lead` review of [ADR 0002](0002-architecture-system-design.md)
**Date:** 2026-09-23
**Version:** 1.1
**Ticket:** [phase0/01-admin-hierarchy-data-source-decision](../../ticket/phase0/01-admin-hierarchy-data-source-decision.md)

## Decision

- **Hierarchy epoch:** the **old 3-level hierarchy** — Tỉnh (province) → Huyện (district) → Xã (commune) — as it stood before Vietnam's 1 July 2025 administrative reform (Resolution 202/2025/QH15, which cut provinces from 63 to 34 and restructured ~10.6k communes into ~3.3k xã/phường/đặc khu). This is a **deliberate interim choice**, not a permanent assumption baked into field names or schemas elsewhere in the system.
- **Data source: GADM alone, for all 3 levels.** No second source (e.g. OSM Geofabrik) is used.
- **Concrete dataset:** [`references/gadm41_VNM_3.json`](../../references/gadm41_VNM_3.json) — GADM v4.1, Vietnam, administrative level 3 (Xã), GeoJSON `FeatureCollection`, CRS `OGC:CRS84` (WGS84 lon/lat).

## Why GADM alone (no OSM reconciliation needed)

Verified directly against the dataset: every level-3 (Xã) feature already carries its full parent chain in its own properties —

```json
{
  "GID_3": "VNM.1.1.1_1",
  "GID_1": "VNM.1_1", "NAME_1": "AnGiang",
  "GID_2": "VNM.1.1_1", "NAME_2": "AnPhú",
  "NAME_3": "AnPhú", "TYPE_3": "Thịtrấn", "ENGTYPE_3": "Townlet"
}
```

Stats: 63 provinces, 710 districts, 11,163 communes — matching the expected pre-reform counts (63 provinces, ~700 districts).

Because Tỉnh/Huyện names and codes are embedded directly in each Xã feature, point-in-polygon lookup against the level-3 geometry alone (per [ADR 0002](0002-architecture-system-design.md)) yields all 3 levels from one hit, from one internally-consistent source. This avoids the boundary-sliver reconciliation problem and OSM's ODbL share-alike obligation entirely — both would apply only if a second source were mixed in.

## Authoritative reference for QA/spot-checks

Tổng cục Thống kê (GSO)'s pre-2025 administrative unit list is the authority for admin codes/names under the old hierarchy, for spot-checking GADM names/codes during QA.

## Data quality caveat (flagged by `tech-lead` review, 2026-09-23)

GADM's names in `references/gadm41_VNM_3.json` are **not display-ready** and there are **no official numeric admin codes** at this level:

- Every `NAME_1`/`NAME_2`/`NAME_3`/`TYPE_3` value has its internal spaces stripped (verified: 0 of 11,163 features have a space in any of these fields) — e.g. `"BàRịa-VũngTàu"` (a `NAME_1` province value), `"ÔLâm"`, `"Phường1"` (`NAME_2`/`NAME_3`), `"Thịtrấn"` (`TYPE_3`). Formatting an address directly from these fields (per [ADR 0002 §2](0002-architecture-system-design.md#2-lookup-engine)) would produce garbled output if copied by a user — the name-restoration join below must cover **all levels**, not just Xã/Huyện.
- `CC_3` (GADM's slot for an official government code) is `"NA"` for all 11,163 features — there is no official numeric code in this dataset. **"Code" in any lookup result therefore means the GADM `GID` string** (e.g. `GID_3: "VNM.1.1.1_1"`), not a GSO or government-issued code. [ADR 0002 §2](0002-architecture-system-design.md#2-lookup-engine) records this explicitly.

**Action required before [phase1/01-boundary-dataset-build](../../ticket/phase1/01-boundary-dataset-build.md) ships display-facing output:** add a name-restoration step — join GADM names (normalized, spaces stripped) against the GSO pre-2025 authoritative list (§"Authoritative reference" above) by normalized-name-plus-parent, with manual fixups for cases that don't match cleanly (diacritics, renamed units, ambiguous splits). Naively re-inserting spaces at capital-letter boundaries is not reliable for Vietnamese text (e.g. multi-word proper nouns, "Thị trấn" vs "Thịtrấn" as one administrative-type token) and must not be used as the fix.

This does not change the hierarchy-epoch or data-source decision above — it's a data-quality step required downstream, tracked here so it isn't lost before phase1/01 starts.

## Open item — legal sign-off (not resolved by this record)

GADM's terms carry a **non-commercial-use restriction**. Whether that is compliant with this tool's actual internal-only distribution model is **explicitly legal's call, not engineering's**, and is **not yet answered**. This must be resolved before the dataset ships in any build distributed outside the engineering team, even internally. Tracked as an open action item — assign to legal/compliance owner before [phase1/01-boundary-dataset-build](../../ticket/phase1/01-boundary-dataset-build.md) ships a build.

Since GADM is the sole source (see above), OSM's ODbL terms do not apply and need no separate sign-off.

## Migration trigger for post-2025-reform data

No concrete trigger date exists yet. Revisit once an official post-reform GADM-equivalent or GSO release becomes available. The migration path runs through the versioned dataset / OTA-update tooling in [phase4/03-ota-dataset-update](../../ticket/phase4/03-ota-dataset-update.md), keyed on the `admin_epoch` field scoped there — not a hardcoded rewrite of this decision.

## Consequences

- All downstream tickets referring to "the administrative levels decided in Phase 0" mean: **Tỉnh → Huyện → Xã, 3 levels, GADM v4.1-sourced, single-file, single-source**.
- [phase1/01-boundary-dataset-build](../../ticket/phase1/01-boundary-dataset-build.md) consumes `references/gadm41_VNM_3.json` directly as its input; no merge/reconciliation pipeline against a second source is needed.
- The dataset schema/format must carry an `admin_epoch` marker from the start so the future 2-level migration is additive, not a breaking rewrite.
