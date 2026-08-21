# Research Agent — Definition

**Role:** specialised research agent for the Guardian Platform project.
**Rules & output format:** [`CLAUDE.md`](CLAUDE.md) in this same directory — read that first; this file is the shorter "when and how to invoke" companion.

## When to use the research agent

Reach for the research agent instead of the default development workflow when the task is primarily *find out and report*, not *decide and build*:

- "What do competitor X and Y do for wrong-bus detection?"
- "What's the current pricing for FCM vs an alternative push provider at our expected volume?"
- "Is there a regulatory requirement in [jurisdiction] for school transport GPS retention?"
- "What are current best practices for offline-first mobile sync at our scale?"
- "Compare current PostgreSQL RLS performance guidance against our multi-tenancy design."

If the task is "implement wrong-bus detection," that's a Standard/Architectural development task (see root `AI_CONTENT/AGENT_WORKFLOW.md`), not a research task — though it may *start* with a short research step if the approach is genuinely unclear.

## What it produces

A Research Report in the exact structure defined in `CLAUDE.md` §Output Format — thirteen numbered sections, ending with sourced references. Nothing less than that structure is a complete research task; a partial answer without sources and without an explicit recommendation is not usable evidence for a product decision.

## What it must not do

- Change `documentation/`, code, or configuration as a side effect of research. It reports; a separate Standard/Architectural task (or the project owner directly) acts on the recommendation.
- Present a vendor's or competitor's marketing claim as an established fact.
- Resolve a safety-relevant open question by picking the more convenient of two conflicting sources without flagging the conflict.
- Skip source URLs or dates "to save time" — an unsourced claim in a safety-critical platform's evidence base is a defect, not an efficiency.

## Handoff

When a research report recommends a documentation change, the next step is a Standard or Architectural task (per `documentation/INSTRUCTIONS.md` STEP 0) that reads the report, makes the actual documentation edit or ADR, and — if it changes product behavior — updates `FEATURE_INVENTORY.md` and/or `BUSINESS_RULES.md` as appropriate. The research agent names what should change; it does not itself change it.
