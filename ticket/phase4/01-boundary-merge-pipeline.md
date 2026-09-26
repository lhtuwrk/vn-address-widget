# Repeatable boundary-merge pipeline (mergers.csv → FlatGeobuf + manifest)

**Phase:** 4 — M4 Data maintenance tooling
**Ticket:** phase4/01-boundary-merge-pipeline
**Depends on:** [phase0/01-admin-hierarchy-data-source-decision](../phase0/01-admin-hierarchy-data-source-decision.md), [phase1/01-boundary-dataset-build](../phase1/01-boundary-dataset-build.md)
**Blocks:** phase4/02, phase4/03
**Status:** Not Started

## Problem / Value

Vietnam's administrative boundaries change periodically (Huyện-level updates historically "1-2 năm/lần" per `plans/map_proposal.html:1202`; Xã-level "theo đợt sáp nhập lớn" per line 1208) — and per [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md), this project will eventually need to migrate from the old 3-level GADM-sourced hierarchy to post-2025-reform data. The proposal's own risk mitigation (line 1335) calls for a one-time `ST_Union` script, but its Data Layer section (line 1214) and M4 roadmap both describe this recurring as an OTA-shipped update. A one-off script can't be re-run safely or audited months later. The team needs a pipeline that takes a reviewed, sourced list of boundary changes and reproducibly emits a new dataset — this is also the concrete mechanism the future hierarchy migration will run through.

## Acceptance Criteria

- Pipeline accepts a `mergers.csv` (or equivalent structured input) with columns for: old admin code(s), new admin code, government resolution/decree reference, and change type (e.g. whole-unit union vs. partial reassignment). Each row must cite a resolution reference; rows without one are rejected by the tool.
- Pipeline supports whole-unit merges via boundary union (e.g. `ST_Union`) AND partial reassignment, where part of an old unit's area moves to a different new unit using externally supplied replacement geometry (not derived by unioning, since union cannot split a polygon) — the tool must accept a replacement-geometry input for partial cases and fail loudly if a `change_type=partial` row has no replacement geometry supplied.
- Boundary simplification step preserves shared edges between neighboring polygons — i.e., after simplification, two polygons that shared a border still share that border (no newly introduced gaps or slivers at shared edges). This is checked by an automated test, not manual inspection.
- Source data snapshots used as pipeline input are pinned (versioned/hashed) and stored or referenced from the repo, so a given pipeline run is reproducible from a known input state.
- Output is a FlatGeobuf file plus a `manifest.json` containing at minimum: `dataset_version`, `schema_version`, `min_app_version`, `admin_epoch`, `sha256`, `size`, `url`.
- Running the pipeline twice on the same pinned inputs produces byte-identical (or checksum-identical) FlatGeobuf output — i.e., it is deterministic, not just "runnable again."
- Pipeline is invokable as a standalone command/script (not tied to a one-time notebook or manual GIS-tool session) and documented (inputs, outputs, how to add a new `mergers.csv` row) so a future maintainer who wasn't on this project can run it.
- Pipeline is a distinct, versioned tool in the repo (not inline code in [phase1/01](../phase1/01-boundary-dataset-build.md)'s initial-build script) — phase1 may reuse it for the first build, but this ticket is what makes it reusable rather than one-off.
- The pipeline's `admin_epoch` field is exercised at least once against the specific old→new migration path named in [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md) (old 3-level → future 2-level), even if the actual new-epoch source data isn't available yet — i.e., prove the schema supports an epoch change, not just same-epoch updates.

## Out of scope

- Deciding the data source / hierarchy model — that's [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md). This pipeline consumes whatever source/schema that ticket lands on.
- Running the CI/CD validation gate itself ([phase4/02](02-data-validation-gate.md)) — this ticket produces the candidate dataset; validation is a downstream gate.
- The OTA delivery/hosting of the manifest and FlatGeobuf file to devices ([phase4/03](03-ota-dataset-update.md)).
- Authoring the actual `mergers.csv` content for the future post-2025-reform migration (a large, one-time data-entry/research task) — this ticket delivers the tool and its format, not the fully populated dataset.
- UI/tooling for non-technical staff to edit `mergers.csv` — assumed to be a reviewed text file edited by whoever maintains the data.

## Open questions

- Who authors and reviews `mergers.csv` entries in practice (a person's role, a review process) — unstated in the proposal.
- What simplification tolerance/algorithm is expected (proposal doesn't specify a value) — needs a decision or an explicit "tunable parameter, default TBD" acceptance criterion.
- Where do partial-reassignment replacement geometries come from in practice (government-published shapefile, OSM extract, manual digitizing)? The proposal doesn't say; this affects what "supplied replacement geometry" means operationally.

## Sizing sense-check

Medium. The mechanics of union/replace + FlatGeobuf/manifest output are moderate engineering, but correctly preserving shared edges under simplification and handling partial reassignment (not just clean unions) is the part that will take real iteration and testing — this is more than the "1 tuần" the proposal budgets for all of M4 combined.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect` research, 2026-09-23.
