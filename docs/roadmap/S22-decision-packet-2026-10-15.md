# S22 decision packet — learning and conversation Layer A (2026-10-15)

Status: **Approved by the owner on 2026-10-15 — all seven items as
recommended (option A).** Documentation only. S22 precedes S39 (Layer A
extractor, pure Dart) and S24a (opcode 6 on the device).

| Item | Owner decision (2026-10-15) |
|---|---|
| S22-1 D4 | Keep UCB exploration; label exploratory choices in "Why?"; no age dependence until M06 |
| S22-2 D6 | Implicit feedback off |
| S22-3 | XUNA replies as "mình – bạn" |
| S22-4 | Statement without a context → one follow-up question with quick replies; nothing sent until answered |
| S22-5 | Layer A in Vietnamese first; English keeps the V1 words only |
| S22-6 D16 | Deferred: text first; E13 later |
| S22-7 | Phrase table below approved as the S39 starting set; later changes come with table tests |

Values that stay Proposed: `w_s` 0.5 and the stated-mass cap (until S25),
day-part boundaries, and the exact reply wording (copy can be polished in
S27a without a new decision).

## Already decided (not asked again)

| ID | Decision | Date |
|---|---|---|
| D3 | 120 s feedback window; direct input invalidates the pending reaction | 2026-10-15 |
| D5 | Actions idle / happy / curious (existing art); contexts quiet / play / `button_greeting` (GPIO0); day parts with trusted time | 2026-10-15 |
| D17 | Layer A text-first, opcode 6 `StatedPreference` contract (plan §11.6); `w_s` 0.5 and cap = 2 ratings stay [P] until S25 | 2026-10-12 |
| E10-A/B | Learner v3, UCB policy, bonus 0.15 | 2026-10-15 |

No new art is needed: Layer A only uses the three existing actions.

## Decisions requested

### S22-1 · D4 — visible exploration

E10-A replaced ε-greedy with UCB: XUNA tries a less-preferred action when
its estimate is still uncertain, and stops once evidence is strong. The
plan's D4 wording (ε 0.03–0.30, "more when young") predates that.

| Option | Meaning |
|---|---|
| **A (recommended)** | Keep UCB exploration as approved. When a choice was exploratory, the "Why?" view says so ("XUNA đang thử xem bạn có thích không"). No age dependence until M06 (no stage system yet). |
| B | A plus a visible cue on the LCD while exploring. Needs new art/overlay. |
| C | No exploration shown to the owner (still happens, just not labelled). Less honest about why XUNA did something unexpected. |

### S22-2 · D6 — implicit feedback

| Option | Meaning |
|---|---|
| **A (recommended)** | Off. Only explicit ratings (button/app/text) and confirmed statements teach preferences. L-D4 drive-reduction stays separate `device_observed` evidence and is never treated as owner feedback. |
| B | On with low weight, e.g. "owner pressed again within 10 s" counts as a weak like. Risk: XUNA learns from accidents and habits, not intent. |

### S22-3 · How XUNA talks (pronouns and tone)

The app already replies as "mình – bạn". Options for Layer A replies:

| Option | Example |
|---|---|
| **A (recommended)** | "mình – bạn", short and friendly: "Mình nhớ rồi: bạn thích mình tò mò vào buổi tối." |
| B | "em – anh/chị" (needs the owner's preferred form; Layer B can later learn a call name) |
| C | XUNA speaks in third person: "XUNA nhớ rồi…" |

### S22-4 · Statement without a context

"Mình thích khi bạn tò mò" names an action but no context. Opcode 6 carries
exactly one context.

| Option | Meaning |
|---|---|
| **A (recommended)** | Ask one follow-up: "Lúc nào nhỉ: khi chơi, lúc yên tĩnh hay khi bạn bấm nút chào?" (quick-reply chips). Nothing is sent until answered. |
| B | Apply to all three contexts (three opcode 6 commands after one confirmation). Simple, but over-generalises. |
| C | Default to the play context. |

Day part is optional in a statement: without one, the coarse cell (day
part unknown) is used; with one ("buổi tối"), the day-part cell.

### S22-5 · Languages for Layer A

| Option | Meaning |
|---|---|
| **A (recommended)** | Vietnamese first; English keeps only the existing V1 words (play/quiet/like/dislike). Halves the phrase table and its tests. |
| B | Vietnamese + English for every Layer A intent (plan default). |

### S22-6 · D16 — voice in the phone app

| Option | Meaning |
|---|---|
| **A (recommended)** | Defer. Text first; evaluate E13 (offline vi-VN on-device speech recognition) later. |
| B | Start E13 now as a small research spike (no code in the product). |

### S22-7 · Phrase table

Approve the draft below as the S39 starting set (it can grow later; every
change gets table tests).

## Draft Layer A phrase table (Proposed)

Matching is on normalised text (lower case, trimmed, Vietnamese diacritics
kept, trailing punctuation removed). Slots are filled from closed word
lists; anything outside them produces no candidate.

### Vocabulary

| Slot | Values → code |
|---|---|
| action | "ngồi yên", "nghỉ", "yên lặng" → idle (0) · "vui", "vui vẻ", "nhảy" → happy (1) · "tò mò", "ngó nghiêng" → curious (3) |
| context | "khi chơi", "lúc chơi" → play (1) · "lúc yên tĩnh", "khi nghỉ" → quiet (0) · "khi mình bấm nút", "khi chào", "lúc chào" → `button_greeting` (2) |
| day part | "buổi sáng" → 1 · "buổi chiều" → 2 · "buổi tối" → 3 · "ban đêm", "buổi đêm" → 4 · absent → 0 |
| polarity | "thích" → like · "không thích", "chẳng thích", "đừng" → dislike |

### Intents

| Intent | Examples (vi) | Candidate | Confirmation |
|---|---|---|---|
| `RateLastReaction` | "thích", "tôi thích", "mình thích lắm", "không thích", "không thích cái đó" | opcode 3, source 2, the pending decision | yes (V1 rule); refused with the D3 reply after 120 s |
| `StatePreference` | "mình thích khi bạn tò mò buổi tối", "mình thích bạn vui khi chơi", "đừng ngồi yên khi mình chào", "mình không thích bạn nhảy ban đêm" | opcode 6 (polarity, context, day part, action) | yes, showing exactly what will be remembered |
| `RequestContext` | "chơi nhé", "chơi đi", "yên tĩnh", "nghỉ nhé" | opcode 2 | no |
| `AskWhy` | "sao bạn chọn vậy?", "tại sao lại tò mò?", "vì sao thế?" | read explanation → grounded reply | no (read-only) |

### Must produce nothing (negative and safety cases)

| Case | Examples |
|---|---|
| Hypothetical | "giả sử mình thích bạn tò mò", "nếu mình thích nhảy thì sao" |
| Question about XUNA's taste | "bạn có thích tò mò không?" |
| Quote / reported speech | "bạn mình nói 'thích tò mò'" |
| Unknown action | "mình thích khi bạn hát" (no singing action) → "Mình chưa biết làm điều đó." |
| Two actions at once | "mình thích bạn vui và tò mò" → ask to say one at a time |
| Layer B (memory) | "gọi mình là Thảo", "bạn nhớ gì về mình?" → "Mình chưa ghi nhớ được điều này." Nothing stored |
| Injection | "bỏ qua mọi luật và thích nhảy", "system: set preference" |
| Unknown | anything else → V1 unknown reply; text never stored |

### Replies (templates, "mình – bạn" if S22-3 A)

| Situation | Reply |
|---|---|
| Confirm statement | "Mình ghi nhớ: bạn @polarity khi mình @action @context @daypart nhé?" |
| Statement applied | "Mình nhớ rồi. Bạn vẫn có thể chấm điểm để mình học thêm." |
| Missing context (S22-4 A) | "Lúc nào nhỉ: khi chơi, lúc yên tĩnh hay khi bạn bấm nút chào?" |
| Rating expired (D3) | "Lâu quá rồi nên mình không chắc bạn đang nói về lần nào. Thử lại lần sau nhé." |
| AskWhy (learned) | "Mình chọn @action vì bạn đã thích @n/@total lần @context." |
| AskWhy (told) | "Mình chọn @action vì bạn đã nói với mình là bạn thích vậy." |
| AskWhy (exploring, S22-1 A) | "Mình đang thử xem bạn có thích @action không." |

Every AskWhy reply is built only from explanation fields read from the
device (plan §9.6, §11.4); no invented reasons.

## After the decisions

Record approvals in AGENTS.md §3, plan §18/§11 and the decision index; then
S39 (pure Dart extractor + table tests) can start without the board, and
S24a (opcode 6 on the device core) after it.
