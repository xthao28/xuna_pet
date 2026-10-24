# Track A — art brief for new XUNA animations (2026-10-24)

> For the owner to hand to an artist or an image tool. Attach these reference files:
> `firmware/assets/generated/pet_frames.png` (current in-game frames, 32 × 4 strip of 96×72) and
> `firmware/assets/source/xuna-emotion-sheet-v2.png` (original character sheet).
> Decision context: [personality plan](personality-plan-2026-10-23.md) Track A / O3. Using the art (option A: expression variants, no learner change) is a separate firmware step.

---

## Prompt (English, copy as is)

**Project.** XUNA is a small pixel-art pet that lives on a 320×170 LCD. I need **4 new animations** of the **existing character**. Same design, same size, same palette. The attached files show the character: an orange, square-ish creature with spiky light-orange hair, a dark brown brow band, two short legs, and a thick dark outline. Do not redesign it.

**Hard technical rules (the firmware depends on them):**
1. **Frame size: exactly 96 × 72 pixels.** True pixel art at native resolution: 1 pixel = 1 screen pixel. No upscaling, no anti-aliasing, no blur, no gradients, no soft shadows.
2. **PNG with transparency.** Alpha must be only 0 (empty) or 255 (solid). No semi-transparent pixels.
3. **Never use pure magenta #FF00FF**: it is the firmware's transparent key colour.
4. **Same size and position as the reference.** In the neutral pose the character fills x = 17…78 and y = 13…65 inside the 96×72 frame (about 62 × 53 px). The **bottom of the feet is on row y = 65** and the body is centred around x = 48. The feet stay planted on that row in every frame, except during an intended hop. The lower body is x = 26…70; the two legs are separated by a gap around x = 48…55.
5. **Stay inside the frame.** Stretching, tilting and hopping may use the empty space (up to 13 px above the hair, about 17 px on each side), but nothing may be cut off. Keep a 1–2 px margin.
6. **Palette** (use these; small extra shades only if really needed):
   - outline / darkest `#160C0B` (2 px thick, like the reference)
   - body `#EC6F38`, body shadow `#A94324`, warm accent `#EE8841`
   - hair `#FCB156`, hair highlight `#FDCA88`
   - brow band: dark brown as in the reference
   - eye white `#FFF7E9`, pupils / mouth `#161516`
7. **No background, no floor, no ground shadow, no text, no props.** The game draws the room.
8. **Timing:** each frame shows for **100 ms**. Deliver **16 frames per animation** (1.6 s). 8–24 frames is acceptable if the motion needs it; say which.
9. **Clean loops and transitions.**
   - *Loop* animations must loop seamlessly: the last frame flows into the first.
   - *One-shot* animations must **start and end exactly on the neutral pose** (frame 1 of the reference), so they blend with the existing idle animation without a jump.

**The 4 animations:**

| Name | Type | What happens | Feeling |
|---|---|---|---|
| `look_around` | loop | Head and upper body tilt slowly to one side, the eyes glance around, return to centre, tilt to the other side. Feet planted. The tilted poses in row 3 of the sheet are the reference. | curious, attentive |
| `yawn_stretch` | one-shot | From neutral: eyes squeeze shut, mouth opens in a big yawn, the body stretches upward 4–6 px (squash and stretch), the hair spikes lift. Then it settles back down and blinks once. Ends neutral. | sleepy, cosy (shown before a nap and after waking) |
| `bounce_play` | loop | Two or three playful hops in place: squash on landing, up to 6 px off the ground at the top, happy closed-eye smile, the hair bounces a little behind the motion. | playful, cheerful |
| `greet_nuzzle` | one-shot | Leans toward the viewer and wiggles happily side to side, with big bright eyes, perked-up hair and a small smile. Ends neutral. | warm "welcome back"; never sad or clingy |

**Do not:** draw sad, angry or crying faces; change proportions, colours or outline thickness; add arms or objects; move the feet off row y = 65 except in `bounce_play`.

**Deliverables (for each animation):**
- `<name>_strip.png`: one horizontal strip, frames left to right, width = frames × 96, height 72.
- `<name>/frame_00.png … frame_15.png`: the same frames as separate 96×72 PNGs.
- A short note: frame count, loop or one-shot, and any frame that should be held longer.
- Optional: an animated GIF preview at 100 ms per frame, scaled up ×4 with nearest-neighbour.

---

## Ghi chú cho owner

- Công cụ AI vẽ ảnh thường **không giữ đúng lưới 96×72 và không giữ alpha 0/255**. Người vẽ bằng Aseprite/Pixquare sẽ cho kết quả ổn định hơn. Nếu dùng AI, xin thêm bản high-res kiểu `xuna-emotion-sheet-v2.png`, rồi mình chuyển về 96×72 bằng tool như đã làm với 4 animation hiện có.
- Khi nhận art: đặt vào `firmware/assets/source/` và báo mình. Mình sẽ kiểm tra kích thước, alpha, đường chân y = 65 và palette, đưa vào asset build, rồi gắn theo hướng A (biểu hiện theo drive/tâm trạng, learner không đổi).
- Flash: 4 × 16 frame ≈ 0,9 MB, trong khi còn trống khoảng 3,5 MB.
