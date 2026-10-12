# ADR-0002 — Storage layout

Date: 2026-10-12. **Status: Proposed draft; decision pending E4/E5 and owner D2.**

## Context

Existing MVP uses 96-byte A/B snapshots in 20 KiB NVS. Planned identity/life/memory/log needs require storage measurements and recovery evidence. [E4/E5 preparation](../research/E4-E5-storage.md) has build-checked artifacts but no runtime measurements.

## Options

- (b) NVS identity/life A/B + LittleFS log/memory on existing spiffs partition: current hypothesis, no partition-table change.
- (c) Larger custom NVS: requires partition migration planning; not approved.
- (d) Raw partition A/B: greater codec/recovery maintenance; not approved.

## Proposed decision

No option selected yet. Compare measured latency, heap/internal RAM, bounded capacity, render/loop impact and power-cut recovery, then ask owner D2. Do not mark LittleFS rename atomicity validated from compilation. No partition/configuration change is accepted by this draft.

## Consequences / pending acceptance

Preserve pet snapshots and verify restoration; avoid formatting a populated filesystem. Bench source remains outside active repositories. S01 completion or explicit benchmark exception is required before experiment upload. Owner D2 and implementation authorization: **pending**.
