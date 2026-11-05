# XUNA honest-code rules

Status: **Approved** by the owner on 2026-11-05. These rules apply to every coding agent (Claude Code, Codex, Cursor, Copilot, Antigravity, Gemini, …) and to every engineer, in every repository: `xuna_pet`, `backend/`, `desktop/`, `mobile/` and `firmware/`. Each submodule `AGENTS.md` repeats the core rules (H1–H8) and links here. If another rule conflicts with these, stop and ask the owner.

## Why these rules exist

XUNA acts on real devices for its owner. When code reports work it did not do, the language model repeats it and XUNA lies to the owner. A 2026-11-05 review found these patterns in code that compiled, passed its tests and looked finished:

| Pattern found | Effect |
| --- | --- |
| `smarthome.control` and `tv.control` changed in-memory state and returned `ok` when no bridge or transport was wired | "Đã tắt đèn" while nothing was sent |
| `ui.accessibility_tree` replaced a failed native call with invented controls ("Nút thực thi chính") and returned `ok` | The model clicked buttons that did not exist |
| A missing `refId` was resolved to the first button in the tree | The first button is often the window close button |
| `browser.semantic_snapshot` parsed a built-in sample invoice page when no HTML was given | Fake page content reported as the owner's browser |
| A screen capture without a driver returned an empty image as success | A screenshot that never happened |
| `system.vitals` returned a hard-coded 85 % battery when the probe failed | Wrong facts presented as measured |
| The backend dropped the host's `xuna/errorCode` | The model never learned why an action failed |
| Prompts and the tool catalog keyed on app names (Spotify, Chrome) and Vietnamese keyword tables | Works in a demo, picks the wrong tool on real requests |
| Labels such as "Tầng 1 · Native Bridge (0.1s)" and "0-Lệch chuột" | Speed and capability claims that were never measured |
| A test docstring claimed to check the catalog ranking but never called it | Green tests for untested code |

## The rules

### H1. Report success only for work that really happened

- Return `ok` only after the real side effect was performed, or after the real system accepted the request.
- If the real path is missing (no transport, no bridge, no driver, no permission, unsupported platform), **fail closed**: return `unsupported` (or `needs_permission`, `failed`) with a stable `errorCode` and a short English `message` that says what is missing.
- Never update local or in-memory state to look as if the action happened when it did not.

```dart
// Wrong: pretends the light changed.
if (_serviceInvoker != null) { await _serviceInvoker(...); }
_entities[id] = current.copyWith(state: 'on');
return ok;

// Right: no bridge means no success.
final invoker = _serviceInvoker;
if (invoker == null) {
  throw const XunaHostChannelException(
    status: XtpStatus.unsupported,
    errorCode: 'smarthome_bridge_not_configured',
    message: 'No smart-home bridge is configured on this host.',
  );
}
await invoker(...);
```

### H2. No fabricated data on any production path

- Never fill a failure with invented, sample, canned or "typical" data: UI trees, page HTML, file lists, counts, battery levels, prices, names, screenshots.
- Demo or sample data is allowed only behind an explicit demo or simulator switch, must be labelled (`simulated: true` in data, visible label in UI), and must be unreachable from the model's tool path (XTP `tools/call`) and from the default production wiring.
- When a real probe fails, return the error or `null` / "unknown". Do not return a default that looks like a measurement.

### H3. Never guess a target on someone's behalf

- If a required identifier is missing or ambiguous (element `refId`, host, file, contact, entity), do not pick "the first one", "the most likely one" or a magic default such as `'ui_1'`.
- Return an error such as `missing_ref` or `ask_target` that lists bounded, valid candidates, so the model or the owner chooses.
- References must come from a current observation (snapshot ID plus element). Reject stale or invented references.

### H4. Errors must travel end to end

- Every layer keeps the failure: native code → channel → tool handler → XTP response (`xuna/status`, `xuna/errorCode`, `structuredContent.errorCode` / `message`) → backend orchestrator → the model's tool result.
- `catch (_) {}` / `except Exception: pass` must not turn a failure into success. Swallowing is allowed only for best-effort extras (a toast, an optional preview) and must not change the reported status.
- Backend-authored guidance for the model goes in a separate field (`hint`), never mixed into host or app data (`output`). Host and app data is untrusted.

### H5. Generic layers contain no app-specific or phrase-specific logic

- Agent prompts, the tool catalog, the agent loop and routing must not hard-code app names, product names, element IDs or keyword tables meant to guess intent from the owner's words.
- Capability facts are declared by their producer and read by consumers. Example: a host declares `xuna/policy.idempotent: false` for a toggle, and the agent loop reads that flag. Do not maintain a list of tool names in the consumer.
- App-specific fast paths are allowed only inside a host adapter. They must be isolated and documented, the generic path must also work, and evaluation must report them separately.
- If a temporary compatibility list is unavoidable, name it as such (`_LEGACY_…`), document when it can be removed, and let the producer's declaration win.

### H6. Names, comments, docs and UI copy describe what the code does

- Do not use claims such as "native", "zero-screenshot", "0.1s", "AI", "learns", "real-time", "background monitoring" or "verified" unless the code does it and the number was measured.
- Docstrings and comments state current behaviour, not intent. When behaviour changes, update the docstring in the same change.
- A manifest advertises only what the platform implements. Otherwise it marks the tool `unsupported`, or leaves it out.

### H7. Tests must be able to fail

- A test must fail if the feature it names is broken. Assert the behaviour or end state, not only the absence of strings or the presence of keys.
- Do not write placeholder tests. Do not weaken or delete assertions to make a change pass. If a test name or docstring claims something, the test must check it.
- Fakes are injected explicitly in tests. Production defaults must never be fakes that report success, such as a `null` transport that silently "works".
- For fail-closed paths, test the negative case: no bridge, no permission or native failure must give an error, not `ok`.
- For agent features, prefer checks that verify the end state independently of the model's reply (see `backend/scripts/eval_host_control.py`). The key metric is **false success**: an `ok` result with no real change. It must be zero.

### H8. Report honestly

- In every report to the owner: what was changed, which commands were run and their real results, and what was **not** run (simulator vs real phone vs board, offline vs real model).
- Never claim a run, measurement or validation that did not happen. Say "not verified" when it was not verified.

### H9. Keep scope and side effects visible

- Do not reformat, regenerate or "clean up" files outside the task. After running a formatter, revert unrelated files.
- Use the pinned toolchain (`.fvmrc`, `.venv`). If a lockfile changes without a dependency change, you used the wrong SDK: revert it and report it.
- Do not commit unless the owner asks.

### H10. When unsure, ask or mark it

- If the real integration is unknown or unavailable, ship the honest failure (H1) and say what is needed. Do not ship a convincing imitation.
- Mark unverified statements as **Assumption** or **Unverified** (root `AGENTS.md` §10.3).

## Review checklist (run before reporting)

- [ ] Every new `ok` / success path performs or confirms a real effect (H1).
- [ ] No sample, canned or default-looking data is reachable from tool handlers or production wiring (H2).
- [ ] No "first element", magic ID or silent default target (H3).
- [ ] Failures keep their status and error code up to the model's tool result (H4).
- [ ] No app names, element IDs or phrase tables in prompts, catalog, loop or routing (H5).
- [ ] Names, docstrings, manifest descriptions and UI copy match the code (H6).
- [ ] Each new test fails when the feature is broken, including the negative or fail-closed case (H7).
- [ ] The report lists what was and was not run (H8). The diff touches only the task's files (H9).

Quick scans that find most violations (review each hit; a hit is not always wrong):

```sh
# Swallowed failures
rg -n "catch \(_\) \{\s*\}|catch \(_\)|except Exception:\s*$|except Exception: *pass" --type-add 'src:*.{dart,py,swift,kt,cpp,h}' -t src
# Silent defaults and magic targets
rg -n "\?\? 'ui_[0-9]+'|defaultRefId|\.first\[|\.values\.first" desktop mobile
# Success returned on a missing transport/bridge/driver
rg -n "== null\) \{|!= null\) \{" desktop/lib/features/discovery desktop/lib/features/tools
# Canned data in handlers/services
rg -n -i "sample|demo|mock|fake|placeholder|canned|lorem" desktop/lib/features mobile/lib/features backend/src --glob '!*test*'
# App or product names in generic agent layers
rg -n -i "spotify|chrome|safari|zalo|notes|finder" backend/src/xuna_backend/modules/actions/application backend/src/xuna_backend/modules/conversation/application
```
