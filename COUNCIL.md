# The Thinking Council

**A multi-model deliberation system for high-stakes AI-assisted decision-making.**

| | |
|---|---|
| **Author** | Walid Saleh |
| **Version** | 1.2 (Hermes edition) |
| **Status** | Specification ready for first invocation |
| **Repository** | `thinking-council/` (Hermes runtime) |
| **Companion artifact** | `thinking-council/` (ChiefOS runtime) |
| **Related work** | MaatSpec (governance protocol), HALE (split-responsibility enforcement), [Project C] (verified-truth agent governance) |

---

## 1. Summary

The Thinking Council is a workflow that assembles a panel of four frontier large language models — drawn from four distinct training distributions — to produce peer-vetted answers to high-stakes questions. A fifth model arbitrates and synthesizes. A sixth model anonymizes panelist outputs between rounds to enable blind peer critique.

It is a deliberate constraint on AI-assisted thinking: rather than accepting one model's confident answer to a contested question, Council surfaces the disagreement that exists *across* models and forces an arbitrated synthesis that distinguishes consensus from genuine dissent.

The system is invoked manually, not automatically. Routine questions get single-model answers. The Council fires only when a question warrants the cost — strategic, multi-domain, or contested prompts where a single model's confidence is the failure mode.

## 2. The problem Council addresses

Frontier LLMs are confidently wrong in ways that are hard to detect from inside any one of them. Three patterns matter:

**Confident hallucination at the synthesis layer.** A model asked to weigh competing considerations will produce a fluent, structured answer that *reads* as judgment but may be pattern-matching rather than reasoning. The user has no signal to distinguish.

**Same-family blind spots.** Models trained on overlapping preference data exhibit correlated failure modes. Asking the same model twice does not produce independent perspectives. Asking two models from the same provider barely improves on this.

**Confidence ≠ correctness.** The most assertive answer is not the most accurate. Single-model interactions reward confidence stylistically, which means even careful users end up over-weighting fluent-but-wrong outputs.

The Council addresses these by structurally requiring **cognitive diversity**, **blind peer review**, and **explicit dissent surfacing** before any answer reaches the user.

## 3. Architecture

The Council is a six-stage pipeline. Each stage has a defined actor, defined inputs and outputs, and a defined failure mode.

### 3.1 Stage overview

| Stage | Actor | Input | Output |
|-------|-------|-------|--------|
| **1. Triage** | Chairman | User prompt | Decision: convene / single-pass / clarify |
| **2. Delegate** | Four panelists (parallel) | User prompt + role prompt | Four raw responses |
| **3. Anonymize** | Anonymizer | Four raw responses | Four anonymized labels (P1–P4) + internal label map |
| **4. Critique** | Four panelists (parallel) | Two anonymized peer responses each | Eight critiques (assigned + most-distant) |
| **5. Synthesize** | Chairman | All anonymized panelists + all critiques | Structured response (Answer / Reasoning / Dissent / Open questions) |
| **6. Log** | Runtime | All artifacts from prior stages | SQLite session record |

### 3.2 The Council seats

Six roles. Five involve LLM reasoning; one is a runtime function.

**Chairman — Claude Opus 4.7.** Triages, arbitrates, and synthesizes. Does not produce a panelist opinion of its own; remains structurally above the panel. This separation exists because the synthesizer's job is not to *contribute* a view but to *weigh* views, and a model wearing both hats favors its own contribution.

**Analyst — Claude Sonnet 4.6.** First-principles reasoning. Decomposes the prompt, surfaces hidden assumptions, shows structure. Strongest contribution: identifying when the question itself is malformed.

**Generalist — GPT-4o.** Broad-knowledge synthesis. Connects the prompt to adjacent domains, prior art, historical analogies. Strongest contribution: surfacing considerations the user did not ask about but should.

**Skeptic — Kimi K2.** Adversarial review. Default move is "the prompt's framing is wrong somewhere — find it." Strongest contribution: refusing to take the question at face value.

**Visionary — Gemini 2.5 Pro.** Long-horizon view. Pushes the time scale of the question — second- and third-order consequences, where things are heading. Strongest contribution: noticing when the right answer at one horizon is the wrong answer at another.

**Anonymizer — Claude Haiku 4.5.** Strips brand and stylistic markers from panelist outputs and returns them with randomized Panelist 1–4 labels. Temperature 0; deterministic transformation. Not a reasoning role.

### 3.3 Why these four panelists

Cognitive diversity is the architectural premise. Four frontier models from four providers produce maximally distinct training distributions:

- **Anthropic** (Sonnet) — reasoning, hedging priors
- **OpenAI** (GPT-4o) — decisive, list-prone, breadth
- **Moonshot** (Kimi K2) — distinct training corpus, less Western-biased
- **Google** (Gemini 2.5 Pro) — long-context, technical reasoning depth

Substituting a panelist for another model from a provider already represented compounds same-family coupling. The Council aborts rather than substitutes when a panelist is unavailable — see §6.1.

### 3.4 The critique routing

Each panelist produces two critiques per session. The first is **assigned by round-robin** to ensure every panelist receives critique. The second is **selected by the panelist** as the peer whose substantive position is most distant from their own — not the weakest target, not the easiest critique. The selection rule is enforced via prompt and surfaced in the panelist's output as a one-sentence justification before the critique itself.

The most-distant rule replaces an earlier "wildcard" design where panelists picked freely. The wildcard created a gaming incentive — pick the weakest peer to look strong by comparison. The most-distant rule forces engagement with genuine disagreement.

Eight critiques per session. Capped at 200 words each. Format: (a) one technical flaw, (b) one missing consideration, (c) one point of agreement worth strengthening.

### 3.5 The output structure

The Chairman's synthesis follows a fixed four-part structure:

**Answer.** The unified position. Lead with this. The user's question gets answered first, plainly, in the strongest form the panel + critiques can defend.

**Reasoning.** Why this answer, drawing on panelist contributions without naming them or their underlying models. The panel is anonymous to the user.

**Dissent.** Points where panelists fundamentally disagreed on substance, presented neutrally. If the panel reached genuine consensus, the section says so. No manufactured dissent.

**Open questions.** Things the council could not resolve — usually empirical questions requiring investigation, value judgments only the user can make, or framings the prompt itself didn't pin down. Three or fewer.

A fifth optional element appears only when triggered: **Chairman departure.** If the Chairman's synthesis substantively departs from all four panelists' reasoning, the departure is flagged in the Open questions section and named explicitly. This is a friction mechanism against Chairman overreach; see §6.2.

## 4. Operating principles

The Council is governed by five principles that constrain how it runs and what it produces.

**Cognitive diversity over panel size.** Four panelists across four providers, not eight panelists across two. Adding redundant models does not improve epistemic coverage.

**Blind critique over named critique.** Panelists do not see which model produced which output during the critique round. Anonymization is imperfect (style markers leak), but the structural commitment to blindness changes how panelists engage with peer work.

**Explicit dissent over false consensus.** When panelists disagree, the disagreement appears in the user-facing output. The Council does not average to a vague middle position no panelist held.

**Manual invocation over auto-fire.** Council fires on explicit trigger phrases or borderline-prompt confirmation. Routine questions get single-model answers. The cost of running Council on every prompt would render it economically unworkable and strategically pointless.

**Logging over disposability.** Every Council session writes a complete record to SQLite — prompt, panelist outputs, critiques, synthesis, dissent flag, departure flag, costs. Sessions are research artifacts, not chat history.

## 5. Invocation

### 5.1 Trigger phrases

Council fires on any of:

- "convene the council"
- "council this"
- "run thinking council"
- "panel this question"
- "thinking council on this"

Plus borderline-prompt confirmation: when a question is high-stakes but no trigger phrase was used, Chairman asks the user to confirm before convening.

### 5.2 When to invoke

Invoke when:
- The prompt is strategic, multi-domain, or contested
- A single-model answer would likely be confidently wrong in detectable-only-after ways
- The cost of a bad answer is high; the cost of $1–$2 in API spend and 60–120 seconds of latency is trivial by comparison

Do not invoke when:
- The question is factual, procedural, or has a known correct answer
- Casual conversation or quick exploration
- Single-domain technical work where one model would clearly suffice
- Iteration speed matters more than thoroughness

### 5.3 Triage

Even after invocation, the Chairman performs a triage step before convening the panel. If the prompt does not warrant Council, the Chairman returns a single-pass response with a note: "Council not convened — escalation criteria not met." The panel is not spawned, no critique round runs, no panel-level cost is incurred. Only triage cost (~$0.10) is logged.

## 6. Known structural risks

Two risks are documented and unaddressed in v1. They are not bugs; they are tradeoffs the design accepts in v1 and intends to revisit with operational data.

### 6.1 Same-family RLHF coupling

The Chairman (Opus 4.7) and the Analyst panelist (Sonnet 4.6) share Anthropic's training lineage. Their reasoning priors are correlated. The Chairman is structurally more likely to find the Analyst's reasoning "intuitive" than equivalent reasoning from a different-family panelist.

Mitigations under consideration for v2:
- Rotate Chairman across providers across sessions
- Designate a non-Anthropic panelist as elevated dissenter
- Run twice per session (current Chairman + alternate Chairman) and compare

The decision to defer is empirical: the cost of swapping Opus out of the chair is synthesis quality, and the actual magnitude of coupling distortion in practice is unknown without session data. v1 logs every session; after 20+ sessions, the coupling can be audited.

### 6.2 Chairman overreach

Opus 4.7 is powerful enough to produce its own answer to the user's prompt and treat the panelists as decoration. The synthesis instruction "draw on panelist contributions" does not structurally prevent this — the Chairman can claim to have drawn on the panel while substantively departing.

Mitigation: explicit anti-overreach clause in the Chairman's system prompt, plus a Chairman departure flag surfaced in Open questions when synthesis cannot ground in any panelist's reasoning. This is a friction mechanism, not a guarantee. If departure flags appear in more than 20% of sessions across the first 30 runs, the Chairman role itself needs redesign — likely splitting Judge from Synthesizer (planned for v1.3 evaluation).

### 6.3 Anonymization fidelity

Anonymization strips brand markers and randomizes labels but cannot eliminate stylistic fingerprints. Models have characteristic opening phrases, paragraph rhythms, formatting tics. A panelist may recognize peer outputs even with brand-stripping, especially within the same family.

Mitigation: post-hoc audit. After 10+ sessions, run a separate Haiku call on each anonymized panelist output asking "which model wrote this?" and log results to `anonymization_audits` table. Above-chance accuracy (>25% for four panelists) is signal that anonymization is failing and needs hardening.

### 6.4 Budget volatility

A Council session is ~10 model calls and costs $0.50–$2.00 depending on prompt length and panelist verbosity. Per-stage budget caps prevent any single stage from runaway cost (delegate $1.50, critique $1.00, synthesize $1.50, total session hard cap $5.00). Even with caps, sustained use can scale: 50 sessions/month is $25–$100; 200 sessions/month is $100–$400.

The mitigation is non-technical: ruthless invocation discipline. Council justifies its cost only when the cost of a single-model wrong answer would be greater. The trigger-phrase requirement and triage stage exist to enforce this.

## 7. Research instrumentation

Every Council session writes a structured record to SQLite. The schema includes the user prompt, all panelist outputs, the anonymization label map, all critiques, the Chairman's full synthesis, dissent and departure flags, per-stage costs, and total duration.

This converts operational cost into research data. The questions the log can answer:

- **Does Council change the answer?** Compare Chairman synthesis against what a single-model Opus call would have produced for the same prompt. The delta is the cost-justification metric.
- **Is anonymization holding?** Run the v_anonymization_accuracy view on post-hoc audits.
- **Is Chairman overreach occurring?** Run v_chairman_departures; track rate over time.
- **Which panelists win on which problem types?** Manual analysis of which panelist's reasoning the Chairman most often surfaces in the synthesis, segmented by prompt type.
- **What is the genuine consensus rate?** Run v_consensus_sessions; if panelists agree more than 70% of the time, the Council may be over-engineered for the prompts being run.

These questions are why the Council exists. The system is a working artifact and a research instrument simultaneously.

## 8. Relationship to the broader portfolio

The Council fits into a sequence of governance and verification artifacts:

**MaatSpec** (the governance protocol) addresses the Self-Binding Problem — the failure mode where AI agents rationalize violations of their own governance rules due to helpfulness bias. MaatSpec governs *agent actions*: tool calls, irrecoverable operations, tier-gated decisions.

**HALE** (Hybrid AI/LLM Enforcement) addresses the architectural question of how MaatSpec is enforced — split-responsibility between deterministic enforcement (rule-following at infrastructure layer) and LLM-based semantic tier classification.

**[Project C]** addresses agent governance over verified truth — the Repository Truth Index and the question of how agent outputs can be authenticated, contested, and corrected.

**Council** addresses a distinct problem: not how agents act under governance, but how AI-assisted *reasoning* can be structurally hardened against single-model failure modes. Where MaatSpec governs the agent, Council vets the answer.

The four artifacts together describe a layered approach to AI governance: deterministic enforcement (HALE), semantic governance (MaatSpec), truth verification ([Project C]), and reasoning vetting (Council).

## 9. Limitations

The Council does not solve the underlying problem of AI epistemic unreliability. It mitigates a specific failure mode — confident single-model answers on contested questions — by surfacing disagreement that already exists across models.

It does not:

- Generate ground truth where none exists. If all four models share a blind spot, Council has no mechanism to detect it.
- Replace expert review on questions requiring domain expertise. Council is a peer-among-peers panel, not a panel-of-experts.
- Eliminate the need for the user to think. The synthesis is a peer-vetted starting point, not a final answer. The Open questions section explicitly flags what the user must still resolve.
- Scale to high-frequency queries. The cost and latency profile reserves Council for deliberation, not iteration.

## 10. Status and next steps

v1.2 is specification-complete. The next operational steps:

1. Register Council as a Hermes skill via the prompt in `register.md`
2. Run the dry-run procedure on a low-stakes prompt with a known answer (validate the plumbing)
3. Run first real invocation on a contested portfolio question
4. Audit the first 10 sessions for: anonymization fidelity, Chairman departure rate, cost trajectory, consensus-vs-dissent ratio
5. Decide on v1.3 changes based on audit findings

The known v1.3 candidate change is splitting Judge from Synthesizer — making the evaluation step that the Chairman currently performs implicitly into an explicit, separately-prompted, separately-logged artifact. This is deferred until v1.2 has produced enough sessions to inform the decision.

---

*Document version 1.0 (Council v1.2 / Hermes edition). Maintained by Walid Saleh. Last revised at v1.2 release.*
