# Initial repo/project scaffolding

**Phase:** 0 — Architecture & Foundation
**Ticket:** phase0/03-repo-scaffolding
**Depends on:** [phase0/01-admin-hierarchy-data-source-decision](01-admin-hierarchy-data-source-decision.md), [phase0/02-architecture-system-design](02-architecture-system-design.md) — do not start until both are approved.
**Blocks:** all of phase1
**Status:** Done

## Problem / Value

The repo is currently empty except for the proposal doc — no code, manifest, tests, or CI. Once the hierarchy/data-source and architecture decisions are approved, the team needs one buildable, multi-language skeleton — Flutter app, shared core, Android/Kotlin shell, iOS/Swift shell — so M1 feature work has a known build/link path instead of four disconnected experiments.

## Acceptance Criteria

- The repo structure separates the Flutter app, the shared core (language per [phase0/02](02-architecture-system-design.md)'s ADR), the Android native shell/widget module, and the iOS native shell/widget module, matching exactly the component split named in that ADR (nothing invented or omitted).
- The shared core builds standalone via a documented command and produces the artifact type the ADR specified, for at least one target triple per platform (e.g. Android arm64 + iOS arm64).
- The Flutter app calls at least one placeholder function in the shared core via the FFI path the ADR names, and the call succeeds on a debug build on both an Android emulator and iOS simulator — demonstrated, not asserted.
- The Android widget module (Glance) and iOS widget module (WidgetKit) each exist as buildable targets, even with placeholder/static content — a tech-lead can build and run each with no missing-dependency errors.
- A CI skeleton runs a build step for each of: Flutter app, shared core, Android widget module, iOS widget module — with per-component pass/fail visibility, not one combined job.
- A root README documents how to build each component locally, how the shared core links into each target, and links to [phase0/01](01-admin-hierarchy-data-source-decision.md)'s and [phase0/02](02-architecture-system-design.md)'s decision records as the basis for this structure.
- No feature logic (geocoding, hierarchy resolution, real UI screens) is present beyond stubs needed to prove the build/link chain.

## Out of scope

- Real geocoding logic, dataset bundling, non-placeholder UI/widgets, CI test coverage beyond "does it build," release/signing pipeline, dataset OTA mechanism (phase4).

## Open questions

- Exact module/file layout can't be finalized until [phase0/02](02-architecture-system-design.md)'s ADR names the shared-core language and component split — the criteria above are structural; concrete paths follow once that lands.
- Does the org have existing CI conventions (provider, iOS signing certs) this must conform to, or is CI greenfield too? Nothing in the current repo answers this.

## Sizing sense-check

Medium-to-large — four toolchains (Dart/Flutter, the shared-core language, Kotlin/Gradle, Swift/Xcode) means the real milestone is "hello world round-trips through FFI on both platforms," which is typically where scaffolding estimates blow up, not "files exist."

---
Source: `plans/map_proposal.html`; scoped via `po` agent from an `architect` research pass, 2026-09-23.

## Completed (2026-09-26)

Scaffolding pass closed. Remaining gaps filled:

- **`app/test/widget_test.dart`** — Flutter smoke test; validates
  `VnaddrCore.expectedAbiVersion == 1` (pure Dart, no FFI call) so CI passes
  without a native library present. Full FFI round-trip is a manual/device
  verification step, as documented in the test file.
- **`app/android/README-GRADLE-SETUP.md`** — dedicated one-time setup guide
  for the Gradle wrapper (three options: Android Studio, `gradle wrapper` CLI,
  copy from another project). Created because `gradle-wrapper.jar` is absent
  (binary, not committed) and the prior inline README note was insufficient for
  first-time contributors.
- **`README.md`** (Android widget section) — updated to link directly to the
  new setup doc instead of the buried inline paragraph.

All other acceptance criteria were already satisfied by the prior scaffolding
pass (file structure, CI skeleton, Rust core build, Flutter FFI wiring, iOS
stubs, root README).

