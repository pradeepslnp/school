# ADMIN WEB

**Document tier:** 5 — UI
**Client:** `admin` (Flutter Web, ADR-0003 — **status Proposed**)
**Personas:** Anil (transport manager), Fatima (school admin)

> **ADR-0003 is the weakest of the platform's current assumptions.** This console is data-dense, which is where Flutter Web is least comfortable. The verification section below defines the conditions that trigger reconsideration in favour of React — an accessibility audit failure or a load-budget breach reopens the ADR rather than waiving the requirement.

---

## Design Brief

**Conditions of use:** desktop, several tabs open, keyboard-driven. Phone during a live incident.

**Anil's day is exceptions.** The console must surface what is going wrong right now, ranked by severity, and let him act without hunting ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md)).

**Fatima's work is bulk.** Import, assign, correct, repeat — data entry that duplicates what the office already has is the main thing that makes her job worse.

---

## Console Livery

**This section is a deliberate, console-only deviation from [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) §Colour and §Typography.** It applies to the `admin` client and to nothing else — the parent and driver apps continue to render `guardian_theme` unchanged. Implemented as `AdminLivery`, a `ThemeExtension` in `admin/lib/app/theme.dart`; the yellow is **not** in `guardian_theme`, because a color added there would repaint all three clients.

| Token | Light | Dark | Use |
|---|---|---|---|
| `rail` | `#FAD35E` | `#E8BE4A` | Navigation rail |
| `railInk` | `#171310` | `#171310` | Everything drawn on `rail` |
| `railMutedInk` | `#5C4B12` | `#54430E` | Band headings on `rail` |
| `canvas` | `#F6F4F0` | `#15181C` | Work surface behind panels |
| `panel` | `#FFFFFF` | `#1C2026` | Cards, tables, header bar |
| `panelSubtle` | `#FAF8F4` | `#232830` | Table headings, stat tiles |
| `border` | `#E4E0D8` | `#2E343D` | Row hairlines |
| `borderStrong` | `#D8D3C8` | `#444C57` | Control outlines (3:1) |

### Yellow is identity, never status, and never carries text

School-bus yellow is the most recognisable color in child transport — real buses use it because drivers catch it in peripheral vision faster than any other hue, which is exactly what a navigation rail wants. It is unusable for almost everything else, for two independent reasons, and both are load-bearing:

1. **Contrast.** Yellow cannot reach 3:1 against white at any usable saturation, so yellow text fails and white-on-yellow fails every contrast test including at large sizes. Black on yellow reaches ~19:1 — which is why real buses carry black lettering. Everything on `rail` is therefore `railInk`, never white, and **no button is ever filled yellow**: primary actions keep `colorScheme.primary` navy. ([`ACCESSIBILITY.md`](ACCESSIBILITY.md) §Contrast.)
2. **Semantics.** `GuardianColors.warning` (`#9A6200`) already spends amber on *delayed, expiring, no-show*. A yellow that also meant "brand" would weaken the one signal that has to stay unambiguous. Yellow appears only as chrome — rail, wordmark, selected destination — and never as the state of anything.

**The status palette is untouched.** `safe` / `info` / `warning` / `critical` / `neutral` keep the values in `DESIGN_SYSTEM.md` §Status colors, so green still means *the child is accounted for* on every surface of the platform. Registry states that are not safety states — enrolment, transport eligibility — take the navy `primaryContainer` or a neutral, never the safety palette.

### Typography

The console sets **Barlow** (UI) and **Archivo** (screen titles, operations counts) rather than the platform's Roboto / Noto Sans. Both are bundled in `admin/pubspec.yaml`, not fetched from `fonts.googleapis.com`: a console an operator opens during an incident must not render in a fallback face because a school network blocks a font host.

Noto's script coverage still governs anything the localisation work adds — see the open item in §Verification.

### Navigation

Nine flat destinations make an operator read the whole rail to find one module. They are banded by `ConsoleGroup` — **Operations**, **Administration**, **Platform** — under quiet headings, in the order `ConsoleDestinations.all` already defines. The selected destination inverts to an ink pill with yellow text: a shape difference as well as a color one, per `DESIGN_SYSTEM.md` §Principles.

---

## A-01 — Operations Dashboard

The landing screen. Exceptions first, statistics second.

```
┌──────────────────────────────────────────────────────────┐
│ 🔴 CRITICAL                                              │
│   Unaccounted child · Bus 12 · Aarav Sharma      [Open]  │
├──────────────────────────────────────────────────────────┤
│ 🟠 NEEDS ATTENTION                          4            │
│   Bus 7 route deviation · 6 min              [Ack]       │
│   Bus 22 not started · 12 min late           [Open]      │
│   Fitness certificate expired · DL1PC1234    [Open]      │
│   Handover override · Bus 9 · 15:22          [Review]    │
├──────────────────────────────────────────────────────────┤
│  Trips today   142      Running  38     Completed  104   │
│  Students      2,140    On bus   612    Delivered  1,203 │
└──────────────────────────────────────────────────────────┘
```

**Ordering is by severity, never by time.** A critical event from an hour ago outranks a warning from a minute ago.

Alerts are deduplicated (BR-ALERT-005) — a bus deviating for twenty minutes is one row, not two hundred. Without this the dashboard becomes noise and Anil stops reading it, which makes the real alert invisible.

---

## A-02 — Fleet Live Map

All active vehicles, clustered at scale. Colour by status; **icon and label too** — color is never the only signal.

Selecting a vehicle opens a side panel: trip, crew, next stop, boarded count, open alerts, with actions to call the driver or open the trip.

Vehicles outside active trips do not appear (BR-TRACK-001) — the platform is a safety tool, not staff surveillance.

---

## A-04 / A-05 — Alert Inbox & Incident Console

Work queues, not notification lists. Every row has an owner, a severity, and a resolution state (BR-ALERT-006).

Resolution requires an outcome — alerts are never silently dropped. Bulk-acknowledge exists for related alerts; **bulk-resolve does not**, because a resolution is a decision about one thing.

The SOS console shows the live escalation trail: who was notified at each level, when, and who acknowledged (BR-SAFE-006 🔴).

---

## A-06 — Safety Exceptions

The screen a principal reads. Left-behind events, no-shows, wrong-stop alights, handover overrides, refused handovers, no-receiver exceptions.

Every row carries actor, reason, resolution, and its **business rule ID** — so "what happened" and "which control caught it" are answerable together.

---

## A-12 — Bulk Student Import

```
┌──────────────────────────────────────────────────────────┐
│  412 rows · 408 imported · 4 errors                      │
├──────────────────────────────────────────────────────────┤
│ Row 17  admissionNo   Already exists: GW-2024-0117       │
│ Row 88  phone         Invalid format for region IN       │
│ Row 201 guardian      No guardian with handover right    │
│ Row 340 stopId        Unknown stop: "Green Prk"          │
├──────────────────────────────────────────────────────────┤
│      [Download error rows]   [Fix and re-upload]         │
└──────────────────────────────────────────────────────────┘
```

**Valid rows are imported; the file is never rejected wholesale.** The error download contains only failed rows in the original format, so Fatima fixes and re-uploads a small file rather than reconciling 412 rows by hand.

Row 201's error is the important one: BR-GRD-002 🔴 refuses a student with no guardian authorised to collect them.

---

## A-13 — Guardian Links & Rights 🔴

```
Meera Sharma · Mother
  ☑ View    ☑ Notifications    ☑ Authorise handover    ☑ Declare absence

Rajesh Sharma · Father
  ☑ View    ☑ Notifications    ☐ Authorise handover    ☐ Declare absence
```

Rights are **explicit checkboxes**, never inferred from relationship (BR-GRD-001 🔴). The relationship label is descriptive only — the form makes that visually obvious so an admin does not assume "father" grants collection.

Unchecking the last `Authorise handover` across all guardians is **blocked** with an explanation (BR-GRD-002 🔴).

---

## A-14 — Custody Restrictions 🔴

Gated behind `PERM-CUSTODY-RESTRICTION-MANAGE`, visually distinct, `reason` required.

Restrictions are **never** exposed in any parent-facing surface. The console warns explicitly that adding one blocks handover and visibility immediately and overrides existing guardian rights (BR-HAND-006).

---

## A-31 — Route Editor

Map-based: drag stops, reorder, adjust geofence radius visually.

**Validation is inline**, not at save:

| Violation | Feedback |
|---|---|
| Radius outside 20–500 m | Circle turns red with the bound explained (BR-ROUTE-003 🔴) |
| Times not increasing | Offending stop highlighted (BR-ROUTE-008) |
| Fewer than two stops | Save disabled (BR-ROUTE-001) |

A banner states that changes apply to **future trips only** — trips already started keep their materialised manifest (BR-ROUTE-006, BR-TRIP-003).

---

## A-32 — Student Route Assignment

Two-panel: unassigned students on the left, stops on the right. Drag or multi-select and assign.

Capacity is shown live against the vehicle's seating (BR-FLEET-005). Assignment preconditions are surfaced **before** the attempt, not as an error afterwards — a student lacking a handover-capable guardian is visibly flagged in the unassigned list.

---

## A-40 — Add Organization

Creating an organization and then its first school is a focused two-step flow, pushed over the console shell by `OrganizationListRoute`. Because it covers the navigation, it carries its own page frame (`OnboardingScaffold`): the console canvas, a labelled way back, a title that names the task, and a step indicator whose steps show a number or check **and** a label — never color alone.

```
← Organizations
Add organization
Create the organization, then add its first school.
(1) Organization ──── (2) First school
┌───────────────────────────────────────────────────────┐
│ Identity        │ Organization name                   │
│ purpose line    │ Organization code   (fixed once …)  │
│─────────────────┼─────────────────────────────────────│
│ Region          │ Region profile code                 │
│─────────────────┼─────────────────────────────────────│
│ Contact         │ Contact email · Contact phone       │
│───────────────────────────────────────────────────────│
│ Cancel                          Create and continue → │
└───────────────────────────────────────────────────────┘
```

- **Sections, not one long column.** Fields are grouped under a titled section (`OnboardingFormSection`) with a one-line purpose on the start side and the fields beside it; the section stacks when its own width is under 600 px. Short values (codes, radius, time zone) take a narrower field that hints at their length.
- **Name before code.** The order an operator thinks in; the immutable code carries its constraint in helper text.
- **Actions.** Primary action at the end of the footer, the way out as a text button at the start (`OnboardingFormFooter`). Errors render directly above the footer, beside the button the operator will press again.
- **Step 2 confirms step 1** in a `primaryContainer` banner. Creating an organization is a registry event, so it never borrows the status palette.
- **Location** is a Plus Code with a status tile beneath it: guidance while empty, the resolved coordinates and precision once decoded, so the operator sees what will be stored before saving. The same `CreateSchoolForm` is reused when a skipped school is added later from the organization's details, and that view's organization form uses the same sections.
- **Copy** in labels and helper text is plain language — no rule or ADR identifiers.

---

## A-45 / A-47 — Configuration & Alert Rules

```
Overspeed threshold
[ 13.9 ] m/s        allowed 5.0 – 25.0        🔒 safety-critical
Sustained for [ 30 ] seconds
```

Bounds are **displayed alongside the field**, not discovered on save (BR-CFG-003 🔴). Safety-critical keys are marked and require `PERM-CONFIG-SAFETY-EDIT`.

The duration field is given equal prominence to the threshold — without it, alerts fire on GPS noise and become unreadable.

Every change shows old and new values in a confirmation and is audited (BR-CFG-004).

---

## A-54 … A-57 — Audit Surfaces

Read-only. **No create, edit, or delete affordance exists anywhere** — audit records are append-only (BR-AUD-001 🔴), and the absence of these controls reflects the absence of the API.

| Screen | Purpose |
|---|---|
| A-54 Audit trail | Searchable by actor, subject, action, correlation ID |
| A-55 Override register | Every override with its required reason (BR-AUD-004) |
| A-56 Child data access log | Who read which child's data, when (BR-IAM-012 🔴) |
| A-57 Platform access log | Cross-tenant operations with justification (BR-TEN-004 🔴) |

---

## Data Grids

Where Flutter Web is weakest, so the rules are strict:

- **Virtualised** — thousands of rows without degradation.
- Cursor pagination, never offset ([`API_STANDARDS.md`](../04-api/API_STANDARDS.md)).
- Sorting only on documented sortable fields; others are not offered.
- Column visibility and order persist per user.
- Bulk selection with an explicit count: *"412 students selected"*.
- Every export is permission-gated and audited with a record count (BR-RPT-002 🔴).
- **Keyboard navigable throughout** — arrow keys, Enter, Escape.

---

## Responsive

| Width | Layout |
|---|---|
| ≥1280 | Full — sidebar, grid, detail panel |
| 768–1279 | Detail collapses to overlay |
| <768 | **Incident-response subset only** — dashboard, alerts, SOS, live map |

The narrow layout is deliberately not the full console. Anil on a phone during an incident needs to act, not administer.

---

## Performance Budget (ADR-0003 gate)

| Metric | Budget |
|---|---|
| First meaningful paint, simulated 4G | < 4 s |
| Route transition | < 300 ms |
| Grid render, 1,000 rows | < 500 ms |
| Initial bundle | Tracked; regressions fail CI |

**A sustained breach reopens ADR-0003.** These numbers are the ADR's own stated reconsideration trigger, not aspirations.

---

## Verification

1. Dashboard orders by severity, not recency.
2. A continuing alert condition renders one row.
3. Import shows per-row errors and imports the valid remainder.
4. Unchecking the last handover right is blocked.
5. Custody restrictions never appear in parent-facing responses.
6. Route editor validates geofence bounds and stop-time ordering inline.
7. Configuration fields display their permitted bounds.
8. Audit screens expose no mutation affordance.
9. Grids virtualise and remain keyboard-navigable.
10. Every export writes an audit record with a record count.
11. Accessibility audit passes ([`ACCESSIBILITY.md`](ACCESSIBILITY.md)) — **failure reopens ADR-0003**.
12. Load budget holds in CI — **sustained breach reopens ADR-0003**.
