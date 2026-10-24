# Track A — 4 variant animations on the board (2026-10-24)

> Brief: [trackA-art-brief-2026-10-24.md](trackA-art-brief-2026-10-24.md). Owner: provided the sheet and asked "dựa vào đây thêm animation mới cho xuna đi".
> Status: **Implemented, uploaded to the board**; parameters **[P]**. Answers O3 (which animations) with the owner's sheet; option A (expression only).

## 1. Art: redrawn from the in-game sprite

- First pass: the owner's sheet (`firmware/assets/source/track_a_sheet_2026-10-24.png`, a 1536×1024 preview with a gradient backdrop and labels) was segmented and scaled per axis.
  - It worked on the board, but the eyes were smaller and the hair noisier than in the base frames, because the source was softened.
- **Owner then asked for a redraw from `pet_frames.png`** ("nhờ bạn vẽ lại animation mới thôi"). `tools/generate_track_a.py` now draws all 64 frames from the project's own idle frame:
  - The face is painted over with the same skin boxes as `generate_pet_scene.py`, then redrawn with the same eye and mouth geometry: open eyes with gaze, closed, happy arcs, `> <`, big bright eyes with a sparkle, flat, smile, "o" and a yawn up to size 3.
  - Motion is whole-pixel only:
    - lean = head rows shifted, body half as much, feet fixed;
    - stretch/squash = nearest-neighbour resample of the body above row 58;
    - hop = the whole sprite lifted.
  - The sheet is kept only as the motion reference; no pixels are copied from it.
- **Checks built into the tool:**
  - the redrawn neutral face equals the idle frame byte for byte;
  - both one-shots start and end on it;
  - feet rows ≥ 59 are unchanged except while hopping;
  - nothing leaves the 96×72 frame.
- **Output:** `assets/generated/track_a_frames.png`, `track_a_preview.gif` (×4, 100 ms), `src/assets/XunaTrackA.cpp` / `include/assets/XunaTrackA.h`: 64 frames, 884,736 B. The segmentation tool was removed.

## 2. When XUNA shows them (option A: the learner still picks idle / happy / curious)

| Variant | Trigger (LifeCore) | Drive |
|---|---|---|
| `greet_nuzzle` (one-shot) | An owner input opens a new owner session (back after ≥ 30 min, or the first press after boot) | — |
| `yawn_stretch` (one-shot) | Activity enters Resting/Sleeping, or wakes to Idle | — |
| `look_around` (loop ×2) | A learner choice of **idle** while explore ≥ ½; XUNA anticipating the owner (routine) | satisfies explore |
| `bounce_play` (loop ×2) | A learner choice of **happy** while play ≥ ¼ **or** emotion ≥ 0.25 (just petted) | (happy already satisfies play) |

- One variant per step: greeting > yawn > look/bounce. Only the variant actually shown satisfies its drive.
- `LifeCore::takeVariant()` latches the variant for the display; `LifeCoreStepOutput::variant` exposes it.
- **Finding:** play only grows while energy ≥ ½, and awake XUNA keeps that for about 30 min, so play rarely passes 0.26. With a ½ threshold bounce would never show. Hence ¼, or a fresh joy.
- **Display:** `VariantPlayer` plays over the current pose, with frame ids 128–191 after the base frames.
  - It uses the personality frame period (tempo).
  - One-shots play 16 frames; loops play 2 cycles.
  - It stops when the pose changes, e.g. the owner sends XUNA to idle, or the 2.4 s happy reaction ends.
- No change to learner, snapshot, BLE or app. Serial: `variant=<name>`.

## 3. Checks

- native / ASan **299/299** (`test_track_a` 5 tests: player timing and cancel; greet once per session; idle + explore → look around and explore satisfied; happy + joy → bounce; every rest/wake yawns).
- Golden S20, Life Lab (md5 `ca3cc133…`) and trace hashes (`7b06fbf8`, `add477bf`, `a5491046`) are unchanged.
- ESP32: RAM 54,880 B, Flash 3,893,949 B (+885 KB, 59.4 %).
- **Board, first pass from the sheet** (backup `~/xuna_backups/2026-10-24-tracka/`, NVS `3997107e…` read twice):
  - parity 2 × PASS, same hashes, `step()` p99 c3 271–277 / c8 317–325 / c9 10 µs;
  - production app `8fdd32f6…`: boot Ok, same PetId, `persona_restored bytes=104 sessions=2 evidence=2`;
  - owner test: first press → `variant=greet_nuzzle`; petted → the next happy greetings → `variant=bounce_play` (×3); draw ≤ 4.9 ms, loop gap ≤ 11 ms.
- **Not seen yet on the board:** `look_around` (needs about 1 h without a curious choice) and `yawn_stretch` (needs a rest or a wake).
- **Board, redrawn frames:** NVS `71343573…` read twice (`tracka/redraw/`); app `e63e9c7a…`; boot `recover=Ok boot=61`, same PetId, `persona_restored bytes=107 sessions=3 evidence=8`.
