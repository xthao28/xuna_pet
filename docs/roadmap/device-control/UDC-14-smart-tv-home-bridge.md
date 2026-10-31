# UDC-14 — Zero-Config Smart TV LAN Bridge (`tv.list_devices`, `tv.control`, `tv.launch_app`, `tv.cast_media`), Cross-Screen Cast (`cast_to_tv`) & Smart Home Room Scenes (`smarthome.list_entities`, `smarthome.control`, `cinema_mode`, `goodnight_mode`)

Status: **Implemented & Host-Verified (2026-10-31; [UDC-14-results-2026-10-31.md](UDC-14-results-2026-10-31.md)); live LAN Smart TV & Home Assistant hardware trial pending**. Complexity: **L (5 sessions: `S14.1` → `S14.5`)**. Repositories: `desktop/` (`xuna_xtp` + agent), `backend/`, `mobile/` (**0 bytes added to `firmware/`**).

---

## 1. Goal & Zero-Hardware-Cost Architecture

Extend XUNA's Universal Device Control beyond computers and phones to **Smart TVs (LG WebOS, Samsung Tizen, Sony Bravia / Android TV / Google TV / Chromecast, Roku)** and **Smart Home appliances (lights, AC, fans, blinds via Home Assistant Local API)** over the local Wi-Fi/LAN:

1. **Zero Extra Hardware & `0 B` Firmware Footprint:**
   - The ESP32-S3 board (`firmware/`) adds **0 bytes of RAM/Flash and 0% CPU**.
   - Instead of requiring extra IR blasters or custom dongles, `desktop/` (and `mobile/`) act as the **Local LAN Bridge**, discovering and controlling Smart TVs and Home Assistant appliances directly inside the home Wi-Fi network.
   - For BLE HID-capable Smart TVs (Android TV, Apple TV, LG/Samsung), `firmware/`'s existing 4-slot BLE HID (`UDC-1`/`UDC-2`) works out of the box alongside the new LAN Bridge.
2. **Zero Cloud Dependency for TV & Smart Home Payloads:**
   - All LAN discovery (`SSDP` / `mDNS`), TV WebSocket/HTTP commands, and Home Assistant local API calls happen on the local network (`desktop/` ↔ TV / Home Assistant).
   - `backend/` only routes compact, content-free XTP tool intents and orchestrates multi-device workflows (`cast_to_tv`, `cinema_mode`, `goodnight_mode`).

---

## 2. Gate

- `UDC-13` (`S13.1` → `S13.5`) is Implemented, verified, and committed (`0cc2f38`, [UDC-13-results-2026-10-31.md](UDC-13-results-2026-10-31.md)).
- Reference reuse policy: [ADR-0001](../../decisions/ADR-0001-reference-reuse-policy.md) (re-implement clean LAN discovery and control patterns inspired by permissive MIT/Apache-2.0 protocols: UPnP/SSDP `urn:dial-multiscreen-org:service:dial:1`, LG WebOS `SSAP` port `3000`/`3001`, Samsung Tizen remote WebSocket port `8001`/`8002`, Roku `ECP` port `8060`, and Home Assistant REST API `/api/services/<domain>/<service>`).

---

## 3. Scope / Out of Scope (`S14.1` → `S14.5`)

### In Scope
- **`S14.1` — Zero-Config Smart TV LAN Discovery (`AutoTvScanner` & `tv.list_devices`, `R1`):**
  - Automatically discovers Smart TVs on the local subnet via **SSDP (`M-SEARCH` UDP `239.255.255.250:1900`)** and known local TV endpoints (`LG WebOS :3000/:3001`, `Samsung Tizen :8001/:8002`, `Roku ECP :8060`, `Android TV / DIAL :8008`) plus optional user-saved TV entries (`~/.xuna/tv_devices.json`).
  - Exposes `tv.list_devices` (`R1`, `ToolFamily.media`, `observes: true`) returning `{devices: [{id, name, brand, protocol, online, supportsWakeOnLan}]}` (never exposing raw MACs or tokens to the cloud).
- **`S14.2` — Smart TV Remote & App/Input Control (`tv.control` `R1` & `tv.launch_app` `R2`):**
  - `tv.control` (`R1`, `ToolFamily.media`, `reversible: true`): executes deterministic remote actions on a discovered TV (`power_wake`, `power_off`, `play_pause`, `mute_toggle`, `volume_up`, `volume_down`, `volume_set`, `nav_up`, `nav_down`, `nav_left`, `nav_right`, `nav_select`, `nav_back`, `nav_home`, `input_hdmi1`, `input_hdmi2`, `input_hdmi3`).
    - When `action == "power_wake"`, automatically broadcasts a local **102-byte Wake-on-LAN Magic Packet** (`UDP :9`) to wake a sleeping LG/Samsung/Sony TV!
    - Records `volume_set`, `mute_toggle`, and `play_pause` in `ReversibleActionLedger` (`S13.5`) so `action.undo` works on TVs too.
  - `tv.launch_app` (`R2`, `ToolFamily.app`): launches an allowlisted TV app (`youtube`, `netflix`, `spotify`, `prime_video`, `disney_plus`, `apple_tv`, `plex`, `browser`) on the target TV after owner `R2` confirmation (phone or physical board `GPIO0`).
- **`S14.3` — Cross-Screen Media Cast (`tv.cast_media` `R2` & `cast_to_tv` Workflow):**
  - `tv.cast_media` (`R2`, `ToolFamily.url`): sends an `https://` media URL (e.g. YouTube watch URL / video ID or HLS stream) to the target TV via DIAL / WebOS / Tizen / Roku launch parameters.
  - `cast_to_tv` (`WorkflowTemplate.CAST_TO_TV`, `R2`):
    1. Reads the active browser tab URL on the PC via `browser.current_url` (`S9.1`) or uses the owner-provided URL.
    2. Requests **one** `R2` confirmation (`"{host} → {tvName} · Chiếu nội dung lên TV"` — can be approved with `GPIO0` on the XUNA board!).
    3. Pauses local playback on the PC (`media.play_pause`) and launches/casts the video on the TV (`tv.cast_media`).
- **`S14.4` — Smart Home Local Bridge (`AutoSmartHomeBridge`: `smarthome.list_entities` `R1` & `smarthome.control` `R2`):**
  - Connects to a local **Home Assistant** instance (`http://<ha-host>:8123/api`, configured via `~/.xuna/smarthome.json` or environment variables; token stays strictly on `desktop/`, never sent to `backend/`).
  - Strictly allowlists safe appliance domains: `light`, `switch`, `fan`, `climate` (air conditioner), `cover` (curtains/blinds), `media_player`, and `scene`.
  - **Hard-denies** physical security domains (`lock`, `alarm_control_panel`, `garage_door`, `camera`) so a voice prompt or model hallucination can **never** unlock doors or disarm alarms!
  - Records reversible appliance state changes in `ReversibleActionLedger` (`action.undo` turns a light/switch back or restores previous AC temperature).
- **`S14.5` — Multi-Device Room Workflows (`cinema_mode` & `goodnight_mode`) & Mobile Presets:**
  - `cinema_mode` (`WorkflowTemplate.CINEMA_MODE`, `R2`):
    - Wakes/turns on the TV + launches the requested streaming app (`netflix` / `youtube`), dims/sets room lights (`smarthome.control` if available), and pauses music on the PC (`media.play_pause`) — all under **one** `R2` approval.
  - `goodnight_mode` (`WorkflowTemplate.GOODNIGHT_MODE`, `R1`):
    - Checks uncommitted Git work (`workspace.git_summary`), pauses media (`media.play_pause`), turns off the TV (`tv.control(power_off)`), turns off room lights (`smarthome.control` if available), and locks the PC screen (`host.lock_screen`).
  - `mobile/`: Adds `SmartTvDeviceSummary`, `BoardWorkflowSlotConfig.smartHomePresets` (`cinema_mode`, `goodnight_mode`, `cast_to_tv`), and TV/Smart-Home state tracking in `HomeActionsService`.

### Out of Scope
- Physical doors/locks/alarms/cameras (`lock`, `alarm_control_panel`, `camera` are permanently hard-denied).
- Any hardware modification or RAM/Flash increase on `firmware/`.

---

## 4. Security & Privacy Invariants

1. **Physical Security Lockout (`UDC-T36`):** `smarthome.control` hard-denies `lock.*`, `alarm_control_panel.*`, `camera.*`, and `garage.*` at both `xuna_xtp` policy evaluation and `HostToolDispatcher` execution (`errorCode: "denied"`).
2. **Local-Only Credentials:** Home Assistant tokens and TV pairing keys (`client-key`) remain exclusively on the local host (`desktop/`) and are never included in XTP outputs, manifests, or logs.
3. **HTTPS-Only Media Cast:** `tv.cast_media` enforces `isAllowedHttpsCurrentUrl` (rejecting `file://`, `http://`, and private/loopback IPs).
4. **Content-Free Audit Logs:** Logs record only `{tool, brand, action, domain, status}` — never media URLs, video titles, or room names.

---

## 5. Verification Plan

1. **`firmware/`:** `0 B` RAM/Flash change (`git -C firmware status` clean).
2. **`desktop/packages/xuna_xtp` & `desktop/`:**
   - `fvm dart analyze` & `fvm dart test` PASS (verifying `tv.*` & `smarthome.*` schemas, policy rules, and hard-denylist on `lock`/`alarm_control_panel`/`camera`).
   - `fvm flutter analyze --no-pub` & `fvm flutter test --no-pub` PASS (verifying `AutoTvScanner`, `tv.control` + WoL wake + undo, `tv.launch_app`, `tv.cast_media`, `AutoSmartHomeBridge` allowlist/denylist, and `ReversibleActionLedger` integration).
3. **`backend/`:**
   - `ruff check src tests`, `mypy src`, and `pytest` PASS (`test_udc14_smart_tv_home.py` covering `cast_to_tv`, `cinema_mode`, and `goodnight_mode`).
4. **`mobile/`:**
   - `fvm dart format`, `fvm flutter analyze --no-pub`, and `fvm flutter test --no-pub test/features/actions/actions_test.dart` PASS.

