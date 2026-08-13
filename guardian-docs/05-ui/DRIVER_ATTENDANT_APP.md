# DRIVER & ATTENDANT APP 🔴

**Document tier:** 5 — UI
**Client:** `guardian-driver-app` (Flutter, offline-first per ADR-0008)
**Personas:** Ramesh (driver), Sunita (attendant) — [`PERSONAS.md`](../01-product-discovery/PERSONAS.md)

---

## Design Brief

**Conditions of use:** a moving or briefly stopped vehicle. Sunlight on the screen. Engine noise. Children boarding. One hand on a rail. Coverage drops on part of the route every single day.

Two roles, one app:

| Role | Primary need | Interaction budget |
|---|---|---|
| **Driver** | Next stop, and a way to raise an alarm | **As close to zero as possible** |
| **Attendant** | Mark many children fast; know who is missing | High, but every action must be fast |

**The driver should be interacting with this app as little as possible.** Where an attendant is assigned, boarding belongs to them (BR-STAFF-005).

---

## Non-Negotiable Constraints

| Constraint | Value | Reason |
|---|---|---|
| Touch targets | **≥ 64 × 64** | A 48 px target on uneven road is a miss; a miss is an unrecorded child |
| SOS target | **≥ 88 × 88** | Reachable without looking |
| Minimum text | **20 px**, next-stop at 32 px | Read at arm's length in sunlight |
| Contrast | Exceeds WCAG AA | Direct sunlight |
| Typing while moving | **None** | No free-text input on any in-motion flow |
| Confirmation dialogs | Only for irreversible safety actions | Dialogs during boarding cost seconds per child |
| Offline | **Every safety action works offline** | ADR-0008 |

---

## D-04 — Active Trip (Driver's default screen)

```
┌───────────────────────────────────┐
│  Bus 12 · Morning · 38 students   │
├───────────────────────────────────┤
│                                   │
│   NEXT STOP                       │
│   GREEN PARK                      │  ← 32px
│   ~4 min · 6 students             │
│                                   │
│   [ Opposite metro gate 3 ]       │
│                                   │
├───────────────────────────────────┤
│  ● 12 boarded   ○ 26 to come      │
│  ⟳ All synced                     │
├───────────────────────────────────┤
│ [ARRIVED AT STOP]                 │  ← full width, 72px
└───────────────────────────────────┘
                                [SOS]  ← 88px, persistent
```

One decision on screen: *arrived*. Landmark text is shown because a driver new to the route needs it and cannot read a map while moving.

---

## D-05 — Stop Boarding (Attendant's screen) 🔴

**The most-used screen in the platform.** A dozen children board in under two minutes.

```
┌───────────────────────────────────┐
│  GREEN PARK · 6 expected          │
├───────────────────────────────────┤
│      ┌───────────────────┐        │
│      │   [camera view]   │        │
│      │   scan credential │        │
│      └───────────────────┘        │
├───────────────────────────────────┤
│ ✓ Aarav Sharma          7:42      │
│ ✓ Priya Nair            7:42      │
│ ○ Rohan Gupta                     │  ← tap to mark manually
│ ○ Diya Menon                      │
│ – Kabir Shah      (absent)        │
├───────────────────────────────────┤
│ [DEPART STOP]                     │
└───────────────────────────────────┘
```

**Scan-first, manual fallback** (BRD-001, BRD-002). Both are one action.

**Feedback is immediate and multi-sensory** — the attendant is not looking at the screen while a child moves past:

| Result | Feedback |
|---|---|
| Success | Green flash + short beep + haptic |
| Already boarded | Amber + double beep |
| **Not on manifest** | Red + long beep + **blocking card** |
| **Wrong vehicle** 🔴 | Red + urgent tone + **blocking card, cannot dismiss without a decision** |

Records are written locally and acknowledged **instantly** — never blocked on a network call (ADR-0008). A child does not wait for a spinner.

### Departure guard

`DEPART STOP` with un-boarded students shows a confirmation naming them:

```
Rohan Gupta and Diya Menon have not boarded.
Depart anyway?          [Cancel]  [Depart]
```

Departure records them as no-shows and notifies guardians (BR-SAFE-002 🔴). **This is one of the few permitted confirmation dialogs** — the cost of a wrong tap here is a child left at a stop.

---

## D-08 — Handover Verification 🔴

```
┌───────────────────────────────────┐
│  Aarav Sharma · Green Park        │
├───────────────────────────────────┤
│  Release to:                      │
│                                   │
│  ┌──────────┐   Meera Sharma      │
│  │ [photo]  │   Mother            │
│  └──────────┘   ✓ Authorised      │
│                                   │
│  [ SCAN PARENT'S CODE ]           │
│  [ ENTER CODE MANUALLY ]          │
├───────────────────────────────────┤
│  [Someone else is collecting]     │
└───────────────────────────────────┘
```

Authorised receivers are listed **with photos** — the attendant is verifying a face, and a name alone does not do that.

| Path | Behaviour |
|---|---|
| Guardian verified | Handover recorded (BRD-008) |
| Authorised pickup person, valid | Handover recorded; **all** guardians notified (NTF-HAND-02) |
| Pickup person expired | Refused; override path only (BR-GRD-005) |
| **Custody restriction** 🔴 | **Blocked**. Card explains the school has been alerted. No override offered. |
| Unverified adult | Override flow (D-09) |
| **Nobody present** | No-receiver flow (D-10) |

**The custody-restriction block offers no override on this screen.** The restriction is refused, recorded, and escalated (BR-HAND-006 🔴) — resolution happens through the school, not through a tap on a bus.

---

## D-09 — Handover Override 🔴

```
⚠ Releasing to an unverified adult

This will be recorded and all guardians will be
notified immediately.

Who is collecting?
Name    [_______________]      ← required
Phone   [_______________]

Reason  ( ) Guardian delayed, confirmed by phone
        ( ) Known to attendant
        ( ) Instructed by school office
        ( ) Other

                    [Cancel]  [Confirm release]
```

**Structured reasons, not free text.** The attendant is standing at a stop with children waiting — typing a paragraph is not realistic, and a free-text field under pressure yields "ok" and nothing useful.

`Name` is required (BR-HAND-003 🔴) — an override recording "unverified adult" and nothing else is not evidence.

On confirmation: all guardians and the transport manager notified immediately, `CRITICAL` (NTF-HAND-03).

---

## D-10 — No Receiver Present 🔴

```
No one is here to collect Aarav Sharma.

Aarav stays on the bus. The school and his
guardians are being contacted now.

                              [Understood]
```

**There is no path on this screen that discharges the child.** The student remains on the vehicle, a `NO_RECEIVER` incident is raised, and the escalation chain starts (BR-HAND-007 🔴).

This is the rule most likely to be argued away for operational convenience. The UI provides no affordance to do so.

---

## D-11 / D-12 — Trip End & Reconciliation 🔴

Ending a trip runs reconciliation (BR-SAFE-001 🔴).

```
┌───────────────────────────────────┐
│ ⚠ 1 STUDENT UNACCOUNTED           │
├───────────────────────────────────┤
│  Aarav Sharma                     │
│  Boarded 7:42 · no record of      │
│  getting off                      │
│                                   │
│  CHECK THE VEHICLE NOW            │
├───────────────────────────────────┤
│ [Found on vehicle]                │
│ [Got off — I missed the record]   │
│ [Never actually boarded]          │
└───────────────────────────────────┘
```

**The trip cannot be closed until every exception is resolved** (BR-TRIP-009). There is no dismiss, no "later", no back gesture that skips it.

The instruction is an action, not a status: *check the vehicle now*. This screen exists for the one case where a child is asleep on a rear seat.

Resolution records outcome, actor, and time together (BR-SAFE-001).

---

## D-14 — Sync Status

```
⟳ All synced · last 15:47
```
```
⚠ 7 records waiting · offline since 15:31
```

**Always visible in the header.** Silent queuing hides failure from the person who most needs to know (Sunita). Tapping shows the pending records and a manual retry.

Local data is encrypted and wiped on logout or remote session revocation (ADR-0008) — driver devices are often shared.

---

## D-15 — SOS 🔴

Persistent overlay on **every screen**. 88 px. Reachable without looking.

```
Press and hold to send SOS
        [ ●●●○○ ]           ← 1.5s hold
```

Hold-to-confirm rather than tap — a pocket press must not raise a false alarm, but the gesture must remain performable in an emergency without precision.

Once sent: immediate confirmation, position attached, escalation chain runs until acknowledged (BR-SAFE-006 🔴). **No cancel** — a raised SOS is resolved, never deleted (BR-INC-006).

---

## Offline Behaviour (ADR-0008)

| Action | Offline |
|---|---|
| Start trip | ✓ if the manifest is cached |
| Board / alight | ✓ **always** |
| Handover | ✓ **always** — verification material is cached |
| Reconciliation | ✓ resolved locally, synced later |
| SOS | ✓ queued and retried aggressively; SMS fallback where available |
| Live map | ✗ degraded to stop list |

Manifest, guardian photos, and pickup-person details are cached at trip start so the whole trip runs offline if needed. A manifest past a configured age shows a warning — it does not lock the attendant out.

---

## Verification

1. Every touch target ≥64 px; SOS ≥88 px.
2. No free-text input on any in-motion flow.
3. A full trip's boarding works with the network disabled, survives an app restart, and syncs exactly once.
4. Boarding feedback is visual, audible, and haptic.
5. Wrong-vehicle detection blocks with a card requiring a decision.
6. Departing with un-boarded students requires confirmation naming them.
7. A custody-restricted handover offers no override affordance.
8. The no-receiver screen has no path that discharges the child.
9. Trip close is impossible with an unresolved exception.
10. Pending-sync count is visible on every screen.
11. Logout wipes the encrypted local store.
12. SOS requires a deliberate hold and cannot be cancelled once sent.
