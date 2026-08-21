# NOTIFICATION CATALOG

**Document tier:** 1 — Product Discovery
**Status:** Active

Every notification the platform sends. Format: `NTF-<AREA>-<nn>`.

Notification is the product's primary output to parents ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §2). This catalog is therefore a product document, not a technical one — the technical delivery mechanism is in [`NOTIFICATION_ARCHITECTURE.md`](../02-system-design/NOTIFICATION_ARCHITECTURE.md).

---

## Priority Classes

| Class | Respects preferences? | Respects quiet hours? | Channels |
|---|---|---|---|
| 🔴 `CRITICAL` | **No** (BR-NTF-006) | **No** | All available, with fallback escalation |
| 🟠 `URGENT` | Channel choice only | No | Push + SMS |
| 🟡 `STANDARD` | Yes | Yes — deferred, not discarded (BR-NTF-004) | Per preference |
| ⚪ `INFO` | Yes | Yes | In-app, optional push |

**The `CRITICAL` class is the exception that makes the rest safe.** A parent may mute everything else precisely because the events that matter will always arrive.

---

## Copy Principles

Derived from [`PERSONAS.md`](PERSONAS.md) (Meera) and [`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §2:

1. **Complete in the first line.** Readable from a lock screen without opening the app.
2. **Named child, named place, stated time.** *"Aarav boarded Bus 12 at Green Park, 7:42 AM."*
3. **Calm for routine events, direct for urgent ones.** Graded language matching graded severity.
4. **Never another family's child** (BR-NTF-007). No passenger lists, no other names, ever.
5. **Localised resource keys only** (BR-CFG-005). No inline strings.
6. **Times in the school's time zone** (BR-CFG-006).

---

## Boarding & Attendance

| ID | Event | Class | Recipients | Sample copy |
|---|---|---|---|---|
| NTF-BOARD-01 | Student boarded | 🟡 | Guardians with notify right | "Aarav boarded Bus 12 at Green Park, 7:42 AM." |
| NTF-BOARD-02 | Student alighted at school | 🟡 | Guardians | "Aarav arrived at school, 8:15 AM." |
| NTF-BOARD-03 | Student alighted at stop | 🟡 | Guardians | "Aarav got off at Green Park, 3:20 PM." |
| NTF-BOARD-04 | No-show at stop (BR-SAFE-002) | 🟠 | Guardians | "Aarav did not board Bus 12 at Green Park this morning." |
| NTF-BOARD-05 | Boarded despite declared absence (BR-BOARD-007) | 🟠 | Guardians, transport manager | "Aarav was marked absent but boarded Bus 12 at 7:44 AM." |
| NTF-BOARD-06 | Alighted at a different stop (BR-BOARD-004) | 🟠 | Guardians, transport manager | "Aarav got off at Ring Road, not his usual stop, at 3:31 PM." |
| NTF-BOARD-07 | Wrong-vehicle detection (BR-SAFE-003) | 🔴 | Guardians, both trips' staff, transport manager | "Aarav boarded Bus 7. He is expected on Bus 12. Staff have been alerted." |

## Handover

| ID | Event | Class | Recipients | Sample copy |
|---|---|---|---|---|
| NTF-HAND-01 | Handover completed | 🟡 | Guardians | "Aarav was handed over to Meera Sharma at 3:20 PM." |
| NTF-HAND-02 | Handover to authorised pickup person | 🟠 | All guardians | "Aarav was handed over to Sunil Kumar (authorised pickup) at 3:21 PM." |
| NTF-HAND-03 | Handover override (BR-HAND-003) | 🔴 | **All** guardians, transport manager | "Aarav was released to an unverified adult at 3:22 PM. Reason recorded: [reason]. Please contact the school." |
| NTF-HAND-04 | Handover refused — custody restriction (BR-HAND-006) | 🔴 | Guardians without restriction, transport manager, school admin | "An unauthorised collection attempt for Aarav was refused at 3:19 PM." |
| NTF-HAND-05 | No receiver at stop (BR-HAND-007) | 🔴 | Guardians, transport manager | "No one was present to collect Aarav at Green Park. He is safe on the bus. We are contacting you." |
| NTF-HAND-06 | Student self-released | 🟡 | Guardians | "Aarav left the bus at Green Park, 3:20 PM." |

## Safety

| ID | Event | Class | Recipients | Sample copy |
|---|---|---|---|---|
| NTF-SAFE-01 | **Unaccounted child at trip close** (BR-SAFE-001) | 🔴 | Driver, attendant, transport manager, guardians | "Aarav has not been recorded leaving Bus 12. Staff are checking the vehicle now." |
| NTF-SAFE-02 | Unaccounted child resolved | 🟠 | Same recipients | "Aarav has been accounted for. [outcome]" |
| NTF-SAFE-03 | Safety alert unacknowledged, escalating (BR-SAFE-006) | 🔴 | Next escalation level | "Unacknowledged critical alert on Bus 12, raised [time]." |

**NTF-SAFE-01 is the platform's most important message.** It is delivered on every available channel, ignores every preference, and escalates until acknowledged.

## Trip & Tracking

| ID | Event | Class | Recipients | Sample copy |
|---|---|---|---|---|
| NTF-TRIP-01 | Trip started | ⚪ | Guardians | "Bus 12 has started its morning route." |
| NTF-TRIP-02 | Bus approaching stop (BR-ALERT-001) | 🟡 | Guardians at that stop | "Bus 12 is about 4 minutes from Green Park." |
| NTF-TRIP-03 | Trip delayed (BR-TRIP-010) | 🟠 | Guardians, transport manager | "Bus 12 is running about 15 minutes late this morning." |
| NTF-TRIP-04 | Trip cancelled (BR-TRIP-007) | 🟠 | Guardians, transport manager | "Bus 12's afternoon route is cancelled today. Reason: [reason]." |
| NTF-TRIP-05 | Signal lost during trip (BR-TRACK-005) | 🟡 | Transport manager | "Bus 12 has not reported its location for 12 minutes." |

## Alerts

| ID | Event | Class | Recipients |
|---|---|---|---|
| NTF-ALERT-01 | Route deviation (BR-ALERT-002) | 🟠 | Transport manager; guardians per severity policy |
| NTF-ALERT-02 | Overspeed (BR-ALERT-003) | 🟠 | Transport manager |
| NTF-ALERT-03 | Unscheduled stop (BR-ALERT-004) | 🟡 | Transport manager |

## Incidents

| ID | Event | Class | Recipients | Sample copy |
|---|---|---|---|---|
| NTF-INC-01 | SOS raised (BR-SAFE-004) | 🔴 | Escalation chain | "SOS from Bus 12, raised by [actor] at [time]. Location: [link]." |
| NTF-INC-02 | SOS escalation | 🔴 | Next level | "SOS on Bus 12 remains unacknowledged." |
| NTF-INC-03 | Incident affecting a student | 🟠 | That student's guardians | "There was an incident involving Aarav on Bus 12. [summary]" |
| NTF-INC-04 | Incident affecting a trip | 🟠 | All guardians on manifest | "Bus 12 was involved in an incident. All children are safe. [summary]" |
| NTF-INC-05 | Incident resolved | 🟡 | Original recipients | |

NTF-INC-04 goes to many families at once and must therefore never name any child (BR-NTF-007).

## Compliance & Administrative

| ID | Event | Class | Recipients |
|---|---|---|---|
| NTF-CMP-01 | Vehicle document expiring (BR-FLEET-003) | 🟡 | Transport manager |
| NTF-CMP-02 | Vehicle document expired — blocked (BR-FLEET-002) | 🟠 | Transport manager, school admin |
| NTF-CMP-03 | Staff credential expiring (BR-STAFF-003) | 🟡 | Transport manager |
| NTF-CMP-04 | Staff credential expired — blocked | 🟠 | Transport manager, school admin |
| NTF-ADM-01 | Guardian invitation | ⚪ | Guardian |
| NTF-ADM-02 | Absence confirmed (BR-ABS-001) | ⚪ | Declaring guardian |
| NTF-ADM-03 | Route or stop assignment changed | 🟡 | Guardians |
| NTF-ADM-04 | Authorised pickup person added (BR-GRD-006) | 🟠 | All guardians with handover right |
| NTF-ADM-05 | Authorised pickup person revoked | 🟡 | All guardians with handover right |
| NTF-SEC-01 | New device sign-in | 🟡 | The user |
| NTF-SEC-02 | Refresh-token reuse detected (BR-IAM-009) | 🟠 | The user, school admin |

---

## Rules for Adding a Notification

1. Assign the next ID in the area and a priority class.
2. Name recipients by **right**, never by role alone (BR-NTF-001).
3. Write sample copy that satisfies the copy principles above.
4. Add template keys for every supported locale and channel (BR-NTF-002).
5. `CRITICAL` class requires justification in review — the class is only protective while it stays small.

## Verification

- A test asserts every `CRITICAL` notification dispatches with preferences disabled and quiet hours active (BR-NTF-006).
- A test asserts no multi-recipient notification body can interpolate a student name (BR-NTF-007).
- A test asserts every catalog ID has a template in the default locale for each of its channels.
