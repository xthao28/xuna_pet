# Speech subtitles on the board — 2026-10-27

Status: **Implemented** (firmware, mobile; host tests and ESP32 build). **Not validated** on the board or a phone.

## Owner decisions (2026-10-27)

- Request: "board hiển thị chữ của xuna nói", Vietnamese and English.
- Style: **subtitle bubble** above XUNA, the pet stays visible (not a full-screen card, not a ticker).
- Content: **XUNA's replies only** (cloud AI and local templates). The owner's own words are never sent to the board.

## Behaviour

- Spoken reply: each sentence shows when the phone starts playing it (`VoiceRepository.playbackStarts`), so the subtitle follows the voice.
- Unspoken reply (text chat, TTS off or unavailable): the whole reply shows once it finished, on both the HTTP and the WebSocket path.
- Local template replies (`_say`) show at once.
- The board wraps the text to 210 px with the 14 px Be Vietnam Pro font, shows three lines per page, keeps each page about 60 ms per character (2–8 s), holds the last page 3 s more, then hides. A new text replaces the old one.
- The bubble sits right of the window and above the pet canvas (x 90–317, y 2–70). The reaction effect above XUNA's head is hidden while it shows. A card (status, pairing) covers it, and it comes back if it has not timed out. The backlight stays full while it shows.
- Display only: the firmware keeps the text in RAM until replaced and logs only its result code and byte count. It never reaches the snapshot, life, learning, personality or the adapter. The app does not log or store it either.

## Protocol (additive)

- Capability byte 3 bit 5 (`0x3f` with the existing bits). Older apps ignore it; with older firmware the app sends nothing.
- Characteristic `7a6e0010-8c44-4db6-9f61-2b7d5300a101`, write with response.
- Frame: `[0]` version 1, `[1]` text id (u8, wraps), `[2]` chunk index, `[3]` chunk count (1–64), `[4..]` UTF-8 bytes. A frame is at most ATT MTU − 3 bytes (≤ 244); the app uses the connection's current MTU (20-byte payloads by default on Android).
- Chunks of one text arrive in order and may split a code point. Index 0 starts a new text and drops an unfinished one; a wrong id, count or index drops the text. At most 600 bytes per text: the app cuts longer text after the last whole word and adds "…".
- One empty chunk (`[1, id, 0, 1]`) clears the bubble.
- The firmware turns control bytes into spaces, collapses runs of spaces and trims the ends.

## Font

`tools/generate_ui_font.py` now gives `kFontValue` (14 px) every Vietnamese letter (12 vowels × 6 tones, both cases, đ/Đ) and `‘ ’ “ ” … – — · • ° « »`: 241 glyphs instead of 134. Title and label fonts are unchanged. Regenerated on Windows with Pillow 13.0.0: existing bitmaps are identical; two advances differ by 1 px from the Mac run (`-` in the value font, `h` in the label font).

Text in decomposed Unicode (NFD) would show its combining marks as gaps; replies from the providers in use are precomposed, but this is not measured.

## Files

- Firmware: `lib/xuna_core/include/xuna/visual/SpeechBubble.h` (assembler, wrap, paging, rendering), `include/BleManager.h`, `include/DisplayManager.h`, `src/DisplayManager.cpp`, `src/main.cpp`, `tools/generate_ui_font.py`, `src/assets/XunaUiFont.cpp`, `test/test_speech_bubble`.
- Mobile: `SpeechTextCodec`, `DeviceBleDataSource.writeSpeechFrame`/`maxWriteLength`, `DeviceRepository.showSpeech` (texts are written one after another, never interleaved), `ShowSpeechTextUseCase`, `VoiceRepository.playbackStarts`, `WatchPlaybackStartsUseCase`, `HomeController._showOnBoard`.

## Not yet checked

- On the board: readability of the 14 px text, bubble placement against the real scene, draw time of a page, effect/bubble transitions, a card opening over a bubble.
- On a phone: write timing with 20-byte payloads (a 600-byte text is 38 writes with response), sync with the voice, iOS MTU.
