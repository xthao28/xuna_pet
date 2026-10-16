# ADR-0002 — Storage layout

Date: 2026-10-12, revised 2026-10-16. **Status: D2a Approved (snapshot medium); LittleFS decision pending S32.**

## Context

Existing MVP uses 96-byte A/B snapshots in 20 KiB NVS. Planned identity/life/memory/log needs require storage measurements and recovery evidence. [E4/E5 preparation](../research/E4-E5-storage.md) has build-checked artifacts but no runtime measurements.

LifeSnapshot v2 (S12a/S12b, host-validated codec, 544–554 B of a 1,536 B budget) is small enough for the same NVS approach the MVP already uses on the board.

## Options

- (b) NVS identity/life A/B + LittleFS log/memory on existing spiffs partition: current hypothesis, no partition-table change.
- (c) Larger custom NVS: requires partition migration planning; not approved.
- (d) Raw partition A/B: greater codec/recovery maintenance; not approved.

## Decision

**D2a (owner-approved 2026-10-16):** LifeSnapshot v2 lives in the existing NVS partition as A/B keys `life0/life1`. On the first boot after the upgrade the device reads `slot0/slot1`, migrates once and leaves `slot0/slot1` untouched for one release as the rollback point. No partition-table change. This is the snapshot half of option (b).

**Still pending:** the experience log/memory medium (LittleFS on `spiffs` or another option) is decided at S32 with E4/E5 measurements. The S11 runtime bench and write-storm power cuts are deferred to that session.

## Consequences

- S13 is unblocked without the S11 bench (merged with S18 by owner decision, AGENTS §3).
- Power-loss behaviour of v2 on this board is **not measured**. Mitigations: A/B newest-valid recovery, host every-offset torn-write sweep, untouched v1 rollback keys, verified NVS backup before upload.
- Preserve pet snapshots and verify restoration; avoid formatting a populated filesystem. Do not mark LittleFS rename atomicity validated from compilation.
