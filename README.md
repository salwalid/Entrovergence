<p align="center">
  <span style="font-size:3rem;">⚖️</span>
</p>

<h1 align="center">Entrovergence</h1>

<p align="center">
  <strong>Entropy meets convergence.</strong><br>
  A multi-model deliberation council for high-stakes thinking.
</p>

<p align="center">
  <a href="#how-it-works">How It Works</a> ·
  <a href="#the-council">The Council</a> ·
  <a href="#workflow">Workflow</a> ·
  <a href="#when-to-use-it">When To Use It</a> ·
  <a href="#ecosystem">Ecosystem</a>
</p>

---

## The Problem

Single-model answers are confidently wrong in ways that are hard to detect from inside that single model. You ask GPT a question, you get a confident answer. You ask Claude, you get a different confident answer. Both sound right. Both might be wrong in the same direction — or opposite directions with no way to tell.

Entrovergence fixes this by making AI models argue with each other before giving you an answer.

---

## What It Is

Entrovergence is a **multi-model deliberation system** that spawns four frontier AI models as panelists, runs a blind peer critique round, and synthesizes a unified answer with explicit dissent surfacing. It's not a chatbot. It's not a wrapper. It's a structured debate protocol with anonymization, peer review, and a research-grade audit trail.

**One question in. One peer-vetted answer out.**

| | |
|---|---|
| **4 frontier models** | Claude, GPT, Kimi, Gemini — each with a distinct cognitive role |
| **Blind critique** | Panelists review each other's work without knowing who wrote what |
| **Dissent surfacing** | Real disagreements are preserved, not averaged away |
| **Session logging** | Every deliberation is persisted to SQLite for research and audit |
| **Cost-bounded** | Per-stage budget caps with hard abort at $5.00/session |
| **~$0.50–$2.00/session** | 10 model calls, 60–120 seconds, structured output |

---

## The Council

Six agents, four distinct AI providers, zero groupthink:

| Role | Model | What They Do |
|------|-------|-------------|
| **Chairman** | Claude Opus | Triages the question, orchestrates the panel, synthesizes the final answer. The highest-leverage seat — arbitrates without dominating |
| **Analyst** | Claude Sonnet | First-principles reasoning. Structured decomposition. Finds the load-bearing assumptions |
| **Generalist** | GPT-4o | Broad-knowledge synthesis. Cross-domain connections. Sees what specialists miss |
| **Skeptic** | Kimi K2 | Adversarial review. Assumes the question's framing is wrong somewhere — and finds where |
| **Visionary** | Gemini 2.5 Pro | Long-horizon view. Surfaces what the prompt is missing entirely |
| **Anonymizer** | Claude Haiku | Strips style markers between rounds so critiques target ideas, not models |

### Why these roles?

The roles aren't arbitrary. They're designed to maximize **cognitive diversity** — the whole point of convening a panel. The Analyst and Generalist produce two flavors of "answer the question." The Skeptic challenges whether the question is right. The Visionary asks what's missing entirely. Together they cover: *what is*, *what's wrong with it*, and *what you haven't thought of yet*.

---

## How It Works

```
                    ┌─────────────────┐
                    │  YOUR QUESTION  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    CHAIRMAN     │
                    │  Triage: worth  │
                    │  convening?     │
                    └────────┬────────┘
                             │ yes
         ┌───────────┬───────┴───────┬───────────┐
         ▼           ▼               ▼           ▼
    ┌─────────┐ ┌─────────┐   ┌─────────┐ ┌─────────┐
    │ ANALYST │ │GENERALIST│  │ SKEPTIC │ │VISIONARY│
    │ Sonnet  │ │  GPT-4o  │  │ Kimi K2 │ │ Gemini  │
    └────┬────┘ └────┬────┘   └────┬────┘ └────┬────┘
         └───────────┴───────┬─────┴───────────┘
                             │ 4 raw outputs
                    ┌────────▼────────┐
                    │   ANONYMIZER    │
                    │  Strip markers  │
                    │  Randomize IDs  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  CRITIQUE ROUND │
                    │  Each panelist  │
                    │  reviews 2 peers│
                    │  (8 critiques)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    CHAIRMAN     │
                    │  Synthesize:    │
                    │  • Answer       │
                    │  • Reasoning    │
                    │  • Dissent      │
                    │  • Open Qs      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  SQLite log     │
                    │  Full session   │
                    │  persisted      │
                    └─────────────────┘
```

### The six stages

1. **Triage** — Chairman decides if the question warrants a full council. Simple questions get a single-pass answer. No wasted API calls.

2. **Delegate** — All four panelists receive the question in parallel, each with their role-specific system prompt. ~30–60 seconds.

3. **Anonymize** — Haiku strips identifying style markers (self-references, brand boilerplate, distinctive formatting tics) and assigns randomized labels: Panelist 1, 2, 3, 4.

4. **Critique** — Each panelist reviews two peers: one assigned (round-robin for coverage) and one self-selected (the peer whose position is *most distant* from their own). 8 critiques total, 200 words each. The selection rule forces engagement with real disagreement — not the weakest target.

5. **Synthesize** — Chairman receives all four anonymized outputs and all eight critiques. Produces a structured response: **Answer**, **Reasoning**, **Dissent**, and **Open Questions**.

6. **Log** — Full session persisted to SQLite: prompt, all panelist outputs, all critiques, synthesis, cost, latency, and failure metadata.

---

## Output Format

The Chairman's synthesis is what you see:

```
## Answer
The unified position — lead with this.

## Reasoning
Why this answer, drawing on the panel without naming models.

## Dissent
Fundamental disagreements presented neutrally.
Or: "Panel reached consensus" — no manufactured dissent.

## Open Questions
Unresolved threads worth your further thought.
```

Intermediate artifacts are available on request:
- *"Show me the panel"* — reveals all four anonymized panelist outputs
- *"Show dissent detail"* — expands dissent with critique excerpts
- *"Show critiques"* — all 8 critiques verbatim

---

## When To Use It

**Use Council when:**
- The question is strategic, multi-domain, or genuinely contested
- A single model's confident answer could be confidently wrong
- The cost of a bad decision is high; the cost of $1–2 and 90 seconds is trivial
- You need dissent surfaced, not smoothed over

**Don't use Council when:**
- The question has a known correct answer (factual lookups, syntax, definitions)
- You're iterating fast and need quick turnaround
- A single domain expert would clearly suffice ("fix this Python bug")
- Casual conversation or exploration

Council does **not** auto-invoke. It fires only on explicit trigger phrases:
- *"Convene the council"*
- *"Council this"*
- *"Run thinking council"*
- *"Panel this question"*

---

## Installation

Entrovergence is a skill package — a folder of specs that an orchestrator (like [CHIEFOS](https://github.com/salwalid/CHIEFOS)) registers and executes.

```bash
# Clone
git clone https://github.com/salwalid/Entrovergence.git

# Initialize the session database
cd Entrovergence
bash init.sh
```

### Requirements

| Requirement | Details |
|---|---|
| **API keys** | Anthropic, OpenAI, Moonshot, Google (4 providers) |
| **Python** | 3.8+ with stdlib `sqlite3` |
| **Orchestrator** | Any runtime that can read `workflow.yaml` and spawn sub-agents |

### File structure

```
Entrovergence/
├── README.md              ← you are here
├── SKILL.md               ← manifest, invocation rules, changelog
├── COUNCIL.md             ← detailed council methodology
├── workflow.yaml          ← orchestration definition (6 stages)
├── architecture.md        ← full architecture + structural diagram
├── register.md            ← registration prompt for your orchestrator
├── chairman.md            ← Chairman role prompt (Opus)
├── panelist_analyst.md    ← Analyst role prompt (Sonnet)
├── panelist_generalist.md ← Generalist role prompt (GPT-4o)
├── panelist_skeptic.md    ← Skeptic role prompt (Kimi K2)
├── panelist_visionary.md  ← Visionary role prompt (Gemini 2.5 Pro)
├── anonymizer.md          ← Anonymizer role prompt (Haiku)
├── schema.sql             ← SQLite schema for session log
├── init.sh                ← database initialization script
├── fig1-architecture.svg  ← architecture diagram
└── fig2-decision-flow.svg ← decision flow diagram
```

---

## Cost & Performance

| Metric | Value |
|---|---|
| Model calls per session | ~10 |
| Latency | 60–120 seconds |
| Cost per session | $0.50–$2.00 |
| Hard cap | $5.00 (per-stage budget pacing) |
| At 50 sessions/month | $25–$100/month |
| At 200 sessions/month | $100–$400 (audit whether Council is actually changing decisions at this rate) |

### Budget pacing

Each stage has its own cost cap — a single runaway stage can't eat the whole session budget:

| Stage | Cap |
|---|---|
| Triage | $0.10 |
| Delegate (4 panelists) | $1.50 |
| Anonymize | $0.20 |
| Critique (8 critiques) | $1.00 |
| Synthesize | $1.50 |

If any stage exceeds its cap, the session aborts and returns partial outputs.

---

## Research Instrumentation

Every session is logged to SQLite with full provenance. This isn't just ops — it's research data:

- **Chairman departure rate** — How often does the Chairman produce an answer that can't be grounded in any panelist's reasoning? Above 20% = redesign needed.
- **Consensus rate** — How often does the panel agree? Persistent consensus may mean Council is over-invoked on easy questions.
- **Anonymization fidelity** — Run a classifier on historical sessions to check if panelist identity leaks through anonymization. Above 25% accuracy (chance for 4) = anonymization is failing.
- **Cost trajectory** — Monthly cost summaries for budget planning.

Built-in SQL views for all of the above — see `schema.sql`.

---

## Known Structural Risks

### Same-family RLHF coupling

The Chairman (Opus) and Analyst (Sonnet) share Anthropic's training lineage. Correlated blind spots are possible. Sonnet's reasoning may "feel right" to Opus during synthesis in ways that non-Anthropic panelists' reasoning doesn't. This is structural, not fixable by tuning.

**v2 mitigations under consideration:** Rotate Chairman across providers. Elevate non-Anthropic dissent weighting. Run comparative sessions.

### Chairman overreach

Opus is powerful enough to produce its own answer and treat the panel as decoration. Mitigated by an anti-overreach clause in the Chairman prompt and a "departure flag" surfaced when synthesis can't ground in panelist reasoning. Friction mechanism, not a guarantee.

---

## Ecosystem

<table>
  <tr>
    <td align="center" width="50%">
      <a href="https://github.com/salwalid/CHIEFOS">
        <strong>🏛️ CHIEFOS</strong>
      </a>
      <br><br>
      The self-hosted AI backend that runs Entrovergence. Structured database, dashboards, alerts, and governance — Entrovergence plugs in as a skill.
      <br><br>
      <code>Your AI. Your server. Your call.</code>
    </td>
    <td align="center" width="50%">
      <a href="https://maatspec.org">
        <strong>🪶 MaatSpec</strong>
      </a>
      <br><br>
      The governance framework. Ensures Council invocations are classified by risk tier and that the results are handled appropriately. Because even peer-vetted answers need guardrails.
      <br><br>
      <code>Autonomy without anarchy.</code>
    </td>
  </tr>
</table>

---

## Philosophy

> *"One model's opinion is just a hallucination with confidence."*

Entrovergence exists because the hardest questions aren't the ones where you need a smarter model — they're the ones where you need a second opinion from a model that thinks differently. Not a bigger brain. A different brain. Four of them.

The name is the thesis: **entropy** (divergent thinking, diverse perspectives, controlled chaos) meets **convergence** (synthesis, arbitration, a single actionable answer). The magic is in the tension between them.

---

## License

MIT

---

<p align="center">
  <sub>Built by a human who ships. <a href="https://phatfaro.com">phatfaro.com</a></sub>
</p>
