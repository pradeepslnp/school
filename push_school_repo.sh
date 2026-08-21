#!/usr/bin/env bash
# Pushes the "school" root-repo-scoped files (documentation, root config, AI_CONTENT, etc.)
# to https://github.com/pradeepslnp/school.git
#
# Run this on your own Mac terminal (NOT through Claude's sandbox), from any directory.
# It assumes ~/projects/school is your Guardian Platform workspace root.

set -euo pipefail

SRC="$HOME/projects/school"
WORK="$(mktemp -d)"
DEST="$WORK/school-repo"
mkdir -p "$DEST"

if [ ! -d "$SRC" ]; then
  echo "ERROR: $SRC not found. Edit SRC in this script to point at your Guardian Platform workspace root."
  exit 1
fi

echo "Staging root-repo-scoped files from $SRC into $DEST ..."

FILES=(
".github/copilot-instructions.md"
".github/workflows/ci.yml"
".vscode/launch.json"
".vscode/tasks.json"
"AGENTS.md"
"AI_CONTENT/AGENT_WORKFLOW.md"
"AI_CONTENT/agents/notes/notes_workflow.md"
"AI_CONTENT/agents/outputs/README.md"
"AI_CONTENT/agents/research_agent/CLAUDE.md"
"AI_CONTENT/agents/research_agent/research_agent.md"
"AI_CONTENT/agents/workflows/README.md"
"AI_CONTENT/prompts/README.md"
"CLAUDE.md"
"README.md"
"analysis_options.yaml"
"api/README.md"
"deployment/README.md"
"documentation/.gitignore"
"documentation/00-governance/DOCUMENT_HIERARCHY.md"
"documentation/00-governance/GLOSSARY.md"
"documentation/00-governance/adr/ADR-0001-multi-tenancy-strategy.md"
"documentation/00-governance/adr/ADR-0002-tenant-hierarchy.md"
"documentation/00-governance/adr/ADR-0003-admin-web-client.md"
"documentation/00-governance/adr/ADR-0004-realtime-tracking-pipeline.md"
"documentation/00-governance/adr/ADR-0005-notification-provider-abstraction.md"
"documentation/00-governance/adr/ADR-0006-authentication-model.md"
"documentation/00-governance/adr/ADR-0007-regional-configuration.md"
"documentation/00-governance/adr/ADR-0008-offline-first-driver-app.md"
"documentation/00-governance/adr/ADR-0009-flavor-configuration.md"
"documentation/00-governance/adr/ADR-0010-parent-read-composition.md"
"documentation/00-governance/adr/ADR-0011-flutter-monorepo-consolidation.md"
"documentation/00-governance/adr/README.md"
"documentation/00-governance/adr/TEMPLATE.md"
"documentation/01-product-discovery/BUSINESS_RULES.md"
"documentation/01-product-discovery/FEATURE_INVENTORY.md"
"documentation/01-product-discovery/MODULE_MAP.md"
"documentation/01-product-discovery/NOTIFICATION_CATALOG.md"
"documentation/01-product-discovery/PERMISSION_MATRIX.md"
"documentation/01-product-discovery/PERSONAS.md"
"documentation/01-product-discovery/STAKEHOLDERS.md"
"documentation/01-product-discovery/USER_JOURNEYS.md"
"documentation/02-system-design/ARCHITECTURE_OVERVIEW.md"
"documentation/02-system-design/AUDIT_AND_LOGGING.md"
"documentation/02-system-design/INTEGRATION_ARCHITECTURE.md"
"documentation/02-system-design/MULTI_TENANCY.md"
"documentation/02-system-design/NOTIFICATION_ARCHITECTURE.md"
"documentation/02-system-design/REALTIME_TRACKING_DESIGN.md"
"documentation/02-system-design/SCALABILITY.md"
"documentation/02-system-design/SECURITY_ARCHITECTURE.md"
"documentation/03-database/CONVENTIONS.md"
"documentation/03-database/DATA_MODEL_OVERVIEW.md"
"documentation/03-database/ERD.md"
"documentation/03-database/INDEXING_AND_PARTITIONING.md"
"documentation/03-database/MIGRATION_STRATEGY.md"
"documentation/03-database/RLS_POLICIES.md"
"documentation/03-database/tables/MOD-01-tenancy.md"
"documentation/03-database/tables/MOD-02-identity.md"
"documentation/03-database/tables/MOD-03-04-students-guardians.md"
"documentation/03-database/tables/MOD-05-06-fleet-staff.md"
"documentation/03-database/tables/MOD-07-routes.md"
"documentation/03-database/tables/MOD-08-trips.md"
"documentation/03-database/tables/MOD-09-boarding.md"
"documentation/03-database/tables/MOD-10-11-tracking-alerts.md"
"documentation/03-database/tables/MOD-12-notification.md"
"documentation/03-database/tables/MOD-13-14-incidents-absence.md"
"documentation/03-database/tables/MOD-16-17-audit-config.md"
"documentation/03-database/tables/README.md"
"documentation/04-api/API_STANDARDS.md"
"documentation/04-api/AUTHENTICATION_API.md"
"documentation/04-api/ERROR_CATALOG.md"
"documentation/04-api/FLEET_STAFF_ROUTES_API.md"
"documentation/04-api/REPORTING_AUDIT_CONFIG_API.md"
"documentation/04-api/STUDENTS_GUARDIANS_API.md"
"documentation/04-api/TENANCY_IDENTITY_API.md"
"documentation/04-api/TRACKING_NOTIFICATION_API.md"
"documentation/04-api/TRIPS_BOARDING_API.md"
"documentation/05-ui/ACCESSIBILITY.md"
"documentation/05-ui/ADMIN_WEB.md"
"documentation/05-ui/DESIGN_SYSTEM.md"
"documentation/05-ui/DRIVER_ATTENDANT_APP.md"
"documentation/05-ui/PARENT_APP.md"
"documentation/05-ui/SCREEN_INVENTORY.md"
"documentation/06-development/ARCHITECTURE_ENFORCEMENT.md"
"documentation/06-development/CODING_STANDARDS_BACKEND.md"
"documentation/06-development/CODING_STANDARDS_FLUTTER.md"
"documentation/06-development/DEFINITION_OF_DONE.md"
"documentation/06-development/GIT_WORKFLOW.md"
"documentation/06-development/LOCAL_SETUP.md"
"documentation/06-development/PROJECT_STRUCTURE.md"
"documentation/07-testing/SAFETY_CRITICAL_TEST_MATRIX.md"
"documentation/07-testing/TEST_CASES.md"
"documentation/07-testing/TEST_STRATEGY.md"
"documentation/08-deployment/BACKUP_AND_DR.md"
"documentation/08-deployment/CI_CD.md"
"documentation/08-deployment/ENVIRONMENTS.md"
"documentation/08-deployment/OBSERVABILITY.md"
"documentation/AI_MASTER_PROMPT.md"
"documentation/ENGINEERING_PRINCIPLES.md"
"documentation/FLUTTER_APP_INSTRUCTIONS.md"
"documentation/INSTRUCTIONS.md"
"documentation/PRODUCT_PRINCIPLES.md"
"documentation/PROJECT_CHARTER.md"
"documentation/README.md"
"flutter/teacher_app/README.md"
"operations/README.md"
"scripts/README.md"
)

for f in "${FILES[@]}"; do
  if [ -f "$SRC/$f" ]; then
    mkdir -p "$DEST/$(dirname "$f")"
    cp "$SRC/$f" "$DEST/$f"
  else
    echo "  WARNING: missing in source, skipped: $f"
  fi
done

cd "$DEST"
git init -q
git checkout -q -b main 2>/dev/null || git branch -m main
git add -A
git commit -q -m "Initial commit: Guardian Platform root repo scaffold

Adds root-level project scaffolding: governance/product/design/database/API/UI/dev/test/deployment documentation (tiers 0-8), AI_CONTENT agent workflow docs, CI/editor config, and top-level READMEs."

echo ""
echo "Committed $(git rev-list --count HEAD) commit(s), $(git ls-files | wc -l | tr -d ' ') files, in $DEST"
echo ""
echo "Now pushing to https://github.com/pradeepslnp/school.git ..."

git remote add origin https://github.com/pradeepslnp/school.git
git push -u origin main

echo ""
echo "Done. Verify at https://github.com/pradeepslnp/school"
echo "(Temp working copy left at $DEST if you want to inspect it before it's cleaned up.)"
