# DESIGN SYSTEM

**Document tier:** 5 — UI
**Status:** Active
**Applies to:** parent app, driver/attendant app, admin web

One design system, three clients with sharply different conditions of use. Shared tokens; **per-client component sizing**, because a widget usable at a desk is not usable in a moving vehicle.

---

## Principles

1. **State over decoration.** The parent app answers "is my child fine?" in the first screen, without a tap.
2. **Legibility beats density** — especially in the driver app.
3. **Colour is never the only signal** ([`ACCESSIBILITY.md`](ACCESSIBILITY.md)). Every status carries an icon and a label.
4. **Calm for routine, direct for urgent.** Visual weight matches severity, so severity stays meaningful.
5. **Never show stale data as current.** Freshness is displayed, not assumed (BR-TRACK-003).

---

## Colour

Semantic tokens, never raw values in components.

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface` | `#FFFFFF` | `#121417` | Page background |
| `surfaceRaised` | `#F6F7F9` | `#1C1F24` | Cards |
| `textPrimary` | `#14181F` | `#EDEFF2` | Body |
| `textSecondary` | `#5A6472` | `#A2ABB8` | Supporting |
| `border` | `#DDE2E8` | `#2C313A` | Dividers |
| `primary` | `#1B5FA8` | `#5B9BD8` | Actions |
| `onPrimary` | `#FFFFFF` | `#0A1017` | Text on primary |

### Status colors

| Token | Light | Dark | Meaning |
|---|---|---|---|
| `statusSafe` | `#1F7A47` | `#4CAF7D` | Boarded, arrived, handed over |
| `statusInfo` | `#1B5FA8` | `#5B9BD8` | In progress, scheduled |
| `statusWarning` | `#9A6200` | `#E0A33E` | Delayed, expiring, no-show |
| `statusCritical` | `#B3261E` | `#F2837B` | Unaccounted child, SOS, override |
| `statusNeutral` | `#5A6472` | `#A2ABB8` | Not started, absent, unknown |

All pairs meet WCAG AA (4.5:1) against their surfaces in both themes. **`statusCritical` is reserved for genuine safety events** — using it for a validation error would erode the one signal that must never be ignored.

---

## Typography

Roboto / Noto Sans, with Noto covering the scripts the platform's locales require. Metrics-compatible fallbacks so translated strings do not reflow layouts.

| Token | Size / weight | Use |
|---|---|---|
| `displayLarge` | 32 / 700 | Driver next-stop |
| `headline` | 24 / 600 | Screen titles |
| `titleLarge` | 20 / 600 | Card titles, student names |
| `body` | 16 / 400 | Default |
| `bodySmall` | 14 / 400 | Supporting |
| `label` | 13 / 500 | Status chips |
| `caption` | 12 / 400 | Timestamps, freshness |

**Minimum 16 px for anything a parent or driver reads while moving.** `bodySmall` and below are for desk contexts and secondary metadata only.

Text scales to 200% without loss of function; no fixed-height text containers.

---

## Spacing, Radius, Elevation

4 px base scale: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48`.

Radius: `sm 6 · md 10 · lg 16 · full`. Elevation: `0` flat, `1` cards, `2` sheets, `3` dialogs. Elevation is never the sole indicator of interactivity.

---

## Touch Targets

| Client | Minimum | Reason |
|---|---|---|
| Admin web | 40 × 40 | Pointer input, desk |
| Parent app | 48 × 48 | WCAG standard |
| **Driver / attendant app** | **64 × 64** | **Moving vehicle, one-handed, gloved** |
| Driver SOS | **88 × 88** | Reachable without looking |

The driver figures are not a preference. A 48 px target on a vehicle over uneven road is a miss, and a miss during boarding means an unrecorded child ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md), Sunita and Ramesh).

---

## Core Components

### Status chip

Icon + label + color, always all three.

```
[✓] Boarded        statusSafe
[→] On the bus     statusInfo
[!] Delayed        statusWarning
[⚠] Unaccounted    statusCritical
[–] Absent         statusNeutral
```

### Student row

Photo (or initials), name, status chip, time. Photos load through the authorising endpoint, never a public URL.

### Live map

Vehicle marker with heading, route polyline, stop markers, the user's stop emphasised. **Always accompanied by a text summary** — the map is an enhancement, not the only way to get the information (`ACCESSIBILITY.md`).

### Freshness indicator

Mandatory wherever live data appears (BR-TRACK-003):

```
● Live · updated 4s ago          statusSafe
◐ Last seen 2 min ago            statusWarning
○ No signal since 07:38          statusNeutral
```

### Timestamp

Always rendered in the **school's** timezone with an explicit label (BR-CFG-006). Never the device's zone — a parent travelling abroad must still see school-local times.

### Empty, loading, error states

Every list defines all three. Errors show the localised `messageKey` from the API and a retry action; they never show a raw code or an internal detail.

---

## Motion

Durations 150–250 ms, standard easing. **Nothing blocks a safety action on an animation.** All motion respects `prefers-reduced-motion` and falls back to instant state change.

---

## Localisation

**No string is written inline in a widget** (BR-CFG-005). All text comes from localisation resources.

- Layouts tolerate ±40% string length; no fixed-width text containers.
- Full RTL support: mirrored layouts, logical start/end rather than left/right.
- Dates, times, and numbers formatted per locale (ADR-0007).
- Names render in the order the locale expects.

A layout that breaks on a longer translation is a defect, not a translation problem.

---

## Implementation

Tokens live in `guardian-core/lib/design/` and are consumed by all three clients. **`guardian_core` must not import `package:flutter/material.dart`** for its domain layer — the design layer is separate, keeping the domain portable if ADR-0003 is reversed.

Components are pure: they render state and emit intents. **No business logic in widgets** ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §8) — a rule checked in a widget is checked for user experience only; the server decides.

---

## Verification

1. Every color pair meets WCAG AA in light and dark themes.
2. No component references a raw color value.
3. Driver app targets are ≥64 px; SOS ≥88 px.
4. No user-facing string literal appears in any widget.
5. Layouts survive a 40% string-length increase and RTL mirroring.
6. Text scales to 200% without loss of function.
7. Every live-data surface renders a freshness indicator.
8. Every timestamp displays with the school's timezone.
9. `guardian_core` domain code does not import Flutter widgets.
