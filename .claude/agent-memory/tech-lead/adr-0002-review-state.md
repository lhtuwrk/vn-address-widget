---
name: adr-0002-review-state
description: ADR 0002 v1.3 check 2026-09-23 -> handle item closed; bootstrap item has one residual (rename onto existing v{N}); what a v1.4 check must confirm
metadata:
  type: project
---

**History:** v1.0 had 11 items, v1.1 had 8, and v1.2 had 2 blocking ones. By the v1.3 check (2026-09-23), all were closed except one.

**v1.3 residual (one sentence left):** §4 step 2 (docs/decisions/0002-architecture-system-design.md:102). If the process is killed after `.staging-vN` has been renamed to `dataset/vN/` but before the pointer swap, the next launch sees "pointer older than bundled" and re-stages. The rename onto the existing non-empty `vN/` then fails every time (POSIX rename, FileManager.moveItem, File.renameTo). On first install that means no dataset, permanently. Fix: "if `dataset/v{bundled}/` already exists it is complete by construction, so skip the copy and swap the pointer; a missing pointer means version 0."
Closed in v1.3: the handle item (§4 step 4 and §10 now say ArcSwapOption, store/load_full, NotOpen, no handle).

**Why:** a v1.4 check should confirm only that one sentence.
**How to apply:** if it's present, approve and tell the caller to set Status to Accepted. Drop this memory once the ADR is Accepted. Related: [[widget-gps-autoupdate-scope]], [[gadm-data-quirks]]
