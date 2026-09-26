# Translation status — parent_app

Generated for ADR-0013 (interim client-bundled localisation, English/Kannada). Every
resource key in `app_en.arb` is listed here with its English value and status.

**Current status (2026-09-23): every key carries a Kannada value, drafted by an AI assistant
at the product owner's request — not yet reviewed by a native speaker.** `app_kn.arb` previously
held the English value as a tracked placeholder, so the app showed English when a parent chose
Kannada; that is what prompted this pass.

Two keys stay in English deliberately: `appTitle` (the product name) and `dashboardGreeting`
(placeholders only, no words of its own).

**The safety-critical table below is not cleared by this pass.** ADR-0013's rule stands: a
Kannada value for wrong-bus, no-show, unaccounted-for, handover-authorisation or staleness copy
must be read by a native speaker before it reaches a real family. Until then these strings are a
draft for testing, not shippable copy.

## Safety-critical / child-safety-relevant copy — needs native-speaker sign-off before a Kannada value ships

These keys surface wrong-bus / no-show / unaccounted-for / handover-authorisation / staleness
copy — the in-app equivalents of the `NTF-BOARD-*` / `NTF-HAND-*` / `NTF-SAFE-*` family in
`NOTIFICATION_CATALOG.md`. Per ADR-0013, a Kannada value for any key in this section must be
reviewed by a native speaker before it ships — a plausible-looking but unverified translation
of safety-relevant copy is a real safety risk in this product, not a cosmetic one.

| Key | English value | Status |
|---|---|---|
| `detailUnaccounted` | No record of {name} getting off the bus. The school has been alerted and is checking now. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerMessage` | {name} has not been accounted for. The school has been alerted and staff are checking now. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerUrgentSemanticLabel` | Urgent. {message} | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerActionNeeded` | ACTION NEEDED NOW | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerNotAccountedTitle` | Not yet accounted for | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerCallSchoolButton` | Call the school | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `criticalBannerSeeWhatHappenedButton` | See what happened | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `freshnessNoSignalFor` | No signal for {age} | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `freshnessLastSeen` | Last seen {age} ago | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `journeyStateDidNotBoard` | Did not board | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `journeyStateNotAccountedFor` | Not yet accounted for | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `legBusDepartedAt` | Bus departed at {time} | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `liveTripEstimateCalculated` | Estimate calculated {ago}{confidence}. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `handoverQrSemanticLabel` | Verification QR code for {name} | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `handoverErrorNotAuthorised` | You do not hold the right to collect this child (BR-GRD-006). Contact another guardian who does, or the school office. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `handoverGenericFailure` | Something went wrong requesting a code. Please try again. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `pickupPersonsExpiredSuffix` |  · expired | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |
| `pickupPersonsErrorNotAuthorised` | You do not hold the right to authorise pickups for this child (BR-GRD-006). Contact another guardian who does, or the school office. | kn-drafted — NATIVE-SPEAKER SIGN-OFF REQUIRED |

(18 keys)

## All other resource keys

| Key | English value | Status |
|---|---|---|
| `appTitle` | Guardian | kn-drafted — review welcome |
| `tryAgainButton` | Try again | kn-drafted — review welcome |
| `cancelButton` | Cancel | kn-drafted — review welcome |
| `retryButton` | Retry | kn-drafted — review welcome |
| `whichChildLabel` | Which child? | kn-drafted — review welcome |
| `trackBusButton` | Track bus | kn-drafted — review welcome |
| `mapViewLabel` | Map view | kn-drafted — review welcome |
| `errorDependencyUnavailable` | Your device cannot reach the school right now. Check your connection and try again. | kn-drafted — review welcome |
| `errorRateLimited` | Too many attempts just now. Wait a moment and try again. | kn-drafted — review welcome |
| `errorGenericTryAgain` | Something went wrong. Please try again. | kn-drafted — review welcome |
| `noChildrenLinkedTitle` | No children linked yet | kn-drafted — review welcome |
| `noChildrenLinkedDetail` | Your school links your children to your account. | kn-drafted — review welcome |
| `dayLabelToday` | Today | kn-drafted — review welcome |
| `dayLabelYesterday` | Yesterday | kn-drafted — review welcome |
| `relativeDayToday` | today | kn-drafted — review welcome |
| `relativeDayTomorrow` | tomorrow | kn-drafted — review welcome |
| `durationSeconds` | {seconds}s | kn-drafted — review welcome |
| `durationMinutes` | {minutes} min | kn-drafted — review welcome |
| `durationHours` | {hours} h | kn-drafted — review welcome |
| `atTimeFragment` | at {time} | kn-drafted — review welcome |
| `themeModeSystem` | Match device | kn-drafted — review welcome |
| `themeModeLight` | Light | kn-drafted — review welcome |
| `themeModeDark` | Dark | kn-drafted — review welcome |
| `themeToggleTooltip` | Appearance: {mode} | kn-drafted — review welcome |
| `languageSwitcherTooltip` | Language | kn-drafted — review welcome |
| `languageSwitcherDialogTitle` | Choose language | kn-drafted — review welcome |
| `navHomeTab` | Home | kn-drafted — review welcome |
| `navJourneysTab` | Journeys | kn-drafted — review welcome |
| `navAlertsTab` | Alerts | kn-drafted — review welcome |
| `navPickupTab` | Pickup | kn-drafted — review welcome |
| `homeAppBarTitle` | My children | kn-drafted — review welcome |
| `refreshTooltip` | Refresh | kn-drafted — review welcome |
| `homeLoadFailureTitle` | Cannot reach the school right now | kn-drafted — review welcome |
| `homeNoChildrenDetail` | Your school links your children to your account. Contact the school office if you expect to see someone here. | kn-drafted — review welcome |
| `homeGenericLoadFailure` | Something went wrong loading your children. Please try again. | kn-drafted — review welcome |
| `fallbackVehicleName` | the bus | kn-drafted — review welcome |
| `fallbackStopName` | your stop | kn-drafted — review welcome |
| `connectionBannerNoData` | Not connected. Nothing has loaded yet. | kn-drafted — review welcome |
| `connectionBannerLastUpdated` | Not connected · last updated {time} | kn-drafted — review welcome |
| `greetingMorning` | Good morning | kn-drafted — review welcome |
| `greetingAfternoon` | Good afternoon | kn-drafted — review welcome |
| `greetingEvening` | Good evening | kn-drafted — review welcome |
| `dashboardGreeting` | {greeting}, {name} | kn-drafted — review welcome |
| `schoolTimeZoneSemanticLabel` | All times are shown in school time, {zone}. | kn-drafted — review welcome |
| `schoolTimeLabel` | School time · {zone} | kn-drafted — review welcome |
| `arrivalEstimateWithAge` | Arriving at school about {eta} · estimated {age} ago | kn-drafted — review welcome |
| `arrivalEstimateNoAge` | Arriving at school about {eta} · estimate | kn-drafted — review welcome |
| `detailAtRestNextBus` | At school. Next bus at {time}. | kn-drafted — review welcome |
| `detailAtRestNoBus` | At school. No bus scheduled for the rest of today. | kn-drafted — review welcome |
| `detailAbsent` | You marked {name} as not travelling today. | kn-drafted — review welcome |
| `detailScheduledVehicle` | {vehicle} is scheduled | kn-drafted — review welcome |
| `detailFromStop` | from {stop} | kn-drafted — review welcome |
| `detailAtEta` | at about {eta} | kn-drafted — review welcome |
| `detailVehicleOnWay` | {vehicle} is on the way | kn-drafted — review welcome |
| `detailToStop` | to {stop} | kn-drafted — review welcome |
| `detailArrivingAbout` | · arriving about {eta} | kn-drafted — review welcome |
| `detailBoardedWord` | Boarded | kn-drafted — review welcome |
| `detailAtStop` | at {stop} | kn-drafted — review welcome |
| `detailArrivedAtTime` | Arrived at school at {time}. | kn-drafted — review welcome |
| `detailArrivedNoTime` | Arrived at school. | kn-drafted — review welcome |
| `detailHandedOverWord` | Handed over | kn-drafted — review welcome |
| `detailDidNotBoardWord` | Did not board | kn-drafted — review welcome |
| `detailBusDepartedAt` | · bus departed {time} | kn-drafted — review welcome |
| `detailUnknown` | This version of the app cannot read {name}''s current status. Update the app, or contact the school office to check. | kn-drafted — review welcome |
| `quickActionsTitle` | Quick actions | kn-drafted — review welcome |
| `quickActionDeclareAbsence` | Declare absence | kn-drafted — review welcome |
| `quickActionPickupPersons` | Pickup persons | kn-drafted — review welcome |
| `freshnessNoSignal` | No signal | kn-drafted — review welcome |
| `freshnessLive` | Live · updated {age} ago | kn-drafted — review welcome |
| `journeyStateAtSchool` | At school | kn-drafted — review welcome |
| `journeyStateBusScheduled` | Bus scheduled | kn-drafted — review welcome |
| `journeyStateBusOnWay` | Bus on the way | kn-drafted — review welcome |
| `journeyStateOnBus` | On the bus | kn-drafted — review welcome |
| `journeyStateArrivedAtSchool` | Arrived at school | kn-drafted — review welcome |
| `journeyStateHandedOver` | Handed over | kn-drafted — review welcome |
| `journeyStateNotTravelling` | Not travelling today | kn-drafted — review welcome |
| `journeyStateUnavailable` | Status unavailable | kn-drafted — review welcome |
| `absenceAppBarTitle` | Declare absence | kn-drafted — review welcome |
| `absenceWhenLabel` | When? | kn-drafted — review welcome |
| `absenceWhenToday` | Today | kn-drafted — review welcome |
| `absenceWhenTomorrow` | Tomorrow | kn-drafted — review welcome |
| `absenceWhenDateRange` | Date range | kn-drafted — review welcome |
| `absenceWhichJourney` | Which journey? | kn-drafted — review welcome |
| `absenceJourneyBoth` | Both | kn-drafted — review welcome |
| `absenceJourneyMorning` | Morning | kn-drafted — review welcome |
| `absenceJourneyAfternoon` | Afternoon | kn-drafted — review welcome |
| `absenceReasonLabel` | Reason (optional) | kn-drafted — review welcome |
| `absenceReasonHint` | Not required | kn-drafted — review welcome |
| `absenceConfirmButton` | Confirm | kn-drafted — review welcome |
| `absenceUpcomingTitle` | Upcoming absences | kn-drafted — review welcome |
| `absenceNoneDeclared` | No absences declared for this child. | kn-drafted — review welcome |
| `absenceDateRangeChoose` | Choose dates | kn-drafted — review welcome |
| `absenceTileJourneyBoth` | Both journeys | kn-drafted — review welcome |
| `absenceTileJourneyMorning` | Morning only | kn-drafted — review welcome |
| `absenceTileJourneyAfternoon` | Afternoon only | kn-drafted — review welcome |
| `absenceNoChildrenLinked` | Your school links your children to your account before you can declare an absence. | kn-drafted — review welcome |
| `absenceErrorTripStarted` | This trip has already started, so this absence cannot be declared. Contact the school office instead. | kn-drafted — review welcome |
| `absenceConfirmationMessage` | {childName} will not be expected {when}{direction, select, morningOnly{ in the morning} afternoonOnly{ in the afternoon} other{}}. | kn-drafted — review welcome |
| `absenceConfirmationRange` | from {from} to {to} | kn-drafted — review welcome |
| `journeyHistoryAppBarTitle` | Journey history | kn-drafted — review welcome |
| `journeyHistoryScopeDenied` | This child is no longer linked to your account. Contact the school office if you think that is wrong. | kn-drafted — review welcome |
| `journeyHistoryGenericFailure` | Something went wrong loading journey history. Please try again. | kn-drafted — review welcome |
| `journeyHistoryLoadFailureTitle` | Cannot load journey history right now | kn-drafted — review welcome |
| `journeyHistoryEmptyTitle` | No journeys recorded yet | kn-drafted — review welcome |
| `journeyHistoryEmptyDetail` | Past trips will appear here once your child has traveled. | kn-drafted — review welcome |
| `legDirectionMorning` | Morning | kn-drafted — review welcome |
| `legDirectionAfternoon` | Afternoon | kn-drafted — review welcome |
| `legMarkedAbsent` | Marked absent | kn-drafted — review welcome |
| `legNoRecordForLeg` | No record for this leg | kn-drafted — review welcome |
| `legNoScheduleForLeg` | No schedule for this leg | kn-drafted — review welcome |
| `legScheduledAt` | Scheduled at {time} | kn-drafted — review welcome |
| `legBoardedAt` | Boarded at {time} | kn-drafted — review welcome |
| `legArrivedAt` | Arrived at {time} | kn-drafted — review welcome |
| `legHandedOverAt` | Handed over at {time} | kn-drafted — review welcome |
| `childDetailNoDetailAvailable` | No detail available for this child. | kn-drafted — review welcome |
| `childDetailTodayLabel` | Today | kn-drafted — review welcome |
| `childDetailNoTripsToday` | No trips scheduled for today. | kn-drafted — review welcome |
| `childDetailShowPickupCodeButton` | Show pickup code | kn-drafted — review welcome |
| `childDetailScopeDenied` | This child is no longer linked to your account. Contact the school office if you think that is wrong. | kn-drafted — review welcome |
| `childDetailGenericFailure` | Something went wrong loading this child''s detail. Please try again. | kn-drafted — review welcome |
| `liveTripGenericFailure` | Something went wrong loading this trip. Please try again. | kn-drafted — review welcome |
| `liveTripAppBarTitle` | Live trip | kn-drafted — review welcome |
| `liveTripUnavailableTitle` | Tracking is not available right now | kn-drafted — review welcome |
| `liveTripUnavailableDetail` | Live tracking only runs while the bus is on a trip (docs/05-ui/PARENT_APP.md, BR-TRACK-001). Check back once the trip has started. | kn-drafted — review welcome |
| `liveTripCannotLoadTitle` | Cannot load this trip right now | kn-drafted — review welcome |
| `liveTripNoTripTitle` | No trip to show | kn-drafted — review welcome |
| `liveTripNoTripDetail` | This child has no active trip right now. | kn-drafted — review welcome |
| `liveTripSummaryStopsAway` | {stops} {stops, plural, one{stop} other{stops}} away | kn-drafted — review welcome |
| `liveTripSummaryEtaToStop` | ~{eta} min to {stop} | kn-drafted — review welcome |
| `liveTripEtaConfidenceModerate` |  · moderate confidence | kn-drafted — review welcome |
| `liveTripEtaConfidenceLow` |  · low confidence — routing unavailable | kn-drafted — review welcome |
| `liveTripEtaJustNow` | just now | kn-drafted — review welcome |
| `liveTripEtaSecondsAgo` | {seconds}s ago | kn-drafted — review welcome |
| `liveTripEtaMinutesAgo` | {minutes} min ago | kn-drafted — review welcome |
| `handoverCollectChildTitleNoName` | Collect your child | kn-drafted — review welcome |
| `handoverCollectChildTitleWithName` | Collect {name} | kn-drafted — review welcome |
| `handoverShowToAttendant` | Show this to the bus attendant | kn-drafted — review welcome |
| `handoverQrSemanticsLabelPlain` | Verification QR code | kn-drafted — review welcome |
| `handoverIfCannotScan` | If the attendant cannot scan | kn-drafted — review welcome |
| `handoverGenerateNewCode` | Generate a new code | kn-drafted — review welcome |
| `handoverCodeExpired` | This code has expired | kn-drafted — review welcome |
| `handoverExpiresInMinSec` | Expires in {minutes}:{seconds} | kn-drafted — review welcome |
| `handoverExpiresInSeconds` | Expires in {seconds}s | kn-drafted — review welcome |
| `pickupPersonsAppBarTitle` | Pickup persons | kn-drafted — review welcome |
| `pickupPersonsAddButton` | Add pickup person | kn-drafted — review welcome |
| `pickupPersonsNoneAuthorised` | No pickup persons authorised for this child. | kn-drafted — review welcome |
| `pickupPersonsRevokeButton` | Revoke | kn-drafted — review welcome |
| `pickupPersonsValidRange` | Valid {from} – {to} | kn-drafted — review welcome |
| `pickupPersonsNewPersonTitle` | New pickup person | kn-drafted — review welcome |
| `pickupPersonsFullNameLabel` | Full name | kn-drafted — review welcome |
| `pickupPersonsPhoneLabel` | Phone number | kn-drafted — review welcome |
| `pickupPersonsRelationshipLabel` | Relationship (optional) | kn-drafted — review welcome |
| `pickupPersonsRelationshipHint` | e.g. Uncle | kn-drafted — review welcome |
| `pickupPersonsValidityChoose` | Choose validity window | kn-drafted — review welcome |
| `pickupPersonsNominateButton` | Nominate | kn-drafted — review welcome |
| `pickupPersonsErrorOutsideValidity` | That validity window has already passed. | kn-drafted — review welcome |
| `pickupPersonsNoChildrenLinked` | Your school links your children to your account before you can manage pickup persons. | kn-drafted — review welcome |
| `notificationsAppBarTitle` | Notifications | kn-drafted — review welcome |
| `notificationsGenericFailure` | Something went wrong loading your notifications. Please try again. | kn-drafted — review welcome |
| `notificationsLoadFailureTitle` | Cannot load notifications right now | kn-drafted — review welcome |
| `notificationsEmptyTitle` | No notifications yet | kn-drafted — review welcome |
| `notificationsEmptyDetail` | You''ll see updates about your children here. | kn-drafted — review welcome |
| `otpAppBarTitle` | Enter code | kn-drafted — review welcome |
| `otpHeading` | Enter the code | kn-drafted — review welcome |
| `otpSentTo` | We sent a code to {phone}. | kn-drafted — review welcome |
| `otpCodeLabel` | Code | kn-drafted — review welcome |
| `otpVerifyButton` | Verify | kn-drafted — review welcome |
| `otpEntryChangeNumberButton` | Change number | kn-drafted — review welcome |
| `otpEntrySendNewCodeButton` | Send a new code | kn-drafted — review welcome |
| `loginHeading` | Sign in | kn-drafted — review welcome |
| `simpleLoginParentHeading` | Parent sign in | kn-drafted — review welcome |
| `loginInstructions` | Enter the mobile number registered with your school. | kn-drafted — review welcome |
| `loginMobileNumberLabel` | Mobile number | kn-drafted — review welcome |
| `loginSendCodeButton` | Send code | kn-drafted — review welcome |
| `loginErrorCredentialsInvalid` | That code is not correct. Please check and try again. | kn-drafted — review welcome |
| `loginErrorOtpExpired` | That code has expired. Tap “Send a new code” to get another. | kn-drafted — review welcome |
| `loginErrorOtpAlreadyUsed` | That code has already been used. Tap “Send a new code”. | kn-drafted — review welcome |
| `loginErrorAccountLocked` | This account is locked. Please contact the school office. | kn-drafted — review welcome |
| `loginErrorRateLimited` | Too many attempts. Please wait a minute before trying again. | kn-drafted — review welcome |
| `loginErrorDependencyUnavailable` | Cannot reach the school right now. Check your connection and try again. | kn-drafted — review welcome |

(180 keys)

## Notes for whoever does the Kannada pass

- **Total resource keys: 198.** `app_kn.arb` has exactly this many keys —
  none silently missing (ADR-0013 verification item 4).
- A number of dashboard/child-status strings (`detail*` keys, e.g. `detailScheduledVehicle`,
  `detailFromStop`, `detailAtEta`, `detailBoardedWord`, `detailAtStop`, `legScheduledAt`, etc.)
  are short *fragments* that the app concatenates in Dart (with spaces or `·`) to build a
  sentence, rather than one whole-sentence template per journey state. That preserves the
  original code's behaviour exactly, but fragment concatenation assumes English word order —
  it will not automatically produce fluent Kannada grammar. Whoever does the native-speaker
  pass should flag if any of these read badly once translated word-for-word, so a follow-up
  can restructure the composition (not just the words) for that family of keys.
- `absenceConfirmationMessage` uses ICU `select` on `direction` (`morningOnly` / `afternoonOnly`
  / `other`) embedded in one sentence — translate the whole template, keeping the `{when}` and
  `{direction, select, ...}` placeholders and selectors intact.
- `liveTripSummaryStopsAway` uses ICU `plural` (`one` / `other`) on `stops` — Kannada plural
  rules differ from English; use the correct CLDR plural category, not a literal copy of the
  English `one`/`other` split.
- Language names in the in-app language switcher (`home_screen.dart`'s `_LanguageSwitcherButton`)
  are **not** ARB keys — "English" and "ಕನ್ನಡ" are hardcoded as each language's own endonym,
  shown the same way regardless of the active locale (the standard pattern for a language
  picker: a user who can't read the current language still needs to find their own). Nothing
  to translate there.
- Weekday and month names (journey history, notifications day grouping) are formatted through
  `intl`'s `DateFormat`, not ARB keys — Kannada calendar names come from `intl`'s locale data,
  not from a translation pass on this file.
