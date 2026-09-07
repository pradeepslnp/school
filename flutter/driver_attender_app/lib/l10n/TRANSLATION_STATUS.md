# Translation status — guardian_driver (English / Kannada)

Tracks ADR-0013's Kannada content policy for this app: `lib/l10n/app_en.arb` is the complete,
real source of truth. `lib/l10n/app_kn.arb` currently carries the **same English text** as an
explicit, tracked placeholder for every key — not a silent gap, not an inline `TODO`. This
file is that tracking. Every key below has `pending-kn-translation` unless noted otherwise.

**Total resource keys: 46.** Both ARB files carry all 46 (verified: `app_kn.arb` mirrors
`app_en.arb` key-for-key).

**When Kannada translation happens:** update the value in `app_kn.arb` and change that row's
status below to `translated` (with translator name/date). Do not delete rows from this file
after translation — keep it as the per-key audit trail.

---

## Safety-relevant — require native-speaker sign-off before a Kannada value ships

ADR-0013: "Safety-critical copy … is called out explicitly in [this file] as requiring
native-speaker sign-off before a Kannada value ships, not just any translation." This app has
no trip/manifest/boarding UI yet (`_DutyScreen` is a placeholder), so none of the
`NTF-BOARD-*`/`NTF-HAND-*` family ADR-0013 names by example exists in this app's code today.
The surfaces below are this app's actual equivalent: they report the state of the encrypted
outbound queue that *will* hold boarding/handover records once those features exist, and they
are what a driver/attendant relies on to know whether child-safety data has left the device.
A mistranslation here can make someone believe unsynced safety records are safe when they are
not, or vice versa — that is a strictly higher bar than ordinary UI copy.

| Key | English value | Status |
|---|---|---|
| `signOutDialogBodyPending` | `{count, plural, one{{count} record has} other{{count} records have}} not been sent yet. Signing out sends what it can, then erases everything on this device.` | pending-kn-translation — **sign-off required** |
| `syncRecordsNeedReview` | `{count, plural, one{{count} record needs review} other{{count} records need review}}` | pending-kn-translation — **sign-off required** |
| `syncOfflinePendingRecords` | `Offline · {count, plural, one{{count} record} other{{count} records}} saved on this device, will send when back in range` | pending-kn-translation — **sign-off required** |
| `syncOfflineNoPending` | `Offline · nothing waiting to send` | pending-kn-translation — **sign-off required** |
| `syncSendingRecords` | `Sending {count, plural, one{{count} record} other{{count} records}}…` | pending-kn-translation — **sign-off required** |
| `syncAllSent` | `All records sent` | pending-kn-translation — **sign-off required** |
| `syncAllSentJustNow` | `All records sent · just now` | pending-kn-translation — **sign-off required** |
| `syncAllSentMinutesAgo` | `All records sent · {minutes} min ago` | pending-kn-translation — **sign-off required** |
| `syncAllSentHoursAgo` | `All records sent · {hours} h ago` | pending-kn-translation — **sign-off required** |

Considered and *not* flagged here: `sessionEndedRevoked` / `sessionEndedRefreshFailed`
(session-integrity copy, BR-IAM-007/009 — affects account security, not child-location or
custody data directly). A reviewer who disagrees should move them into the table above; the
call is documented, not hidden.

---

## Everything else — pending-kn-translation, standard review

### General / duty screen

| Key | English value |
|---|---|
| `cancel` | `Cancel` |
| `signOut` | `Sign out` |
| `launchScreenStartingLabel` | `Starting` |
| `dutyScreenTitle` | `Today` |
| `dutyScreenNoTripLoaded` | `No trip loaded` |
| `dutyScreenSignedInGeneric` | `Signed in.` |
| `dutyScreenSignedInAs` | `Signed in as {name}.` |
| `signOutDialogTitle` | `Sign out?` |
| `signOutDialogBodyNoPending` | `Records on this device will be erased.` |

### Sign-in — phone entry

| Key | English value |
|---|---|
| `phoneEntryTitle` | `Driver sign in` |
| `phoneEntrySubtitle` | `Enter your mobile number to receive a one-time code.` |
| `phoneFieldLabel` | `Mobile number` |
| `sendCodeButton` | `Send code` |

### Sign-in — one-time code entry

| Key | English value |
|---|---|
| `otpEntryTitle` | `Enter the code` |
| `otpEntrySubtitle` | `We sent a code to {phone}.` |
| `otpFieldLabel` | `Code` |
| `otpResentNotice` | `A new code has been sent.` |
| `verifyButton` | `Verify` |
| `changeNumberButton` | `Change number` |
| `resendCodeButton` | `Send a new code` |

### Sign-in errors

| Key | English value |
|---|---|
| `errorInvalidCode` | `That code was not correct. Check it and try again.` |
| `errorOtpExpired` | `That code has expired. Ask for a new one.` |
| `errorOtpAlreadyUsed` | `That code has already been used. Ask for a new one.` |
| `errorAccountLocked` | `This account is locked after too many attempts. Call the transport office.` |
| `errorRateLimited` | `Too many attempts. Wait a minute, then try again.` |
| `errorNoConnection` | `No connection. Move to where you have signal and try again.` |
| `errorValidationFailed` | `Check the details you entered.` |
| `errorSignInUnavailable` | `Sign-in is not working right now. Call the transport office.` |

### Session-ended notice

| Key | English value |
|---|---|
| `sessionEndedRevoked` | `Your session was ended by the school. Sign in again, or call the transport office if this keeps happening.` |
| `sessionEndedRefreshFailed` | `Your session expired. Sign in again to keep recording this trip.` |

### Misc

| Key | English value |
|---|---|
| `workingLabel` | `Working` |
| `signInTitle` | `Sign in` |

### Language switcher

| Key | English value | Status |
|---|---|---|
| `languageSwitcherTooltip` | `Change language` | pending-kn-translation |
| `languagePickerTitle` | `Language` | pending-kn-translation |
| `languageOptionSystemDefault` | `Match device` | pending-kn-translation |
| `languageOptionEnglish` | `English` | **not applicable** — a language's own name in Latin script, judged invariant across every locale's ARB rather than translatable content (same reasoning as flag emoji / proper nouns in most i18n style guides). Identical value in both files by design, not a placeholder. |
| `languageOptionKannada` | `ಕನ್ನಡ` | **not applicable** — the Kannada endonym, shown in Kannada's own script regardless of the app's current language, which is the standard convention for language pickers (so the option is recognisable to a reader who cannot read the surrounding UI language at all). Identical value in both files by design, not a placeholder — this is the one key in the whole ARB pair where the "value" is already Kannada script, and that is intentional, not an oversight of ADR-0013's English-fallback policy. |

---

## Notes for the translator

- ICU plural messages (`signOutDialogBodyPending`, `syncRecordsNeedReview`,
  `syncOfflinePendingRecords`, `syncSendingRecords`) use `{count, plural, one{…} other{…}}`.
  Kannada's CLDR plural rule set also has `one`/`other` categories, so the same two-branch
  structure carries over — translate both branches, keep the `{count}` placeholder token
  exactly as written in each branch.
- `{name}` and `{phone}` are runtime values (a person's name, a phone number) — keep the
  placeholder token, translate only the surrounding sentence.
- `·` (middle dot) in `syncOfflinePendingRecords`, `syncAllSentJustNow`,
  `syncAllSentMinutesAgo`, `syncAllSentHoursAgo` is a visual separator, not punctuation to
  translate — keep it, or use the equivalent conventional separator if Kannada UI copy
  elsewhere in the platform establishes one.
