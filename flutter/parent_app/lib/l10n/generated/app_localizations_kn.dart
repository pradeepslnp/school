// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'Guardian';

  @override
  String get tryAgainButton => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get cancelButton => 'ರದ್ದುಮಾಡಿ';

  @override
  String get retryButton => 'ಮರುಪ್ರಯತ್ನ';

  @override
  String get whichChildLabel => 'ಯಾವ ಮಗು?';

  @override
  String get trackBusButton => 'ಬಸ್ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ';

  @override
  String get mapViewLabel => 'ನಕ್ಷೆ ನೋಟ';

  @override
  String get errorDependencyUnavailable =>
      'ಈಗ ನಿಮ್ಮ ಸಾಧನಕ್ಕೆ ಶಾಲೆಯನ್ನು ತಲುಪಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ನಿಮ್ಮ ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errorRateLimited =>
      'ಈಗಷ್ಟೇ ಹಲವು ಪ್ರಯತ್ನಗಳಾಗಿವೆ. ಸ್ವಲ್ಪ ಕಾದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errorGenericTryAgain =>
      'ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get noChildrenLinkedTitle => 'ಇನ್ನೂ ಯಾವ ಮಗುವೂ ಜೋಡಿಸಿಲ್ಲ';

  @override
  String get noChildrenLinkedDetail =>
      'ನಿಮ್ಮ ಶಾಲೆ ನಿಮ್ಮ ಮಕ್ಕಳನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸುತ್ತದೆ.';

  @override
  String get dayLabelToday => 'ಇಂದು';

  @override
  String get dayLabelYesterday => 'ನಿನ್ನೆ';

  @override
  String get relativeDayToday => 'ಇಂದು';

  @override
  String get relativeDayTomorrow => 'ನಾಳೆ';

  @override
  String durationSeconds(int seconds) {
    return '$seconds ಸೆ';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes ನಿ';
  }

  @override
  String durationHours(int hours) {
    return '$hours ಗಂ';
  }

  @override
  String atTimeFragment(String time) {
    return '$time ಕ್ಕೆ';
  }

  @override
  String get themeModeSystem => 'ಸಾಧನದಂತೆ';

  @override
  String get themeModeLight => 'ತಿಳಿ';

  @override
  String get themeModeDark => 'ಕಡು';

  @override
  String themeToggleTooltip(String mode) {
    return 'ಗೋಚರತೆ: $mode';
  }

  @override
  String get languageSwitcherTooltip => 'ಭಾಷೆ';

  @override
  String get languageSwitcherDialogTitle => 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get navHomeTab => 'ಮುಖಪುಟ';

  @override
  String get navJourneysTab => 'ಪ್ರಯಾಣಗಳು';

  @override
  String get navAlertsTab => 'ಎಚ್ಚರಿಕೆಗಳು';

  @override
  String get navPickupTab => 'ಕರೆದೊಯ್ಯುವಿಕೆ';

  @override
  String get homeAppBarTitle => 'ನನ್ನ ಮಕ್ಕಳು';

  @override
  String get refreshTooltip => 'ರಿಫ್ರೆಶ್';

  @override
  String get homeLoadFailureTitle => 'ಈಗ ಶಾಲೆಯನ್ನು ತಲುಪಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ';

  @override
  String get homeNoChildrenDetail =>
      'ನಿಮ್ಮ ಶಾಲೆ ನಿಮ್ಮ ಮಕ್ಕಳನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸುತ್ತದೆ. ಇಲ್ಲಿ ಯಾರಾದರೂ ಕಾಣಿಸಬೇಕೆಂದು ನೀವು ನಿರೀಕ್ಷಿಸಿದರೆ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get homeGenericLoadFailure =>
      'ನಿಮ್ಮ ಮಕ್ಕಳ ಮಾಹಿತಿ ಲೋಡ್ ಮಾಡುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get fallbackVehicleName => 'ಬಸ್';

  @override
  String get fallbackStopName => 'ನಿಮ್ಮ ನಿಲ್ದಾಣ';

  @override
  String get connectionBannerNoData => 'ಸಂಪರ್ಕವಿಲ್ಲ. ಇನ್ನೂ ಏನೂ ಲೋಡ್ ಆಗಿಲ್ಲ.';

  @override
  String connectionBannerLastUpdated(String time) {
    return 'ಸಂಪರ್ಕವಿಲ್ಲ · ಕೊನೆಯ ಅಪ್‌ಡೇಟ್ $time';
  }

  @override
  String get greetingMorning => 'ಶುಭೋದಯ';

  @override
  String get greetingAfternoon => 'ಶುಭ ಮಧ್ಯಾಹ್ನ';

  @override
  String get greetingEvening => 'ಶುಭ ಸಂಜೆ';

  @override
  String dashboardGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String schoolTimeZoneSemanticLabel(String zone) {
    return 'ಎಲ್ಲಾ ಸಮಯಗಳನ್ನು ಶಾಲಾ ಸಮಯದಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ, $zone.';
  }

  @override
  String schoolTimeLabel(String zone) {
    return 'ಶಾಲಾ ಸಮಯ · $zone';
  }

  @override
  String arrivalEstimateWithAge(String eta, String age) {
    return 'ಸುಮಾರು $eta ಕ್ಕೆ ಶಾಲೆ ತಲುಪುತ್ತದೆ · $age ಹಿಂದೆ ಅಂದಾಜಿಸಲಾಗಿದೆ';
  }

  @override
  String arrivalEstimateNoAge(String eta) {
    return 'ಸುಮಾರು $eta ಕ್ಕೆ ಶಾಲೆ ತಲುಪುತ್ತದೆ · ಅಂದಾಜು';
  }

  @override
  String detailAtRestNextBus(String time) {
    return 'ಶಾಲೆಯಲ್ಲಿ. ಮುಂದಿನ ಬಸ್ $time ಕ್ಕೆ.';
  }

  @override
  String get detailAtRestNoBus =>
      'ಶಾಲೆಯಲ್ಲಿ. ಇಂದು ಉಳಿದ ಸಮಯಕ್ಕೆ ಬಸ್ ನಿಗದಿಯಾಗಿಲ್ಲ.';

  @override
  String detailAbsent(String name) {
    return '$name ಇಂದು ಪ್ರಯಾಣಿಸುವುದಿಲ್ಲ ಎಂದು ನೀವು ಗುರುತಿಸಿದ್ದೀರಿ.';
  }

  @override
  String detailScheduledVehicle(String vehicle) {
    return '$vehicle ನಿಗದಿಯಾಗಿದೆ';
  }

  @override
  String detailFromStop(String stop) {
    return '$stop ಇಂದ';
  }

  @override
  String detailAtEta(String eta) {
    return 'ಸುಮಾರು $eta ಕ್ಕೆ';
  }

  @override
  String detailVehicleOnWay(String vehicle) {
    return '$vehicle ದಾರಿಯಲ್ಲಿದೆ';
  }

  @override
  String detailToStop(String stop) {
    return '$stop ಕಡೆಗೆ';
  }

  @override
  String detailArrivingAbout(String eta) {
    return '· ಸುಮಾರು $eta ಕ್ಕೆ ತಲುಪುತ್ತದೆ';
  }

  @override
  String get detailBoardedWord => 'ಬಸ್ ಹತ್ತಿದ್ದಾರೆ';

  @override
  String detailAtStop(String stop) {
    return '$stop ನಲ್ಲಿ';
  }

  @override
  String detailArrivedAtTime(String time) {
    return '$time ಕ್ಕೆ ಶಾಲೆ ತಲುಪಿದ್ದಾರೆ.';
  }

  @override
  String get detailArrivedNoTime => 'ಶಾಲೆ ತಲುಪಿದ್ದಾರೆ.';

  @override
  String get detailHandedOverWord => 'ಹಸ್ತಾಂತರಿಸಲಾಗಿದೆ';

  @override
  String get detailDidNotBoardWord => 'ಬಸ್ ಹತ್ತಲಿಲ್ಲ';

  @override
  String detailBusDepartedAt(String time) {
    return '· ಬಸ್ $time ಕ್ಕೆ ಹೊರಟಿದೆ';
  }

  @override
  String detailUnaccounted(String name) {
    return '$name ಬಸ್‌ನಿಂದ ಇಳಿದ ದಾಖಲೆ ಇಲ್ಲ. ಶಾಲೆಗೆ ಎಚ್ಚರಿಕೆ ನೀಡಲಾಗಿದೆ ಮತ್ತು ಅವರು ಈಗ ಪರಿಶೀಲಿಸುತ್ತಿದ್ದಾರೆ.';
  }

  @override
  String detailUnknown(String name) {
    return 'ಈ ಆವೃತ್ತಿಯ ಆ್ಯಪ್‌ಗೆ $name ಅವರ ಪ್ರಸ್ತುತ ಸ್ಥಿತಿಯನ್ನು ಓದಲು ಸಾಧ್ಯವಿಲ್ಲ. ಆ್ಯಪ್ ಅಪ್‌ಡೇಟ್ ಮಾಡಿ, ಅಥವಾ ಪರಿಶೀಲಿಸಲು ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';
  }

  @override
  String criticalBannerMessage(String name) {
    return '$name ಅವರ ಬಗ್ಗೆ ಇನ್ನೂ ಲೆಕ್ಕ ಸಿಕ್ಕಿಲ್ಲ. ಶಾಲೆಗೆ ಎಚ್ಚರಿಕೆ ನೀಡಲಾಗಿದೆ ಮತ್ತು ಸಿಬ್ಬಂದಿ ಈಗ ಪರಿಶೀಲಿಸುತ್ತಿದ್ದಾರೆ.';
  }

  @override
  String criticalBannerUrgentSemanticLabel(String message) {
    return 'ತುರ್ತು. $message';
  }

  @override
  String get criticalBannerActionNeeded => 'ಈಗಲೇ ಕ್ರಮ ಅಗತ್ಯ';

  @override
  String get criticalBannerNotAccountedTitle => 'ಇನ್ನೂ ಲೆಕ್ಕ ಸಿಕ್ಕಿಲ್ಲ';

  @override
  String get criticalBannerCallSchoolButton => 'ಶಾಲೆಗೆ ಕರೆ ಮಾಡಿ';

  @override
  String get criticalBannerSeeWhatHappenedButton => 'ಏನಾಯಿತು ನೋಡಿ';

  @override
  String get quickActionsTitle => 'ತ್ವರಿತ ಕ್ರಮಗಳು';

  @override
  String get quickActionDeclareAbsence => 'ಗೈರು ತಿಳಿಸಿ';

  @override
  String get quickActionPickupPersons => 'ಕರೆದೊಯ್ಯುವವರು';

  @override
  String get freshnessNoSignal => 'ಸಿಗ್ನಲ್ ಇಲ್ಲ';

  @override
  String freshnessNoSignalFor(String age) {
    return '$age ಇಂದ ಸಿಗ್ನಲ್ ಇಲ್ಲ';
  }

  @override
  String freshnessLastSeen(String age) {
    return '$age ಹಿಂದೆ ಕೊನೆಯದಾಗಿ ಕಂಡಿದೆ';
  }

  @override
  String freshnessLive(String age) {
    return 'ನೇರ · $age ಹಿಂದೆ ಅಪ್‌ಡೇಟ್ ಆಗಿದೆ';
  }

  @override
  String get journeyStateAtSchool => 'ಶಾಲೆಯಲ್ಲಿ';

  @override
  String get journeyStateBusScheduled => 'ಬಸ್ ನಿಗದಿಯಾಗಿದೆ';

  @override
  String get journeyStateBusOnWay => 'ಬಸ್ ದಾರಿಯಲ್ಲಿದೆ';

  @override
  String get journeyStateOnBus => 'ಬಸ್‌ನಲ್ಲಿ';

  @override
  String get journeyStateArrivedAtSchool => 'ಶಾಲೆ ತಲುಪಿದ್ದಾರೆ';

  @override
  String get journeyStateHandedOver => 'ಹಸ್ತಾಂತರಿಸಲಾಗಿದೆ';

  @override
  String get journeyStateDidNotBoard => 'ಬಸ್ ಹತ್ತಲಿಲ್ಲ';

  @override
  String get journeyStateNotTravelling => 'ಇಂದು ಪ್ರಯಾಣವಿಲ್ಲ';

  @override
  String get journeyStateNotAccountedFor => 'ಇನ್ನೂ ಲೆಕ್ಕ ಸಿಕ್ಕಿಲ್ಲ';

  @override
  String get journeyStateUnavailable => 'ಸ್ಥಿತಿ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get absenceAppBarTitle => 'ಗೈರು ತಿಳಿಸಿ';

  @override
  String get absenceWhenLabel => 'ಯಾವಾಗ?';

  @override
  String get absenceWhenToday => 'ಇಂದು';

  @override
  String get absenceWhenTomorrow => 'ನಾಳೆ';

  @override
  String get absenceWhenDateRange => 'ದಿನಾಂಕ ವ್ಯಾಪ್ತಿ';

  @override
  String get absenceWhichJourney => 'ಯಾವ ಪ್ರಯಾಣ?';

  @override
  String get absenceJourneyBoth => 'ಎರಡೂ';

  @override
  String get absenceJourneyMorning => 'ಬೆಳಿಗ್ಗೆ';

  @override
  String get absenceJourneyAfternoon => 'ಮಧ್ಯಾಹ್ನ';

  @override
  String get absenceReasonLabel => 'ಕಾರಣ (ಐಚ್ಛಿಕ)';

  @override
  String get absenceReasonHint => 'ಅಗತ್ಯವಿಲ್ಲ';

  @override
  String get absenceConfirmButton => 'ದೃಢೀಕರಿಸಿ';

  @override
  String get absenceUpcomingTitle => 'ಮುಂಬರುವ ಗೈರುಗಳು';

  @override
  String get absenceNoneDeclared => 'ಈ ಮಗುವಿಗೆ ಯಾವುದೇ ಗೈರು ತಿಳಿಸಿಲ್ಲ.';

  @override
  String get absenceDateRangeChoose => 'ದಿನಾಂಕಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get absenceTileJourneyBoth => 'ಎರಡೂ ಪ್ರಯಾಣಗಳು';

  @override
  String get absenceTileJourneyMorning => 'ಬೆಳಿಗ್ಗೆ ಮಾತ್ರ';

  @override
  String get absenceTileJourneyAfternoon => 'ಮಧ್ಯಾಹ್ನ ಮಾತ್ರ';

  @override
  String get absenceNoChildrenLinked =>
      'ಗೈರು ತಿಳಿಸುವ ಮೊದಲು ನಿಮ್ಮ ಶಾಲೆ ನಿಮ್ಮ ಮಕ್ಕಳನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸಬೇಕು.';

  @override
  String get absenceErrorTripStarted =>
      'ಈ ಪ್ರಯಾಣ ಈಗಾಗಲೇ ಆರಂಭವಾಗಿದೆ, ಆದ್ದರಿಂದ ಈ ಗೈರು ತಿಳಿಸಲು ಸಾಧ್ಯವಿಲ್ಲ. ಬದಲಾಗಿ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String absenceConfirmationMessage(
    String childName,
    String when,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'morningOnly': ' ಬೆಳಿಗ್ಗೆ',
      'afternoonOnly': ' ಮಧ್ಯಾಹ್ನ',
      'other': '',
    });
    return '$childName ಅವರನ್ನು $when$_temp0 ನಿರೀಕ್ಷಿಸಲಾಗುವುದಿಲ್ಲ.';
  }

  @override
  String absenceConfirmationRange(String from, String to) {
    return '$from ಇಂದ $to ವರೆಗೆ';
  }

  @override
  String get journeyHistoryAppBarTitle => 'ಪ್ರಯಾಣ ಇತಿಹಾಸ';

  @override
  String get journeyHistoryScopeDenied =>
      'ಈ ಮಗು ಇನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸಿಲ್ಲ. ಇದು ತಪ್ಪು ಎಂದು ನೀವು ಭಾವಿಸಿದರೆ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get journeyHistoryGenericFailure =>
      'ಪ್ರಯಾಣ ಇತಿಹಾಸ ಲೋಡ್ ಮಾಡುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get journeyHistoryLoadFailureTitle =>
      'ಈಗ ಪ್ರಯಾಣ ಇತಿಹಾಸ ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ';

  @override
  String get journeyHistoryEmptyTitle => 'ಇನ್ನೂ ಯಾವುದೇ ಪ್ರಯಾಣ ದಾಖಲಾಗಿಲ್ಲ';

  @override
  String get journeyHistoryEmptyDetail =>
      'ನಿಮ್ಮ ಮಗು ಪ್ರಯಾಣಿಸಿದ ನಂತರ ಹಿಂದಿನ ಪ್ರಯಾಣಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.';

  @override
  String get legDirectionMorning => 'ಬೆಳಿಗ್ಗೆ';

  @override
  String get legDirectionAfternoon => 'ಮಧ್ಯಾಹ್ನ';

  @override
  String get legMarkedAbsent => 'ಗೈರು ಎಂದು ಗುರುತಿಸಲಾಗಿದೆ';

  @override
  String get legNoRecordForLeg => 'ಈ ಹಂತಕ್ಕೆ ದಾಖಲೆ ಇಲ್ಲ';

  @override
  String get legNoScheduleForLeg => 'ಈ ಹಂತಕ್ಕೆ ವೇಳಾಪಟ್ಟಿ ಇಲ್ಲ';

  @override
  String legScheduledAt(String time) {
    return '$time ಕ್ಕೆ ನಿಗದಿಯಾಗಿದೆ';
  }

  @override
  String legBoardedAt(String time) {
    return '$time ಕ್ಕೆ ಬಸ್ ಹತ್ತಿದ್ದಾರೆ';
  }

  @override
  String legArrivedAt(String time) {
    return '$time ಕ್ಕೆ ತಲುಪಿದ್ದಾರೆ';
  }

  @override
  String legHandedOverAt(String time) {
    return '$time ಕ್ಕೆ ಹಸ್ತಾಂತರಿಸಲಾಗಿದೆ';
  }

  @override
  String legBusDepartedAt(String time) {
    return 'ಬಸ್ $time ಕ್ಕೆ ಹೊರಟಿದೆ';
  }

  @override
  String get childDetailNoDetailAvailable => 'ಈ ಮಗುವಿಗೆ ವಿವರ ಲಭ್ಯವಿಲ್ಲ.';

  @override
  String get childDetailTodayLabel => 'ಇಂದು';

  @override
  String get childDetailNoTripsToday => 'ಇಂದು ಯಾವುದೇ ಪ್ರಯಾಣ ನಿಗದಿಯಾಗಿಲ್ಲ.';

  @override
  String get childDetailShowPickupCodeButton => 'ಕರೆದೊಯ್ಯುವ ಕೋಡ್ ತೋರಿಸಿ';

  @override
  String get childDetailScopeDenied =>
      'ಈ ಮಗು ಇನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸಿಲ್ಲ. ಇದು ತಪ್ಪು ಎಂದು ನೀವು ಭಾವಿಸಿದರೆ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get childDetailGenericFailure =>
      'ಈ ಮಗುವಿನ ವಿವರ ಲೋಡ್ ಮಾಡುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get liveTripGenericFailure =>
      'ಈ ಪ್ರಯಾಣ ಲೋಡ್ ಮಾಡುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get liveTripAppBarTitle => 'ನೇರ ಪ್ರಯಾಣ';

  @override
  String get liveTripUnavailableTitle => 'ಈಗ ಟ್ರ್ಯಾಕಿಂಗ್ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get liveTripUnavailableDetail =>
      'ಬಸ್ ಪ್ರಯಾಣದಲ್ಲಿದ್ದಾಗ ಮಾತ್ರ ನೇರ ಟ್ರ್ಯಾಕಿಂಗ್ ನಡೆಯುತ್ತದೆ. ಪ್ರಯಾಣ ಆರಂಭವಾದ ಮೇಲೆ ಮತ್ತೆ ನೋಡಿ.';

  @override
  String get liveTripCannotLoadTitle => 'ಈಗ ಈ ಪ್ರಯಾಣ ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ';

  @override
  String get liveTripNoTripTitle => 'ತೋರಿಸಲು ಪ್ರಯಾಣವಿಲ್ಲ';

  @override
  String get liveTripNoTripDetail => 'ಈ ಮಗುವಿಗೆ ಈಗ ಯಾವುದೇ ಸಕ್ರಿಯ ಪ್ರಯಾಣವಿಲ್ಲ.';

  @override
  String liveTripSummaryStopsAway(int stops) {
    String _temp0 = intl.Intl.pluralLogic(
      stops,
      locale: localeName,
      other: 'ನಿಲ್ದಾಣಗಳು',
      one: 'ನಿಲ್ದಾಣ',
    );
    return '$stops $_temp0 ದೂರ';
  }

  @override
  String liveTripSummaryEtaToStop(int eta, String stop) {
    return '$stop ಗೆ ಸುಮಾರು $eta ನಿ';
  }

  @override
  String get liveTripEtaConfidenceModerate => ' · ಮಧ್ಯಮ ವಿಶ್ವಾಸ';

  @override
  String get liveTripEtaConfidenceLow =>
      ' · ಕಡಿಮೆ ವಿಶ್ವಾಸ — ಮಾರ್ಗ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get liveTripEtaJustNow => 'ಈಗಷ್ಟೇ';

  @override
  String liveTripEtaSecondsAgo(int seconds) {
    return '$seconds ಸೆ ಹಿಂದೆ';
  }

  @override
  String liveTripEtaMinutesAgo(int minutes) {
    return '$minutes ನಿ ಹಿಂದೆ';
  }

  @override
  String liveTripEstimateCalculated(String ago, String confidence) {
    return 'ಅಂದಾಜನ್ನು $ago ಲೆಕ್ಕ ಹಾಕಲಾಗಿದೆ$confidence.';
  }

  @override
  String get handoverCollectChildTitleNoName => 'ನಿಮ್ಮ ಮಗುವನ್ನು ಕರೆದೊಯ್ಯಿರಿ';

  @override
  String handoverCollectChildTitleWithName(String name) {
    return '$name ಅವರನ್ನು ಕರೆದೊಯ್ಯಿರಿ';
  }

  @override
  String get handoverShowToAttendant => 'ಇದನ್ನು ಬಸ್ ಸಹಾಯಕರಿಗೆ ತೋರಿಸಿ';

  @override
  String handoverQrSemanticLabel(String name) {
    return '$name ಅವರಿಗಾಗಿ ಪರಿಶೀಲನಾ QR ಕೋಡ್';
  }

  @override
  String get handoverQrSemanticsLabelPlain => 'ಪರಿಶೀಲನಾ QR ಕೋಡ್';

  @override
  String get handoverIfCannotScan => 'ಸಹಾಯಕರಿಗೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗದಿದ್ದರೆ';

  @override
  String get handoverGenerateNewCode => 'ಹೊಸ ಕೋಡ್ ರಚಿಸಿ';

  @override
  String get handoverCodeExpired => 'ಈ ಕೋಡ್ ಅವಧಿ ಮುಗಿದಿದೆ';

  @override
  String handoverExpiresInMinSec(int minutes, String seconds) {
    return '$minutes:$seconds ರಲ್ಲಿ ಅವಧಿ ಮುಗಿಯುತ್ತದೆ';
  }

  @override
  String handoverExpiresInSeconds(int seconds) {
    return '$seconds ಸೆ ರಲ್ಲಿ ಅವಧಿ ಮುಗಿಯುತ್ತದೆ';
  }

  @override
  String get handoverErrorNotAuthorised =>
      'ಈ ಮಗುವನ್ನು ಕರೆದೊಯ್ಯುವ ಹಕ್ಕು ನಿಮಗಿಲ್ಲ. ಆ ಹಕ್ಕು ಇರುವ ಇನ್ನೊಬ್ಬ ಪೋಷಕರನ್ನು ಅಥವಾ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get handoverGenericFailure =>
      'ಕೋಡ್ ಕೋರುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get pickupPersonsAppBarTitle => 'ಕರೆದೊಯ್ಯುವವರು';

  @override
  String get pickupPersonsAddButton => 'ಕರೆದೊಯ್ಯುವವರನ್ನು ಸೇರಿಸಿ';

  @override
  String get pickupPersonsNoneAuthorised =>
      'ಈ ಮಗುವಿಗೆ ಯಾರಿಗೂ ಕರೆದೊಯ್ಯುವ ಅನುಮತಿ ಇಲ್ಲ.';

  @override
  String get pickupPersonsRevokeButton => 'ರದ್ದುಗೊಳಿಸಿ';

  @override
  String pickupPersonsValidRange(String from, String to) {
    return 'ಮಾನ್ಯತೆ $from – $to';
  }

  @override
  String get pickupPersonsExpiredSuffix => ' · ಅವಧಿ ಮುಗಿದಿದೆ';

  @override
  String get pickupPersonsNewPersonTitle => 'ಹೊಸ ಕರೆದೊಯ್ಯುವವರು';

  @override
  String get pickupPersonsFullNameLabel => 'ಪೂರ್ಣ ಹೆಸರು';

  @override
  String get pickupPersonsPhoneLabel => 'ದೂರವಾಣಿ ಸಂಖ್ಯೆ';

  @override
  String get pickupPersonsRelationshipLabel => 'ಸಂಬಂಧ (ಐಚ್ಛಿಕ)';

  @override
  String get pickupPersonsRelationshipHint => 'ಉದಾ. ಚಿಕ್ಕಪ್ಪ';

  @override
  String get pickupPersonsValidityChoose => 'ಮಾನ್ಯತೆ ಅವಧಿ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get pickupPersonsNominateButton => 'ನಾಮನಿರ್ದೇಶನ ಮಾಡಿ';

  @override
  String get pickupPersonsErrorNotAuthorised =>
      'ಈ ಮಗುವನ್ನು ಕರೆದೊಯ್ಯಲು ಅನುಮತಿ ನೀಡುವ ಹಕ್ಕು ನಿಮಗಿಲ್ಲ. ಆ ಹಕ್ಕು ಇರುವ ಇನ್ನೊಬ್ಬ ಪೋಷಕರನ್ನು ಅಥವಾ ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get pickupPersonsErrorOutsideValidity =>
      'ಆ ಮಾನ್ಯತೆ ಅವಧಿ ಈಗಾಗಲೇ ಮುಗಿದಿದೆ.';

  @override
  String get pickupPersonsNoChildrenLinked =>
      'ಕರೆದೊಯ್ಯುವವರನ್ನು ನಿರ್ವಹಿಸುವ ಮೊದಲು ನಿಮ್ಮ ಶಾಲೆ ನಿಮ್ಮ ಮಕ್ಕಳನ್ನು ನಿಮ್ಮ ಖಾತೆಗೆ ಜೋಡಿಸಬೇಕು.';

  @override
  String get notificationsAppBarTitle => 'ಅಧಿಸೂಚನೆಗಳು';

  @override
  String get notificationsGenericFailure =>
      'ನಿಮ್ಮ ಅಧಿಸೂಚನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡುವಾಗ ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get notificationsLoadFailureTitle =>
      'ಈಗ ಅಧಿಸೂಚನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ';

  @override
  String get notificationsEmptyTitle => 'ಇನ್ನೂ ಯಾವುದೇ ಅಧಿಸೂಚನೆ ಇಲ್ಲ';

  @override
  String get notificationsEmptyDetail =>
      'ನಿಮ್ಮ ಮಕ್ಕಳ ಕುರಿತ ಅಪ್‌ಡೇಟ್‌ಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.';

  @override
  String get otpAppBarTitle => 'ಕೋಡ್ ನಮೂದಿಸಿ';

  @override
  String get otpHeading => 'ಕೋಡ್ ನಮೂದಿಸಿ';

  @override
  String otpSentTo(String phone) {
    return '$phone ಗೆ ನಾವು ಕೋಡ್ ಕಳುಹಿಸಿದ್ದೇವೆ.';
  }

  @override
  String get otpCodeLabel => 'ಕೋಡ್';

  @override
  String get otpVerifyButton => 'ಪರಿಶೀಲಿಸಿ';

  @override
  String get otpEntryChangeNumberButton => 'ಸಂಖ್ಯೆ ಬದಲಾಯಿಸಿ';

  @override
  String get otpEntrySendNewCodeButton => 'ಹೊಸ ಕೋಡ್ ಕಳುಹಿಸಿ';

  @override
  String get loginHeading => 'ಸೈನ್ ಇನ್';

  @override
  String get simpleLoginParentHeading => 'ಪೋಷಕರ ಸೈನ್ ಇನ್';

  @override
  String get loginInstructions =>
      'ನಿಮ್ಮ ಶಾಲೆಯಲ್ಲಿ ನೋಂದಾಯಿಸಿರುವ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ.';

  @override
  String get loginMobileNumberLabel => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ';

  @override
  String get loginSendCodeButton => 'ಕೋಡ್ ಕಳುಹಿಸಿ';

  @override
  String get loginErrorCredentialsInvalid =>
      'ಆ ಕೋಡ್ ಸರಿಯಿಲ್ಲ. ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get loginErrorOtpExpired =>
      'ಆ ಕೋಡ್ ಅವಧಿ ಮುಗಿದಿದೆ. ಹೊಸದನ್ನು ಪಡೆಯಲು “ಹೊಸ ಕೋಡ್ ಕಳುಹಿಸಿ” ಒತ್ತಿ.';

  @override
  String get loginErrorOtpAlreadyUsed =>
      'ಆ ಕೋಡ್ ಈಗಾಗಲೇ ಬಳಕೆಯಾಗಿದೆ. “ಹೊಸ ಕೋಡ್ ಕಳುಹಿಸಿ” ಒತ್ತಿ.';

  @override
  String get loginErrorAccountLocked =>
      'ಈ ಖಾತೆ ಲಾಕ್ ಆಗಿದೆ. ದಯವಿಟ್ಟು ಶಾಲಾ ಕಚೇರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get loginErrorRateLimited =>
      'ಹಲವು ಪ್ರಯತ್ನಗಳಾಗಿವೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸುವ ಮೊದಲು ಒಂದು ನಿಮಿಷ ಕಾಯಿರಿ.';

  @override
  String get loginErrorDependencyUnavailable =>
      'ಈಗ ಶಾಲೆಯನ್ನು ತಲುಪಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ನಿಮ್ಮ ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';
}
