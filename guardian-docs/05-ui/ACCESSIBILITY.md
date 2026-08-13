# ACCESSIBILITY

**Document tier:** 5 — UI
**Status:** Active
**Target:** WCAG 2.2 Level AA across all three clients

Accessibility is a **requirement, not an enhancement** ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §6). The platform's users span a wide range of literacy, language, vision, dexterity, device quality, and connectivity — and a parent who cannot read their child's status is not served by this product.

---

## Why This Document Has Teeth

ADR-0003 chose Flutter Web for the admin console, whose accessibility support is weaker than DOM. That ADR names an accessibility audit failure as an explicit **reconsideration trigger**.

**This document is therefore not aspirational.** A failure here reopens an architectural decision rather than producing a waiver.

---

## Perceivable

### Colour and contrast

- Text ≥ 4.5:1 against its background; large text ≥ 3:1; UI components and focus indicators ≥ 3:1.
- **Colour is never the only signal.** Every status carries an icon and a text label ([`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md)).
- Verified for both light and dark themes, and for the common color-vision deficiencies.

The driver app **exceeds** AA because it is read in direct sunlight — a compliant contrast ratio indoors can still be unreadable on a windscreen-lit screen.

### Text

- Body text ≥ 16 px in the parent app, ≥ 20 px in the driver app.
- Scales to **200% without loss of content or function**. No fixed-height text containers.
- No text baked into images.
- Line height ≥ 1.5; paragraph spacing ≥ 2× font size.

### Non-text content

- Every image, icon, and control has a meaningful label. Decorative images are explicitly marked decorative.
- **Maps are never the only route to information.** Every map is accompanied by an equivalent text summary — *"Bus 12 · 3 stops away · ~7 min to Green Park"* ([`PARENT_APP.md`](PARENT_APP.md)).
- Student photos carry the student's name as their label.

---

## Operable

### Touch targets

| Client | Minimum |
|---|---|
| Admin web | 40 × 40 |
| Parent app | 48 × 48 |
| Driver app | **64 × 64** |
| Driver SOS | **88 × 88** |

Driver figures are motor-accessibility requirements under vibration, not stylistic choices.

### Keyboard

The admin console is **fully keyboard operable** — every action, including data grids, route editing, and dialogs.

- Visible focus indicator at ≥ 3:1, never suppressed.
- Logical focus order; focus trapped inside modals and restored on close.
- Skip-to-content link.
- No keyboard traps.

### Timing and motion

- No time limits on any safety action.
- Session expiry warns and offers extension.
- All motion respects `prefers-reduced-motion` and degrades to instant state change.
- Nothing flashes more than three times per second.

### Gestures

Every gesture has a single-pointer alternative. **Nothing requires a multi-touch or path-based gesture** — the driver app in particular is operated one-handed, sometimes with gloves.

---

## Understandable

### Language

- Page and app language declared programmatically; per-user, independent of the school default.
- Full **RTL** support: mirrored layouts, logical start/end.
- Plain language in all user-facing copy. Notification copy is complete in the first line ([`NOTIFICATION_CATALOG.md`](../01-product-discovery/NOTIFICATION_CATALOG.md)).
- Layouts tolerate ±40% string length — a layout that breaks on a longer translation is a defect, not a translation problem.

### Predictability

- Consistent navigation and component behaviour across screens.
- No context change on focus or input alone.
- Destructive and safety-critical actions always confirm; nothing else does.

### Errors

- Errors identified in text, not by color or position alone.
- The localised `messageKey` from the API is displayed, never a raw code.
- Errors describe the fix: *"Fitness certificate expired 2026-07-15"*, not "invalid vehicle".
- Errors are associated with their field and announced to screen readers.
- All field errors returned at once, not one per submission.

---

## Robust

### Screen readers

Tested with TalkBack (Android), VoiceOver (iOS), and NVDA (admin web).

- Every interactive element exposes role, name, value, and state.
- Live regions announce status changes: boarding confirmations, alert arrivals, sync state.
- **Critical alerts use assertive live regions**; everything else is polite.
- Dynamic content changes are announced, not silent.

### Flutter specifics

- `Semantics` widgets on every custom component; `excludeSemantics` on decorative layers.
- Custom-painted elements (map markers, status indicators) always carry semantic labels.
- Focus order verified explicitly — visual order is not sufficient for Flutter Web.

---

## Situational and Environmental

The platform's hardest accessibility conditions are situational rather than permanent:

| Condition | Response |
|---|---|
| Sunlight on a driver's screen | Contrast above AA; large type; high-contrast mode |
| Vibration in a moving vehicle | 64 px targets; no precision gestures |
| One hand occupied | Every action single-pointer; SOS reachable one-handed |
| Noisy environment | Feedback is visual **and** haptic, never audio-only |
| Low-end parent device | Lightweight parent app; SMS as the floor channel |
| Poor connectivity | Cached state with explicit freshness; offline-first driver app (ADR-0008) |
| Limited literacy | Icons paired with short plain-language labels; SMS in the user's language |

---

## Testing

| Layer | Method |
|---|---|
| Automated | Contrast, target size, missing labels — in CI, failures break the build |
| Widget tests | Semantics assertions on every custom component |
| Manual | Screen-reader walkthrough of every critical journey each release |
| Keyboard | Full admin console traversal without a pointer |
| Scaling | Every screen at 200% text |
| RTL | Every screen mirrored |

### Critical journeys audited every release

1. Parent checks child status (P-02)
2. Parent receives and acts on a critical alert
3. Attendant records boarding (D-05)
4. Attendant completes handover (D-08)
5. Driver raises SOS (D-15)
6. Manager acknowledges a critical alert (A-04)

---

## Verification

1. Automated accessibility checks pass in CI; failures break the build.
2. Every color pair meets AA in light and dark themes.
3. Every screen functions at 200% text scale.
4. Every screen renders correctly mirrored in RTL.
5. Admin console is fully operable by keyboard.
6. Every custom component exposes role, name, value, and state.
7. Critical alerts are announced assertively by screen readers.
8. Every map has an equivalent text summary.
9. No gesture lacks a single-pointer alternative.
10. **The admin console passes a full audit before it is declared production-ready — a failure reopens ADR-0003.**
