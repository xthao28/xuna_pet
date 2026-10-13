# S01 — Observed BLE v1 transcript

Date: 2026-10-13 (Asia/Ho_Chi_Minh). Status: In progress.

Physical ESP32 running firmware c84d4e3; nRF Connect on REDMI Note 15 / Android 15, connected to 98:C3:77:A6:6F:D9. Values below are observed through nRF Read, captured with ADB UI XML; not host-derived fixtures. UUID suffix is -8c44-4db6-9f61-2b7d5300a101.

## Initial read baseline

Reads occurred sequentially, not atomically. Existing pet has one confirmed-text approval episode from earlier S01 smoke tests.

| UUID prefix | Value (hex) | Bytes |
|---|---|---|
| 7a6e0002 capabilities | 01 08 0F 00 0F 03 60 09 | 8 |
| 7a6e0004 status | 01 01 02 00 00 00 00 00 01 00 00 00 E5 E4 01 00 | 16 |
| 7a6e0005 life | 01 14 00 00 A9 0F 00 00 01 00 00 00 00 00 00 00 00 00 00 01 | 20 |
| 7a6e0006 memory page 0 | 01 01 00 00 00 00 01 02 00 00 00 00 00 00 00 00 00 00 00 00 | 20 |
| 7a6e0007 memory page 1 | 01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 | 20 |

Capabilities: command mask 0x000f, animation mask 0x0f, flags 0x03, duration 2400 ms. Life: activeSeconds 4009, feedback 1, pending ID 0, quiet/play Idle, canFeedback 0, retained memory 1. Memory page 0: quiet/Idle/approved/source 2 (confirmed text); page 1 empty.

Raw XMLs outside Git: /Users/xthao28/xuna_backups/2026-10-13-s01/nrf-read-{2,4,5,6,7}.xml. Capture helper nrf_read.py retained beside them. This step only read GATT values; no characteristic writes or firmware upload.

## Pending scripted writes

Status Notify; quiet suggestion/approval; duplicate request; reused ID with conflicting payload; feedback without pending decision; physical button during pending decision; forget. Capture every write and subsequent status/life/memory values. Read baseline alone does not complete S01/S08a prerequisites.

## Invalid-length command — observed

Owner attempted Suggest Quiet request 1. Inspector shows transmitted value **7 bytes**, `01 02 01 00 00 00 00` (missing final reserved/source byte). Status Read: `01 01 01 00 00 00 02 00 03 00 00 00 20 F0 27 00`; request 1, result 2 = invalid_length. Life Read: `01 14 00 00 B9 14 00 00 01 00 00 00 00 00 00 00 00 00 00 01`; pending ID 0/canFeedback 0, feedback 1/memory 1 unchanged. Memory pages unchanged from baseline. Notify descriptor shows notifications enabled. Invalid-length rejection observed; valid Suggest Quiet still pending. Use a fresh request ID 2 for the valid attempt to avoid conflating this rejection with request-cache behavior.

Raw capture copies: external nrf-invalid-length-{2,4,5,6,7}.xml. The helper's nrf-read files are latest captures and may be overwritten on subsequent reads; the baseline hex table above remains the durable initial record.

## Valid quiet suggestion — request 2

Observed Write: `01 02 02 00 00 00 00 00` (8 B).
Status Read: `01 01 02 00 00 00 00 00 03 00 00 00 3E EF 29 00` (16 B): result OK, request 2, Idle.
Life Read: `01 14 00 00 35 15 00 00 01 00 00 00 02 00 00 00 00 00 01 01` (20 B): quiet/Idle, activeSeconds 5429, feedback 1, pending suggestion 2, canFeedback 1, memory 1. Both memory page values unchanged from initial baseline. Suggest alone did not learn. Raw captures external nrf-suggest-2-{2,4,5,6,7}.xml. Next scripted approval uses fresh request 3, source 1, target 2; not sent during this read step.

## Approval and duplicate — request 3

Owner authorized direct ADB operation of nRF Connect for the scripted cases.

Approval Write: `01 03 03 00 00 00 01 01 02 00 00 00`.
Status: `01 01 03 00 00 00 00 00 03 00 00 00 6C 80 2C 00` (OK).
Life: `01 14 00 00 D3 15 00 00 02 00 00 00 02 00 00 00 00 00 00 02`: feedback 2, memory 2, canFeedback 0.
Memory 0: `01 02 00 00 00 00 01 02 00 00 01 01 00 00 00 00 00 00 00 00`; memory 1 unchanged/empty. Second episode quiet/Idle/approved/source 1.

Exact duplicate Write: `01 03 03 00 00 00 01 01 02 00 00 00`.
Status: `01 01 03 00 00 00 00 00 03 00 00 00 AC ED 2D 00` (OK).
Life: `01 14 00 00 2A 16 00 00 02 00 00 00 02 00 00 00 00 00 00 02`: feedback and memory remain 2. Both memory pages unchanged. Duplicate does not learn twice: PASS.

External captures nrf-approve-3-{2,4,5,6,7}.xml, duplicate-3.json and nrf-duplicate-3-{4,5,6,7}.xml. Raw GATT values observed, not derived.

## conflict-3 — observed

Write: `010303000000000102000000`.

Characteristic 4: `01 01 03 00 00 00 06 00 03 00 00 00 6C E1 2E 00`.

Characteristic 5: `01 14 00 00 68 16 00 00 02 00 00 00 02 00 00 00 00 00 00 02`.

Characteristic 6: `01 02 00 00 00 00 01 02 00 00 01 01 00 00 00 00 00 00 00 00`.

Characteristic 7: `01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

Feedback/memory unchanged at 2. Result 6 request_id_conflict: PASS. External JSON/XML capture names match case label.

## no-pending-4 — observed

Write: `010304000000010102000000`.

Characteristic 4: `01 01 04 00 00 00 04 00 03 00 00 00 92 99 2F 00`.

Characteristic 5: `01 14 00 00 99 16 00 00 02 00 00 00 02 00 00 00 00 00 00 02`.

Characteristic 6: `01 02 00 00 00 00 01 02 00 00 01 01 00 00 00 00 00 00 00 00`.

Characteristic 7: `01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

Feedback/memory unchanged at 2. Result 4 invalid_argument with canFeedback 0: PASS. External JSON/XML capture names match case label.

## pending-5 — observed

Write: `0102050000000000`.

Characteristic 4: `01 01 05 00 00 00 00 00 03 00 00 00 15 8E 30 00`.

Characteristic 5: `01 14 00 00 D6 16 00 00 02 00 00 00 05 00 00 00 00 00 01 02`.

Characteristic 6: `01 02 00 00 00 00 01 02 00 00 01 01 00 00 00 00 00 00 00 00`.

Characteristic 7: `01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

OK, pending 5/canFeedback 1; owner then pressed GPIO0 (confirmed in chat). External JSON/XML files match case label.

## button-feedback-6 — observed

Write: `010306000000010105000000`.

Characteristic 4: `01 01 06 00 00 00 04 00 05 00 00 00 9D 09 32 00`.

Characteristic 5: `01 14 00 00 38 17 00 00 02 00 00 00 00 00 00 00 00 00 00 02`.

Characteristic 6: `01 02 00 00 00 00 01 02 00 00 01 01 00 00 00 00 00 00 00 00`.

Characteristic 7: `01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

Feedback for target 5 rejected with invalid_argument 4 after physical GPIO0; pending 0/canFeedback 0, counters unchanged at 2. PASS. External JSON/XML files match case label.

## forget-7 — observed

Write: `0104070000000000`.

Characteristic 4: `01 01 07 00 00 00 00 00 05 00 00 00 0B C8 32 00`.

Characteristic 5: `01 14 00 00 67 17 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

Characteristic 6: `01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

Characteristic 7: `01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.

OK; feedback/memory 0, both choices Idle, pending 0. Active lifetime 5991 retained. PASS. External JSON/XML files match case label.

## Script checkpoint

Required S01 §3 inspector sequence captured: baseline Read; quiet/approve; exact duplicate; conflict; no-pending feedback; physical-button invalidation; forget. Invalid-length rejection additionally observed. Captures are sequential and non-atomic; status Read reflects the latest command result. Notify enabled, but full notification timing stream/timeout behavior not measured here. S01 overall remains In progress pending full physical/diagnostics/text/power-cut criteria.
