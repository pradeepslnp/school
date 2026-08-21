# PARENT APP

**Document tier:** 5 — UI
**Client:** `flutter/parent_app` (Flutter) · **Persona:** Meera ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md))

---

## Design Brief

**Conditions of use:** 10–20 second glances, one-handed, between other tasks, often on mobile data with variable signal.

**The app must answer "is my child fine?" in the first screen, without a tap.** Everything else is secondary.

This is not a tracking app that happens to send notifications. It is a **reassurance product** where the map is a detail view, not the entry point ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §2).

---

## P-02 — Home

The screen that matters.

```
┌─────────────────────────────────┐
│ Good morning, Meera             │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ [photo] Aarav Sharma        │ │
│ │         Class 5-B           │ │
│ │                             │ │
│ │ [✓] On the bus              │ │
│ │ Boarded Green Park, 7:42 AM │ │
│ │ Arriving at school ~8:15 AM │ │
│ │ ● Live · updated 6s ago     │ │
│ │                    [Track →]│ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [photo] Ananya Sharma       │ │
│ │ [–] Not travelling today    │ │
│ │ You marked her absent       │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Rules:**
- One card per child, complete status without interaction.
- Freshness indicator always present (BR-TRACK-003) — never show stale as current.
- ETA always labelled as an estimate, with its calculation time (BR-TRACK-006).
- **Between trips the card is calm, not empty**: "At school · next bus 3:10 PM". Absence of news is itself communicated.
- Times in the **school's** timezone, not the device's (BR-CFG-006) — a parent travelling abroad still sees school-local times.

### States

| State | Display |
|---|---|
| No trip today | "At school · afternoon bus 3:10 PM" |
| Trip scheduled | "Bus 12 starts at 7:15 AM" |
| Waiting at stop | "Bus 12 arriving in ~4 min" |
| On the bus | Live tracking available |
| Arrived | "Arrived at school, 8:15 AM" |
| Handed over | "Handed to you at 3:20 PM" |
| No-show | ⚠ "Aarav did not board at Green Park" |
| **Unaccounted** | 🔴 Full-width critical banner, top of screen |
| Absent | "Not travelling today" |

**The critical banner is the only element permitted to dominate the home screen.** It appears for NTF-SAFE-01 and NTF-HAND-05 only — the events where a parent must act immediately.

---

## P-04 — Live Trip Map

Reached by tapping *Track*, never the default view.

- Vehicle marker with heading; route polyline; the parent's stop emphasised.
- **Other students are never shown** — no markers, no count, no names (BR-NTF-007 🔴).
- Text summary above the map, always: *"Bus 12 · 3 stops away · ~7 min to Green Park"*. The map is an enhancement; the information is available without it ([`ACCESSIBILITY.md`](ACCESSIBILITY.md)).
- Freshness indicator persistent.
- Available only while the trip is active (BR-TRACK-001) — outside a trip the screen explains that tracking is trip-scoped, rather than showing an empty map.

---

## P-06 — Declare Absence

```
Which child?      [Aarav ▾]
When?             ( ) Today  ( ) Tomorrow  ( ) Date range
Which journey?    ( ) Both  ( ) Morning only  ( ) Afternoon only
Reason (optional) [                    ]
                             [Confirm]
```

**Reason is optional** (BR-ABS-001) — requiring a parent to justify their child's absence is friction with no safety value.

Confirmation states the effect plainly: *"Aarav will not be expected on Bus 12 tomorrow morning."*

After trip start, declaration is refused with an explanation and a route to contacting the school (BR-ABS-003).

---

## P-07 — Authorised Pickup Persons

Visible only to guardians holding `canAuthoriseHandover` (BR-GRD-006).

```
Sunil Kumar (Uncle)
+91 98123 45678
Valid 5–12 Aug 2026                    [Revoke]

                        [+ Add pickup person]
```

**The validity window is mandatory and prominent** — nominations always expire (BR-GRD-005). The form defaults to a short window rather than a long one.

Adding or revoking notifies **all** guardians with the handover right (NTF-ADM-04/05), so one guardian cannot quietly authorise someone the others would object to.

Custody restrictions are **never displayed here** or anywhere in this app.

---

## P-12 — Handover Verification

Shown when the parent is collecting their child at a drop stop.

```
      ┌───────────────┐
      │               │
      │   [QR code]   │      Show this to the bus attendant
      │               │
      └───────────────┘
      Code: 4 8 2 9 1 3      (if the attendant cannot scan)

      Aarav Sharma · Bus 12 · Green Park
```

Large, high-contrast, **screen brightness raised automatically** — it is scanned outdoors, often in sunlight.

The numeric code is a fallback for a failed scan, not a lesser option (BR-HAND-002).

---

## P-08 — Notification Centre

The durable record. A parent who missed a push must be able to scroll back and find it.

Grouped by day, newest first. Critical items are visually distinct and stay unread until acknowledged. Each entry links to the relevant child or trip.

---

## Behaviour Under Poor Conditions

The parent app is a **read surface** and is deliberately **not** offline-first (ADR-0008) — stale data here is a display problem, not data loss.

| Condition | Behaviour |
|---|---|
| Slow network | Last known state shown with an explicit freshness indicator |
| Offline | Cached state with "Not connected · last updated 07:44"; never a blank screen |
| Live position stale | Downgraded indicator, never presented as current (BR-TRACK-003) |
| Push token expired | Silent re-registration; SMS remains the floor channel |

---

## Notifications

Copy principles are in [`NOTIFICATION_CATALOG.md`](../01-product-discovery/NOTIFICATION_CATALOG.md). For this client specifically:

- **Readable from the lock screen without opening the app.** Complete in the first line.
- Deep-link to the relevant child, not the app root.
- Critical notifications bypass mute and quiet hours (BR-NTF-006 🔴) and use a distinct sound.
- **SMS is the floor.** A parent on a low-end device with no app installed still receives the safety-critical messages ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §6).

---

## Accessibility & Localisation

- Minimum 16 px body text; scales to 200%.
- 48 × 48 minimum touch targets.
- Full screen-reader labels on every status; **color is never the only signal**.
- Language is per-user, independent of school default — a family may prefer a language the school does not use by default.
- Full RTL support.
- Screenshots suppressed on screens showing child personal data.

---

## Verification

1. Home shows complete child status with zero taps.
2. Every live-data element carries a freshness indicator.
3. No other family's child appears anywhere, including on the map.
4. All times display in the school's timezone with the zone labelled.
5. Live tracking is unavailable outside an active trip, with an explanation.
6. Critical notifications arrive with the app muted and during quiet hours.
7. Offline shows cached state with a freshness label, never a blank screen.
8. Pickup-person nomination requires the handover right and an expiry.
9. Custody restrictions never appear in any response rendered by this app.
10. The app functions at 200% text scale and in RTL.
