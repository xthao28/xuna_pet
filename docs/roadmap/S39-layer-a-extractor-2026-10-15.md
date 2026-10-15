# S39 — Conversation Layer A extractor (2026-10-15)

Status: **done — pure Dart domain in `mobile/`, not wired into the UI.**
Wiring (follow-up question, confirmation sheet, opcode 6, "Why?") is S27a;
the device side of opcode 6 is S24a. No board, phone or network involved.

## What was built

`mobile/lib/features/conversation/domain/`:

| File | Content |
|---|---|
| `entity/candidate_event.dart` | `CandidateEvent` (typed slots instead of the plan's generic map): type (`rateLastReaction`, `statePreference`, `requestContext`, `askWhy`), polarity, action (`AnimationState`, idle/happy/curious only), `PreferenceContext`, `DayPart`, requested `InteractionContext`; derived `provenance` (`userStated` for statements, `userFeedback` otherwise), `requiresConfirmation`, `isComplete`, `withContext` for the follow-up answer |
| `entity/extraction_result.dart` | `ExtractionOutcome`: `candidate`, `needsContext`, `oneAtATime`, `unsupportedAction`, `notAvailableYet`, `unknown` |
| `entity/preference_context.dart` | quiet / play / greeting (D5) |
| `entity/day_part.dart` | unknown / morning / afternoon / evening / night (plan §9.2) |
| `usecase/extract_candidate_use_case.dart` | `ExtractCandidateUseCase`, the LocalRuleExtractor |

Rules (S22 decisions): Vietnamese first, English only the V1 words; closed
word lists matched on whole tokens, longest phrase first, contexts before
actions ("khi nghỉ" is a context, "nghỉ" an action); a statement is a
candidate only if every other word is an allowed filler; "không"/"chẳng"
count only in "không thích"/"chẳng thích"; two actions, contexts or day
parts → `oneAtATime`; no context → `needsContext` with a partial candidate.
Hypotheticals ("giả sử", "nếu"…), questions (question mark, "có … không",
"à/hả/chứ/nhỉ"), quotes, instruction-like text and inputs over 120
characters → `unknown`. Layer B phrases → `notAvailableYet`. The input is
not stored or logged.

Not created: the plan §11.3 speech/provider/retriever interfaces. They
belong to D16 (deferred) and D11 (open); adding them now would build later
sessions speculatively (mobile AGENTS §0). The V1 `ParseTextIntentUseCase`
and its tests are unchanged; the home screen still uses V1 until S27a.

## Validation (Flutter 3.32.8, the pinned SDK)

- `flutter pub get`: `pubspec.lock` unchanged. `dart format`: applied.
- `flutter analyze`: no issues.
- `flutter test`: 39/39 PASS (10 new table tests: ratings, context
  requests, the S22 statements, AskWhy, one-at-a-time, Layer B and unknown
  actions, 19 must-produce-nothing cases incl. injection strings, follow-up
  completion, confirmation/provenance, never `sleep`).

## Known limits

- Vietnamese must be precomposed (NFC). Dart has no built-in Unicode
  normalisation; common keyboards produce NFC. Revisit if a real keyboard
  sends decomposed text.
- The phrase table is intentionally small; growing it needs table tests.
