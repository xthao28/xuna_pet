# XUNA learning upgrade — competitive review and plan

Status: owner request 2026-10-15. **Decisions L-D1–L-D5 approved 2026-10-15** (AGENTS.md §3; L-D5 = research on touch, IMU and microphone only). Algorithms, thresholds, budgets and phase contents remain Proposed until Life Lab evidence.
It amends, and does not replace, [implementation plan §9–§10](XUNA_IMPLEMENTATION_PLAN.md)
and the [learning roadmap L1–L5](../roadmap/learning/LEARNING-ENGINE-UPGRADE.md).
Owner allowed revising the plan where needed; the amendments are already in the
implementation plan as [P] items: §9.4 Alternative D, two new §9.9 scenarios,
§9.10 teachable tricks and decisions L-D1–L-D5 in §18.
AGENTS.md remains canonical; open decisions stay open until the owner decides.

## 1. Goal

Make XUNA's learning **noticeable to the owner within days**, **better than
competitors where it matters**, and still **local-first, bounded and
explainable**. Competitors mostly sell "it develops a personality"; few can
show *why*. XUNA's edge should be learning that is both felt and verifiable.

## 2. What competitors do (public claims, mostly marketing)

| Product | What "learning" means publicly | Inputs | Where it runs | XUNA takeaway |
|---|---|---|---|---|
| Casio Moflin | Personality forms over ~50 days; mood suffers when ignored; learns what the owner likes from petting/cuddling | Touch, sound, motion sensors | On device; app sync optional | A visible **formation arc** and **touch** drive attachment |
| GROOVE X LOVOT | Attachment to people who treat it well; avoids those who mistreat it | ~50 sensors, camera, mic, touch | On-device deep learning (vendor claim) | **Per-person valence** and avoidance are compelling |
| Sony aibo ERS-1000 | Learns faces, remembers what pleases the owner, owner can **teach tricks** with praise; personality "clingy or wild" | Camera, mic, touch | Cloud plan required for growth features | **Teachable tricks** with reward are a proven hook; XUNA can do it offline |
| KEYi Loona | ChatGPT conversation, face/voice recognition of family | Camera, ToF, mic | Cloud LLM | Conversation quality is cloud-bound; XUNA should not compete on open chat |
| Living.ai Emo | "Personality evolves"; learns favourite music/games | Camera, mic, NPU | Partly cloud; users question how much it learns | Unverifiable claims are a weakness XUNA can exploit |
| Anki Vector | Emotion engine pushed by sensor events; investigates novel objects | Camera, mic array, ToF | On device + cloud voice | Novelty-driven curiosity reads as "alive" |

Hardware gap: every competitor learns from **touch and/or voice**. XUNA today
has two buttons and the phone (BLE). This limits richness more than any
algorithm does (see §6.1).

## 3. Algorithms reviewed and fit for XUNA

Constraints applied (AGENTS.md, plan §5.6, §9.3, §17.1): C++11, no heap,
Q16.16 fixed point and bit-exact host/target replay, ≤16 KB core RAM, learner
section ≤800 B, ≤1 urgent commit per explicit action, silence is never
negative, explanations only from evidence fields, no on-device neural nets or
LLM, no claims beyond what is measured.

| Source | Technique | Fit | Use in XUNA |
|---|---|---|---|
| Contextual bandits (Vowpal Wabbit; discounted/sliding-window Thompson sampling literature) | Per-context action values; discounting for drifting preferences | **High**; already plan §9.3 | Keep discounted Beta + hierarchical prior. Add drift scenarios to E10. Thompson stays Life Lab–only (float sampling breaks parity) |
| Oudeyer IAC (Sony CSL, AIBO playground) | Intrinsic motivation = choose where **learning progress** (drop in prediction error) is highest; avoid the unlearnable | **High**; integer-friendly using existing prequential Brier | New exploration variant **D**: exploration budget per context from learning progress, not only stage ε. Gives an honest "curious because still learning" signal |
| Creatures (Grand), The Sims | Drives/needs; behaviour learned by **drive reduction** | Medium | Learn which activity restores which need (device-observed evidence, own provenance), kept separate from owner preference |
| Black & White (Evans) | BDI desires weighted by perceptrons trained by reward/punishment | Medium–high in reduced form | **Teachable tricks**: bounded linear cue→action association (delta rule / Rescorla–Wagner) trained only by explicit reward |
| FSRS (open-spaced-repetition) | Memory stability/retrievability; spaced reinforcement increases stability | Medium | Trick and fact **retention**: practice raises stability; unused tricks fade slowly and can be refreshed. Integer table, not floats |
| Generative Agents (Park et al. 2023) | Memory stream ranked by recency × importance × relevance; periodic reflection | Medium without LLM | Integer salience score for episodic retrieval and **consolidation** of episodes into patterns with evidence IDs (plan §10); LLM, if ever, only words it on the phone |
| TinyOL, MCUNetV3 (on-device training) | Train last layer or sparse layers on MCU | **Low now** | Out of scope (no sensors, plan forbids on-device NN). Revisit only with a mic/IMU and an approved decision |
| Espressif ESP-SR (WakeNet/MultiNet) | Offline wake word + up to 200 commands on ESP32-S3 | Conditional | If the voice workstream adds a mic, spoken commands become **cues** for trick learning without cloud |

Rejected for now: deep RL, on-device neural networks, cloud learning,
LLM-driven traits (all conflict with approved constraints or the evidence rule).

## 4. Gaps in the current plan

1. **Too few actions.** The learner chooses between idle/happy only. With two
   actions, learning is hard to see. Needs D5 (3–4+ actions, button greeting
   as a context).
2. **No teaching.** The owner can rate but cannot *teach*. Trick teaching is
   the clearest "it learned from me" moment (aibo, B&W).
3. **Exploration is gameplay, not cognition.** Stage-scaled ε is labeled
   gameplay (D4). Learning-progress curiosity would be genuine and explainable.
4. **No visible formation arc early.** Personality traits wait for M06; the
   owner sees no "becoming" story in the first weeks.
5. **No closed-loop evaluation yet.** Today's runners are open-loop with a
   64-event cap ([lab runs](../roadmap/learning/lifecore-lab-runs-2026-10-15.md)).
   Every claim below depends on the planned Life Lab (M04.6/S19a) with the §9.9
   oracle owner.
6. **Input poverty** (hardware), see §2.

## 5. Upgrade plan

Each phase keeps D1 (finish M04 first) and the existing session gates. New
items are marked **NEW**; the rest re-prioritizes planned work.

### Phase 0 — Measurement first (M04.6, S19a scope)
- Closed-loop Life Lab: simulated owner zoo from §9.9 (oracle, reversal, no
  feedback, isolation) **plus NEW** gradual drift, noisy owner, sparse owner,
  "teacher" owner (for Phase 3).
- Time-series output (activity, needs, mood, decisions) and long generated
  runs instead of the 64-event cap.
- Parity fix before LifeCore replaces BLE: plan §9.5 already specifies the
  production model (commit first, ACK `not_ready` and RAM unchanged on failure,
  retry allowed). `LifeCore` must be brought in line; no new decision needed.
- Exit: §9.9 scenarios B/C/D run with 200 seeds and bootstrap CIs.

### Phase 1 — Preference learner v3 (M05a, S23–S26; L1→L2)
- Implement plan §9.3 exactly (discounted Beta γ, hierarchical day-part prior)
  in place of v2's undiscounted UCB cells.
- E10 compares ε-greedy (A), UCB (C) and **NEW** learning-progress curiosity
  (D). Rule stays "simplest within 5% regret"; D wins only if it also improves
  drift recovery or visible behaviour.
- Persistence v2 + migration of the 96-byte snapshot (L2), then production
  switch after shadow evidence and owner acceptance.
- Needs D3, D4, D5.

### Phase 2 — Routines and anticipation (M05d habit, after S10 trusted time)
- Plan §9.7 habit predictor (48 decayed slots, prequential gate).
- Visible use: anticipation pose near the owner's usual time; never guilt.
- Skill `predictInteractionWindow` journaled with evidence.

### Phase 3 — Teachable tricks (NEW capability, proposed C-level)
- Teach mode: the owner gives a **cue** (button pattern, app command, later a
  spoken command), XUNA tries an action, the owner rewards or not.
- Model: bounded table `w[cue][action]` in Q16.16, delta-rule update toward the
  reward, learning rate decays with evidence; masked by the same ActionGate.
- Retention: per-trick stability (FSRS-inspired integer table); practice raises
  it; disuse lowers *readiness* slowly, never deletes evidence.
- Skill `learnedTrick` acquired only when cue→action accuracy ≥ threshold over
  the last N trials (thresholds Proposed, set by Life Lab).
- Budget target: ≤8 cues × ≤8 actions × 4 B ≈ 256 B + stability bytes.

### Phase 4 — Formation arc, memory and self-knowledge (M05b; part of M06)
- Episodic salience = recency × importance × context match (integers);
  consolidation of episodes into patterns with evidence IDs (plan §10).
- **NEW** drive-reduction learning: which activities restore energy or
  stimulation, labeled `device_observed`, never mixed with owner ratings.
- Formation arc: a journal timeline of first skills, first preferences and
  learned tricks during the first weeks, built only from evidence. Whether
  this moves ahead of Evolution depends on D15.

### Phase 5 — Conversation as a learning sensor (M05c, D17)
- Layer A stated preferences (capped `w_s`), stated vs rated separated in
  explanations. Optional phone LLM only for wording (D11/D11a). No change to
  the device learning rules.

### Phase 6 — Richer senses (hardware R&D, gated)
- Capacitive touch pads (ESP32-S3 touch GPIOs) for petting; IMU for pick-up or
  shake; mic + ESP-SR for offline commands (VOICE-01–04).
- Each sense enters as a new cue or context with its own provenance. Implicit
  feedback stays off unless D6 changes.
- Free pins and wiring must be checked against the T-Display-S3 pinout before
  any purchase; nothing is wired without owner approval.

### Online layer (hybrid, added 2026-10-15)

The owner asked to combine offline and online learning. The offline phases
above stay complete on their own; each gains an optional online add-on under
the contract in [plan §22](XUNA_IMPLEMENTATION_PLAN.md) and
[ADR-0007](../decisions/ADR-0007-hybrid-offline-online-learning.md).

| Offline phase | Online add-on | What it improves |
|---|---|---|
| 0 Life Lab | E15: does cloud consolidation beat on-device defaults? | Decides whether O1 is worth building |
| 1 Preference v3 | O1: per-owner tuning of γ/ε/curiosity from history; O2: population priors | Faster first days, better drift handling |
| 2 Habits | O1: long-horizon drift detection over weeks | Routine changes noticed sooner |
| 3 Tricks | O2: trick/action content packs | New things to teach without firmware updates |
| 4 Memory, formation arc | O4: encrypted backup, restore to a new board | The pet survives hardware loss |
| 5 Conversation | O3: LLM wording and candidate extraction into the confirm flow | Natural chat while the device keeps authority |
| 6 Senses | O6: STT/vision offload | Richer perception |

All online data is opt-in by class (U0 by default). Suggestions only change
priors/parameters, never owner evidence. If the service ends, the pet keeps
everything and stays fully offline. Transport: phone gateway first, device
MQTT/TLS after E14.

## 6. Decisions needed

| ID | Question | Recommendation |
|---|---|---|
| L-D1 | Adopt this plan as a Proposed amendment to plan §9–§10 | Yes |
| L-D2 | Add learning-progress curiosity (variant D) to E10 | Yes; costs only Life Lab time |
| L-D3 | Add teachable tricks (Phase 3) as a new capability | Yes; strongest competitive hook that stays offline |
| L-D4 | Allow drive-reduction learning as device-observed evidence | Yes, labeled and separate from owner preference |
| L-D5 | Start a hardware R&D track for touch first (cheapest, highest impact) | Yes, research only |
| D5 | Expand contexts/actions to 3–4+ | Needed before Phase 1 is meaningful |
| D15 | Cognition first vs Evolution MVP first | Cognition first if the formation arc is wanted early |
| D21–D24 | Hybrid contract, transport/broker, data/consent/legal, online business model | See plan §18 and §22 |

## 7. Success measures (to confirm with Life Lab data; no targets claimed yet)

- Preference: beats random/static baselines with non-overlapping CIs (§9.9 B);
  recovers after reversal within O(1/(1−γ)) ratings (C); bit-identical cells
  with no feedback (D).
- Tricks: trials to learn a new cue→action; retention after N idle days.
- Curiosity: exploration falls in learned contexts and stays in unlearned ones.
- Owner-facing: every learned behaviour has an evidence-backed explanation.

## Sources

- Moflin: [Casio product page](https://www.casio.com/us/moflin/product.PE-M10GD/), [Fast Company review](https://www.fastcompany.com/91431412/casio-moflin-ai-pet-review), [Domus](https://domusweb.it/en/news/2024/10/15/moflin-casio-ai-pet-adapts-to-its-owner.html)
- LOVOT: [Quartz](https://qz.com/1502648/lovot-is-a-cuddly-japanese-robot-that-aims-to-change-your-feels), [Tom's Guide](https://www.tomsguide.com/us/lovot-robot-price-features,news-28892.html)
- aibo: [Sony help guide](https://helpguide.sony.net/aibo/ers1000/v1/en/contents/TP0001970093.html), [Sony press release](https://sony.mediaroom.com/2024-02-15-Sony-Electronics-Launches-Limited-aibo-Espresso-Edition-in-the-US)
- Loona: [Airmore review](https://airmore.ai/ai-review/loona-robot-review); Emo: [Hackster](https://hackster.io/news/living-ai-s-emo-pet-uses-1-2-tops-of-neural-compute-performance-to-liven-up-your-desk-cc42a5372c04), [Living.ai forum](https://forums.living.ai/t/how-ai-is-emo/3900)
- Vector: [eeNews Europe](https://www.eenewseurope.com/en/ai-based-robots-and-emotional-intelligence-video)
- Creatures: [Sussex report](https://www.sussex.ac.uk/informatics/cogslib/reports/csrp/csrp434.pdf), [Alan Zucconi](https://www.alanzucconi.com/2020/07/27/the-ai-of-creatures/)
- Black & White: [Richard Evans](https://en.wikipedia.org/wiki/Richard_Evans_(AI_researcher)), [Northwestern AIIDE paper](https://www.qrg.northwestern.edu/Resources/aigames.org/papers2002/DIsla02.pdf)
- IAC: [Oudeyer et al.](https://www.cs.swarthmore.edu/~meeden/DevelopmentalRobotics/oudeyer.pdf), [cogprints 4144](https://web-archive.southampton.ac.uk/cogprints.org/4144/index.html)
- Bandits: [Vowpal Wabbit CB tutorial](https://vowpalwabbit.org/docs/vowpal_wabbit/python/9.1.0/tutorials/python_Contextual_bandits_and_Vowpal_Wabbit.html), [JMLR bandit bake-off](https://jmlr2020.csail.mit.edu/papers/volume22/18-863/18-863.pdf), [Discounted TS](https://alphaxiv.org/abs/1707.09727), [TS for non-stationary bandits](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11765042/)
- Memory: [Generative Agents](https://arxiv.org/pdf/2304.03442v1), [FSRS in 100 lines](https://borretti.me/article/implementing-fsrs-in-100-lines)
- On-device ML: [TinyOL](https://arxiv.org/pdf/2103.08295), [On-Device Training Under 256KB](https://hanlab.mit.edu/projects/mcunetv3), [ESP-SR](https://components.espressif.com/components/espressif/esp-sr/versions/2.6.0/readme)
