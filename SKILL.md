---
name: thinking-council
description: Invoke the Thinking Council — a multi-model deliberation panel — for strategically important, high-stakes, or genuinely contested questions where a single model's answer is insufficient. Use ONLY when explicitly requested by the user (phrases like "convene the council," "council this," "thinking council on this") or when a prompt clearly meets the escalation criteria below. Do NOT auto-invoke for routine questions, factual lookups, casual conversation, or single-domain technical questions. The Council costs 6–10 model calls per session; reserve it for questions that warrant the spend.
owner: open-source
version: 1.2
changelog:
  v1.2:
    - Added scripts/init.sh — initializes data/council_sessions.db from schema.sql on first run.
    - Added explicit First Run section instructing Hermes to invoke init.sh before first Council session.
    - Confirmed Hermes does not auto-create databases or auto-apply .sql files; init must be explicit.
  v1.1:
    - Added anti-overreach clause to Chairman prompt (mitigates "Chairman bypasses panel" failure mode).
    - Replaced wildcard self-selection in critique with structured "most-distant peer" rule (removes gaming incentive).
    - Added per-stage budget caps with abort logic (replaces blunt single-cap with isolation per stage).
    - Documented same-family RLHF coupling (Opus + Sonnet) as known v1 structural risk; mitigations deferred to v2 pending session data.
  v1.0:
    - Initial release. Four-panelist Council with Opus chair, paired+wildcard critique, SQLite logging.
---

# Thinking Council

A peer-vetted, multi-model deliberation system for high-stakes thinking. Hermes orchestrates a panel of four frontier models, runs a blind critique round, and synthesizes a unified answer with explicit dissent surfacing.

## First Run

**Before the first Council invocation, Hermes must initialize the local SQLite database.**

Hermes does not auto-create databases or auto-apply `.sql` files at registration time — `.sql` files are treated as supporting assets. The skill's own initialization script handles this.

On first invocation (or any time the database is missing), Hermes must run:

```bash
bash scripts/init.sh
```

This script:
- Checks whether `data/council_sessions.db` exists
- If missing: creates it and applies `data/schema.sql`
- If present: verifies the expected tables exist and exits clean
- Is idempotent — safe to re-run any time

If `init.sh` fails or returns a non-zero exit code, do not proceed with Council invocation. Surface the error to the user and stop.

## When to invoke

**Invoke when:**
- the user uses an explicit trigger phrase: "convene the council," "council this," "run thinking council," "panel this question."
- The prompt is strategic, multi-domain, or contested (e.g., architectural decisions, governance design, research framing, strategic direction).
- A single-model answer would likely be confidently wrong in ways the user can't easily detect.
- The cost of a bad answer is high and the cost of an extra 30 seconds + ~$1–2 in API spend is trivial by comparison.

**Do NOT invoke when:**
- The question is factual, procedural, or has a known correct answer.
- The question is casual, conversational, or exploratory chat.
- A single domain expert model would clearly suffice (e.g., "fix this Python bug").
- the user is iterating quickly and needs fast turnaround.

When in doubt, ask the user: "This looks like a Council-worthy question — convene?"

## The Council

| Role | Model | Function |
|------|-------|----------|
| **Chairman** | Claude Opus 4.7 | Orchestrates workflow, anonymizes, surfaces dissent, synthesizes final answer |
| **Analyst** | Claude Sonnet 4.6 | First-principles reasoning, structured decomposition |
| **Generalist** | GPT-4o | Broad-knowledge synthesis, cross-domain connections |
| **Skeptic** | Kimi K2 | Adversarial review, finds the flaw in the question's framing |
| **Visionary** | Gemini 2.5 Pro | Long-horizon view, surfaces what the prompt is missing |
| **Anonymizer** | Claude Haiku 4.5 | Strips style markers between rounds |

## Workflow

1. **Triage.** Hermes confirms invocation criteria are met. If borderline, asks the user to confirm.
2. **Delegate (parallel).** Hermes spawns the four panelist sub-agents simultaneously, each with the user's prompt and its role-specific system prompt.
3. **Anonymize.** The Anonymizer sub-agent strips brand/style markers from each panelist output and assigns randomized labels: Panelist 1, 2, 3, 4.
4. **Critique (paired + wildcard).** Each panelist receives two peer outputs to critique: one assigned (round-robin coverage) and one of their choosing — the output they most disagree with. 8 critiques total.
5. **Synthesize.** Chairman receives all four anonymized outputs and all eight critiques. Produces:
   - **Answer** — the unified position
   - **Reasoning** — why this answer
   - **Dissent** — points of fundamental disagreement, presented neutrally
   - **Open questions** — unresolved threads worth the user's further thought
6. **Log.** Full session (prompt, panelist outputs, critiques, synthesis, dissent) writes to the local SQLite database for research and post-hoc analysis.

## Outputs

The Chairman's final response is what the user sees. The intermediate panelist outputs and critiques are logged but not surfaced unless requested ("show me the panel" or "show dissent detail").

## Constraints

- Chairman never names the underlying models in the final output.
- If panelists genuinely agree, the Dissent section says so. No manufactured disagreement.
- If the prompt turns out to be Council-unworthy (too simple, factual, etc.), Chairman returns a single-pass response and notes "Council not convened — escalation criteria not met."
- Each panelist critique is capped at 200 words. Synthesis is capped at 1500 words unless the user requests longer.

## Cost guardrails

A full Council session is ~10 model calls (4 panelists + 8 critiques routed via 4 panelists' second turns + 1 synthesis + Anonymizer overhead). Approximate cost per session: $0.50–$2.00 depending on prompt length and panelist verbosity. Hermes logs cost per session to the same SQLite table for tracking.

## Files

- `workflow.yaml` — Hermes orchestration definition
- `agents/chairman.md` — Chairman role prompt (Opus)
- `agents/panelist_analyst.md` — Analyst role prompt (Sonnet)
- `agents/panelist_generalist.md` — Generalist role prompt (GPT-4o)
- `agents/panelist_skeptic.md` — Skeptic role prompt (Kimi K2)
- `agents/panelist_visionary.md` — Visionary role prompt (Gemini 2.5 Pro)
- `agents/anonymizer.md` — Anonymizer role prompt (Haiku)
- `architecture.md` — Full architecture description and diagram
