# Learning Engine upgrade roadmap

Ngày cập nhật: 2026-10-14

## Mục tiêu

XUNA sẽ được nâng cấp dần từ preference learner có giới hạn thành một learning engine có thể giải thích, replay và đo lường được. Tầng đầu tiên ưu tiên tính xác định, bounded memory và khả năng chạy trên MCU; không nhảy thẳng vào neural network hay cloud.

## Trạng thái hiện tại

### Fact

- Learner v1 trong `LifeEngine` vẫn là bảng Beta 2 context × 2 action, chỉ nhận feedback explicit và được lưu bằng snapshot 96 byte.
- Đã thêm `xuna/learning/PreferenceLearnerV2.h` như một lõi thử nghiệm độc lập, chưa thay thế v1 trong production.
- V2 hỗ trợ bảng context/action bounded, posterior Beta, optimistic exploration theo uncertainty, propensity, decision ID, feedback idempotent, provenance source, bounded evidence/history, metrics và fingerprint replay.
- Đã thêm test cho exploration ban đầu, học theo context, chống feedback trùng, thay đổi policy sau feedback, giới hạn evidence và deterministic fingerprint.

### Assumption

- Hai context và hai action hiện tại là đủ để kiểm tra vertical slice; số context/action thật sẽ phải được đo trong Life Lab trước khi đưa vào thiết bị.
- `source != 0` là contract tối thiểu cho feedback; mapping opcode/source cụ thể vẫn thuộc protocol/persistence work.

### Proposal

1. **L1 — Bounded contextual preference (đã code, chưa production):** dùng V2 làm shadow learner cạnh v1 để so sánh quyết định, không đổi BLE payload và không phá snapshot cũ.
2. **L2 — Persistence v2 + migration:** định nghĩa codec/version/CRC cho posterior, decision counter, bounded history và metrics; migrate snapshot 96 byte thành Newborn-compatible state; kiểm tra power interruption và replay.
3. **L3 — Context/action features:** thay bảng context tĩnh bằng vector nhỏ (quiet/play, mood, needs, day-part khi trusted time có sẵn), với trọng số bounded hoặc bucket hóa; vẫn giữ explainability.
4. **L4 — Delayed credit + conversation:** tách candidate fact, explicit confirmation và behavioral feedback; ghi provenance/confidence, cho phép correction/delete, rồi mới cập nhật learner.
5. **L5 — Optional sequence learning:** chỉ thử tiny Q-learning/eligibility trace hoặc active-inference-style exploration nếu dữ liệu cho thấy preference learner không đủ; đây là experiment, không phải cam kết MVP.

## L1 contract

- Không cấp phát heap và không phụ thuộc Arduino.
- Mọi quyết định có `decisionId`, context, action, policy version và propensity.
- Feedback lặp cùng decision ID không được cập nhật posterior lần hai.
- Evidence bị giới hạn; history chỉ giữ cửa sổ bounded gần nhất, vì vậy duplicate protection không phải dedup vô hạn.
- `fingerprint()` dùng để so sánh golden trace/replay, không phải checksum bảo mật.
- V2 chưa được gọi từ `LifeEngine`, `LocalBehavior` hoặc BLE production cho tới khi có persistence v2 và shadow comparison.

## Validation boundary

Các test đã được viết nhưng chưa chạy được trong session này vì máy không có `pio`, `c++`, `g++`, `clang++` hoặc `cl`. Vì vậy L1 hiện có static/source review evidence tĩnh; chưa có native, sanitizer, ESP32 hay board result. Lệnh xác nhận khi toolchain sẵn sàng:

```text
pio test -d firmware -e native
pio test -d firmware -e native_asan
pio run -d firmware -e xuna_t_display_s3
```

## Tiêu chí để gọi là learning engine

Không chỉ tăng counter. Cần chứng minh bằng replay/golden data rằng:

1. cùng input + cùng seed tạo cùng decision/fingerprint;
2. feedback được gắn đúng decision/context/source và không bị áp dụng hai lần;
3. policy tương lai thay đổi theo feedback có lợi, nhưng không làm rò rỉ giữa context;
4. state tồn tại qua reboot/power interruption sau khi có codec v2;
5. một metric holdout hoặc A/B trong Life Lab cho thấy lựa chọn sau học tốt hơn baseline, với confidence và giới hạn dữ liệu được ghi lại.


## L1.5 — Prequential evaluation (2026-10-14)

- Fact: added `xuna/learning/PrequentialEvaluator.h`. It scores a decision before feedback using fixed-point Brier loss, accuracy and gain against a uniform 50/50 baseline.
- Contract: callers must invoke `score()` before applying the matching feedback; invalid decision context/action is rejected and no metric is changed. Aggregates are bounded integer types and do not retain raw samples.
- Experiment: added tests showing the post-feedback prediction can beat the uniform baseline and that invalid decisions are ignored.
- Validation limit: no native/compiler run was possible; this is source/test preparation only. L1.5 does not prove general learning quality or authorize production wiring.

## L1.6 — v1/v2 shadow comparison (2026-10-14)

- Fact: added `xuna/learning/LearningShadow.h`, a pure test/Life-Lab harness that keeps the existing `LifeEngine` v1 baseline beside `PreferenceLearnerV2`.
- Contract: each shadow decision records baseline action and candidate decision; accepted feedback trains both exactly once, while invalid/duplicate candidate feedback cannot double-train v1. The harness exposes agreement, exploration and feedback counters plus a deterministic fingerprint.
- Experiment: added deterministic replay and baseline/candidate synchronization tests. This does not change BLE payloads, snapshots or production behavior.
- Validation limit: no native/compiler run was available; only static checks are recorded.

## L1.7 — bounded learning trace runner (2026-10-14)

- Fact: added `xuna/learning/LearningTrace.h`, a fixed-size event runner for `Choose` and `Feedback` traces. It retains only the latest eight decisions, replays v1/v2 shadow decisions, applies prequential scoring before accepted feedback, and emits metrics plus a deterministic fingerprint.
- Contract: unknown feedback is reported separately; structurally invalid events make the run fail; duplicate feedback is passed to the shadow harness but never scored twice. Source validation follows the current v1 contract (1–2).
- Experiment: added replay tests for shadow synchronization, duplicate handling, online score collection and same-seed fingerprint equality.
- Boundary: this is a learning-focused pre-Lab runner, not the full S19a command-line DSL or LifeCore simulator. It is not linked into firmware production.

## L1.8 — bounded learning explanations (2026-10-14)

- Fact: added `xuna/learning/LearningExplanation.h`. It emits a fixed-size explanation with context, selected action, per-action positive/negative counts, posterior mean, sample count, margin, policy version and a small reason enum (`Exploration`, `HighestPosterior`, `Invalid`).
- Contract: explanations contain numeric evidence only; no generated prose, heap allocation or fabricated causes. Invalid decisions produce an invalid explanation.
- Experiment: added tests for initial exploration, posterior-winner explanation and invalid decision handling.
- Boundary: this is a core/Life-Lab data contract, not yet a mobile Journal UI or production BLE payload.

## L1.9 — learning trace DSL + host runner preparation (2026-10-14)

- Fact: added `xuna/learning/LearningTraceDsl.h` with bounded parsing for `@+<ms>` traces, learner verbs (`choose`, `feedback`) and reserved S19a verbs (`button`, `cmd`, `sync`, `reboot`, `powercut`, `day`, `expect`). It supports comments, decimal/hex values, signed timezone values and typed parse errors without heap allocation.
- Fact: added `firmware/sim/lifelab.cpp` and `firmware/sim/README.md`. The host-only runner consumes the learner subset, feeds the existing trace/shadow/evaluator stack and emits one deterministic CSV metrics row.
- Experiment: added parser tests for learner events, extended verbs, malformed lines and replay through `LearningTraceRunner`.
- Boundary: this is a pre-S19a learning runner. Reserved non-learner verbs are counted as unsupported; it does not emulate LifeCore, NVS/LittleFS, persistence or board behavior.

## Competitive upgrade plan (2026-10-15, Proposed)

Competitor review and phased amendments (closed-loop Life Lab, v3 learner,
curiosity variant, teachable tricks, formation arc, senses):
[XUNA_LEARNING_COMPETITIVE_UPGRADE.md](../architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md).
