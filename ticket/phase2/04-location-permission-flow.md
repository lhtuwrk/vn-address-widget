# Location permission flow (foreground in-app + background widget auto-refresh, both platforms)

**Phase:** 2 — M2 Widgets
**Ticket:** phase2/04-location-permission-flow
**Depends on:** [phase1/03-lookup-screens](../phase1/03-lookup-screens.md)
**Blocks:** phase2/01, phase2/02
**Status:** Not Started

## Problem / Value

The GPS-based "vị trí hiện tại" feature and widget auto-update both depend on location permission being granted; the proposal's only related bullet is the single unelaborated "Background location permission handling" (line 1293) with no denial-state UI specified anywhere. Without this ticket, a denied/partial grant degrades unpredictably instead of failing gracefully.

## Acceptance Criteria

- In-app current-location screen: on first visit without permission, triggers the system foreground-location prompt (Android `ACCESS_FINE_LOCATION`, iOS "When In Use"). If denied, the screen shows an explicit denied state (not blank, not a crash) with a CTA to system settings.
- Manual lat/lng entry and map-tap entry remain fully usable with location permission fully denied — the architecture diagram treats GPS and manual input as independent arrows, and nothing in the proposal makes manual/map input depend on location permission.
- Background/widget-refresh permission is requested as a *separate*, later step from foreground permission, following each platform's own convention: Android's `ACCESS_BACKGROUND_LOCATION` is a distinct runtime grant requested only after foreground is granted; iOS's "Always" authorization is requested only after "When In Use" is granted and only right before the background-refresh feature is actually used — not requested speculatively at first launch.
- UI/widget states distinguish at minimum: never-asked, foreground-granted/background-denied, fully-denied, fully-granted. The widget's permission-denied rendering (owned in [phase2/01](01-android-widgets.md)/[phase2/02](02-ios-widgets.md)) is fed by this state, not invented independently there.
- No surface (app or either widget) silently shows nothing or freezes indefinitely on a denial — every denial state has a defined, visible UI response.

## Out of scope

- Widget content/layout once permission is granted ([phase2/01](01-android-widgets.md), [phase2/02](02-ios-widgets.md)).
- The data-bridge mechanics of how a granted permission's result gets to the widget ([phase2/03](03-app-widget-data-bridge.md)).
- Any MDM/device-policy enforcement mechanism itself — the *app-level* UX flow is in scope; whether the org pre-grants via policy is a decision this ticket depends on, not implements.
- Android 12+ precise-vs-approximate location toggle handling beyond acknowledging it exists — full UX for a degraded-accuracy grant is not designed and not assumed in scope here.

## Open questions

- **Org device-policy decision, explicitly unresolved in the proposal and flagged as the driver here:** is this internal tool distributed via MDM with `ACCESS_BACKGROUND_LOCATION` pre-approved/whitelisted, or does every user go through the standard runtime dialog (with the Play Store's background-location review requirements attached)? This materially changes the ticket's scope and cannot be assumed either way.
- **Resolved by architecture:** [ADR 0002 §7](../../docs/decisions/0002-architecture-system-design.md) defines both modes — M2a (snapshot-only, reads the app's last foreground-written snapshot per [phase2/03](03-app-widget-data-bridge.md), **no** location permission needed) and M2b (GPS auto-update, **requires** `ACCESS_BACKGROUND_LOCATION`). The architecture question is answered; what remains here is purely the org device-policy/product call on whether to build M2b at all (see the open question above) — not an architect call.
- What happens to geocoding accuracy if Android location is granted only at "approximate" precision (~3km) — does that break ward/district-level resolution, and if so what's the fallback? Not addressed anywhere in the proposal.
- Denied-state copy and visuals aren't designed in any mockup — needs `ui-reviewer` input, not a PO-invented placeholder.

## Sizing sense-check

Medium-Large, with real variance risk: the org device-policy question and the "does the widget even need background location" question can each independently shrink or grow this ticket substantially. Recommend resolving both before final estimation, not mid-build.

---
Source: `plans/map_proposal.html`; scoped via `po` agent, informed by `architect`/`ba` research, 2026-09-23.
