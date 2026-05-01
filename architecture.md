# Thinking Council — Architecture

## What this is

A skill registered with Hermes that, on demand, spawns a multi-model deliberation panel to produce a peer-vetted answer to a high-stakes prompt. Hermes is the runtime — it does not think. It spawns sub-agents, routes data between them, and persists the session. The thinking happens in the sub-agents' model calls.

## Why this exists

Single-model answers are confidently wrong in ways that are hard to detect from inside that single model. The Council mitigates this by:
- **Cognitive diversity** — four frontier models with distinct training distributions and stylistic priors generate genuinely different takes on the same prompt.
- **Role differentiation** — each panelist receives a distinct role prompt (Analyst, Generalist, Skeptic, Visionary) that pushes it away from the others' default behavior.
- **Blind peer critique** — panelists review each other's work without knowing which model produced what. Critiques are paired (assigned coverage) plus wildcard (panelist's own choice of who to push back on).
- **Opus synthesis** — the strongest available reasoning model arbitrates, surfaces dissent, and produces the unified answer. This is the highest-leverage seat in the system.

## Structural diagram

```
                          ┌─────────────────────┐
                          │   USER PROMPT       │
                          │   (Walid)           │
                          └──────────┬──────────┘
                                     │
                                     ▼
                          ┌─────────────────────┐
                          │   HERMES RUNTIME    │
                          │   (orchestrator —   │
                          │    not a model)     │
                          └──────────┬──────────┘
                                     │
                                     ▼
                          ┌─────────────────────┐
                          │   CHAIRMAN          │
                          │   (Opus 4.7)        │
                          │   Triage decision:  │
                          │   convene? skip?    │
                          └──────────┬──────────┘
                                     │ proceed
                                     ▼
            ┌────────────┬───────────┴───────────┬────────────┐
            │            │                       │            │
            ▼            ▼                       ▼            ▼
       ┌─────────┐  ┌─────────┐            ┌─────────┐  ┌─────────┐
       │ANALYST  │  │GENERAL- │            │SKEPTIC  │  │VISION-  │
       │Sonnet   │  │IST      │            │Kimi K2  │  │ARY      │
       │4.6      │  │GPT-4o   │            │         │  │Gemini   │
       │         │  │         │            │         │  │2.5 Pro  │
       └────┬────┘  └────┬────┘            └────┬────┘  └────┬────┘
            │            │                       │            │
            └────────────┴───────────┬───────────┴────────────┘
                                     │ four raw outputs
                                     ▼
                          ┌─────────────────────┐
                          │   ANONYMIZER        │
                          │   (Haiku 4.5)       │
                          │   Strip style       │
                          │   markers, assign   │
                          │   randomized labels │
                          │   P1, P2, P3, P4    │
                          └──────────┬──────────┘
                                     │
                                     ▼
                  ┌──────────────────────────────────┐
                  │   CRITIQUE ROUND (parallel)      │
                  │                                  │
                  │   Each panelist critiques 2:     │
                  │   - 1 assigned (coverage)        │
                  │   - 1 wildcard (own choice)      │
                  │                                  │
                  │   8 critiques total              │
                  └──────────────┬───────────────────┘
                                 │
                                 ▼
                          ┌─────────────────────┐
                          │   CHAIRMAN          │
                          │   (Opus 4.7)        │
                          │   Synthesize:       │
                          │   • Answer          │
                          │   • Reasoning       │
                          │   • Dissent         │
                          │   • Open questions  │
                          └──────────┬──────────┘
                                     │
                                     ▼
                          ┌─────────────────────┐
                          │   FINAL RESPONSE    │
                          │   (to Walid)        │
                          └─────────────────────┘
                                     │
                                     ▼
                          ┌─────────────────────┐
                          │   SQLite log        │
                          │   chiefos.db       │
                          │   table_Council_    │
                          │   Sessions          │
                          └─────────────────────┘
```

## Hierarchy summary

| Layer | Component | Backed by | Role |
|-------|-----------|-----------|------|
| Runtime | Hermes | (no model — code) | Spawn sub-agents, route data, persist session |
| Triage + Synthesis | Chairman | Claude Opus 4.7 | Decide whether to convene; arbitrate and synthesize the panel |
| Panel | Analyst | Claude Sonnet 4.6 | First-principles reasoning |
| Panel | Generalist | GPT-4o | Broad-knowledge synthesis |
| Panel | Skeptic | Kimi K2 | Adversarial review of the prompt's framing |
| Panel | Visionary | Gemini 2.5 Pro | Long-horizon view, surface what's missing |
| Transform | Anonymizer | Claude Haiku 4.5 | Strip style markers between rounds |
| Storage | SQLite | (no model) | Persist full session for research |

## Data flow per stage

1. **User prompt arrives** → Hermes receives it, checks invocation triggers (skill named explicitly, trigger phrase used, or borderline-prompt confirmation from user).
2. **Triage** → Chairman receives the prompt and decides convene / single-pass / clarify. If single-pass or clarify, the rest of the workflow is skipped.
3. **Delegate** → Hermes spawns the four panelists in parallel, each with the user's prompt + its role-specific system prompt. ~30–60 sec for slowest panelist to return.
4. **Anonymize** → Hermes hands the four raw outputs to Anonymizer, which returns Panelist 1/2/3/4 labeled outputs and an internal label_map (kept by Hermes, not surfaced).
5. **Critique** → Hermes routes anonymized outputs back to the original panelists for critique. Each panelist gets two anonymized peer outputs and produces two critiques (assigned + wildcard).
6. **Synthesize** → Chairman receives all four anonymized outputs + all eight critiques, produces the structured final response.
7. **Log** → Hermes writes the full session to SQLite, including token counts and estimated cost.
8. **Return** → User receives Chairman's synthesis. Intermediate artifacts available on request.

## What Hermes actually does (code-side)

Hermes itself is not an LLM. It is the orchestration layer. Concretely:
- Reads `workflow.yaml`.
- Loads each sub-agent's role prompt from disk.
- Manages parallel API calls (the four panelists in delegate stage; the four critique stages).
- Handles timeouts, retries, error fallbacks per `error_handling` section of the workflow.
- Manages the anonymization label_map.
- Persists session data to SQLite.
- Returns Chairman's synthesis to the calling context (CLI, web UI, chiefos.example.com dashboard, whatever).

## Cost and latency profile

- **Total model calls per session:** ~10 (4 panelists + 4 critique turns + 1 synthesis + 1 anonymizer).
- **Latency:** ~60–120 seconds, dominated by the slowest panelist in the delegate stage and the Opus synthesis call.
- **Cost:** ~$0.50–$2.00 per session, depending on prompt length and panelist verbosity. Bounded by `budget_exceeded` guard at $5.00.
- **This is why invocation is gated.** Hermes does not auto-fire Council. Walid invokes it via skill name or trigger phrase, or confirms it on borderline prompts.

## Failure modes and mitigations

| Failure | Mitigation |
|---------|-----------|
| Panelist times out | Proceed with remaining panelists; minimum 3 required; Chairman noted in synthesis. |
| Panelist API error | Retry once, then proceed with remaining. |
| Chairman fails | Fall back to Sonnet synthesis; log warning. |
| Anonymization leaks brand | Acceptable — Chairman is instructed never to name models in output regardless. |
| Panelists all agree | Dissent section says "Panel reached consensus." No manufactured dissent. |
| Prompt didn't warrant Council | Chairman's triage stage catches this and returns single-pass response. |
| Cost overrun | Per-stage budget caps + total session hard abort at $5.00. |
| **Same-family RLHF coupling** | **Documented but not fixed in v1. See note below.** |
| **Chairman overreach** | **Anti-overreach clause in Chairman prompt; "Chairman departure" surfaced in Open questions when synthesis cannot ground in panelist reasoning.** |

## Known structural risks not fixed in v1

### Same-family RLHF coupling

The Chairman (Opus 4.7) and the Analyst panelist (Sonnet 4.6) share Anthropic's RLHF lineage. They are trained on overlapping preference data and exhibit correlated stylistic and substantive priors. This means:

- Sonnet's reasoning is more likely to "feel right" to Opus during synthesis than equivalent reasoning from a different-family panelist.
- Blind spots in Anthropic's training (whatever they are) appear in *both* the Chairman and one of the panelists, with no compensating perspective.
- The Council's anti-bias premise — that four distinct training distributions produce diverse views — is partially undermined by having two Anthropic models in the loop, one of them in the highest-leverage seat.

This is not fixable by tuning. It is structural to the v1 model assignments.

**Mitigations under consideration for v2:**

- Rotate Chairman across providers (e.g., GPT-4o or Gemini 2.5 Pro chairing on alternating sessions) to break Anthropic-family dominance.
- Designate a non-Anthropic panelist (likely Skeptic or Visionary) as "elevated dissenter" — Chairman is instructed to weight their dissent higher when the Anthropic panelist agrees with the Anthropic Chairman's instinct.
- Run sessions twice — once with current config, once with Chairman swapped to a non-Anthropic model — and compare. Expensive but informative for the DBA research.

**Why not fix in v1:** Opus is the strongest available synthesizer. Swapping it out costs synthesis quality to gain independence. Without data on whether the coupling actually distorts outputs in practice, the swap is speculative. Log sessions, audit Anthropic-vs-non-Anthropic agreement patterns after 20+ runs, then decide.

### Chairman overreach

Opus is powerful enough to produce its own answer to a prompt and treat the panel as decoration. The v1 mitigation is the anti-overreach clause in `agents/chairman.md` plus the "Chairman departure" mechanism in the Open questions section — Chairman must explicitly flag when synthesis cannot ground in any panelist's reasoning. This is a friction mechanism, not a guarantee. If departure flags appear in more than 20% of sessions, the mechanism is failing and the Chairman role itself needs redesign (likely splitting "synthesizer" from "arbiter" into two seats).

## Research instrumentation

The SQLite log is not just for ops — it's research data. Each session captures the full debate, which is useful for:
- Studying which models tend to win on which problem types (your DBA research).
- Detecting whether anonymization actually masks model identity (run a separate classifier over historical sessions).
- Quantifying how often Council changes the answer vs. how often it just re-confirms a single-model take (this is the key cost-justification metric).
- Patent portfolio evidence — Council itself is a candidate governance pattern worth documenting.
