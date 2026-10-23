# S26 explanation codec - 2026-10-16

Status: host preparation done; production wiring blocked by S13/S18.

Owner approved S25 starting defaults `w_s=0.5`, cap 2. Added a pure C++11 20-byte explanation projection for the shown action: version, size, interaction, day part, action, reason, fine flag, saturated rated count, then p/nEff/positive/negative/stated-positive/stated-negative as little-endian Q8.8/u16 fields.

The payload contains evidence only and no prose. Rated and stated mass stay separate. Invalid explanations are not encoded.

Validation: golden layout test PASS (test_stated_preference 16/16); ESP32 build PASS at unchanged RAM 48,976 B and Flash 1,347,853 B; purity and whitespace PASS.

Production opcode 6/capability/explanation characteristic are not enabled on the current BoardLearner/v1 snapshot path. That path cannot durably represent 3x5x3 stated evidence. Wiring waits for S13/S18 ProductLearner + LifeSnapshot v2 integration; no board operation occurred.
