# GitHub Copilot Instructions (machine-friendly)

Follow these rules when generating code, patches, or tasks for this repository:

1. Read `guardian-docs/INSTRUCTIONS.md` and `guardian-docs/FLUTTER_APP_INSTRUCTIONS.md` before making code changes.
2. Produce a 3–6 line plan before any non-trivial change: requirement summary, files to change, and verification steps.
3. Prefer linking to existing documentation instead of copying it. Use markdown links to the files in `guardian-docs/`.
4. Do not introduce placeholder or pseudo-production code in repositories; return an implementation or a clearly documented TODO with an ADR.
5. For Flutter changes: run `flutter analyze` locally; CI runs also check this. Do not add new widget tests unless requested by the maintainer.
6. For architectural changes: add an ADR under `guardian-docs/00-governance/adr/` and reference it in the PR description.
7. When adding or changing tasks/workflows: include clear run steps in the PR description so reviewers can reproduce locally.

If you are an automated agent, output only the minimal patch and a short summary that references the files you changed.
