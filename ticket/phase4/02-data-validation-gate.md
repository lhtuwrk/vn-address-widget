# Data validation gate (CI/CD, pre-ship)

**Phase:** 4 — M4 Data maintenance tooling
**Ticket:** phase4/02-data-validation-gate
**Depends on:** [phase4/01-boundary-merge-pipeline](01-boundary-merge-pipeline.md)
**Blocks:** phase4/03
**Status:** Not Started

## Problem / Value

An incorrect boundary dataset shipped to production would silently mis-geocode users (wrong Tỉnh/Huyện/Xã), which is the core function of the app — there's no manual-review fallback once it's live. The team needs an automated gate that catches structural and geometric errors in a candidate dataset before it's ever built into the app or offered as an OTA update, so bad data physically cannot ship.

## Acceptance Criteria

- Gate runs as part of CI/CD and produces a pass/fail result; a failing gate blocks the dataset from being marked shippable (no manual override path is assumed unless specified).
- Checks performed, each independently reportable (pass/fail + diagnostic detail, not just an aggregate boolean):
  - Unit counts (Tỉnh, Huyện, Xã) match an official reference list (e.g. GSO) for the target `admin_epoch`.
  - Every admin code in the dataset is unique within its level.
  - Every Xã (and Huyện) resolves to an existing parent code — no orphan units.
  - Gaps and overlaps between neighboring polygons stay below a defined tolerance (tolerance value to be set — see Open questions).
  - The union of all Xã/commune polygons covers the national outline, including Hoàng Sa and Trường Sa and adjacent sea area required by law to be depicted.
  - A `golden_points.csv` of known lat/lng → expected admin code passes 100% (any single mismatch fails the gate).
  - A representative set of out-of-country / at-sea points return an explicit "no match" result rather than being assigned to the nearest polygon.
- Gate consumes the FlatGeobuf + manifest output of [phase4/01](01-boundary-merge-pipeline.md) as its input — it validates the pipeline's output, not raw source data.
- Failure output identifies which specific check failed and, where applicable, which admin code(s)/geometry are implicated (e.g. "gap of 340m between code X and code Y exceeds tolerance"), so a developer doesn't have to re-derive the failure from scratch.
- Gate is re-runnable on-demand against any candidate dataset version, not just wired to a single CI trigger.

## Out of scope

- Producing or maintaining the `golden_points.csv` fixture content itself beyond establishing its format/location — populating it with a comprehensive, verified set of points is a data task, not purely an engineering one (flagged as an open question below).
- The lighter on-device self-test that runs during OTA activation ([phase4/03](03-ota-dataset-update.md)) — that's a subset sanity check on the device, not the full CI gate.
- Sourcing the "official government/GSO list" used for unit-count comparison — assumed to be an input this ticket's implementer obtains, not something this ticket defines the acquisition process for beyond noting it's needed.
- Automatic correction/fixing of failed geometry — the gate reports failures; fixing them is a manual pipeline-input change ([phase4/01](01-boundary-merge-pipeline.md)), not automated remediation.

## Open questions

- What is the acceptable gap/overlap tolerance (in meters or another unit)? Not stated anywhere in the proposal — needs an explicit decision, not an assumed number.
- What counts as the authoritative "official government/GSO list" for unit counts (specific dataset/publication), and how current does it need to be relative to `admin_epoch`?
- Who owns/curates `golden_points.csv` initially and over time, and what's the minimum coverage expected (e.g. does every province need at least one point, do known boundary-adjacent points need dedicated coverage)? Unstated.
- Is a failing gate a hard block with no override, or can someone force-ship with a documented waiver? Proposal doesn't say; defaulting to hard block per "validate after every update" framing (line 1317) unless told otherwise.

## Sizing sense-check

Medium. Each individual check is small in isolation, but building a reliable "gaps/overlaps below tolerance" geometric check and a correct sea/Hoàng Sa/Trường Sa coverage check both require care with geometry-library edge cases (multi-part polygons, enclaves). Establishing `golden_points.csv` with real coverage is a data-collection effort that could extend this beyond the code work alone.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect` research, 2026-09-23.
