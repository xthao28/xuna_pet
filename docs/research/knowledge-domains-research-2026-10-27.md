# Knowledge domains — research (2026-10-27)

Question (owner): the knowledge plan's fixed domain list "không nên cố định". How do comparable open-source projects create topics, and how do they show depth? Sources were checked on 2026-10-27; claims marked *unverified* could not be confirmed.

## 1. Companion, pet and assistant projects

| Project | Topic model | Retrieval | User control | Limits | License |
|---|---|---|---|---|---|
| [xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server) `mem_local_short` | Fixed JSON schema, no domains; an LLM rewrites a "frequent topics" (高频话题) list | Whole summary every turn | None found | Prunes at 900 characters | MIT |
| [SillyTavern World Info](https://docs.sillytavern.app/usage/core-concepts/worldinfo/) | **User-authored** entries (keys + content) | Keyword/regex scan of recent messages, optional embeddings; *inclusion groups* stop overlapping entries all firing | Full editing | Token budget filled by priority | AGPL-3.0 (ideas only) |
| [KoboldAI World Info](https://github-wiki-see.page/m/KoboldAI/KoboldAI-Client/wiki/Memory,-Author's-Note-and-World-Info) | User-authored keyword entries | Key appears in text | Manual | ~50–150 tokens per entry (guidance) | AGPL-3.0 |
| [kimjammer/Neuro](https://github.com/kimjammer/Neuro) | Emergent reflections (Generative Agents style), no topics | ChromaDB similarity | Delete, import/export | None stated | MIT |
| [Open-LLM-VTuber](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber), [AIRI](https://github.com/moeru-ai/airi), [Amica](https://github.com/semperai/amica), [wire-pod](https://github.com/kercre123/wire-pod), ESP32 Tamagotchi clones | No topic structure (chat logs, rolling history; AIRI memory is WIP) | — | — | wire-pod: last 16 lines | MIT / various |
| [openmoxie](https://github.com/jbeghtol/openmoxie) | Fixed curriculum modules, not memory | — | Schedule/exclude modules | — | MIT |

**No surveyed project shows a per-topic knowledge level.** XUNA would be designing that metric.

## 2. LLM memory libraries

| Library | How topics are created | Retrieval | License |
|---|---|---|---|
| [mem0](https://github.com/mem0ai/mem0) | 15 default categories, replaceable by `{name: description}`; an LLM tags each memory; old memories are not re-tagged (documented for the hosted platform, OSS *unverified*) | Semantic + BM25 + entity, fused | Apache-2.0 |
| [Letta / MemGPT](https://docs.letta.com/guides/agents/memory-blocks) | Developer-defined labelled blocks, each with a description and a character limit | Blocks always in context; archival search with tags | Apache-2.0 |
| [Graphiti (Zep)](https://github.com/getzep/graphiti) | Custom entity types or emergent; **communities** by label propagation, incremental or rebuilt; contradicted facts invalidated, not deleted | Semantic + BM25 + graph | Apache-2.0 |
| [Cognee](https://github.com/topoteretes/cognee) | Auto-extracted graph + user tags (NodeSets) at ingest | Graph + vector | Apache-2.0 |
| [A-MEM](https://github.com/agiresearch/A-mem), [GraphRAG](https://github.com/microsoft/graphrag) | Fully emergent (LLM tags / Leiden communities); GraphRAG warns indexing is expensive | Semantic / community summaries | MIT |
| [BERTopic](https://maartengr.github.io/BERTopic/) | **Hybrid by design.** Zero-shot: match a text to a named topic above `zeroshot_min_similarity`, cluster the rest into new topics; `merge_models` adds a topic only below `min_similarity` 0.7 | Not retrieval | MIT (*unverified*) |

## 3. Findings that matter for XUNA

1. **User-authored topics earn the most trust** (SillyTavern, Kobold: years of use, every entry owned by the user). **Fully emergent topics have no precedent** in companion projects and tend to churn (xiaozhi's rewritten topic list).
2. **The working hybrid** is BERTopic zero-shot: named topics first, leftovers clustered, and a new topic is *proposed* only when leftovers form a group. This maps onto XUNA's candidate → owner confirms → device commits flow.
3. **A topic needs a description,** not only a name (mem0, Letta): the description is what makes tagging and retrieval work.
4. **Merge rather than multiply:** check similarity with existing topics before proposing a new one; owner-confirmed merges keep history (Graphiti).
5. **Hard caps everywhere** (Letta block limits, xiaozhi 900 chars, wire-pod 16 lines, SillyTavern token budget). Suggested: 5–8 active domains, at most one pending suggestion, propose only after 3–5 unsorted confirmed facts.
6. **Per message only cheap work:** one embedding of the turn, cosine against <10 domain vectors, top-k facts in the matched domain. Clustering and summaries run in the background.
7. **Prompt budget in tiers:** 1–2 identity facts, a domain summary built only from confirmed facts, then the top facts of the active domain, so one well-taught domain does not crowd out the others.
8. **Dedup at confirmation:** show the owner whether a candidate is new, refines an existing fact, or contradicts one (mem0 paper-era ADD/UPDATE/DELETE/NOOP; its newer ADD-only mode admits duplicates).
9. **Honest depth = auditable counts:** confirmed facts per domain and distinct teaching days, shown as tiers with the evidence one tap away. Not BKT-style "87 % mastery" (needs graded attempts and fitted parameters XUNA does not have). FSRS-style freshness is possible inspiration, but a falling level would penalize downtime (AGENTS §6).
10. **Device storage:** the surveyed devices keep no knowledge locally. XUNA's device can hold a small slot id, a bounded name, and counters; the board font cannot render every Vietnamese name, so the board shows pips or a short label.
11. **Licenses:** SillyTavern and Kobold are AGPL-3.0 — borrow ideas, not code. Others are MIT or Apache-2.0.
