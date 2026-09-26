---
name: gadm-data-quirks
description: GADM v4.1 VNM level-3 file has space-stripped names and no official codes - affects address formatting and "code" fields
metadata:
  type: project
---

**Rule:** GADM v4.1 VNM names have their spaces stripped in all 11,163 features (e.g. "BàRịa-VũngTàu", "ÔLâm", "Phường1", TYPE_3 "Thịtrấn"), and CC_3 is "NA" everywhere. The only codes are GADM GIDs. Any design that "formats the address from feature properties" or promises "name+code" needs a name-restoration step, and "code" means a GID, not a GSO code. Flag designs that assume clean names.

**Evidence:** references/gadm41_VNM_3.json (checked 2026-09-23: zero NAME_2 values contain a space, 11163x "CC_3":"NA").

**How to apply:** check this in any review of ADR 0001, phase1/01 (dataset build), phase1/02 (formatting), or the last_result.json schema. Related: [[adr-0002-review-state]]
