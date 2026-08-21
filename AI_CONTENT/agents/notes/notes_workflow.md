# Notes Workflow

**Purpose:** a place for an agent to record something worth keeping that is not yet — or may never become — official documentation.

Notes are not a replacement for `documentation/`. If a note describes something that has become an official requirement, architectural decision, or business rule, the obligation is to move it into the appropriate tier of `documentation/` (with an ADR if it's architectural) and either delete the note or mark it superseded — not to leave the real answer sitting only in a note where the next agent won't think to look.

## What belongs in a note

- **Architectural decisions** that haven't yet been written up as a formal ADR, or the reasoning trail behind one that was.
- **Open questions** raised during a task that the developer hasn't answered yet — so the next agent doesn't re-ask or re-guess.
- **Requirement changes** noticed mid-task that haven't been reconciled with `documentation/` yet.
- **Important assumptions** an agent had to make explicit in order to proceed on a non-blocking ambiguity (per `documentation/AI_MASTER_PROMPT.md`: proceed on what doesn't depend on the open question, ask about the part that does, and record the assumption).
- **Research findings** that haven't yet been evaluated for a documentation update (see the research agent's output format, which explicitly recommends whether `documentation/` should change).
- **Technical risks** identified but not yet mitigated.
- **Deferred decisions** — explicitly punted, with the reason, so "we decided not to decide yet" doesn't get mistaken for "nobody thought of it."
- **Lessons learned** — something that went wrong, or would have, and why.

## What does not belong in a note

- A restated business rule that already has an ID in `documentation/01-product-discovery/BUSINESS_RULES.md`.
- A finished architectural decision that should be an ADR under `documentation/00-governance/adr/` instead.
- Product requirements — those belong in `documentation/`, never only in a note.
- Anything the next reader needs in order to safely make a change. If it's load-bearing, it belongs in official documentation, not a note.

## Format

Store notes as dated Markdown files under `AI_CONTENT/agents/notes/`, named `YYYY-MM-DD_short-topic.md`. Each note should state: what it's about, why it exists as a note rather than a documentation update, and — if applicable — what would need to happen for it to graduate into `documentation/`.

## Promotion

When a note becomes an official requirement or decision:

1. Write or update the appropriate `documentation/` file (and an ADR if it's architectural).
2. Reference the promoted note from the new documentation entry, or delete the note if it added nothing beyond what's now documented.
3. Do not leave a stale note contradicting the documentation it was promoted into.
