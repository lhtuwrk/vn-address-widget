---
name: widget-gps-autoupdate-scope
description: Proposal M2 explicitly includes widget GPS auto-update + background location; any "snapshot-only widget" default silently drops scope
metadata:
  type: project
---

**Rule:** The proposal's M2 lists "Widget nhỏ: vị trí hiện tại (GPS auto-update)" and "Background location permission handling". A design that makes widgets read only the app's last snapshot, with no background location, drops an M2 feature. Flag it as a product decision that needs sign-off, not an engineering default. It also decides whether the widget processes need the Rust core and whether the iOS extension memory budget matters.

**Evidence:** plans/map_proposal.html:1291-1293 (widgets are M2 only, none in M1). ADR 0002 v1.2 §7 (docs/decisions/0002-architecture-system-design.md:117-123) handles this correctly now: M2a is snapshot-only and M2b needs ACCESS_BACKGROUND_LOCATION, pending org sign-off. Compare ticket/phase2/01 (periodic WorkManager refresh, permission-denied state).

**How to apply:** check widget, bridge, permission, and architecture reviews for this. Related: [[adr-0002-review-state]]
