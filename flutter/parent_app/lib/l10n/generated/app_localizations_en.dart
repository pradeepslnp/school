// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Guardian';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get retryButton => 'Retry';

  @override
  String get whichChildLabel => 'Which child?';

  @override
  String get trackBusButton => 'Track bus';

  @override
  String get mapViewLabel => 'Map view';

  @override
  String get errorDependencyUnavailable =>
      'Your device cannot reach the school right now. Check your connection and try again.';

  @override
  String get errorRateLimited =>
      'Too many attempts just now. Wait a moment and try again.';

  @override
  String get errorGenericTryAgain => 'Something went wrong. Please try again.';

  @override
  String get noChildrenLinkedTitle => 'No children linked yet';

  @override
  String get noChildrenLinkedDetail =>
      'Your school links your children to your account.';

  @override
  String get dayLabelToday => 'Today';

  @override
  String get dayLabelYesterday => 'Yesterday';

  @override
  String get relativeDayToday => 'today';

  @override
  String get relativeDayTomorrow => 'tomorrow';

  @override
  String durationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String atTimeFragment(String time) {
    return 'at $time';
  }

  @override
  String get themeModeSystem => 'Match device';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String themeToggleTooltip(String mode) {
    return 'Appearance: $mode';
  }

  @override
  String get languageSwitcherTooltip => 'Language';

  @override
  String get languageSwitcherDialogTitle => 'Choose language';

  @override
  String get navHomeTab => 'Home';

  @override
  String get navJourneysTab => 'Journeys';

  @override
  String get navAlertsTab => 'Alerts';

  @override
  String get navPickupTab => 'Pickup';

  @override
  String get homeAppBarTitle => 'My children';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get homeLoadFailureTitle => 'Cannot reach the school right now';

  @override
  String get homeNoChildrenDetail =>
      'Your school links your children to your account. Contact the school office if you expect to see someone here.';

  @override
  String get homeGenericLoadFailure =>
      'Something went wrong loading your children. Please try again.';

  @override
  String get fallbackVehicleName => 'the bus';

  @override
  String get fallbackStopName => 'your stop';

  @override
  String get connectionBannerNoData => 'Not connected. Nothing has loaded yet.';

  @override
  String connectionBannerLastUpdated(String time) {
    return 'Not connected · last updated $time';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String dashboardGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String schoolTimeZoneSemanticLabel(String zone) {
    return 'All times are shown in school time, $zone.';
  }

  @override
  String schoolTimeLabel(String zone) {
    return 'School time · $zone';
  }

  @override
  String arrivalEstimateWithAge(String eta, String age) {
    return 'Arriving at school about $eta · estimated $age ago';
  }

  @override
  String arrivalEstimateNoAge(String eta) {
    return 'Arriving at school about $eta · estimate';
  }

  @override
  String detailAtRestNextBus(String time) {
    return 'At school. Next bus at $time.';
  }

  @override
  String get detailAtRestNoBus =>
      'At school. No bus scheduled for the rest of today.';

  @override
  String detailAbsent(String name) {
    return 'You marked $name as not travelling today.';
  }

  @override
  String detailScheduledVehicle(String vehicle) {
    return '$vehicle is scheduled';
  }

  @override
  String detailFromStop(String stop) {
    return 'from $stop';
  }

  @override
  String detailAtEta(String eta) {
    return 'at about $eta';
  }

  @override
  String detailVehicleOnWay(String vehicle) {
    return '$vehicle is on the way';
  }

  @override
  String detailToStop(String stop) {
    return 'to $stop';
  }

  @override
  String detailArrivingAbout(String eta) {
    return '· arriving about $eta';
  }

  @override
  String get detailBoardedWord => 'Boarded';

  @override
  String detailAtStop(String stop) {
    return 'at $stop';
  }

  @override
  String detailArrivedAtTime(String time) {
    return 'Arrived at school at $time.';
  }

  @override
  String get detailArrivedNoTime => 'Arrived at school.';

  @override
  String get detailHandedOverWord => 'Handed over';

  @override
  String get detailDidNotBoardWord => 'Did not board';

  @override
  String detailBusDepartedAt(String time) {
    return '· bus departed $time';
  }

  @override
  String detailUnaccounted(String name) {
    return 'No record of $name getting off the bus. The school has been alerted and is checking now.';
  }

  @override
  String detailUnknown(String name) {
    return 'This version of the app cannot read $name\'\'s current status. Update the app, or contact the school office to check.';
  }

  @override
  String criticalBannerMessage(String name) {
    return '$name has not been accounted for. The school has been alerted and staff are checking now.';
  }

  @override
  String criticalBannerUrgentSemanticLabel(String message) {
    return 'Urgent. $message';
  }

  @override
  String get criticalBannerActionNeeded => 'ACTION NEEDED NOW';

  @override
  String get criticalBannerNotAccountedTitle => 'Not yet accounted for';

  @override
  String get criticalBannerCallSchoolButton => 'Call the school';

  @override
  String get criticalBannerSeeWhatHappenedButton => 'See what happened';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickActionDeclareAbsence => 'Declare absence';

  @override
  String get quickActionPickupPersons => 'Pickup persons';

  @override
  String get freshnessNoSignal => 'No signal';

  @override
  String freshnessNoSignalFor(String age) {
    return 'No signal for $age';
  }

  @override
  String freshnessLastSeen(String age) {
    return 'Last seen $age ago';
  }

  @override
  String freshnessLive(String age) {
    return 'Live · updated $age ago';
  }

  @override
  String get journeyStateAtSchool => 'At school';

  @override
  String get journeyStateBusScheduled => 'Bus scheduled';

  @override
  String get journeyStateBusOnWay => 'Bus on the way';

  @override
  String get journeyStateOnBus => 'On the bus';

  @override
  String get journeyStateArrivedAtSchool => 'Arrived at school';

  @override
  String get journeyStateHandedOver => 'Handed over';

  @override
  String get journeyStateDidNotBoard => 'Did not board';

  @override
  String get journeyStateNotTravelling => 'Not travelling today';

  @override
  String get journeyStateNotAccountedFor => 'Not yet accounted for';

  @override
  String get journeyStateUnavailable => 'Status unavailable';

  @override
  String get absenceAppBarTitle => 'Declare absence';

  @override
  String get absenceWhenLabel => 'When?';

  @override
  String get absenceWhenToday => 'Today';

  @override
  String get absenceWhenTomorrow => 'Tomorrow';

  @override
  String get absenceWhenDateRange => 'Date range';

  @override
  String get absenceWhichJourney => 'Which journey?';

  @override
  String get absenceJourneyBoth => 'Both';

  @override
  String get absenceJourneyMorning => 'Morning';

  @override
  String get absenceJourneyAfternoon => 'Afternoon';

  @override
  String get absenceReasonLabel => 'Reason (optional)';

  @override
  String get absenceReasonHint => 'Not required';

  @override
  String get absenceConfirmButton => 'Confirm';

  @override
  String get absenceUpcomingTitle => 'Upcoming absences';

  @override
  String get absenceNoneDeclared => 'No absences declared for this child.';

  @override
  String get absenceDateRangeChoose => 'Choose dates';

  @override
  String get absenceTileJourneyBoth => 'Both journeys';

  @override
  String get absenceTileJourneyMorning => 'Morning only';

  @override
  String get absenceTileJourneyAfternoon => 'Afternoon only';

  @override
  String get absenceNoChildrenLinked =>
      'Your school links your children to your account before you can declare an absence.';

  @override
  String get absenceErrorTripStarted =>
      'This trip has already started, so this absence cannot be declared. Contact the school office instead.';

  @override
  String absenceConfirmationMessage(
    String childName,
    String when,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'morningOnly': ' in the morning',
      'afternoonOnly': ' in the afternoon',
      'other': '',
    });
    return '$childName will not be expected $when$_temp0.';
  }

  @override
  String absenceConfirmationRange(String from, String to) {
    return 'from $from to $to';
  }

  @override
  String get journeyHistoryAppBarTitle => 'Journey history';

  @override
  String get journeyHistoryScopeDenied =>
      'This child is no longer linked to your account. Contact the school office if you think that is wrong.';

  @override
  String get journeyHistoryGenericFailure =>
      'Something went wrong loading journey history. Please try again.';

  @override
  String get journeyHistoryLoadFailureTitle =>
      'Cannot load journey history right now';

  @override
  String get journeyHistoryEmptyTitle => 'No journeys recorded yet';

  @override
  String get journeyHistoryEmptyDetail =>
      'Past trips will appear here once your child has traveled.';

  @override
  String get legDirectionMorning => 'Morning';

  @override
  String get legDirectionAfternoon => 'Afternoon';

  @override
  String get legMarkedAbsent => 'Marked absent';

  @override
  String get legNoRecordForLeg => 'No record for this leg';

  @override
  String get legNoScheduleForLeg => 'No schedule for this leg';

  @override
  String legScheduledAt(String time) {
    return 'Scheduled at $time';
  }

  @override
  String legBoardedAt(String time) {
    return 'Boarded at $time';
  }

  @override
  String legArrivedAt(String time) {
    return 'Arrived at $time';
  }

  @override
  String legHandedOverAt(String time) {
    return 'Handed over at $time';
  }

  @override
  String legBusDepartedAt(String time) {
    return 'Bus departed at $time';
  }

  @override
  String get childDetailNoDetailAvailable =>
      'No detail available for this child.';

  @override
  String get childDetailTodayLabel => 'Today';

  @override
  String get childDetailNoTripsToday => 'No trips scheduled for today.';

  @override
  String get childDetailShowPickupCodeButton => 'Show pickup code';

  @override
  String get childDetailScopeDenied =>
      'This child is no longer linked to your account. Contact the school office if you think that is wrong.';

  @override
  String get childDetailGenericFailure =>
      'Something went wrong loading this child\'\'s detail. Please try again.';

  @override
  String get liveTripGenericFailure =>
      'Something went wrong loading this trip. Please try again.';

  @override
  String get liveTripAppBarTitle => 'Live trip';

  @override
  String get liveTripUnavailableTitle => 'Tracking is not available right now';

  @override
  String get liveTripUnavailableDetail =>
      'Live tracking only runs while the bus is on a trip (docs/05-ui/PARENT_APP.md, BR-TRACK-001). Check back once the trip has started.';

  @override
  String get liveTripCannotLoadTitle => 'Cannot load this trip right now';

  @override
  String get liveTripNoTripTitle => 'No trip to show';

  @override
  String get liveTripNoTripDetail => 'This child has no active trip right now.';

  @override
  String liveTripSummaryStopsAway(int stops) {
    String _temp0 = intl.Intl.pluralLogic(
      stops,
      locale: localeName,
      other: 'stops',
      one: 'stop',
    );
    return '$stops $_temp0 away';
  }

  @override
  String liveTripSummaryEtaToStop(int eta, String stop) {
    return '~$eta min to $stop';
  }

  @override
  String get liveTripEtaConfidenceModerate => ' · moderate confidence';

  @override
  String get liveTripEtaConfidenceLow =>
      ' · low confidence — routing unavailable';

  @override
  String get liveTripEtaJustNow => 'just now';

  @override
  String liveTripEtaSecondsAgo(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String liveTripEtaMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String liveTripEstimateCalculated(String ago, String confidence) {
    return 'Estimate calculated $ago$confidence.';
  }

  @override
  String get handoverCollectChildTitleNoName => 'Collect your child';

  @override
  String handoverCollectChildTitleWithName(String name) {
    return 'Collect $name';
  }

  @override
  String get handoverShowToAttendant => 'Show this to the bus attendant';

  @override
  String handoverQrSemanticLabel(String name) {
    return 'Verification QR code for $name';
  }

  @override
  String get handoverQrSemanticsLabelPlain => 'Verification QR code';

  @override
  String get handoverIfCannotScan => 'If the attendant cannot scan';

  @override
  String get handoverGenerateNewCode => 'Generate a new code';

  @override
  String get handoverCodeExpired => 'This code has expired';

  @override
  String handoverExpiresInMinSec(int minutes, String seconds) {
    return 'Expires in $minutes:$seconds';
  }

  @override
  String handoverExpiresInSeconds(int seconds) {
    return 'Expires in ${seconds}s';
  }

  @override
  String get handoverErrorNotAuthorised =>
      'You do not hold the right to collect this child (BR-GRD-006). Contact another guardian who does, or the school office.';

  @override
  String get handoverGenericFailure =>
      'Something went wrong requesting a code. Please try again.';

  @override
  String get pickupPersonsAppBarTitle => 'Pickup persons';

  @override
  String get pickupPersonsAddButton => 'Add pickup person';

  @override
  String get pickupPersonsNoneAuthorised =>
      'No pickup persons authorised for this child.';

  @override
  String get pickupPersonsRevokeButton => 'Revoke';

  @override
  String pickupPersonsValidRange(String from, String to) {
    return 'Valid $from – $to';
  }

  @override
  String get pickupPersonsExpiredSuffix => ' · expired';

  @override
  String get pickupPersonsNewPersonTitle => 'New pickup person';

  @override
  String get pickupPersonsFullNameLabel => 'Full name';

  @override
  String get pickupPersonsPhoneLabel => 'Phone number';

  @override
  String get pickupPersonsRelationshipLabel => 'Relationship (optional)';

  @override
  String get pickupPersonsRelationshipHint => 'e.g. Uncle';

  @override
  String get pickupPersonsValidityChoose => 'Choose validity window';

  @override
  String get pickupPersonsNominateButton => 'Nominate';

  @override
  String get pickupPersonsErrorNotAuthorised =>
      'You do not hold the right to authorise pickups for this child (BR-GRD-006). Contact another guardian who does, or the school office.';

  @override
  String get pickupPersonsErrorOutsideValidity =>
      'That validity window has already passed.';

  @override
  String get pickupPersonsNoChildrenLinked =>
      'Your school links your children to your account before you can manage pickup persons.';

  @override
  String get notificationsAppBarTitle => 'Notifications';

  @override
  String get notificationsGenericFailure =>
      'Something went wrong loading your notifications. Please try again.';

  @override
  String get notificationsLoadFailureTitle =>
      'Cannot load notifications right now';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyDetail =>
      'You\'\'ll see updates about your children here.';

  @override
  String get otpAppBarTitle => 'Enter code';

  @override
  String get otpHeading => 'Enter the code';

  @override
  String otpSentTo(String phone) {
    return 'We sent a code to $phone.';
  }

  @override
  String get otpCodeLabel => 'Code';

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get otpEntryChangeNumberButton => 'Change number';

  @override
  String get otpEntrySendNewCodeButton => 'Send a new code';

  @override
  String get loginHeading => 'Sign in';

  @override
  String get simpleLoginParentHeading => 'Parent sign in';

  @override
  String get loginInstructions =>
      'Enter the mobile number registered with your school.';

  @override
  String get loginMobileNumberLabel => 'Mobile number';

  @override
  String get loginSendCodeButton => 'Send code';

  @override
  String get loginErrorCredentialsInvalid =>
      'That code is not correct. Please check and try again.';

  @override
  String get loginErrorOtpExpired =>
      'That code has expired. Tap “Send a new code” to get another.';

  @override
  String get loginErrorOtpAlreadyUsed =>
      'That code has already been used. Tap “Send a new code”.';

  @override
  String get loginErrorAccountLocked =>
      'This account is locked. Please contact the school office.';

  @override
  String get loginErrorRateLimited =>
      'Too many attempts. Please wait a minute before trying again.';

  @override
  String get loginErrorDependencyUnavailable =>
      'Cannot reach the school right now. Check your connection and try again.';
}
