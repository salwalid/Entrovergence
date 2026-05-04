# Hermes Registration Prompt

Paste the section between the `===` markers to Hermes verbatim.

The skill installs to `~/.hermes/skills/research/thinking-council/` (using `research` as the category folder). If you prefer a different category — `governance`, `strategy`, `autonomous-ai-agents` — substitute it in the prompt below.

---

```
========================================================================
Hermes — register a new skill.

Source folder:       /path/to/thinking-council/
Install location:    ~/.hermes/skills/research/thinking-council/

You are an agent runtime, not an LLM. Your job for this skill is to
register it and execute it on invocation. You do not redesign,
interpret, or optimize the specification. The files in the skill
folder are immutable spec.

REGISTRATION STEPS

1. Read SKILL.md as the skill manifest. Note the name (thinking-council),
   version (1.2), trigger phrases, invocation rules, and First Run section.

2. Read workflow.yaml as the orchestration definition. Six stages:
   triage, delegate, anonymize, critique, synthesize, log. Each stage
   names its actor (sub-agent role), inputs, outputs, and routing.
   Honor the parallel: true flags — delegate and critique stages run
   panelists concurrently, not sequentially.

3. For each agent named in workflow.yaml's "agents" block, load the
   corresponding file from the agents/ directory as that sub-agent's
   system prompt. The agents are:
     - chairman      → agents/chairman.md            (Claude Opus 4.7)
     - analyst       → agents/panelist_analyst.md    (Claude Sonnet 4.6)
     - generalist    → agents/panelist_generalist.md (GPT-4o)
     - skeptic       → agents/panelist_skeptic.md    (Kimi K2)
     - visionary    → agents/panelist_visionary.md  (Gemini 2.5 Pro)
     - anonymizer    → agents/anonymizer.md          (Claude Haiku 4.5)

4. INITIALIZATION — run scripts/init.sh once now, as part of registration.
   This creates data/council_sessions.db from data/schema.sql if missing.
   The script is idempotent. If it returns a non-zero exit code, abort
   registration and report the error.

   Command:
     cd ~/.hermes/skills/research/thinking-council/ && bash scripts/init.sh

   Verify success: the file data/council_sessions.db should exist and
   contain three tables: council_sessions, anonymization_audits,
   stage_latencies.

5. Register the skill with these invocation rules:
     - Manual invocation only. Do not auto-fire on any prompt.
     - Trigger phrases (case-insensitive, fuzzy match): "convene the
       council", "council this", "run thinking council", "panel this
       question", "thinking council on this".
     - Borderline prompts: ask the user to confirm before invoking.
     - On invocation, Chairman runs the triage stage first and may
       return a single-pass response if the prompt does not warrant
       Council. Honor that decision.
     - On every invocation, before calling Chairman, verify
       data/council_sessions.db exists. If missing, re-run
       scripts/init.sh. If init fails, abort the session.

6. Do not modify any file in the skill folder. If you believe a file
   should change, surface the issue to the maintainer for a version bump rather
   than editing in place.

CONFIRMATION

After registration, echo back the following so I can verify:
  - Skill name and version
  - Trigger phrases registered
  - Model assignments per role (role > provider > model string)
  - Path to council_sessions.db and confirmation that init.sh ran successfully
  - Tables present in the database (should be: council_sessions,
    anonymization_audits, stage_latencies, plus sqlite_sequence)
  - Any errors or warnings encountered during registration

Do not invoke the skill until I send a trigger phrase. Confirm
registration is complete and await further instructions.
========================================================================
```

---

## After registration completes

When Hermes echoes back the registration summary, verify each item:

- Trigger phrases match what's in `SKILL.md`
- Model strings match the table in `README.md` section 2
- `data/council_sessions.db` exists and reports the three expected tables
- No errors or warnings — if any, resolve before first invocation

If anything is off, do **not** proceed to dry run. Fix the registration first.

## First invocation (dry run)

Once registration is verified, invoke Council on a low-stakes prompt where you already know the answer. The goal is to confirm the *plumbing works*, not to learn anything from the answer.

Example dry-run prompts:

- "Convene the council: should the Council session log live in its own SQLite database or share the main application DB?" *(You already decided — own DB. You're testing whether the system runs end-to-end.)*
- "Council this: should the Anonymizer use Haiku or a smaller model?" *(You already chose Haiku for v1. Testing parallel panelist returns and synthesis structure.)*

Watch for during dry run:

1. All four panelists return within the timeout (90s)
2. Anonymizer produces four labeled outputs in randomized order
3. Each panelist returns two critiques (assigned + most-distant)
4. Chairman synthesis follows the four-section structure (Answer / Reasoning / Dissent / Open questions)
5. Per-stage costs track to `cost_*_usd` columns in the database
6. A row appears in `council_sessions` table after the run completes

If any of these fail, debug before running on a real question.

## First real invocation

Once dry run passes, fire on a question that actually matters. Two prompts that fit Council's profile:

- *"Convene the council: what should the go-to-market sequence be for a new developer tool — Reddit first, Product Hunt first, or LinkedIn first, and why?"*
- *"Council this: should our intellectual property strategy lean defensive or offensive, given a portfolio of three complementary innovations?"*

Both are contested, multi-domain, and have stakes. Either is a good first real test of whether Council changes your thinking or just confirms a single-model take you'd have accepted anyway. That delta is the only metric that justifies the cost.
