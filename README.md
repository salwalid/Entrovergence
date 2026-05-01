# Thinking Council — Skill Package

A multi-model deliberation skill for Hermes. Spawns a four-panelist council to produce peer-vetted answers to high-stakes prompts. Reserved for explicit invocation only.

**Owner:** Walid Saleh
**Version:** 1.1
**Status:** Spec ready for Hermes registration. Pre-flight checklist below.

## What this package is

A complete, portable skill folder. Drop it into Hermes's skills directory, run the registration prompt (see `register.md`), and Council becomes invokable via trigger phrases.

**This is a specification, not a library.** Hermes registers it and executes the workflow; nothing in this folder is meant to be modified post-registration. Treat the files as immutable spec and version-bump the whole package if you need to change behavior.

## Folder layout

```
thinking-council/
├── README.md                       ← this file
├── SKILL.md                        ← skill manifest, invocation rules, version log
├── workflow.yaml                   ← Hermes orchestration definition (six stages)
├── architecture.md                 ← full architecture description + ASCII diagram
├── register.md                     ← prompt to give Hermes for registration
├── agents/
│   ├── chairman.md                 ← Opus role prompt (orchestrate + synthesize)
│   ├── panelist_analyst.md         ← Sonnet role prompt
│   ├── panelist_generalist.md      ← GPT-4o role prompt
│   ├── panelist_skeptic.md         ← Kimi K2 role prompt
│   ├── panelist_visionary.md       ← Gemini 2.5 Pro role prompt
│   └── anonymizer.md               ← Haiku role prompt
├── scripts/
│   └── init.sh                     ← creates data/council_sessions.db on first run
└── data/
    ├── schema.sql                  ← SQLite schema for session log
    └── council_sessions.db         ← created by init.sh on first run (do not commit to git)
```

## Install location

Hermes installs skills under `~/.hermes/skills/<category>/<skill-name>/`. Council lives at:

```
~/.hermes/skills/research/thinking-council/
```

Substitute `research` for another category if you prefer (`governance`, `strategy`, etc.) — adjust the path in `register.md` to match.

## Pre-flight checklist

Before handing this folder to Hermes, confirm all four:

### 1. API credentials available to Hermes

Hermes needs four API tokens in its environment or secrets store:

| Provider | Token env var | Used by |
|----------|---------------|---------|
| Anthropic | `ANTHROPIC_API_KEY` | Chairman (Opus), Analyst (Sonnet), Anonymizer (Haiku) |
| OpenAI | `OPENAI_API_KEY` | Generalist (GPT-4o) |
| Moonshot | `MOONSHOT_API_KEY` | Skeptic (Kimi K2) |
| Google | `GOOGLE_API_KEY` (or `GEMINI_API_KEY`) | Visionary (Gemini 2.5 Pro) |

Confirm Hermes reads these correctly. If Hermes uses different env var names, update `workflow.yaml` accordingly — but verify the change applies before first invocation.

### 2. Model strings verified against current provider docs

The `workflow.yaml` uses these exact model identifiers. These were correct at v1.1 release; verify before first run:

| Role | Provider | Model string |
|------|----------|--------------|
| Chairman | anthropic | `claude-opus-4-7` |
| Analyst | anthropic | `claude-sonnet-4-6` |
| Anonymizer | anthropic | `claude-haiku-4-5-20251001` |
| Generalist | openai | `gpt-4o` |
| Skeptic | moonshot | `kimi-k2` |
| Visionary | google-generative-ai | `gemini-2.5-pro` |

**Walid-specific gotcha:** Google provider's `api` field must be `"google-generative-ai"` exactly. `"google-gemini"` or `"gemini"` will fail validation. Verify the other three providers' identifiers in the same way against current API docs.

### 3. SQLite available to Hermes

Council ships with its own database — `data/council_sessions.db` — created by `scripts/init.sh` on first run. Hermes only needs Python's stdlib `sqlite3` module, which is built into any Python install. No external dependency required.

**Confirmed for Walid's Hermes install:** Hermes uses SQLite internally (for `~/.hermes/state.db`) and has Python sqlite3 available. Council's database is fully separate by design — it lives inside the skill folder, not in Hermes's runtime state.

**Hermes does NOT auto-create the database or auto-apply schema.sql.** This was confirmed directly with Hermes: registration copies files but does not execute setup. The skill handles its own initialization via `scripts/init.sh`. The registration prompt in `register.md` instructs Hermes to run init.sh as part of registration.

Manual setup if needed:

```bash
cd ~/.hermes/skills/research/thinking-council/
bash scripts/init.sh
```

The script is idempotent — safe to re-run any time. It creates the DB if missing, verifies schema if present, and refuses to modify an incomplete existing DB.

### 4. Hermes understands the skill registration model

Hermes is an agent runtime, not an LLM. Its job here is to:

- Read `workflow.yaml` as the orchestration spec
- Load each `agents/*.md` file as the system prompt for that sub-agent role
- Spawn sub-agents in the order/parallelism defined by the workflow
- Route data between sub-agents per the workflow
- Persist sessions to the local SQLite database
- Return the Chairman's synthesis to the calling context

Hermes does **not** redesign, optimize, or interpret the spec. The whole point of the package is reproducibility — for Walid's DBA research, sessions need to be comparable across time, which requires the spec to stay fixed.

## Registration

See `register.md` for the exact prompt to give Hermes. After registration, confirm by asking Hermes to echo back:

- Skill name and version
- Trigger phrases that invoke the skill
- Model assignments per role
- Database path and schema status

If anything in the echo-back is wrong, fix before first invocation. Silent misregistration produces failures that look like API errors and are hard to diagnose.

## First-run procedure

1. **Pre-flight:** Walk through the four-item checklist above.
2. **Register:** Hand Hermes the `register.md` prompt. Verify echo-back.
3. **Dry run:** Invoke Council on a low-stakes prompt with a known-correct answer. Goal is to confirm the system *works*, not to learn anything from the answer. Suggested: a question you've already decided.
4. **First real invocation:** Use a trigger phrase ("convene the council on …") with a genuinely contested high-stakes prompt.
5. **Audit after 10 sessions:** Run the queries in `data/schema.sql`'s research views to check for Chairman departure rate, consensus rate, and cost trajectory. Anonymization fidelity audit is also Tier 2 — run when you have enough sessions to see signal.

## Cost expectations

Per session: ~$0.50–$2.00 depending on prompt length and panelist verbosity. Hard cap at $5.00 with per-stage budget pacing (see `workflow.yaml`'s `budget` block).

At 50 sessions/month: $25–$100/month operational cost.
At 200 sessions/month: $100–$400/month — at this rate, audit whether Council is actually changing decisions or just adding latency to single-model answers you'd have accepted anyway.

## When *not* to use Council

- Routine factual questions (search, definitions, syntax)
- Single-domain technical work (code review, debugging)
- Casual conversation or quick exploration
- Iterative work where speed > thoroughness
- Anything where you'd accept a single-model answer if it were confident

The skill explicitly does not auto-invoke. Council fires only on trigger phrases or borderline-prompt confirmation. This is by design.

## Known v1 structural risks

Documented in detail in `architecture.md` under "Known structural risks not fixed in v1":

1. **Same-family RLHF coupling** — Chairman (Opus) and Analyst (Sonnet) share Anthropic lineage; correlated blind spots. Mitigations deferred to v2 pending session data.
2. **Chairman overreach** — Opus may bypass panel and produce its own answer. Mitigated by anti-overreach clause in `agents/chairman.md` plus Chairman departure flag surfaced in Open questions. Friction mechanism, not a guarantee.

If Chairman departure flags exceed 20% of sessions after the first 30 runs, the Chairman role itself needs redesign.

## Versioning

Bump the version in `SKILL.md`'s frontmatter on any substantive change. Skill version is logged with every session in `council_sessions.skill_version`, so historical audits can correlate behavior changes with version bumps. Do not silently modify files in place.

## Contact

Walid Saleh — noreply@chiefos.local
