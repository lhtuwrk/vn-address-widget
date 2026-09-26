# iOS home-screen widgets (WidgetKit): small + large

**Phase:** 2 — M2 Widgets
**Ticket:** phase2/02-ios-widgets
**Depends on:** [phase1/02-geocoding-core](../phase1/02-geocoding-core.md), [phase2/03-app-widget-data-bridge](03-app-widget-data-bridge.md), [phase2/04-location-permission-flow](04-location-permission-flow.md)
**Blocks:** none
**Status:** Not Started

## Problem / Value

iOS users get the same glanceable current-location widget as Android, working within WidgetKit's stricter background-refresh and process-isolation model.

## Acceptance Criteria

- Two WidgetKit widgets exist, sized to mirror the Android 2×2/4×2 intent (exact iOS family mapping — `systemSmall`/`systemMedium`/`systemLarge` — is an open question below, since WidgetKit doesn't use Android's grid-unit vocabulary and the proposal never maps one to the other).
- Timeline entries are scheduled on a 15–30 minute cadence (explicit in risk section, line 1342) and every rendered entry displays a "last updated" timestamp (also explicit, line 1342) — this is the mechanism that makes staleness visible to the user, not a bug to hide.
- **Baseline tap behavior for both sizes: tapping the widget opens the app** to the current-location screen. This is the only interactive behavior in scope for the initial ship.
- Same 5-state matrix as [phase2/01](01-android-widgets.md) (no data yet / fresh / stale-cached / permission-denied / outside coverage), rendered per WidgetKit's timeline-entry model rather than live state.
- Permission-denied state's tap target deep-links to the iOS Settings app (WidgetKit extensions cannot themselves trigger a system permission prompt — this is a platform constraint, not a design choice).

### Sub-scope: in-widget copy button (spike-gated, NOT baseline)
- The feature table's "nút copy" / "copy thẳng từ widget" (lines 725-726) for the large widget is **not** committed baseline scope for iOS. It requires an iOS 17+ App Intent as the widget's tap target, and writing to `UIPasteboard` from a backgrounded widget-extension AppIntent is not guaranteed reliable on iOS.
- This sub-scope is blocked on a prerequisite spike (separate task, not implied as included here) confirming: (a) pasteboard-write reliability from the extension process, (b) acceptable UX if it silently fails.
- Do not build the in-widget copy tap target until that spike reports back; ship baseline tap-to-open in the meantime.

## Out of scope

- Android widgets ([phase2/01](01-android-widgets.md)).
- In-widget copy button, until the spike above clears it (tracked separately, not bundled into this ticket's completion).
- Manual "refresh now" action — not specified in the proposal for either platform.
- Lock Screen widgets / StandBy / watchOS complications — not mentioned anywhere in the proposal; called out explicitly here so nobody assumes they're implied by "WidgetKit."

## Open questions

- Minimum supported iOS version: does the org's device fleet allow requiring iOS 17+ (needed only if/when the copy sub-scope ships), or does baseline need to support an older floor? This is an org/product decision, tracked jointly with [phase0/02](../phase0/02-architecture-system-design.md).
- iOS widget family mapping (small/medium/large) vs Android's 2×2/4×2 — which iOS family is "the large one"? Not stated in the proposal.
- Same small-widget content-field contradiction as [phase2/01](01-android-widgets.md) — same `ui-reviewer` dependency, carried here rather than re-litigated.
- Does the widget extension need its own location fetch, or does it only ever read the app's last-written snapshot? (Ties directly to [phase2/03](03-app-widget-data-bridge.md)'s open question on the architecture diagram's sibling-consumer ambiguity, line 1176.) This affects whether iOS widget refresh needs "Always" location authorization at all.

## Sizing sense-check

Medium-Large. WidgetKit's process isolation, App Group setup, and the timeline model are more constrained than Glance; the spike-gated copy sub-scope adds schedule uncertainty even though it's explicitly not baseline.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research, 2026-09-23.
