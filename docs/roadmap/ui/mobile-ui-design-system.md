# Mobile UI — XUNA design system and four-tab home

Date: 2026-10-14 (Asia/Ho_Chi_Minh). Source design: Claude Design project "XUNA App" (`XUNA App.dc.html`, project `021e070e-cd28-4c9e-924b-d571616aa42e`), imported read-only through the claude_design connector.

Scope: owner-requested mobile UI session. Owner choices (2026-10-14): design system plus the four tabs on **real data only**; parts without data or approval are **shown locked with a "SẮP CÓ" label**; design fonts **bundled as assets**. No protocol, firmware, backend, dependency or SDK change. No commit or push.

## Implemented

- Tokens: `AppColors.xuna*`, `AppTextStyle.display*` (Anton), `mono*` (JetBrains Mono), body sizes on Be Vietnam Pro (new default family), XUNA stroke/shadow/radius values in `AppDimens`. App theme uses the XUNA font and paper background.
- Fonts: Anton, Be Vietnam Pro (400–800), JetBrains Mono (500, 700) in `mobile/assets/fonts/` with their SIL OFL 1.1 texts. No package added.
- Base widgets (`lib/shared/widgets/`): `AppInkCard`, `AppCtaButton`, `AppBoxButton`, `AppPillButton`, `AppTag`, `AppToggle`, `AppStatusDot`, `AppKeyValueRow`, `AppDisplayHeading`, `AppSheetFrame`, `AppBottomNavBar` + `AppNavItem`; 24 SVG icons redrawn from the design.
- Home shell with bottom navigation (Nhà / Trò chuyện / Nhật ký / Thiết bị) over the existing `HomeController` and device repository:
  - **Nhà:** connection shortcut, XUNA room with activity chip and happy bubble mirroring the device `AnimationState`; tapping XUNA requests `happy`; talk CTA; latest memory card.
  - **Trò chuyện:** local text V1 as chat bubbles, quick replies that map to the parser's phrases, explicit confirmation bar before feedback is recorded, restart/journal menu sheet.
  - **Nhật ký:** filters; pending suggestion card with Thích / Không thích (real feedback); "Học được" card per context from the device preference with recent evidence; memory episodes (newest first, numbered, no invented dates); forget with confirmation.
  - **Thiết bị:** board illustration reflecting the connection, status card (scan, connect, disconnect, status/errors, mode), direct expressions, static hardware info sheet.
- Device errors now also show as a snack bar so they are visible from any tab.

## Follow-up adjustments (owner review, 2026-10-14)

- `AppDisplayHeading`: the title now takes all width left by the side note (it previously shared it with a `Spacer`, which wrapped "LỚN LÊN." and truncated "MỖI NGÀY.").
- Display tokens loosened for stacked Vietnamese diacritics: `display62` line height 1.25 / tracking +0.3; new `display48` (line height 1.3 / tracking +1.5) for the journal title. Checked with a real-font render.
- UI design roadmap and Claude Design prompts for later waves: [XUNA_UI_DESIGN_PLAN.md](../../design/XUNA_UI_DESIGN_PLAN.md) (Proposed).

## Fact / Assumption / Proposal

- Fact: the chat transcript lives only in controller memory (max 40 lines); it is never persisted or logged.
- Fact: locked "SẮP CÓ": growth level and stages (M06), brightness (no protocol opcode), voice/mic (gated), image attach, auto-connect/wake toggles, device speaker/mic.
- Assumption: the claude_design read tool caps files at 256 KiB, so `room.png` arrived truncated and `avatar.png`/`book.png` could not be saved. Stand-ins: `rain.png` for the room, `hero.png` for the avatar and growth sprites, a redrawn pixel-book SVG. Replace with the original exports when available.
- Proposal: a follow-up restyles the inherited base dialogs/snack bars with XUNA tokens (mobile AGENTS §11).

## Validation

- `fvm flutter pub get`: `pubspec.lock` unchanged. `fvm flutter analyze`: no issues. `fvm flutter test`: 29/29 (13 new: home shell flows, small-screen layout smoke, controller chat/poke/toast, journal text derivation, base widget behavior).
- iOS Simulator (iPhone 13, `--dart-define=XUNA_SIMULATOR=true`, Flutter 3.32.8): debug build launched; the Nhà tab screenshot was inspected (fonts, tokens, room card, nav). Other tabs were exercised by widget tests only. No real phone, BLE board or Android run.
