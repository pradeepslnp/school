# Translation status — parent_app

Generated for ADR-0013 (interim client-bundled localisation, English/Kannada). Every
resource key in `app_en.arb` is listed here with its English value and status.

**Current status for every key below: `pending-kn-translation`.** `app_kn.arb` currently
holds the English value as an explicit, tracked placeholder for every key — not a real
Kannada translation, and not silently missing either. This is deliberate per ADR-0013: an
honest, reviewable gap rather than an unreviewed machine translation, especially for
safety-critical copy.

## Safety-critical / child-safety-relevant copy — needs native-speaker sign-off before a Kannada value ships

These keys surface wrong-bus / no-show / unaccounted-for / handover-authorisation / staleness
copy — the in-app equivalents of the `NTF-BOARD-*` / `NTF-HAND-*` / `NTF-SAFE-*` family in
`NOTIFICATION_CATALOG.md`. Per ADR-0013, a Kannada value for any key in this section must be
reviewed by a native speaker before it ships — a plausible-looking but unverified translation
of safety-relevant copy is a real safety risk in this product, not a cosmetic one.

| Key | English value | Status |
|---|---|---|
| `detailUnaccounted` | No record of {name} getting off the bus. The school has been alerted and is checking now. | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerMessage` | {name} has not been accounted for. The school has been alerted and staff are checking now. | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerUrgentSemanticLabel` | Urgent. {message} | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerActionNeeded` | ACTION NEEDED NOW | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerNotAccountedTitle` | Not yet accounted for | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerCallSchoolButton` | Call the school | pending-kn-translation — native-speaker sign-off required |
| `criticalBannerSeeWhatHappenedButton` | See what happened | pending-kn-translation — native-speaker sign-off required |
| `freshnessNoSignalFor` | No signal for {age} | pending-kn-translation — native-speaker sign-off required |
| `freshnessLastSeen` | Last seen {age} ago | pending-kn-translation — native-speaker sign-off required |
| `journeyStateDidNotBoard` | Did not board | pending-kn-translation — native-speaker sign-off required |
| `journeyStateNotAccountedFor` | Not yet accounted for | pending-kn-translation — native-speaker sign-off required |
| `legBusDepartedAt` | Bus departed at {time} | pending-kn-translation — native-speaker sign-off required |
| `liveTripEstimateCalculated` | Estimate calculated {ago}{confidence}. | pending-kn-translation — native-speaker sign-off required |
| `handoverQrSemanticLabel` | Verification QR code for {name} | pending-kn-translation — native-speaker sign-off required |
| `handoverErrorNotAuthorised` | You do not hold the right to collect this child (BR-GRD-006). Contact another guardian who does, or the school office. | pending-kn-translation — native-speaker sign-off required |
| `handoverGenericFailure` | Something went wrong requesting a code. Please try again. | pending-kn-translation — native-speaker sign-off required |
| `pickupPersonsExpiredSuffix` |  · expired | pending-kn-translation — native-speaker sign-off required |
| `pickupPersonsErrorNotAuthorised` | You do not hold the right to authorise pickups for this child (BR-GRD-006). Contact another guardian who does, or the school office. | pending-kn-translation — native-speaker sign-off required |

(18 keys)

## All other resource keys

| Key | English value | Status |
|---|---|---|
| `appTitle` | Guardian | pending-kn-translation |
| `tryAgainButton` | Try again | pending-kn-translation |
| `cancelButton` | Cancel | pending-kn-translation |
| `retryButton` | Retry | pending-kn-translation |
| `whichChildLabel` | Which child? | pending-kn-translation |
| `trackBusButton` | Track bus | pending-kn-translation |
| `mapViewLabel` | Map view | pending-kn-translation |
| `errorDependencyUnavailable` | Your device cannot reach the school right now. Check your connection and try again. | pending-kn-translation |
| `errorRateLimited` | Too many attempts just now. Wait a moment and try again. | pending-kn-translation |
| `errorGenericTryAgain` | Something went wrong. Please try again. | pending-kn-translation |
| `noChildrenLinkedTitle` | No children linked yet | pending-kn-translation |
| `noChildrenLinkedDetail` | Your school links your children to your account. | pending-kn-translation |
| `dayLabelToday` | Today | pending-kn-translation |
| `dayLabelYesterday` | Yesterday | pending-kn-translation |
| `relativeDayToday` | today | pending-kn-translation |
| `relativeDayTomorrow` | tomorrow | pending-kn-translation |
| `durationSeconds` | {seconds}s | pending-kn-translation |
| `durationMinutes` | {minutes} min | pending-kn-translation |
| `durationHours` | {hours} h | pending-kn-translation |
| `atTimeFragment` | at {time} | pending-kn-translation |
| `themeModeSystem` | Match device | pending-kn-translation |
| `themeModeLight` | Light | pending-kn-translation |
| `themeModeDark` | Dark | pending-kn-translation |
| `themeToggleTooltip` | Appearance: {mode} | pending-kn-translation |
| `languageSwitcherTooltip` | Language | pending-kn-translation |
| `languageSwitcherDialogTitle` | Choose language | pending-kn-translation |
| `navHomeTab` | Home | pending-kn-translation |
| `navJourneysTab` | Journeys | pending-kn-translation |
| `navAlertsTab` | Alerts | pending-kn-translation |
| `navPickupTab` | Pickup | pending-kn-translation |
| `homeAppBarTitle` | My children | pending-kn-translation |
| `refreshTooltip` | Refresh | pending-kn-translation |
| `homeLoadFailureTitle` | Cannot reach the school right now | pending-kn-translation |
| `homeNoChildrenDetail` | Your school links your children to your account. Contact the school office if you expect to see someone here. | pending-kn-translation |
| `homeGenericLoadFailure` | Something went wrong loading your children. Please try again. | pending-kn-translation |
| `fallbackVehicleName` | the bus | pending-kn-translation |
| `fallbackStopName` | your stop | pending-kn-translation |
| `connectionBannerNoData` | Not connected. Nothing has loaded yet. | pending-kn-translation |
| `connectionBannerLastUpdated` | Not connected · last updated {time} | pending-kn-translation |
| `greetingMorning` | Good morning | pending-kn-translation |
| `greetingAfternoon` | Good afternoon | pending-kn-translation |
| `greetingEvening` | Good evening | pending-kn-translation |
| `dashboardGreeting` | {greeting}, {name} | pending-kn-translation |
| `schoolTimeZoneSemanticLabel` | All times are shown in school time, {zone}. | pending-kn-translation |
| `schoolTimeLabel` | School time · {zone} | pending-kn-translation |
| `arrivalEstimateWithAge` | Arriving at school about {eta} · estimated {age} ago | pending-kn-translation |
| `arrivalEstimateNoAge` | Arriving at school about {eta} · estimate | pending-kn-translation |
| `detailAtRestNextBus` | At school. Next bus at {time}. | pending-kn-translation |
| `detailAtRestNoBus` | At school. No bus scheduled for the rest of today. | pending-kn-translation |
| `detailAbsent` | You marked {name} as not travelling today. | pending-kn-translation |
| `detailScheduledVehicle` | {vehicle} is scheduled | pending-kn-translation |
| `detailFromStop` | from {stop} | pending-kn-translation |
| `detailAtEta` | at about {eta} | pending-kn-translation |
| `detailVehicleOnWay` | {vehicle} is on the way | pending-kn-translation |
| `detailToStop` | to {stop} | pending-kn-translation |
| `detailArrivingAbout` | · arriving about {eta} | pending-kn-translation |
| `detailBoardedWord` | Boarded | pending-kn-translation |
| `detailAtStop` | at {stop} | pending-kn-translation |
| `detailArrivedAtTime` | Arrived at school at {time}. | pending-kn-translation |
| `detailArrivedNoTime` | Arrived at school. | pending-kn-translation |
| `detailHandedOverWord` | Handed over | pending-kn-translation |
| `detailDidNotBoardWord` | Did not board | pending-kn-translation |
| `detailBusDepartedAt` | · bus departed {time} | pending-kn-translation |
| `detailUnknown` | This version of the app cannot read {name}''s current status. Update the app, or contact the school office to check. | pending-kn-translation |
| `quickActionsTitle` | Quick actions | pending-kn-translation |
| `quickActionDeclareAbsence` | Declare absence | pending-kn-translation |
| `quickActionPickupPersons` | Pickup persons | pending-kn-translation |
| `freshnessNoSignal` | No signal | pending-kn-translation |
| `freshnessLive` | Live · updated {age} ago | pending-kn-translation |
| `journeyStateAtSchool` | At school | pending-kn-translation |
| `journeyStateBusScheduled` | Bus scheduled | pending-kn-translation |
| `journeyStateBusOnWay` | Bus on the way | pending-kn-translation |
| `journeyStateOnBus` | On the bus | pending-kn-translation |
| `journeyStateArrivedAtSchool` | Arrived at school | pending-kn-translation |
| `journeyStateHandedOver` | Handed over | pending-kn-translation |
| `journeyStateNotTravelling` | Not travelling today | pending-kn-translation |
| `journeyStateUnavailable` | Status unavailable | pending-kn-translation |
| `absenceAppBarTitle` | Declare absence | pending-kn-translation |
| `absenceWhenLabel` | When? | pending-kn-translation |
| `absenceWhenToday` | Today | pending-kn-translation |
| `absenceWhenTomorrow` | Tomorrow | pending-kn-translation |
| `absenceWhenDateRange` | Date range | pending-kn-translation |
| `absenceWhichJourney` | Which journey? | pending-kn-translation |
| `absenceJourneyBoth` | Both | pending-kn-translation |
| `absenceJourneyMorning` | Morning | pending-kn-translation |
| `absenceJourneyAfternoon` | Afternoon | pending-kn-translation |
| `absenceReasonLabel` | Reason (optional) | pending-kn-translation |
| `absenceReasonHint` | Not required | pending-kn-translation |
| `absenceConfirmButton` | Confirm | pending-kn-translation |
| `absenceUpcomingTitle` | Upcoming absences | pending-kn-translation |
| `absenceNoneDeclared` | No absences declared for this child. | pending-kn-translation |
| `absenceDateRangeChoose` | Choose dates | pending-kn-translation |
| `absenceTileJourneyBoth` | Both journeys | pending-kn-translation |
| `absenceTileJourneyMorning` | Morning only | pending-kn-translation |
| `absenceTileJourneyAfternoon` | Afternoon only | pending-kn-translation |
| `absenceNoChildrenLinked` | Your school links your children to your account before you can declare an absence. | pending-kn-translation |
| `absenceErrorTripStarted` | This trip has already started, so this absence cannot be declared. Contact the school office instead. | pending-kn-translation |
| `absenceConfirmationMessage` | {childName} will not be expected {when}{direction, select, morningOnly{ in the morning} afternoonOnly{ in the afternoon} other{}}. | pending-kn-translation |
| `absenceConfirmationRange` | from {from} to {to} | pending-kn-translation |
| `journeyHistoryAppBarTitle` | Journey history | pending-kn-translation |
| `journeyHistoryScopeDenied` | This child is no longer linked to your account. Contact the school office if you think that is wrong. | pending-kn-translation |
| `journeyHistoryGenericFailure` | Something went wrong loading journey history. Please try again. | pending-kn-translation |
| `journeyHistoryLoadFailureTitle` | Cannot load journey history right now | pending-kn-translation |
| `journeyHistoryEmptyTitle` | No journeys recorded yet | pending-kn-translation |
| `journeyHistoryEmptyDetail` | Past trips will appear here once your child has traveled. | pending-kn-translation |
| `legDirectionMorning` | Morning | pending-kn-translation |
| `legDirectionAfternoon` | Afternoon | pending-kn-translation |
| `legMarkedAbsent` | Marked absent | pending-kn-translation |
| `legNoRecordForLeg` | No record for this leg | pending-kn-translation |
| `legNoScheduleForLeg` | No schedule for this leg | pending-kn-translation |
| `legScheduledAt` | Scheduled at {time} | pending-kn-translation |
| `legBoardedAt` | Boarded at {time} | pending-kn-translation |
| `legArrivedAt` | Arrived at {time} | pending-kn-translation |
| `legHandedOverAt` | Handed over at {time} | pending-kn-translation |
| `childDetailNoDetailAvailable` | No detail available for this child. | pending-kn-translation |
| `childDetailTodayLabel` | Today | pending-kn-translation |
| `childDetailNoTripsToday` | No trips scheduled for today. | pending-kn-translation |
| `childDetailShowPickupCodeButton` | Show pickup code | pending-kn-translation |
| `childDetailScopeDenied` | This child is no longer linked to your account. Contact the school office if you think that is wrong. | pending-kn-translation |
| `childDetailGenericFailure` | Something went wrong loading this child''s detail. Please try again. | pending-kn-translation |
| `liveTripGenericFailure` | Something went wrong loading this trip. Please try again. | pending-kn-translation |
| `liveTripAppBarTitle` | Live trip | pending-kn-translation |
| `liveTripUnavailableTitle` | Tracking is not available right now | pending-kn-translation |
| `liveTripUnavailableDetail` | Live tracking only runs while the bus is on a trip (docs/05-ui/PARENT_APP.md, BR-TRACK-001). Check back once the trip has started. | pending-kn-translation |
| `liveTripCannotLoadTitle` | Cannot load this trip right now | pending-kn-translation |
| `liveTripNoTripTitle` | No trip to show | pending-kn-translation |
| `liveTripNoTripDetail` | This child has no active trip right now. | pending-kn-translation |
| `liveTripSummaryStopsAway` | {stops} {stops, plural, one{stop} other{stops}} away | pending-kn-translation |
| `liveTripSummaryEtaToStop` | ~{eta} min to {stop} | pending-kn-translation |
| `liveTripEtaConfidenceModerate` |  · moderate confidence | pending-kn-translation |
| `liveTripEtaConfidenceLow` |  · low confidence — routing unavailable | pending-kn-translation |
| `liveTripEtaJustNow` | just now | pending-kn-translation |
| `liveTripEtaSecondsAgo` | {seconds}s ago | pending-kn-translation |
| `liveTripEtaMinutesAgo` | {minutes} min ago | pending-kn-translation |
| `handoverCollectChildTitleNoName` | Collect your child | pending-kn-translation |
| `handoverCollectChildTitleWithName` | Collect {name} | pending-kn-translation |
| `handoverShowToAttendant` | Show this to the bus attendant | pending-kn-translation |
| `handoverQrSemanticsLabelPlain` | Verification QR code | pending-kn-translation |
| `handoverIfCannotScan` | If the attendant cannot scan | pending-kn-translation |
| `handoverGenerateNewCode` | Generate a new code | pending-kn-translation |
| `handoverCodeExpired` | This code has expired | pending-kn-translation |
| `handoverExpiresInMinSec` | Expires in {minutes}:{seconds} | pending-kn-translation |
| `handoverExpiresInSeconds` | Expires in {seconds}s | pending-kn-translation |
| `pickupPersonsAppBarTitle` | Pickup persons | pending-kn-translation |
| `pickupPersonsAddButton` | Add pickup person | pending-kn-translation |
| `pickupPersonsNoneAuthorised` | No pickup persons authorised for this child. | pending-kn-translation |
| `pickupPersonsRevokeButton` | Revoke | pending-kn-translation |
| `pickupPersonsValidRange` | Valid {from} – {to} | pending-kn-translation |
| `pickupPersonsNewPersonTitle` | New pickup person | pending-kn-translation |
| `pickupPersonsFullNameLabel` | Full name | pending-kn-translation |
| `pickupPersonsPhoneLabel` | Phone number | pending-kn-translation |
| `pickupPersonsRelationshipLabel` | Relationship (optional) | pending-kn-translation |
| `pickupPersonsRelationshipHint` | e.g. Uncle | pending-kn-translation |
| `pickupPersonsValidityChoose` | Choose validity window | pending-kn-translation |
| `pickupPersonsNominateButton` | Nominate | pending-kn-translation |
| `pickupPersonsErrorOutsideValidity` | That validity window has already passed. | pending-kn-translation |
| `pickupPersonsNoChildrenLinked` | Your school links your children to your account before you can manage pickup persons. | pending-kn-translation |
| `notificationsAppBarTitle` | Notifications | pending-kn-translation |
| `notificationsGenericFailure` | Something went wrong loading your notifications. Please try again. | pending-kn-translation |
| `notificationsLoadFailureTitle` | Cannot load notifications right now | pending-kn-translation |
| `notificationsEmptyTitle` | No notifications yet | pending-kn-translation |
| `notificationsEmptyDetail` | You''ll see updates about your children here. | pending-kn-translation |
| `otpAppBarTitle` | Enter code | pending-kn-translation |
| `otpHeading` | Enter the code | pending-kn-translation |
| `otpSentTo` | We sent a code to {phone}. | pending-kn-translation |
| `otpCodeLabel` | Code | pending-kn-translation |
| `otpVerifyButton` | Verify | pending-kn-translation |
| `otpEntryChangeNumberButton` | Change number | pending-kn-translation |
| `otpEntrySendNewCodeButton` | Send a new code | pending-kn-translation |
| `loginHeading` | Sign in | pending-kn-translation |
| `simpleLoginParentHeading` | Parent sign in | pending-kn-translation |
| `loginInstructions` | Enter the mobile number registered with your school. | pending-kn-translation |
| `loginMobileNumberLabel` | Mobile number | pending-kn-translation |
| `loginSendCodeButton` | Send code | pending-kn-translation |
| `loginErrorCredentialsInvalid` | That code is not correct. Please check and try again. | pending-kn-translation |
| `loginErrorOtpExpired` | That code has expired. Tap “Send a new code” to get another. | pending-kn-translation |
| `loginErrorOtpAlreadyUsed` | That code has already been used. Tap “Send a new code”. | pending-kn-translation |
| `loginErrorAccountLocked` | This account is locked. Please contact the school office. | pending-kn-translation |
| `loginErrorRateLimited` | Too many attempts. Please wait a minute before trying again. | pending-kn-translation |
| `loginErrorDependencyUnavailable` | Cannot reach the school right now. Check your connection and try again. | pending-kn-translation |

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
