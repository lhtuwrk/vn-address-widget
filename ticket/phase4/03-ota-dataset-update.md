# OTA dataset update & on-device versioning

**Phase:** 4 — M4 Data maintenance tooling
**Ticket:** phase4/03-ota-dataset-update
**Depends on:** [phase4/02-data-validation-gate](02-data-validation-gate.md)
**Blocks:** none
**Status:** Not Started

## Problem / Value

The app is fully offline for its core lookup, but boundary data changes over time and the proposal explicitly wants updates delivered "không cần release app" — without an app store release (`plans/map_proposal.html:1318`). Without a safe update mechanism, every boundary correction (including the eventual migration to post-2025-reform data flagged in [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md)) would force a full app release cycle, and a corrupted or bad download could break offline geocoding for users with no recourse. This ticket delivers the on-device half: safely fetching, verifying, and switching to a new dataset, with rollback if something's wrong.

## Acceptance Criteria

- On foreground app launch, the app checks whether a newer compatible dataset is available (compatible = `schema_version` supported by the current app build).
- A new dataset downloads to a versioned, non-active directory — the currently active dataset remains untouched and in use during download.
- Before activation, the app verifies the downloaded dataset: `sha256` hash matches manifest, signature is valid, `schema_version` is compatible with the running app build, and a golden-point self-test (a small subset check, not the full CI gate) passes.
- If verification fails at any step, the downloaded dataset is discarded/not activated, the previously active dataset continues to be used, and the failure is recorded/logged (exact logging destination TBD — see open questions).
- Activation is atomic: switching the "active" pointer to the new dataset version is a single operation such that no reader (app or widget process) ever observes a partially-active or inconsistent state.
- The previous dataset version (N-1) is retained after a successful update, enabling rollback to it if the new version is later found to be bad.
- A defined rollback action exists to point "active" back at N-1 (triggered condition — automatic vs. manual — is an open question below).
- Every runtime process that reads the dataset (main app process, Android widget process, iOS widget process) independently re-checks the active-version pointer and reopens the dataset if it has changed, rather than relying on a single process to notify the others.
- "Active version" is computed, at any point in time, as the highest version whose schema the current app build supports — regardless of whether that version was bundled at install time or downloaded later. Concretely: a fresh install with a newer bundled dataset must not be overridden by a stale "downloaded" pointer from a previous install/reinstall scenario, and a downloaded update must not be shadowed by an older bundled version once activation succeeds.
- This mechanism is the concrete path by which the future migration from the old 3-level hierarchy to post-2025-reform data (flagged in [phase0/01](../phase0/01-admin-hierarchy-data-source-decision.md)) would ship — an `admin_epoch` change is just a dataset update with a bigger schema delta, not a new mechanism.
- iOS: given WidgetKit's background refresh limits (15-30 min refresh cadence, "last updated" shown), the update-check-and-activation flow does not require it to complete within a single widget refresh cycle — a stale-but-valid dataset continuing to serve lookups while a check/download is in progress is acceptable and expected, not an error state.

## Out of scope

- The CI/CD validation gate that produces a shippable dataset in the first place ([phase4/02](02-data-validation-gate.md)) — this ticket assumes the manifest and FlatGeobuf file it downloads have already passed that gate.
- The merge pipeline that produces new dataset versions ([phase4/01](01-boundary-merge-pipeline.md)).
- Server-side hosting/CDN infrastructure for serving the manifest and FlatGeobuf file — this ticket covers device-side consumption, not where files are hosted or how they're published.
- Background/scheduled update checks outside of app foreground launch — no background task is assumed or specified.
- Signing-key management/rotation process — signature verification is in scope on-device; how keys are generated/rotated/distributed is not addressed here.
- Any user-facing UI for manually triggering or viewing update status, unless such UI is already specified elsewhere in the proposal (it isn't).

## Open questions

- What is the rollback trigger — automatic (e.g. app detects repeated failures using the new dataset and reverts) or manual (a support/debug action)? Proposal doesn't specify; needs a decision before rollback behavior can be fully defined.
- Where do verification failures get logged/reported (local log only, remote telemetry, none)? Unstated — this is an internal tool so there may be no analytics pipeline at all; needs confirmation.
- Is there any update frequency expectation, or is none assumed (the "1-2 năm/lần" and "theo đợt sáp nhập lớn" cadences describe data-change frequency, not an SLA for how fast the app must pick up a published update)? No SLA is stated in the proposal, so none is assumed here.
- How many prior versions beyond N-1 are retained, and is there a storage-cleanup policy for old dataset versions? Proposal doesn't say; N-1 retention for rollback is the only requirement explicitly implied.
- Does `min_app_version` in the manifest block download entirely, or block activation only after download? Affects whether older app builds waste bandwidth downloading datasets they can't use.

## Sizing sense-check

Large relative to the other phase4 tickets. Atomic activation with cross-process consistency across three separate runtimes (main app, Android widget process, iOS widget process) on two different OS widget frameworks (Glance and WidgetKit) is the hardest part — it's not just a download-and-swap, it's getting multiple independently-scheduled processes to agree on "current" state without a shared always-running process to coordinate them. This alone likely exceeds the "1 tuần" the proposal allots to all of M4.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect` research, 2026-09-23.
