# ADR-0021 — Declarative Capability Adapter Engine, Verified Skills & Manifest Foundry

Date: 2026-11-26. **Status: Approved (owner-delegated 2026-11-26: D7=Manifests Only, D9=No Hub/Marketplace, D10=Declarative Manifest + Generic Engine).** Extends [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md) and [ADR-0019](ADR-0019-draft-workspace-and-effect-bound-approval.md); builds on upgrade plan P1.1 (`expectFiles` / `artifacts`), P1.2 (`toolchains` + `remediation`) and P2 (`DraftWorkspace`).

## Context

- Hardcoding dedicated per-app tools (e.g., `doc.convert` invoking a specific office binary) violates **Rule H5** (hardcoding specific apps into generic engine/backend/prompt layers), wastes finite LLM catalog slots (`MAX_CATALOG_TOOLS = 36`), and gives no safe uniform target for automated headless workflow discovery.
- Third-party plugin/skill hubs (e.g., CLI-Hub / ClawHub precedent) introduce unverified arbitrary code execution and supply-chain risks.
- Existing synthesized skills (`OmniForgeService` / `SKILL.md`) previously defaulted non-script skills to `selfTestPassed: true` without running a real verification test, violating **Rule H1**.

## Decision (Owner-Delegated 2026-11-26: D7, D9, D10)

### 1. Declarative Capability Adapters & Generic Engine (`P4.1` — D9, D10)

- **Zero marketplaces / zero per-app engine code:** No CLI-Hub or remote plugin downloads. Adapters are local **declarative JSON manifests** (pure data files, not executable code). Neither the capability engine, backend generic layers, nor LLM prompts contain hardcoded application or CLI names (**Rule H5**).
- **Two fixed XTP tool slots:** Instead of adding a new XTP tool per external capability, hosts advertise only two generic tools (`XUNA_XTP_V1_CONTRACT.md` §8 rule 8):
  - `capability.list` (`ToolFamily.host`, `R1`, `observes: true`): returns only approved manifests whose target binary passed live detection and SHA-256 provenance verification on this host. Missing binaries or tampered manifests/binaries are omitted fail-closed.
  - `capability.run` (`ToolFamily.exec`, `R2` floor, mandatory host `xuna/preflight`): gated by local-only `shellControl.enabled`, validates `inputsJson` against the manifest's strict `inputs` schema, checks every path input through `FsPathGuard`, computes effective risk as `max(manifest.risk, ExecCommandClassifier(argv))`, and executes the binary **directly without a shell** (`runInShell: false`, scrubbed environment, timeout, E-Stop cancellation).
- **Fail-closed manifest invariants (`CapabilityManifest` in `xuna_xtp`):**
  - Strictly forbids shell/script-host executables (`cmd`, `cmd.exe`, `powershell`, `pwsh`, `bash`, `sh`, `zsh`, `fish`, `osascript`, `wscript`, `cscript`, `mshta`), inline evaluation flags (`-c`, `-e`, `--eval`, `/c`, `-EncodedCommand`), shell metacharacters (`&`, `|`, `;`, `<`, `>`, `` ` ``, `$()`, `\n`, `\r`, `\0`) in template tokens, and untyped or undeclared `{placeholder}` substitutions.
  - Output postconditions (`verifyFiles`) reuse P1.1 (`verifyExpectedFiles`: `minBytes`, `magic`, `sha256`). Exit code `0` with missing or mismatched outputs fails closed (`expected_output_missing` / `expected_output_mismatch`, Rule H1).
  - Provenance records `kind` (`seed` | `foundry`), `approved` (`bool`), `manifestSha256`, and optional pinned `binarySha256`. Any modification to manifest contents or pinned binary hash invalidates execution until re-approved.
  - Missing binary returns `toolchain_missing` with display-only `remediation` declared inside the manifest's own `detect` section (reusing P1.2 / U4).

### 2. First Seed Adapter = Pure Data File (`P4.2` / U7)

- Shipped as a standalone JSON manifest (`desktop/assets/capabilities/seed_document_convert.json`) with zero app references in `capability_engine.dart` or backend code. Deleting the JSON file removes the capability from `capability.list`. Replaces the LibreOffice CLI-Anything spike (D9).

### 3. Verified Skills (`P4.3` / U6)

- `ForgedSkillEntry` carries explicit `verificationStatus: "draft" | "verified"`.
- Pipeline-only skills and imported `SKILL.md` entries start as `"draft"` (`selfTestPassed: false`).
- `SandboxedToolRunner` marks simulated widget-test stubs explicitly (`simulated: true`). A skill transitions to `"verified"` **only** after a real non-simulated `SandboxedToolRunner` self-test succeeds (`exitCode == 0 && !simulated`). Unverified `"draft"` skills are never exposed as dynamic `forge.custom_*` XTP descriptors.

### 4. Manifest Foundry (`P4.4` / F2 — D7)

- `CapabilityFoundryService` synthesizes **declarative `CapabilityManifest` data only** (never arbitrary scripts, COM, or AppleScript code).
- Every foundry candidate starts `provenance.kind = foundry`, `approved = false`, passes strict `CapabilityManifest` validation, and must pass a real golden verification run inside an isolated `W4-M3` `DraftWorkspace` (leaving the real workspace byte-identical).
- Promotion into `AgentPaths.capabilitiesDir` fails closed unless **both** draft verification succeeded **and** explicit owner approval is supplied, pinning both `manifestSha256` and live `binarySha256`.

## Honest Limitations (Rule H6 / H8)

1. Manifests execute non-shell binaries as the non-elevated user (`desktop/AGENTS.md` §3.7); OS-level network sandboxing is not claimed.
2. Live macOS and real headless office binary conversion tests require a host with those binaries installed and remain tracked separately in `UDC-16` (Rule H8).

## Consequences

- `XUNA_XTP_V1_CONTRACT.md` §8 rule 8 and shared fixtures (`exec_fs_frames.json` in `backend/` and `xuna_xtp`) add `capability.list` and `capability.run` (byte-identical, `diff -r` exit `0`).
- Zero new third-party packages; `desktop/AGENTS.md` §3.6 (zero paths/contents in logs/audit) and backend Rule H5 invariants remain intact.
