import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
  ];

  /// App title, used for the OS task switcher via onGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get appTitle;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @whichChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Which child?'**
  String get whichChildLabel;

  /// No description provided for @trackBusButton.
  ///
  /// In en, this message translates to:
  /// **'Track bus'**
  String get trackBusButton;

  /// No description provided for @mapViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get mapViewLabel;

  /// No description provided for @errorDependencyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your device cannot reach the school right now. Check your connection and try again.'**
  String get errorDependencyUnavailable;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts just now. Wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorGenericTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGenericTryAgain;

  /// No description provided for @noChildrenLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'No children linked yet'**
  String get noChildrenLinkedTitle;

  /// No description provided for @noChildrenLinkedDetail.
  ///
  /// In en, this message translates to:
  /// **'Your school links your children to your account.'**
  String get noChildrenLinkedDetail;

  /// No description provided for @dayLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayLabelToday;

  /// No description provided for @dayLabelYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayLabelYesterday;

  /// No description provided for @relativeDayToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get relativeDayToday;

  /// No description provided for @relativeDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get relativeDayTomorrow;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @atTimeFragment.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String atTimeFragment(String time);

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {mode}'**
  String themeToggleTooltip(String mode);

  /// No description provided for @languageSwitcherTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitcherTooltip;

  /// No description provided for @languageSwitcherDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageSwitcherDialogTitle;

  /// No description provided for @navHomeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHomeTab;

  /// No description provided for @navJourneysTab.
  ///
  /// In en, this message translates to:
  /// **'Journeys'**
  String get navJourneysTab;

  /// No description provided for @navAlertsTab.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlertsTab;

  /// No description provided for @navPickupTab.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get navPickupTab;

  /// No description provided for @homeAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'My children'**
  String get homeAppBarTitle;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @homeLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the school right now'**
  String get homeLoadFailureTitle;

  /// No description provided for @homeNoChildrenDetail.
  ///
  /// In en, this message translates to:
  /// **'Your school links your children to your account. Contact the school office if you expect to see someone here.'**
  String get homeNoChildrenDetail;

  /// No description provided for @homeGenericLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your children. Please try again.'**
  String get homeGenericLoadFailure;

  /// Used when a specific vehicle display name is not yet known.
  ///
  /// In en, this message translates to:
  /// **'the bus'**
  String get fallbackVehicleName;

  /// Used when a specific stop name is not yet known.
  ///
  /// In en, this message translates to:
  /// **'your stop'**
  String get fallbackStopName;

  /// No description provided for @connectionBannerNoData.
  ///
  /// In en, this message translates to:
  /// **'Not connected. Nothing has loaded yet.'**
  String get connectionBannerNoData;

  /// No description provided for @connectionBannerLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not connected · last updated {time}'**
  String connectionBannerLastUpdated(String time);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String dashboardGreeting(String greeting, String name);

  /// No description provided for @schoolTimeZoneSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'All times are shown in school time, {zone}.'**
  String schoolTimeZoneSemanticLabel(String zone);

  /// No description provided for @schoolTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'School time · {zone}'**
  String schoolTimeLabel(String zone);

  /// No description provided for @arrivalEstimateWithAge.
  ///
  /// In en, this message translates to:
  /// **'Arriving at school about {eta} · estimated {age} ago'**
  String arrivalEstimateWithAge(String eta, String age);

  /// No description provided for @arrivalEstimateNoAge.
  ///
  /// In en, this message translates to:
  /// **'Arriving at school about {eta} · estimate'**
  String arrivalEstimateNoAge(String eta);

  /// No description provided for @detailAtRestNextBus.
  ///
  /// In en, this message translates to:
  /// **'At school. Next bus at {time}.'**
  String detailAtRestNextBus(String time);

  /// No description provided for @detailAtRestNoBus.
  ///
  /// In en, this message translates to:
  /// **'At school. No bus scheduled for the rest of today.'**
  String get detailAtRestNoBus;

  /// No description provided for @detailAbsent.
  ///
  /// In en, this message translates to:
  /// **'You marked {name} as not travelling today.'**
  String detailAbsent(String name);

  /// No description provided for @detailScheduledVehicle.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} is scheduled'**
  String detailScheduledVehicle(String vehicle);

  /// No description provided for @detailFromStop.
  ///
  /// In en, this message translates to:
  /// **'from {stop}'**
  String detailFromStop(String stop);

  /// No description provided for @detailAtEta.
  ///
  /// In en, this message translates to:
  /// **'at about {eta}'**
  String detailAtEta(String eta);

  /// No description provided for @detailVehicleOnWay.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} is on the way'**
  String detailVehicleOnWay(String vehicle);

  /// No description provided for @detailToStop.
  ///
  /// In en, this message translates to:
  /// **'to {stop}'**
  String detailToStop(String stop);

  /// No description provided for @detailArrivingAbout.
  ///
  /// In en, this message translates to:
  /// **'· arriving about {eta}'**
  String detailArrivingAbout(String eta);

  /// No description provided for @detailBoardedWord.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get detailBoardedWord;

  /// No description provided for @detailAtStop.
  ///
  /// In en, this message translates to:
  /// **'at {stop}'**
  String detailAtStop(String stop);

  /// No description provided for @detailArrivedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Arrived at school at {time}.'**
  String detailArrivedAtTime(String time);

  /// No description provided for @detailArrivedNoTime.
  ///
  /// In en, this message translates to:
  /// **'Arrived at school.'**
  String get detailArrivedNoTime;

  /// No description provided for @detailHandedOverWord.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get detailHandedOverWord;

  /// No description provided for @detailDidNotBoardWord.
  ///
  /// In en, this message translates to:
  /// **'Did not board'**
  String get detailDidNotBoardWord;

  /// No description provided for @detailBusDepartedAt.
  ///
  /// In en, this message translates to:
  /// **'· bus departed {time}'**
  String detailBusDepartedAt(String time);

  /// Safety-critical: BR-SAFE-001 unaccounted-for child copy.
  ///
  /// In en, this message translates to:
  /// **'No record of {name} getting off the bus. The school has been alerted and is checking now.'**
  String detailUnaccounted(String name);

  /// No description provided for @detailUnknown.
  ///
  /// In en, this message translates to:
  /// **'This version of the app cannot read {name}\'\'s current status. Update the app, or contact the school office to check.'**
  String detailUnknown(String name);

  /// Safety-critical: BR-SAFE-001 critical banner body.
  ///
  /// In en, this message translates to:
  /// **'{name} has not been accounted for. The school has been alerted and staff are checking now.'**
  String criticalBannerMessage(String name);

  /// Safety-critical.
  ///
  /// In en, this message translates to:
  /// **'Urgent. {message}'**
  String criticalBannerUrgentSemanticLabel(String message);

  /// Safety-critical.
  ///
  /// In en, this message translates to:
  /// **'ACTION NEEDED NOW'**
  String get criticalBannerActionNeeded;

  /// Safety-critical.
  ///
  /// In en, this message translates to:
  /// **'Not yet accounted for'**
  String get criticalBannerNotAccountedTitle;

  /// Safety-critical.
  ///
  /// In en, this message translates to:
  /// **'Call the school'**
  String get criticalBannerCallSchoolButton;

  /// Safety-critical.
  ///
  /// In en, this message translates to:
  /// **'See what happened'**
  String get criticalBannerSeeWhatHappenedButton;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @quickActionDeclareAbsence.
  ///
  /// In en, this message translates to:
  /// **'Declare absence'**
  String get quickActionDeclareAbsence;

  /// No description provided for @quickActionPickupPersons.
  ///
  /// In en, this message translates to:
  /// **'Pickup persons'**
  String get quickActionPickupPersons;

  /// No description provided for @freshnessNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get freshnessNoSignal;

  /// Safety-relevant: staleness of live position (BR-TRACK-003).
  ///
  /// In en, this message translates to:
  /// **'No signal for {age}'**
  String freshnessNoSignalFor(String age);

  /// Safety-relevant: staleness of live position (BR-TRACK-003).
  ///
  /// In en, this message translates to:
  /// **'Last seen {age} ago'**
  String freshnessLastSeen(String age);

  /// No description provided for @freshnessLive.
  ///
  /// In en, this message translates to:
  /// **'Live · updated {age} ago'**
  String freshnessLive(String age);

  /// No description provided for @journeyStateAtSchool.
  ///
  /// In en, this message translates to:
  /// **'At school'**
  String get journeyStateAtSchool;

  /// No description provided for @journeyStateBusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Bus scheduled'**
  String get journeyStateBusScheduled;

  /// No description provided for @journeyStateBusOnWay.
  ///
  /// In en, this message translates to:
  /// **'Bus on the way'**
  String get journeyStateBusOnWay;

  /// No description provided for @journeyStateOnBus.
  ///
  /// In en, this message translates to:
  /// **'On the bus'**
  String get journeyStateOnBus;

  /// No description provided for @journeyStateArrivedAtSchool.
  ///
  /// In en, this message translates to:
  /// **'Arrived at school'**
  String get journeyStateArrivedAtSchool;

  /// No description provided for @journeyStateHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get journeyStateHandedOver;

  /// Safety-relevant: BR-SAFE-002 no-show state.
  ///
  /// In en, this message translates to:
  /// **'Did not board'**
  String get journeyStateDidNotBoard;

  /// No description provided for @journeyStateNotTravelling.
  ///
  /// In en, this message translates to:
  /// **'Not travelling today'**
  String get journeyStateNotTravelling;

  /// Safety-critical: BR-SAFE-001 unaccounted state.
  ///
  /// In en, this message translates to:
  /// **'Not yet accounted for'**
  String get journeyStateNotAccountedFor;

  /// No description provided for @journeyStateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get journeyStateUnavailable;

  /// No description provided for @absenceAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Declare absence'**
  String get absenceAppBarTitle;

  /// No description provided for @absenceWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get absenceWhenLabel;

  /// No description provided for @absenceWhenToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get absenceWhenToday;

  /// No description provided for @absenceWhenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get absenceWhenTomorrow;

  /// No description provided for @absenceWhenDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get absenceWhenDateRange;

  /// No description provided for @absenceWhichJourney.
  ///
  /// In en, this message translates to:
  /// **'Which journey?'**
  String get absenceWhichJourney;

  /// No description provided for @absenceJourneyBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get absenceJourneyBoth;

  /// No description provided for @absenceJourneyMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get absenceJourneyMorning;

  /// No description provided for @absenceJourneyAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get absenceJourneyAfternoon;

  /// No description provided for @absenceReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get absenceReasonLabel;

  /// No description provided for @absenceReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Not required'**
  String get absenceReasonHint;

  /// No description provided for @absenceConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get absenceConfirmButton;

  /// No description provided for @absenceUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming absences'**
  String get absenceUpcomingTitle;

  /// No description provided for @absenceNoneDeclared.
  ///
  /// In en, this message translates to:
  /// **'No absences declared for this child.'**
  String get absenceNoneDeclared;

  /// No description provided for @absenceDateRangeChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get absenceDateRangeChoose;

  /// No description provided for @absenceTileJourneyBoth.
  ///
  /// In en, this message translates to:
  /// **'Both journeys'**
  String get absenceTileJourneyBoth;

  /// No description provided for @absenceTileJourneyMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning only'**
  String get absenceTileJourneyMorning;

  /// No description provided for @absenceTileJourneyAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon only'**
  String get absenceTileJourneyAfternoon;

  /// No description provided for @absenceNoChildrenLinked.
  ///
  /// In en, this message translates to:
  /// **'Your school links your children to your account before you can declare an absence.'**
  String get absenceNoChildrenLinked;

  /// No description provided for @absenceErrorTripStarted.
  ///
  /// In en, this message translates to:
  /// **'This trip has already started, so this absence cannot be declared. Contact the school office instead.'**
  String get absenceErrorTripStarted;

  /// Plain-language confirmation shown after a successful absence declaration.
  ///
  /// In en, this message translates to:
  /// **'{childName} will not be expected {when}{direction, select, morningOnly{ in the morning} afternoonOnly{ in the afternoon} other{}}.'**
  String absenceConfirmationMessage(
    String childName,
    String when,
    String direction,
  );

  /// No description provided for @absenceConfirmationRange.
  ///
  /// In en, this message translates to:
  /// **'from {from} to {to}'**
  String absenceConfirmationRange(String from, String to);

  /// No description provided for @journeyHistoryAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey history'**
  String get journeyHistoryAppBarTitle;

  /// No description provided for @journeyHistoryScopeDenied.
  ///
  /// In en, this message translates to:
  /// **'This child is no longer linked to your account. Contact the school office if you think that is wrong.'**
  String get journeyHistoryScopeDenied;

  /// No description provided for @journeyHistoryGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading journey history. Please try again.'**
  String get journeyHistoryGenericFailure;

  /// No description provided for @journeyHistoryLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot load journey history right now'**
  String get journeyHistoryLoadFailureTitle;

  /// No description provided for @journeyHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No journeys recorded yet'**
  String get journeyHistoryEmptyTitle;

  /// No description provided for @journeyHistoryEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Past trips will appear here once your child has traveled.'**
  String get journeyHistoryEmptyDetail;

  /// No description provided for @legDirectionMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get legDirectionMorning;

  /// No description provided for @legDirectionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get legDirectionAfternoon;

  /// No description provided for @legMarkedAbsent.
  ///
  /// In en, this message translates to:
  /// **'Marked absent'**
  String get legMarkedAbsent;

  /// No description provided for @legNoRecordForLeg.
  ///
  /// In en, this message translates to:
  /// **'No record for this leg'**
  String get legNoRecordForLeg;

  /// No description provided for @legNoScheduleForLeg.
  ///
  /// In en, this message translates to:
  /// **'No schedule for this leg'**
  String get legNoScheduleForLeg;

  /// No description provided for @legScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at {time}'**
  String legScheduledAt(String time);

  /// No description provided for @legBoardedAt.
  ///
  /// In en, this message translates to:
  /// **'Boarded at {time}'**
  String legBoardedAt(String time);

  /// No description provided for @legArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String legArrivedAt(String time);

  /// No description provided for @legHandedOverAt.
  ///
  /// In en, this message translates to:
  /// **'Handed over at {time}'**
  String legHandedOverAt(String time);

  /// Safety-relevant: BR-SAFE-002 no-show detail.
  ///
  /// In en, this message translates to:
  /// **'Bus departed at {time}'**
  String legBusDepartedAt(String time);

  /// No description provided for @childDetailNoDetailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No detail available for this child.'**
  String get childDetailNoDetailAvailable;

  /// No description provided for @childDetailTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get childDetailTodayLabel;

  /// No description provided for @childDetailNoTripsToday.
  ///
  /// In en, this message translates to:
  /// **'No trips scheduled for today.'**
  String get childDetailNoTripsToday;

  /// No description provided for @childDetailShowPickupCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Show pickup code'**
  String get childDetailShowPickupCodeButton;

  /// No description provided for @childDetailScopeDenied.
  ///
  /// In en, this message translates to:
  /// **'This child is no longer linked to your account. Contact the school office if you think that is wrong.'**
  String get childDetailScopeDenied;

  /// No description provided for @childDetailGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading this child\'\'s detail. Please try again.'**
  String get childDetailGenericFailure;

  /// No description provided for @liveTripGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading this trip. Please try again.'**
  String get liveTripGenericFailure;

  /// No description provided for @liveTripAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Live trip'**
  String get liveTripAppBarTitle;

  /// No description provided for @liveTripUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking is not available right now'**
  String get liveTripUnavailableTitle;

  /// No description provided for @liveTripUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'Live tracking only runs while the bus is on a trip (docs/05-ui/PARENT_APP.md, BR-TRACK-001). Check back once the trip has started.'**
  String get liveTripUnavailableDetail;

  /// No description provided for @liveTripCannotLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot load this trip right now'**
  String get liveTripCannotLoadTitle;

  /// No description provided for @liveTripNoTripTitle.
  ///
  /// In en, this message translates to:
  /// **'No trip to show'**
  String get liveTripNoTripTitle;

  /// No description provided for @liveTripNoTripDetail.
  ///
  /// In en, this message translates to:
  /// **'This child has no active trip right now.'**
  String get liveTripNoTripDetail;

  /// No description provided for @liveTripSummaryStopsAway.
  ///
  /// In en, this message translates to:
  /// **'{stops} {stops, plural, one{stop} other{stops}} away'**
  String liveTripSummaryStopsAway(int stops);

  /// No description provided for @liveTripSummaryEtaToStop.
  ///
  /// In en, this message translates to:
  /// **'~{eta} min to {stop}'**
  String liveTripSummaryEtaToStop(int eta, String stop);

  /// No description provided for @liveTripEtaConfidenceModerate.
  ///
  /// In en, this message translates to:
  /// **' · moderate confidence'**
  String get liveTripEtaConfidenceModerate;

  /// No description provided for @liveTripEtaConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **' · low confidence — routing unavailable'**
  String get liveTripEtaConfidenceLow;

  /// No description provided for @liveTripEtaJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get liveTripEtaJustNow;

  /// No description provided for @liveTripEtaSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String liveTripEtaSecondsAgo(int seconds);

  /// No description provided for @liveTripEtaMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String liveTripEtaMinutesAgo(int minutes);

  /// Safety-relevant: BR-TRACK-006 estimate-age disclosure.
  ///
  /// In en, this message translates to:
  /// **'Estimate calculated {ago}{confidence}.'**
  String liveTripEstimateCalculated(String ago, String confidence);

  /// No description provided for @handoverCollectChildTitleNoName.
  ///
  /// In en, this message translates to:
  /// **'Collect your child'**
  String get handoverCollectChildTitleNoName;

  /// No description provided for @handoverCollectChildTitleWithName.
  ///
  /// In en, this message translates to:
  /// **'Collect {name}'**
  String handoverCollectChildTitleWithName(String name);

  /// No description provided for @handoverShowToAttendant.
  ///
  /// In en, this message translates to:
  /// **'Show this to the bus attendant'**
  String get handoverShowToAttendant;

  /// Safety-relevant: handover verification (BR-HAND-002).
  ///
  /// In en, this message translates to:
  /// **'Verification QR code for {name}'**
  String handoverQrSemanticLabel(String name);

  /// No description provided for @handoverQrSemanticsLabelPlain.
  ///
  /// In en, this message translates to:
  /// **'Verification QR code'**
  String get handoverQrSemanticsLabelPlain;

  /// No description provided for @handoverIfCannotScan.
  ///
  /// In en, this message translates to:
  /// **'If the attendant cannot scan'**
  String get handoverIfCannotScan;

  /// No description provided for @handoverGenerateNewCode.
  ///
  /// In en, this message translates to:
  /// **'Generate a new code'**
  String get handoverGenerateNewCode;

  /// No description provided for @handoverCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired'**
  String get handoverCodeExpired;

  /// No description provided for @handoverExpiresInMinSec.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}:{seconds}'**
  String handoverExpiresInMinSec(int minutes, String seconds);

  /// No description provided for @handoverExpiresInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Expires in {seconds}s'**
  String handoverExpiresInSeconds(int seconds);

  /// Safety-critical: BR-GRD-006 handover authorisation refusal.
  ///
  /// In en, this message translates to:
  /// **'You do not hold the right to collect this child (BR-GRD-006). Contact another guardian who does, or the school office.'**
  String get handoverErrorNotAuthorised;

  /// Safety-relevant: handover code request failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong requesting a code. Please try again.'**
  String get handoverGenericFailure;

  /// No description provided for @pickupPersonsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup persons'**
  String get pickupPersonsAppBarTitle;

  /// No description provided for @pickupPersonsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add pickup person'**
  String get pickupPersonsAddButton;

  /// No description provided for @pickupPersonsNoneAuthorised.
  ///
  /// In en, this message translates to:
  /// **'No pickup persons authorised for this child.'**
  String get pickupPersonsNoneAuthorised;

  /// No description provided for @pickupPersonsRevokeButton.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get pickupPersonsRevokeButton;

  /// No description provided for @pickupPersonsValidRange.
  ///
  /// In en, this message translates to:
  /// **'Valid {from} – {to}'**
  String pickupPersonsValidRange(String from, String to);

  /// Safety-relevant: nominations always expire (BR-GRD-005).
  ///
  /// In en, this message translates to:
  /// **' · expired'**
  String get pickupPersonsExpiredSuffix;

  /// No description provided for @pickupPersonsNewPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'New pickup person'**
  String get pickupPersonsNewPersonTitle;

  /// No description provided for @pickupPersonsFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get pickupPersonsFullNameLabel;

  /// No description provided for @pickupPersonsPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get pickupPersonsPhoneLabel;

  /// No description provided for @pickupPersonsRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship (optional)'**
  String get pickupPersonsRelationshipLabel;

  /// No description provided for @pickupPersonsRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Uncle'**
  String get pickupPersonsRelationshipHint;

  /// No description provided for @pickupPersonsValidityChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose validity window'**
  String get pickupPersonsValidityChoose;

  /// No description provided for @pickupPersonsNominateButton.
  ///
  /// In en, this message translates to:
  /// **'Nominate'**
  String get pickupPersonsNominateButton;

  /// Safety-critical: BR-GRD-006 pickup-person authorisation refusal.
  ///
  /// In en, this message translates to:
  /// **'You do not hold the right to authorise pickups for this child (BR-GRD-006). Contact another guardian who does, or the school office.'**
  String get pickupPersonsErrorNotAuthorised;

  /// No description provided for @pickupPersonsErrorOutsideValidity.
  ///
  /// In en, this message translates to:
  /// **'That validity window has already passed.'**
  String get pickupPersonsErrorOutsideValidity;

  /// No description provided for @pickupPersonsNoChildrenLinked.
  ///
  /// In en, this message translates to:
  /// **'Your school links your children to your account before you can manage pickup persons.'**
  String get pickupPersonsNoChildrenLinked;

  /// No description provided for @notificationsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsAppBarTitle;

  /// No description provided for @notificationsGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your notifications. Please try again.'**
  String get notificationsGenericFailure;

  /// No description provided for @notificationsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot load notifications right now'**
  String get notificationsLoadFailureTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'You\'\'ll see updates about your children here.'**
  String get notificationsEmptyDetail;

  /// No description provided for @otpAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get otpAppBarTitle;

  /// No description provided for @otpHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpHeading;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {phone}.'**
  String otpSentTo(String phone);

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get otpCodeLabel;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// No description provided for @otpEntryChangeNumberButton.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get otpEntryChangeNumberButton;

  /// No description provided for @otpEntrySendNewCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get otpEntrySendNewCodeButton;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginHeading;

  /// No description provided for @simpleLoginParentHeading.
  ///
  /// In en, this message translates to:
  /// **'Parent sign in'**
  String get simpleLoginParentHeading;

  /// No description provided for @loginInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the mobile number registered with your school.'**
  String get loginInstructions;

  /// No description provided for @loginMobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get loginMobileNumberLabel;

  /// No description provided for @loginSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get loginSendCodeButton;

  /// No description provided for @loginErrorCredentialsInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Please check and try again.'**
  String get loginErrorCredentialsInvalid;

  /// No description provided for @loginErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Tap “Send a new code” to get another.'**
  String get loginErrorOtpExpired;

  /// No description provided for @loginErrorOtpAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'That code has already been used. Tap “Send a new code”.'**
  String get loginErrorOtpAlreadyUsed;

  /// No description provided for @loginErrorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'This account is locked. Please contact the school office.'**
  String get loginErrorAccountLocked;

  /// No description provided for @loginErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute before trying again.'**
  String get loginErrorRateLimited;

  /// No description provided for @loginErrorDependencyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the school right now. Check your connection and try again.'**
  String get loginErrorDependencyUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
