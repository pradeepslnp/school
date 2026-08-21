# Reusable Workflows

Task-specific workflows for common categories of work. Created as they're needed, not all at once — a workflow file that exists "just in case" is dead documentation nobody maintains.

Anticipated workflows (create the ones you actually need, in this style, when you need them):

- `feature_workflow.md` — end-to-end steps for adding a new product feature spanning backend, Flutter, and documentation.
- `backend_feature_workflow.md` — backend-only feature workflow (module layout, ArchUnit, migration + RLS).
- `flutter_feature_workflow.md` — Flutter-only feature workflow (five-part feature shape, BLoC).
- `database_change_workflow.md` — schema change, migration, RLS policy update, `tables/` documentation.
- `api_change_workflow.md` — endpoint addition/change, permission declaration, contract test, API doc update.
- `testing_workflow.md` — test-level selection (unit/integration/contract/e2e) and business-rule-ID traceability.
- `code_review_workflow.md` — what a reviewer checks against `documentation/ENGINEERING_PRINCIPLES.md` and the quality gate in root `CLAUDE.md` §20.
- `documentation_workflow.md` — how to add or amend a `documentation/` tier document, including the ADR path.

Each workflow file, once created, should follow the same shape as `AI_CONTENT/AGENT_WORKFLOW.md`: a numbered process an agent can follow without re-deriving it from first principles each time.
