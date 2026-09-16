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

  /// Browser tab / window title for the console (MaterialApp.title).
  ///
  /// In en, this message translates to:
  /// **'Guardian Admin'**
  String get appTitle;

  /// Product mark text in the console header, next to the shield icon.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get consoleHeaderBrand;

  /// No description provided for @consoleDestinationOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get consoleDestinationOrganizations;

  /// No description provided for @consoleDestinationSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get consoleDestinationSchool;

  /// No description provided for @consoleDestinationStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get consoleDestinationStudents;

  /// No description provided for @consoleDestinationDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get consoleDestinationDrivers;

  /// No description provided for @consoleDestinationVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get consoleDestinationVehicles;

  /// No description provided for @consoleDestinationRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get consoleDestinationRoutes;

  /// No description provided for @consoleDestinationUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get consoleDestinationUsers;

  /// No description provided for @consoleDestinationRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get consoleDestinationRoles;

  /// No description provided for @consoleDestinationPlatformHealth.
  ///
  /// In en, this message translates to:
  /// **'Platform health'**
  String get consoleDestinationPlatformHealth;

  /// Nav labels for ConsoleDestinations.all (side rail / drawer / narrow-layout menu).
  ///
  /// In en, this message translates to:
  /// **'Audit trail'**
  String get consoleDestinationAuditTrail;

  /// No description provided for @accountMenuSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountMenuSignOut;

  /// No description provided for @accountMenuSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get accountMenuSigningOut;

  /// No description provided for @noModulesNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'No console modules in this build'**
  String get noModulesNoticeTitle;

  /// No description provided for @noModulesNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'You are signed in. The operations dashboard, alert inbox, and administration screens are not part of this build yet.'**
  String get noModulesNoticeBody;

  /// No description provided for @bootSplashLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading the console'**
  String get bootSplashLoadingLabel;

  /// No description provided for @languageSwitcherTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageSwitcherTooltip;

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// Language endonyms shown in the language picker itself — intentionally identical in app_en.arb and app_kn.arb; see TRANSLATION_STATUS.md.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get languageNameKannada;

  /// No description provided for @roleNameSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleNameSuperAdmin;

  /// No description provided for @roleNameOrgAdmin.
  ///
  /// In en, this message translates to:
  /// **'Organization Admin'**
  String get roleNameOrgAdmin;

  /// No description provided for @roleNameSchoolAdmin.
  ///
  /// In en, this message translates to:
  /// **'School Admin'**
  String get roleNameSchoolAdmin;

  /// No description provided for @roleNamePrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get roleNamePrincipal;

  /// No description provided for @roleNameTransportManager.
  ///
  /// In en, this message translates to:
  /// **'Transport Manager'**
  String get roleNameTransportManager;

  /// No description provided for @roleNameVendorStaff.
  ///
  /// In en, this message translates to:
  /// **'Vendor Staff'**
  String get roleNameVendorStaff;

  /// No description provided for @roleNameDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleNameDriver;

  /// No description provided for @roleNameAttendant.
  ///
  /// In en, this message translates to:
  /// **'Attendant'**
  String get roleNameAttendant;

  /// No description provided for @roleNameGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get roleNameGuardian;

  /// No description provided for @roleShortSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super\nAdmin'**
  String get roleShortSuperAdmin;

  /// No description provided for @roleShortOrgAdmin.
  ///
  /// In en, this message translates to:
  /// **'Org\nAdmin'**
  String get roleShortOrgAdmin;

  /// No description provided for @roleShortSchoolAdmin.
  ///
  /// In en, this message translates to:
  /// **'School\nAdmin'**
  String get roleShortSchoolAdmin;

  /// No description provided for @roleShortPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get roleShortPrincipal;

  /// No description provided for @roleShortTransportManager.
  ///
  /// In en, this message translates to:
  /// **'Transport\nMgr'**
  String get roleShortTransportManager;

  /// No description provided for @roleShortVendorStaff.
  ///
  /// In en, this message translates to:
  /// **'Vendor\nStaff'**
  String get roleShortVendorStaff;

  /// No description provided for @roleShortDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleShortDriver;

  /// No description provided for @roleShortAttendant.
  ///
  /// In en, this message translates to:
  /// **'Attendant'**
  String get roleShortAttendant;

  /// Narrow column headers for the Roles & Permissions matrix table; may contain an embedded line break.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get roleShortGuardian;

  /// No description provided for @permCategoryTenancyConfig.
  ///
  /// In en, this message translates to:
  /// **'Tenancy & Configuration'**
  String get permCategoryTenancyConfig;

  /// No description provided for @permCategoryIdentityAccess.
  ///
  /// In en, this message translates to:
  /// **'Identity & Access'**
  String get permCategoryIdentityAccess;

  /// No description provided for @permCategoryStudentsGuardians.
  ///
  /// In en, this message translates to:
  /// **'Students & Guardians'**
  String get permCategoryStudentsGuardians;

  /// No description provided for @permCategoryFleetStaff.
  ///
  /// In en, this message translates to:
  /// **'Fleet & Staff'**
  String get permCategoryFleetStaff;

  /// No description provided for @permCategoryRoutesTrips.
  ///
  /// In en, this message translates to:
  /// **'Routes & Trips'**
  String get permCategoryRoutesTrips;

  /// No description provided for @permCategoryBoardingHandover.
  ///
  /// In en, this message translates to:
  /// **'Boarding & Handover'**
  String get permCategoryBoardingHandover;

  /// No description provided for @permCategoryTrackingAlertsIncidents.
  ///
  /// In en, this message translates to:
  /// **'Tracking, Alerts, Incidents'**
  String get permCategoryTrackingAlertsIncidents;

  /// No description provided for @permCategoryAbsenceNotificationReportingAudit.
  ///
  /// In en, this message translates to:
  /// **'Absence, Notification, Reporting, Audit'**
  String get permCategoryAbsenceNotificationReportingAudit;

  /// No description provided for @permCategoryPlatformOperations.
  ///
  /// In en, this message translates to:
  /// **'Platform Operations'**
  String get permCategoryPlatformOperations;

  /// No description provided for @permNoteConfigSafetyEdit.
  ///
  /// In en, this message translates to:
  /// **'Governs safety-relevant thresholds; bounded by platform floors (BR-CFG-003).'**
  String get permNoteConfigSafetyEdit;

  /// No description provided for @permNoteStudentView.
  ///
  /// In en, this message translates to:
  /// **'Non-admin roles see only the current trip manifest or their own children (BR-IAM-005); non-guardian access is logged (BR-IAM-012).'**
  String get permNoteStudentView;

  /// No description provided for @permNotePickupPersonManage.
  ///
  /// In en, this message translates to:
  /// **'A guardian\'s grant requires the \"authorise handover\" right on the relationship (BR-GRD-006).'**
  String get permNotePickupPersonManage;

  /// No description provided for @permNoteHandoverCodeRequest.
  ///
  /// In en, this message translates to:
  /// **'Requires \"can_authorise_handover\" on the relationship (BR-GRD-006); redemption at the vehicle is the separate attendant-side flow (BR-HAND-001–007).'**
  String get permNoteHandoverCodeRequest;

  /// No description provided for @permNoteTripView.
  ///
  /// In en, this message translates to:
  /// **'A guardian\'s grant is limited to trips carrying one of their children (BR-TRACK-002).'**
  String get permNoteTripView;

  /// No description provided for @permNoteBoardingCorrect.
  ///
  /// In en, this message translates to:
  /// **'Override-capable; always audited with a reason (BR-AUD-004).'**
  String get permNoteBoardingCorrect;

  /// No description provided for @permNoteBoardingOverride.
  ///
  /// In en, this message translates to:
  /// **'Override-capable; always audited with a reason (BR-AUD-004).'**
  String get permNoteBoardingOverride;

  /// No description provided for @permNoteHandoverOverride.
  ///
  /// In en, this message translates to:
  /// **'Notifies all guardians and the transport manager (BR-HAND-003); always audited with a reason (BR-AUD-004).'**
  String get permNoteHandoverOverride;

  /// No description provided for @permNoteReconciliationResolve.
  ///
  /// In en, this message translates to:
  /// **'Override-capable; always audited with a reason (BR-AUD-004).'**
  String get permNoteReconciliationResolve;

  /// No description provided for @permNoteIncidentView.
  ///
  /// In en, this message translates to:
  /// **'A guardian\'s grant is limited to incidents affecting their own child (BR-INC-004, BR-NTF-007).'**
  String get permNoteIncidentView;

  /// No description provided for @permNoteAbsenceDeclare.
  ///
  /// In en, this message translates to:
  /// **'A guardian\'s grant requires the \"declare absence\" right (BR-ABS-001).'**
  String get permNoteAbsenceDeclare;

  /// No description provided for @permNoteNotificationSelfView.
  ///
  /// In en, this message translates to:
  /// **'Everyone, scoped to their own notifications only — never a route to another family\'s child (BR-NTF-007).'**
  String get permNoteNotificationSelfView;

  /// No description provided for @permNoteDataExport.
  ///
  /// In en, this message translates to:
  /// **'Always audited with actor, scope, and record count (BR-RPT-002).'**
  String get permNoteDataExport;

  /// No description provided for @permNotePlatformTenantAccess.
  ///
  /// In en, this message translates to:
  /// **'The only path across the tenant boundary (BR-TEN-004); every use is audited with the target organization and justification (AUD-004).'**
  String get permNotePlatformTenantAccess;

  /// No description provided for @roleReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & permissions'**
  String get roleReferenceTitle;

  /// No description provided for @roleReferenceDescription.
  ///
  /// In en, this message translates to:
  /// **'What each system role can do, straight from the permission matrix this platform enforces server-side on every request. Reference only — roles cannot be edited here yet.'**
  String get roleReferenceDescription;

  /// No description provided for @roleReferenceSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get roleReferenceSearchLabel;

  /// No description provided for @roleReferenceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by permission ID or category'**
  String get roleReferenceSearchHint;

  /// No description provided for @roleReferenceClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get roleReferenceClearSearchTooltip;

  /// No description provided for @roleReferenceRoleFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleReferenceRoleFilterLabel;

  /// No description provided for @roleReferenceEveryRoleOption.
  ///
  /// In en, this message translates to:
  /// **'Every role'**
  String get roleReferenceEveryRoleOption;

  /// No description provided for @roleReferenceNoResults.
  ///
  /// In en, this message translates to:
  /// **'No permission matches this search.'**
  String get roleReferenceNoResults;

  /// No description provided for @roleReferenceGrantNarrowerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Granted, narrowed to a smaller scope than this role normally has'**
  String get roleReferenceGrantNarrowerTooltip;

  /// No description provided for @errorValidationRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Fill in every required field.'**
  String get errorValidationRequiredField;

  /// No description provided for @errorValidationCheckDetails.
  ///
  /// In en, this message translates to:
  /// **'Check the details you entered.'**
  String get errorValidationCheckDetails;

  /// No description provided for @errorApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The Guardian API could not be reached. Check your connection, then try again.'**
  String get errorApiUnreachable;

  /// No description provided for @errorSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'That session has ended. Sign in again.'**
  String get errorSessionEnded;

  /// Shared ErrorCode-to-copy fallbacks reused by OnboardingErrorText, StudentErrorText, and similar widgets — kept as one key per distinct message rather than duplicated per feature.
  ///
  /// In en, this message translates to:
  /// **'That could not be saved right now. Try again shortly.'**
  String get errorGenericRetryShortly;

  /// No description provided for @onboardingErrorOrgCodeExists.
  ///
  /// In en, this message translates to:
  /// **'That organization code is already in use. Choose another — codes cannot be changed once operational data exists (BR-TEN-007).'**
  String get onboardingErrorOrgCodeExists;

  /// No description provided for @onboardingErrorCannotSuspendOwnOrganization.
  ///
  /// In en, this message translates to:
  /// **'You cannot suspend the organization your own account belongs to — it would lock out every account able to reactivate it.'**
  String get onboardingErrorCannotSuspendOwnOrganization;

  /// No description provided for @onboardingErrorSchoolCodeExists.
  ///
  /// In en, this message translates to:
  /// **'That school code is already used within this organization. Choose another.'**
  String get onboardingErrorSchoolCodeExists;

  /// No description provided for @onboardingErrorStaffEmployeeCodeExists.
  ///
  /// In en, this message translates to:
  /// **'That employee code is already used at this school. Choose another.'**
  String get onboardingErrorStaffEmployeeCodeExists;

  /// No description provided for @onboardingErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Your account does not have permission to create organizations.'**
  String get onboardingErrorPermissionDenied;

  /// No description provided for @studentErrorAdmissionNoExists.
  ///
  /// In en, this message translates to:
  /// **'That admission number is already used at this school. Check whether the student is already enrolled before creating a second record for them.'**
  String get studentErrorAdmissionNoExists;

  /// No description provided for @studentErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That student could not be found. They may have been moved to another school.'**
  String get studentErrorNotFound;

  /// No description provided for @studentErrorNotActive.
  ///
  /// In en, this message translates to:
  /// **'That student is not on the active roll, so they cannot be assigned to transport.'**
  String get studentErrorNotActive;

  /// No description provided for @studentErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Your account does not have permission to manage students.'**
  String get studentErrorPermissionDenied;

  /// No description provided for @studentErrorScopeDenied.
  ///
  /// In en, this message translates to:
  /// **'That student is outside the schools your account covers.'**
  String get studentErrorScopeDenied;

  /// No description provided for @loginErrorCredentialsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Those details were not recognised. Check the email address and password.'**
  String get loginErrorCredentialsInvalid;

  /// No description provided for @loginErrorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'This account is locked after too many failed attempts. Contact your platform administrator to unlock it.'**
  String get loginErrorAccountLocked;

  /// No description provided for @loginErrorRateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts. Wait a minute, then try again.'**
  String get loginErrorRateLimitExceeded;

  /// No description provided for @loginErrorValidationRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Enter both your email address and your password.'**
  String get loginErrorValidationRequiredField;

  /// No description provided for @loginErrorGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not working right now. Contact your platform administrator.'**
  String get loginErrorGenericFailure;

  /// No description provided for @schoolScopeOrganizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get schoolScopeOrganizationLabel;

  /// No description provided for @schoolScopeLoadingHint.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get schoolScopeLoadingHint;

  /// No description provided for @schoolScopeSelectOrganizationHint.
  ///
  /// In en, this message translates to:
  /// **'Select an organization'**
  String get schoolScopeSelectOrganizationHint;

  /// No description provided for @schoolScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get schoolScopeLabel;

  /// No description provided for @schoolScopeSelectOrganizationFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Select an organization first'**
  String get schoolScopeSelectOrganizationFirstHint;

  /// No description provided for @schoolScopeSelectSchoolHint.
  ///
  /// In en, this message translates to:
  /// **'Select a school'**
  String get schoolScopeSelectSchoolHint;

  /// No description provided for @schoolScopeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your organizations or schools.'**
  String get schoolScopeLoadError;

  /// No description provided for @schoolScopeNoSchoolsNotice.
  ///
  /// In en, this message translates to:
  /// **'This organization has no schools yet. Add a school before enrolling students or registering vehicles, staff and routes.'**
  String get schoolScopeNoSchoolsNotice;

  /// No description provided for @schoolScopeCrossTenantNotice.
  ///
  /// In en, this message translates to:
  /// **'A platform operator cannot open another organization\'s schools. To manage students, staff, vehicles or routes, sign in with an account belonging to that organization.'**
  String get schoolScopeCrossTenantNotice;

  /// No description provided for @commonCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancelButton;

  /// No description provided for @commonSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSaveButton;

  /// No description provided for @commonCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonCloseButton;

  /// No description provided for @commonRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetryButton;

  /// No description provided for @commonAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAddButton;

  /// Generic action-button labels reused verbatim across many forms/dialogs — one key per label rather than one per call site.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDoneButton;

  /// No description provided for @schoolSettingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get schoolSettingsScreenTitle;

  /// No description provided for @loginSessionEndedRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your session was ended by the platform. This happens when an account is deactivated or a session is revoked.'**
  String get loginSessionEndedRevoked;

  /// No description provided for @loginSessionEndedRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Your session expired and could not be renewed. Sign in to continue.'**
  String get loginSessionEndedRefreshFailed;

  /// No description provided for @loginSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInLabel;

  /// No description provided for @loginFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian administration console'**
  String get loginFormSubtitle;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginSubmittingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get loginSubmittingSpinnerLabel;

  /// No description provided for @loginForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPasswordLink;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddressLabel;

  /// No description provided for @passwordVisibilityShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordVisibilityShowTooltip;

  /// Shared across every password field in the console (sign-in, accept-invitation, reset) — reused by key rather than duplicated per feature.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordVisibilityHideTooltip;

  /// No description provided for @confirmPasswordFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordFieldLabel;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get passwordMismatchError;

  /// No description provided for @passwordValidationTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {minLength} characters.'**
  String passwordValidationTooShort(int minLength);

  /// No description provided for @goToSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get goToSignInButton;

  /// No description provided for @acceptInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get acceptInvitationTitle;

  /// No description provided for @acceptInvitationIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a password to activate your account and sign in.'**
  String get acceptInvitationIntro;

  /// No description provided for @acceptInvitationSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Activate account'**
  String get acceptInvitationSubmitLabel;

  /// No description provided for @acceptInvitationDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Account activated'**
  String get acceptInvitationDoneTitle;

  /// No description provided for @acceptInvitationDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You can now sign in with your email address and new password.'**
  String get acceptInvitationDoneBody;

  /// No description provided for @setPasswordErrorLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired. Ask an administrator to send you a new one.'**
  String get setPasswordErrorLinkExpired;

  /// No description provided for @setPasswordErrorLinkAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This link has already been used. If you have set your password, just sign in.'**
  String get setPasswordErrorLinkAlreadyUsed;

  /// No description provided for @setPasswordErrorLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is not valid. Check you opened the most recent email, or ask for a new link.'**
  String get setPasswordErrorLinkInvalid;

  /// No description provided for @authRecoveryErrorPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'That password is too weak. Use at least {minLength} characters and avoid common passwords.'**
  String authRecoveryErrorPasswordTooWeak(int minLength);

  /// No description provided for @authRecoveryErrorApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'We could not reach the server. Check your connection and try again.'**
  String get authRecoveryErrorApiUnreachable;

  /// No description provided for @authRecoveryErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'That could not be completed right now. Please try again.'**
  String get authRecoveryErrorGeneric;

  /// No description provided for @newPasswordFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordFieldLabel;

  /// No description provided for @newPasswordHelperText.
  ///
  /// In en, this message translates to:
  /// **'At least {minLength} characters.'**
  String newPasswordHelperText(int minLength);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a 6-digit code to reset your password.'**
  String get forgotPasswordIntro;

  /// No description provided for @forgotPasswordEmailValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get forgotPasswordEmailValidationError;

  /// No description provided for @forgotPasswordSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotPasswordSendCodeButton;

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @forgotPasswordEnterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get forgotPasswordEnterCodeTitle;

  /// No description provided for @forgotPasswordCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we’ve emailed a 6-digit code. It is valid for 10 minutes. Enter it and choose a new password.'**
  String forgotPasswordCodeIntro(String email);

  /// No description provided for @forgotPasswordCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get forgotPasswordCodeFieldLabel;

  /// No description provided for @forgotPasswordCodeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your email.'**
  String get forgotPasswordCodeValidationError;

  /// No description provided for @forgotPasswordDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get forgotPasswordDoneTitle;

  /// No description provided for @forgotPasswordDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset and you’ve been signed out everywhere else. Sign in with your new password.'**
  String get forgotPasswordDoneBody;

  /// No description provided for @resetPasswordSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmitButton;

  /// No description provided for @forgotPasswordErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Go back and request a new one.'**
  String get forgotPasswordErrorOtpExpired;

  /// No description provided for @forgotPasswordErrorOtpAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'That code has already been used. Request a new one if you still need to reset.'**
  String get forgotPasswordErrorOtpAlreadyUsed;

  /// No description provided for @forgotPasswordErrorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect codes. Please wait 15 minutes and try again.'**
  String get forgotPasswordErrorAccountLocked;

  /// No description provided for @forgotPasswordErrorCredentialsInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Check the latest email and try again.'**
  String get forgotPasswordErrorCredentialsInvalid;

  /// No description provided for @guardianRelationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get guardianRelationshipMother;

  /// No description provided for @guardianRelationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get guardianRelationshipFather;

  /// No description provided for @guardianRelationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardianRelationshipGuardian;

  /// No description provided for @guardianRelationshipGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get guardianRelationshipGrandparent;

  /// No description provided for @guardianRelationshipAuntUncle.
  ///
  /// In en, this message translates to:
  /// **'Aunt / Uncle'**
  String get guardianRelationshipAuntUncle;

  /// Shared by GuardianTile and AddGuardianForm — both mapped the same relationship codes independently before ADR-0013.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get guardianRelationshipOther;

  /// No description provided for @guardianTilePrimaryChip.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get guardianTilePrimaryChip;

  /// No description provided for @guardianTileCanCollectChip.
  ///
  /// In en, this message translates to:
  /// **'Can collect'**
  String get guardianTileCanCollectChip;

  /// No description provided for @guardianTileCannotCollectChip.
  ///
  /// In en, this message translates to:
  /// **'Cannot collect'**
  String get guardianTileCannotCollectChip;

  /// No description provided for @guardianTileNotifiedChip.
  ///
  /// In en, this message translates to:
  /// **'Notified'**
  String get guardianTileNotifiedChip;

  /// No description provided for @guardianTileCanReportAbsenceChip.
  ///
  /// In en, this message translates to:
  /// **'Can report absence'**
  String get guardianTileCanReportAbsenceChip;

  /// No description provided for @guardianTileCanSignInChip.
  ///
  /// In en, this message translates to:
  /// **'Can sign in'**
  String get guardianTileCanSignInChip;

  /// No description provided for @guardianTileNoSignInYetChip.
  ///
  /// In en, this message translates to:
  /// **'No sign-in yet'**
  String get guardianTileNoSignInYetChip;

  /// No description provided for @guardianTileRelationshipAndPhone.
  ///
  /// In en, this message translates to:
  /// **'{relationship} · {phone}'**
  String guardianTileRelationshipAndPhone(String relationship, String phone);

  /// No description provided for @addGuardianFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add parent'**
  String get addGuardianFormTitle;

  /// No description provided for @addGuardianFormIntro.
  ///
  /// In en, this message translates to:
  /// **'The phone number becomes their sign-in straight away — they open the parent app, enter their number, and get a one-time code. Enter it carefully.'**
  String get addGuardianFormIntro;

  /// No description provided for @addGuardianRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get addGuardianRelationshipLabel;

  /// No description provided for @addGuardianFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get addGuardianFirstNameLabel;

  /// No description provided for @addGuardianLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get addGuardianLastNameLabel;

  /// No description provided for @addGuardianPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (parent-app sign-in)'**
  String get addGuardianPhoneLabel;

  /// No description provided for @addGuardianPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9990000001'**
  String get addGuardianPhoneHint;

  /// No description provided for @addGuardianEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get addGuardianEmailLabel;

  /// No description provided for @addGuardianCanViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Can see this child'**
  String get addGuardianCanViewTitle;

  /// No description provided for @addGuardianCanViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View the child and their journey in the app'**
  String get addGuardianCanViewSubtitle;

  /// No description provided for @addGuardianCanNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Receives notifications'**
  String get addGuardianCanNotifyTitle;

  /// No description provided for @addGuardianCanNotifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding, arrival, and alert messages'**
  String get addGuardianCanNotifySubtitle;

  /// No description provided for @addGuardianCanHandoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Can collect the child'**
  String get addGuardianCanHandoverTitle;

  /// No description provided for @addGuardianCanHandoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authorised to receive the child at the stop — needed before the child can be put on a bus'**
  String get addGuardianCanHandoverSubtitle;

  /// No description provided for @addGuardianCanAbsenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Can report an absence'**
  String get addGuardianCanAbsenceTitle;

  /// No description provided for @addGuardianCanAbsenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell the school the child will not travel'**
  String get addGuardianCanAbsenceSubtitle;

  /// No description provided for @addGuardianPrimaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary contact'**
  String get addGuardianPrimaryTitle;

  /// No description provided for @addGuardianPrimarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The first person the school reaches'**
  String get addGuardianPrimarySubtitle;

  /// No description provided for @addGuardianSubmitSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Adding'**
  String get addGuardianSubmitSpinnerLabel;

  /// No description provided for @assignRouteTitlePickup.
  ///
  /// In en, this message translates to:
  /// **'Set pickup'**
  String get assignRouteTitlePickup;

  /// No description provided for @assignRouteTitleDrop.
  ///
  /// In en, this message translates to:
  /// **'Set drop'**
  String get assignRouteTitleDrop;

  /// No description provided for @assignRoutePickupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this child is picked up in the morning.'**
  String get assignRoutePickupSubtitle;

  /// No description provided for @assignRouteDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this child is dropped in the afternoon.'**
  String get assignRouteDropSubtitle;

  /// No description provided for @assignRouteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get assignRouteFieldLabel;

  /// No description provided for @assignRouteNoRoutesHint.
  ///
  /// In en, this message translates to:
  /// **'No routes on this school yet'**
  String get assignRouteNoRoutesHint;

  /// No description provided for @assignRouteSelectRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Select a route'**
  String get assignRouteSelectRouteHint;

  /// No description provided for @assignRouteNameAndCode.
  ///
  /// In en, this message translates to:
  /// **'{name} · {code}'**
  String assignRouteNameAndCode(String name, String code);

  /// No description provided for @assignStopFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get assignStopFieldLabel;

  /// No description provided for @assignRouteStopsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this route\'s stops. Try again.'**
  String get assignRouteStopsLoadError;

  /// No description provided for @assignRouteStopHintSelectRouteFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a route first'**
  String get assignRouteStopHintSelectRouteFirst;

  /// No description provided for @assignRouteStopHintLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading stops…'**
  String get assignRouteStopHintLoading;

  /// No description provided for @assignRouteStopHintNoStops.
  ///
  /// In en, this message translates to:
  /// **'This route has no stops yet'**
  String get assignRouteStopHintNoStops;

  /// No description provided for @assignRouteStopHintSelectStop.
  ///
  /// In en, this message translates to:
  /// **'Select a stop'**
  String get assignRouteStopHintSelectStop;

  /// No description provided for @assignRouteSavingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get assignRouteSavingSpinnerLabel;

  /// No description provided for @platformHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform health'**
  String get platformHealthTitle;

  /// No description provided for @platformHealthRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get platformHealthRefreshButton;

  /// No description provided for @platformHealthIntro.
  ///
  /// In en, this message translates to:
  /// **'A quick pulse check — whether the platform is reachable, and how many organizations are on it. Not a full monitoring dashboard.'**
  String get platformHealthIntro;

  /// No description provided for @platformHealthCheckingLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking platform health'**
  String get platformHealthCheckingLabel;

  /// No description provided for @platformHealthOrganizationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Organizations on the platform'**
  String get platformHealthOrganizationsHeading;

  /// No description provided for @platformHealthCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked {relativeTime}'**
  String platformHealthCheckedAt(String relativeTime);

  /// No description provided for @platformHealthJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get platformHealthJustNow;

  /// No description provided for @platformHealthSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second ago} other{{seconds} seconds ago}}'**
  String platformHealthSecondsAgo(int seconds);

  /// No description provided for @platformHealthMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute ago} other{{minutes} minutes ago}}'**
  String platformHealthMinutesAgo(int minutes);

  /// No description provided for @platformHealthHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour ago} other{{hours} hours ago}}'**
  String platformHealthHoursAgo(int hours);

  /// No description provided for @platformHealthReachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform is reachable'**
  String get platformHealthReachableTitle;

  /// No description provided for @platformHealthDegradedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm platform health'**
  String get platformHealthDegradedTitle;

  /// No description provided for @platformHealthReachableBody.
  ///
  /// In en, this message translates to:
  /// **'The last check reached the database without issue.'**
  String get platformHealthReachableBody;

  /// No description provided for @platformHealthDegradedBody.
  ///
  /// In en, this message translates to:
  /// **'The last check could not read organization data. This can be transient — try refreshing in a moment. If it keeps failing, that\'s worth escalating.'**
  String get platformHealthDegradedBody;

  /// No description provided for @platformHealthCountTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get platformHealthCountTotal;

  /// No description provided for @platformHealthCountActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get platformHealthCountActive;

  /// No description provided for @platformHealthCountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get platformHealthCountSuspended;

  /// No description provided for @platformHealthCountClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get platformHealthCountClosed;

  /// No description provided for @auditTrailTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit trail'**
  String get auditTrailTitle;

  /// No description provided for @auditScopeAllActivity.
  ///
  /// In en, this message translates to:
  /// **'All activity'**
  String get auditScopeAllActivity;

  /// No description provided for @auditScopeOverrides.
  ///
  /// In en, this message translates to:
  /// **'Overrides'**
  String get auditScopeOverrides;

  /// No description provided for @auditOverridesDescription.
  ///
  /// In en, this message translates to:
  /// **'Actions taken with an override reason — a person overrode a safety check and said why.'**
  String get auditOverridesDescription;

  /// No description provided for @auditAllActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Every safety-relevant action, most recent first. Records cannot be edited or removed.'**
  String get auditAllActivityDescription;

  /// No description provided for @auditLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading audit trail'**
  String get auditLoadingLabel;

  /// No description provided for @auditLoadError.
  ///
  /// In en, this message translates to:
  /// **'The audit trail could not be loaded right now. Try again.'**
  String get auditLoadError;

  /// No description provided for @auditNoOverridesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No overrides recorded. That is the healthy state.'**
  String get auditNoOverridesEmptyState;

  /// No description provided for @auditNoActivityEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet.'**
  String get auditNoActivityEmptyState;

  /// No description provided for @auditReasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String auditReasonPrefix(String reason);

  /// No description provided for @auditOverrideBadge.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get auditOverrideBadge;

  /// No description provided for @errorGenericLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'That could not be loaded right now. Try again.'**
  String get errorGenericLoadRetry;

  /// No description provided for @pickSchoolFirstTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick a school first'**
  String get pickSchoolFirstTooltip;

  /// No description provided for @vehicleListTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicleListTitle;

  /// No description provided for @vehicleListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading fleet'**
  String get vehicleListLoadingLabel;

  /// No description provided for @vehicleListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No fleet loaded. Pick a school above, or add the first vehicle.'**
  String get vehicleListEmptyState;

  /// No description provided for @vehicleListRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{registrationNo} · {vehicleType} · {seats} seats'**
  String vehicleListRowSubtitle(
    String registrationNo,
    String vehicleType,
    int seats,
  );

  /// No description provided for @vehicleListAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get vehicleListAddButton;

  /// No description provided for @commonAddingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Adding'**
  String get commonAddingSpinnerLabel;

  /// No description provided for @createVehicleFormIntro.
  ///
  /// In en, this message translates to:
  /// **'The display name is what parents see in notifications — \"Bus 12\", not the plate number. Added to the school you have selected above.'**
  String get createVehicleFormIntro;

  /// No description provided for @vehicleTypeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get vehicleTypeBus;

  /// No description provided for @vehicleTypeVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleTypeVan;

  /// No description provided for @vehicleTypeMinibus.
  ///
  /// In en, this message translates to:
  /// **'Minibus'**
  String get vehicleTypeMinibus;

  /// No description provided for @createVehicleRegistrationNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get createVehicleRegistrationNoLabel;

  /// No description provided for @createVehicleRegistrationNoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. DL1PC1234'**
  String get createVehicleRegistrationNoHint;

  /// No description provided for @createVehicleDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get createVehicleDisplayNameLabel;

  /// No description provided for @createVehicleDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bus 12'**
  String get createVehicleDisplayNameHint;

  /// No description provided for @createVehicleSeatingCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Seating capacity'**
  String get createVehicleSeatingCapacityLabel;

  /// No description provided for @createVehicleVendorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor name (optional, for outsourced fleets)'**
  String get createVehicleVendorNameLabel;

  /// No description provided for @commonSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearchLabel;

  /// No description provided for @commonClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearchTooltip;

  /// No description provided for @staffListTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get staffListTitle;

  /// No description provided for @staffListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name, phone, or employee code'**
  String get staffListSearchHint;

  /// No description provided for @staffListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading roster'**
  String get staffListLoadingLabel;

  /// No description provided for @staffListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No roster loaded. Pick a school above, or add the first driver.'**
  String get staffListEmptyState;

  /// No description provided for @staffListSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No one on this roster matches \"{query}\".'**
  String staffListSearchNoMatches(String query);

  /// No description provided for @staffListRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{staffType} · {phone}'**
  String staffListRowSubtitle(String staffType, String phone);

  /// No description provided for @staffListHasLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'Can sign in to the driver app'**
  String get staffListHasLoginTooltip;

  /// No description provided for @staffListNoLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'No driver-app sign-in yet'**
  String get staffListNoLoginTooltip;

  /// No description provided for @staffListAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get staffListAddButton;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @commonSavingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get commonSavingSpinnerLabel;

  /// No description provided for @commonSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChangesButton;

  /// No description provided for @commonChangesSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get commonChangesSavedSnackbar;

  /// No description provided for @createStaffFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add driver or attendant'**
  String get createStaffFormTitle;

  /// No description provided for @createStaffFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Creates the roster record and a working driver-app sign-in in one step — the phone number below is what they sign in with (phone + one-time code). Added to the school you have selected above.'**
  String get createStaffFormIntro;

  /// No description provided for @staffTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get staffTypeDriver;

  /// No description provided for @staffTypeAttendant.
  ///
  /// In en, this message translates to:
  /// **'Attendant'**
  String get staffTypeAttendant;

  /// No description provided for @staffPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (driver-app sign-in)'**
  String get staffPhoneLabel;

  /// No description provided for @staffPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9990000001'**
  String get staffPhoneHint;

  /// No description provided for @staffEmployeeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee code (optional)'**
  String get staffEmployeeCodeLabel;

  /// No description provided for @staffVendorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor name (optional, for contracted staff)'**
  String get staffVendorNameLabel;

  /// No description provided for @editStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editStaffTitle(String name);

  /// No description provided for @studentListTitle.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentListTitle;

  /// No description provided for @studentListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter loaded students by name or admission number'**
  String get studentListSearchHint;

  /// No description provided for @studentWithdrawConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw student?'**
  String get studentWithdrawConfirmTitle;

  /// Safety-relevant: confirms removing a student from transport eligibility.
  ///
  /// In en, this message translates to:
  /// **'{name} ({admissionNo}) will be taken off the roll and removed from transport.\n\nTheir record is kept — safety records reference it — and can still be read.'**
  String studentWithdrawConfirmBody(String name, String admissionNo);

  /// No description provided for @studentWithdrawConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get studentWithdrawConfirmButton;

  /// No description provided for @studentListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading register'**
  String get studentListLoadingLabel;

  /// No description provided for @studentListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No register loaded. Pick a school above, or enrol the first student.'**
  String get studentListEmptyState;

  /// No description provided for @studentListNoMatchWithMore.
  ///
  /// In en, this message translates to:
  /// **'No loaded student matches that. Scroll to load more of the register, then search again.'**
  String get studentListNoMatchWithMore;

  /// No description provided for @studentListNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No student matches that.'**
  String get studentListNoMatch;

  /// No description provided for @studentListLoadingMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading more students'**
  String get studentListLoadingMoreLabel;

  /// No description provided for @studentListCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String studentListCount(int count);

  /// No description provided for @studentListEnrolButton.
  ///
  /// In en, this message translates to:
  /// **'Enrol student'**
  String get studentListEnrolButton;

  /// No description provided for @studentListEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String studentListEditTooltip(String name);

  /// No description provided for @studentListWithdrawTooltip.
  ///
  /// In en, this message translates to:
  /// **'Withdraw {name}'**
  String studentListWithdrawTooltip(String name);

  /// No description provided for @studentStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get studentStatusWithdrawn;

  /// No description provided for @studentStatusOnRollNoTransport.
  ///
  /// In en, this message translates to:
  /// **'On roll · not using transport'**
  String get studentStatusOnRollNoTransport;

  /// No description provided for @studentStatusOnRollTransport.
  ///
  /// In en, this message translates to:
  /// **'On roll · transport'**
  String get studentStatusOnRollTransport;

  /// No description provided for @studentListRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{admissionNo} · {status}'**
  String studentListRowSubtitle(String admissionNo, String status);

  /// No description provided for @studentFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get studentFormEditTitle;

  /// No description provided for @studentFormAdmissionNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Admission number'**
  String get studentFormAdmissionNoLabel;

  /// No description provided for @studentFormAdmissionNoHelperEditing.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed — safety records reference it'**
  String get studentFormAdmissionNoHelperEditing;

  /// No description provided for @studentFormAdmissionNoHelperNew.
  ///
  /// In en, this message translates to:
  /// **'The number the school already uses for this student'**
  String get studentFormAdmissionNoHelperNew;

  /// No description provided for @studentFormAdmissionNoRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an admission number'**
  String get studentFormAdmissionNoRequired;

  /// No description provided for @studentFormFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a first name'**
  String get studentFormFirstNameRequired;

  /// No description provided for @studentFormLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a last name'**
  String get studentFormLastNameRequired;

  /// No description provided for @studentFormDateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get studentFormDateOfBirthLabel;

  /// No description provided for @studentFormDateOfBirthHelper.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD — used to decide self-release eligibility'**
  String get studentFormDateOfBirthHelper;

  /// No description provided for @studentFormDateOfBirthFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use the format YYYY-MM-DD'**
  String get studentFormDateOfBirthFormatError;

  /// No description provided for @studentFormDateOfBirthPastError.
  ///
  /// In en, this message translates to:
  /// **'Date of birth must be in the past'**
  String get studentFormDateOfBirthPastError;

  /// No description provided for @studentFormTransportEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligible for transport'**
  String get studentFormTransportEligibleTitle;

  /// No description provided for @studentFormTransportEligibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A student on the roll whose family has opted out stays enrolled but off the bus'**
  String get studentFormTransportEligibleSubtitle;

  /// No description provided for @studentDetailAdmissionLine.
  ///
  /// In en, this message translates to:
  /// **'Admission {admissionNo}'**
  String studentDetailAdmissionLine(String admissionNo);

  /// No description provided for @studentDetailDobLine.
  ///
  /// In en, this message translates to:
  /// **'Date of birth {date}'**
  String studentDetailDobLine(String date);

  /// No description provided for @studentDetailStatusOnRollTransport.
  ///
  /// In en, this message translates to:
  /// **'On roll · using transport'**
  String get studentDetailStatusOnRollTransport;

  /// No description provided for @studentDetailParentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get studentDetailParentsTitle;

  /// No description provided for @studentDetailLoadingParentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading parents'**
  String get studentDetailLoadingParentsLabel;

  /// No description provided for @studentDetailNoParentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No parents yet. Add one so they can see this child and be reached — and so the child can be assigned to a bus.'**
  String get studentDetailNoParentsEmptyState;

  /// Safety-relevant: warns that no guardian is authorised to collect the child before a bus assignment is made.
  ///
  /// In en, this message translates to:
  /// **'No parent here can collect the child yet — turn on \"Can collect the child\" for at least one before assigning a bus.'**
  String get studentDetailNoHandoverGuardianWarning;

  /// No description provided for @studentDetailPickupDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup & drop'**
  String get studentDetailPickupDropTitle;

  /// No description provided for @studentDetailLoadingAssignmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading assignments'**
  String get studentDetailLoadingAssignmentsLabel;

  /// No description provided for @studentDetailDirectionPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get studentDetailDirectionPickup;

  /// No description provided for @studentDetailDirectionDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get studentDetailDirectionDrop;

  /// No description provided for @studentDetailAssignmentSummary.
  ///
  /// In en, this message translates to:
  /// **'{routeName} · {routeCode} → {stopName}'**
  String studentDetailAssignmentSummary(
    String routeName,
    String routeCode,
    String stopName,
  );

  /// No description provided for @studentDetailAssignmentNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get studentDetailAssignmentNotSet;

  /// No description provided for @studentDetailRemoveAssignment.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String studentDetailRemoveAssignment(String label);

  /// No description provided for @studentDetailChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get studentDetailChangeButton;

  /// No description provided for @studentDetailSetButton.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get studentDetailSetButton;

  /// Safety-relevant: blocks a bus assignment until a guardian is authorised to collect the child.
  ///
  /// In en, this message translates to:
  /// **'Add a parent who can collect this child (turn on \"Can collect the child\") before assigning a bus.'**
  String get studentAssignErrorNoActiveGuardian;

  /// No description provided for @studentAssignErrorAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'This child already has that assignment — remove the current one first.'**
  String get studentAssignErrorAlreadyAssigned;

  /// No description provided for @studentAssignErrorApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The service is unreachable right now. Try again.'**
  String get studentAssignErrorApiUnreachable;

  /// No description provided for @studentAssignErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'That could not be saved right now. Try again.'**
  String get studentAssignErrorGeneric;

  /// No description provided for @userListTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get userListTitle;

  /// No description provided for @userListAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add administrator'**
  String get userListAddButton;

  /// No description provided for @userListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name, email, or role'**
  String get userListSearchHint;

  /// No description provided for @userListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading users'**
  String get userListLoadingLabel;

  /// No description provided for @userListPickOrgPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick an organization above to see its administrators.'**
  String get userListPickOrgPrompt;

  /// No description provided for @userListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No administrators yet. Add the first one above.'**
  String get userListEmptyState;

  /// No description provided for @userListNoSearchMatches.
  ///
  /// In en, this message translates to:
  /// **'No one matches \"{query}\".'**
  String userListNoSearchMatches(String query);

  /// No description provided for @userToggleReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}?'**
  String userToggleReactivateTitle(String name);

  /// No description provided for @userToggleDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String userToggleDeactivateTitle(String name);

  /// No description provided for @userToggleReactivateBody.
  ///
  /// In en, this message translates to:
  /// **'They will be able to sign in again.'**
  String get userToggleReactivateBody;

  /// No description provided for @userToggleDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to sign in. This can be reversed at any time.'**
  String get userToggleDeactivateBody;

  /// No description provided for @userToggleReactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get userToggleReactivateButton;

  /// No description provided for @userToggleDeactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get userToggleDeactivateButton;

  /// No description provided for @userStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userStatusActive;

  /// No description provided for @userStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get userStatusPending;

  /// No description provided for @userStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get userStatusInactive;

  /// No description provided for @userListRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{email} · {role}'**
  String userListRowSubtitle(String email, String role);

  /// No description provided for @userMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get userMoreActionsTooltip;

  /// No description provided for @userResendInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Resend invitation'**
  String get userResendInvitationLabel;

  /// No description provided for @userSendResetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get userSendResetCodeLabel;

  /// No description provided for @createUserInviteDescription.
  ///
  /// In en, this message translates to:
  /// **'We email them a link to set their own password and activate the account.'**
  String get createUserInviteDescription;

  /// No description provided for @createUserPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'You set a password now and share it with them yourself.'**
  String get createUserPasswordDescription;

  /// No description provided for @createUserSendInviteOption.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get createUserSendInviteOption;

  /// No description provided for @createUserSetPasswordOption.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get createUserSetPasswordOption;

  /// No description provided for @createUserSchoolHint.
  ///
  /// In en, this message translates to:
  /// **'Which school this role applies to'**
  String get createUserSchoolHint;

  /// No description provided for @createUserEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (sign-in)'**
  String get createUserEmailLabel;

  /// No description provided for @createUserEmailHint.
  ///
  /// In en, this message translates to:
  /// **'What this person signs in with'**
  String get createUserEmailHint;

  /// No description provided for @createUserPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get createUserPhoneLabel;

  /// No description provided for @createUserPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial password'**
  String get createUserPasswordLabel;

  /// No description provided for @createUserPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters'**
  String get createUserPasswordHint;

  /// No description provided for @createUserGeneratePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate a password'**
  String get createUserGeneratePasswordTooltip;

  /// No description provided for @invitationSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invitationSentTitle;

  /// No description provided for @invitationSentBody.
  ///
  /// In en, this message translates to:
  /// **'We’ve emailed {email} a link to set their password. It is valid for 72 hours; you can re-send it from their row if it expires.'**
  String invitationSentBody(String email);

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get accountCreatedTitle;

  /// Safety/security-relevant: a one-time-shown administrative credential.
  ///
  /// In en, this message translates to:
  /// **'Share these sign-in details with them now — this password will not be shown again.'**
  String get accountCreatedBody;

  /// No description provided for @credentialsEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get credentialsEmailLabel;

  /// No description provided for @credentialsPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get credentialsPasswordLabel;

  /// No description provided for @copyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyTooltip;

  /// No description provided for @copiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String copiedSnackbar(String label);

  /// No description provided for @editUserLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred locale'**
  String get editUserLocaleLabel;

  /// No description provided for @editUserLocaleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. en'**
  String get editUserLocaleHint;

  /// No description provided for @orgListAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add organization'**
  String get orgListAddButton;

  /// No description provided for @orgListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading organizations'**
  String get orgListLoadingLabel;

  /// No description provided for @orgListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No organizations yet. Add the first one to get started.'**
  String get orgListEmptyState;

  /// No description provided for @orgListRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{code} · {regionProfile}'**
  String orgListRowSubtitle(String code, String regionProfile);

  /// No description provided for @orgSuspendedChip.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get orgSuspendedChip;

  /// No description provided for @orgListLoadError.
  ///
  /// In en, this message translates to:
  /// **'That could not be loaded right now. Try again shortly.'**
  String get orgListLoadError;

  /// No description provided for @createOrgCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization code'**
  String get createOrgCodeLabel;

  /// No description provided for @createOrgCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GREENWOOD'**
  String get createOrgCodeHint;

  /// No description provided for @createOrgNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization name'**
  String get createOrgNameLabel;

  /// No description provided for @createOrgNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Greenwood Education Group'**
  String get createOrgNameHint;

  /// No description provided for @createOrgRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region profile code'**
  String get createOrgRegionLabel;

  /// No description provided for @createOrgContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact email (optional)'**
  String get createOrgContactEmailLabel;

  /// No description provided for @createOrgContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone (optional)'**
  String get createOrgContactPhoneLabel;

  /// No description provided for @createOrgCreatingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Creating organization'**
  String get createOrgCreatingSpinnerLabel;

  /// No description provided for @schoolFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'School name'**
  String get schoolFieldNameLabel;

  /// No description provided for @schoolFieldTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone (IANA identifier)'**
  String get schoolFieldTimezoneLabel;

  /// No description provided for @schoolFieldLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get schoolFieldLatitudeLabel;

  /// No description provided for @schoolFieldLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get schoolFieldLongitudeLabel;

  /// Shared field labels between CreateSchoolForm (onboarding step 2) and SchoolEditForm (A-40/A-41 edit) — one key per field so the two never drift in Kannada either.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius (metres, 20–2000)'**
  String get schoolFieldGeofenceLabel;

  /// No description provided for @schoolFieldPlusCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Plus Code'**
  String get schoolFieldPlusCodeLabel;

  /// No description provided for @schoolFieldPlusCodeResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved to {latitude}, {longitude} — accurate to about {metres} m'**
  String schoolFieldPlusCodeResolved(
    String latitude,
    String longitude,
    String metres,
  );

  /// No description provided for @schoolFieldPlusCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a complete Plus Code. A short code like 8F+6W needs a town name, which this field cannot resolve — use the full code.'**
  String get schoolFieldPlusCodeInvalid;

  /// No description provided for @createSchoolCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'School code'**
  String get createSchoolCodeLabel;

  /// No description provided for @createSchoolCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GW-MAIN'**
  String get createSchoolCodeHint;

  /// No description provided for @createSchoolNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Greenwood Main Campus'**
  String get createSchoolNameHint;

  /// No description provided for @createSchoolAddingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Adding school'**
  String get createSchoolAddingSpinnerLabel;

  /// No description provided for @createSchoolSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Add school'**
  String get createSchoolSubmitButton;

  /// No description provided for @schoolDetailsIdLabel.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get schoolDetailsIdLabel;

  /// No description provided for @schoolDetailsIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Give this to whoever registers staff, vehicles, or routes for this school.'**
  String get schoolDetailsIdHelper;

  /// No description provided for @schoolDetailsCodeFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'School code (fixed)'**
  String get schoolDetailsCodeFixedLabel;

  /// No description provided for @schoolDetailsSavingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving school'**
  String get schoolDetailsSavingSpinnerLabel;

  /// No description provided for @schoolDetailsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save school changes'**
  String get schoolDetailsSaveButton;

  /// No description provided for @copiedToClipboardSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboardSnackbar;

  /// No description provided for @onboardingCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization onboarded'**
  String get onboardingCompleteTitle;

  /// No description provided for @onboardingSummaryOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get onboardingSummaryOrgLabel;

  /// No description provided for @onboardingNameAndCode.
  ///
  /// In en, this message translates to:
  /// **'{name} ({code})'**
  String onboardingNameAndCode(String name, String code);

  /// No description provided for @onboardingSummaryFirstSchoolLabel.
  ///
  /// In en, this message translates to:
  /// **'First school'**
  String get onboardingSummaryFirstSchoolLabel;

  /// No description provided for @onboardingNoSchoolYet.
  ///
  /// In en, this message translates to:
  /// **'No school was added yet. Add one from the Schools screen before this organization is used day to day (BR-TEN-002).'**
  String get onboardingNoSchoolYet;

  /// No description provided for @onboardingStartAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Onboard another organization'**
  String get onboardingStartAnotherButton;

  /// No description provided for @orgDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization details'**
  String get orgDetailsSectionTitle;

  /// No description provided for @orgStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get orgStatusClosed;

  /// No description provided for @orgStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orgStatusActive;

  /// No description provided for @orgConfirmSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String orgConfirmSuspendTitle(String name);

  /// No description provided for @orgConfirmSuspendBody.
  ///
  /// In en, this message translates to:
  /// **'This blocks sign-in and administrative access for everyone in {name}. No data is deleted, and any trip already in progress keeps recording safety events as normal (BR-TEN-006). You can reactivate at any time.'**
  String orgConfirmSuspendBody(String name);

  /// No description provided for @orgSuspendButton.
  ///
  /// In en, this message translates to:
  /// **'Suspend organization'**
  String get orgSuspendButton;

  /// No description provided for @orgConfirmReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}?'**
  String orgConfirmReactivateTitle(String name);

  /// No description provided for @orgConfirmReactivateBody.
  ///
  /// In en, this message translates to:
  /// **'This restores sign-in and administrative access for everyone in {name}.'**
  String orgConfirmReactivateBody(String name);

  /// No description provided for @orgReactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate organization'**
  String get orgReactivateButton;

  /// No description provided for @orgDetailsCodeFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization code (fixed, BR-TEN-007)'**
  String get orgDetailsCodeFixedLabel;

  /// No description provided for @orgDetailsSavingSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving organization'**
  String get orgDetailsSavingSpinnerLabel;

  /// No description provided for @orgDetailsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save organization changes'**
  String get orgDetailsSaveButton;

  /// No description provided for @addSchoolPromptIntro.
  ///
  /// In en, this message translates to:
  /// **'No school has been added yet. {orgName} needs at least one before it can be used day to day.'**
  String addSchoolPromptIntro(String orgName);

  /// No description provided for @addSchoolPromptSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get addSchoolPromptSkipButton;

  /// No description provided for @routeListLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading routes'**
  String get routeListLoadingLabel;

  /// No description provided for @routeListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No routes loaded. Pick a school above, or add the first route.'**
  String get routeListEmptyState;

  /// No description provided for @routeStopsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stops on {name}'**
  String routeStopsTooltip(String name);

  /// No description provided for @routeHasVehicleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Has a default bus'**
  String get routeHasVehicleTooltip;

  /// No description provided for @routeNoVehicleTooltip.
  ///
  /// In en, this message translates to:
  /// **'No bus assigned yet'**
  String get routeNoVehicleTooltip;

  /// No description provided for @routeListAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get routeListAddButton;

  /// No description provided for @createRouteIntro.
  ///
  /// In en, this message translates to:
  /// **'Creates the route itself. Stops are added separately once the map editor exists — this is enough for assigning a driver or attendant to it today. Added to the school you have selected above.'**
  String get createRouteIntro;

  /// No description provided for @createRouteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Route code'**
  String get createRouteCodeLabel;

  /// No description provided for @createRouteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. R3'**
  String get createRouteCodeHint;

  /// No description provided for @createRouteNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get createRouteNameLabel;

  /// No description provided for @createRouteNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Green Park — Morning'**
  String get createRouteNameHint;

  /// No description provided for @createRouteDefaultVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default bus (optional)'**
  String get createRouteDefaultVehicleLabel;

  /// No description provided for @createRouteNoVehiclesHint.
  ///
  /// In en, this message translates to:
  /// **'No vehicles on this school yet'**
  String get createRouteNoVehiclesHint;

  /// No description provided for @noneOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOptionLabel;

  /// No description provided for @createRouteVehicleOption.
  ///
  /// In en, this message translates to:
  /// **'{displayName} · {registrationNo}'**
  String createRouteVehicleOption(String displayName, String registrationNo);

  /// No description provided for @routeCrewAssignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign crew'**
  String get routeCrewAssignButton;

  /// No description provided for @routeCrewLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading crew'**
  String get routeCrewLoadingLabel;

  /// No description provided for @routeCrewEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No crew assigned yet.'**
  String get routeCrewEmptyState;

  /// No description provided for @routeCrewBothDirectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Both directions'**
  String get routeCrewBothDirectionsLabel;

  /// No description provided for @dutyFormStaffLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver or attendant'**
  String get dutyFormStaffLabel;

  /// No description provided for @dutyFormNoRosterHint.
  ///
  /// In en, this message translates to:
  /// **'No roster loaded for this school'**
  String get dutyFormNoRosterHint;

  /// No description provided for @dutyFormSelectPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Select a person'**
  String get dutyFormSelectPersonHint;

  /// No description provided for @dutyFormStaffOption.
  ///
  /// In en, this message translates to:
  /// **'{name} · {staffType}'**
  String dutyFormStaffOption(String name, String staffType);

  /// No description provided for @directionBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get directionBoth;

  /// No description provided for @dutyFormAssigningSpinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigning'**
  String get dutyFormAssigningSpinnerLabel;

  /// No description provided for @dutyFormAssignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get dutyFormAssignButton;

  /// No description provided for @routeStopsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get routeStopsDialogTitle;

  /// No description provided for @routeStopsLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading stops'**
  String get routeStopsLoadingLabel;

  /// No description provided for @routeStopsMinWarning.
  ///
  /// In en, this message translates to:
  /// **'A route needs at least two stops before students can be assigned to it.'**
  String get routeStopsMinWarning;

  /// No description provided for @routeStopsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No stops yet. Add the first one.'**
  String get routeStopsEmptyState;

  /// No description provided for @routeStopsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get routeStopsAddButton;

  /// No description provided for @routeStopsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String routeStopsRemoveTooltip(String name);

  /// No description provided for @stopPickupTime.
  ///
  /// In en, this message translates to:
  /// **'pickup {time}'**
  String stopPickupTime(String time);

  /// No description provided for @stopDropTime.
  ///
  /// In en, this message translates to:
  /// **'drop {time}'**
  String stopDropTime(String time);

  /// No description provided for @stopGeofenceRadiusMetres.
  ///
  /// In en, this message translates to:
  /// **'{radius} m'**
  String stopGeofenceRadiusMetres(int radius);

  /// No description provided for @stopFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop name'**
  String get stopFormNameLabel;

  /// No description provided for @stopFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Green Park — parents see this'**
  String get stopFormNameHint;

  /// No description provided for @stopFormLatitudeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 28.5494'**
  String get stopFormLatitudeHint;

  /// No description provided for @stopFormLongitudeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 77.2001'**
  String get stopFormLongitudeHint;

  /// No description provided for @stopFormGeofenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius (metres)'**
  String get stopFormGeofenceLabel;

  /// No description provided for @stopFormGeofenceHint.
  ///
  /// In en, this message translates to:
  /// **'20–500'**
  String get stopFormGeofenceHint;

  /// No description provided for @stopFormPickupTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup time (optional)'**
  String get stopFormPickupTimeLabel;

  /// No description provided for @stopFormDropTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop time (optional)'**
  String get stopFormDropTimeLabel;

  /// No description provided for @stopFormTimeHint.
  ///
  /// In en, this message translates to:
  /// **'HH:mm'**
  String get stopFormTimeHint;

  /// No description provided for @stopFormLandmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get stopFormLandmarkLabel;

  /// No description provided for @stopFormLandmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Helps parents find the stop'**
  String get stopFormLandmarkHint;

  /// No description provided for @stopFormErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the stop a name.'**
  String get stopFormErrorNameRequired;

  /// No description provided for @stopFormErrorLatitudeRange.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be a number between -90 and 90.'**
  String get stopFormErrorLatitudeRange;

  /// No description provided for @stopFormErrorLongitudeRange.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be a number between -180 and 180.'**
  String get stopFormErrorLongitudeRange;

  /// No description provided for @stopFormErrorGeofenceRange.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius must be between 20 and 500 metres.'**
  String get stopFormErrorGeofenceRange;

  /// No description provided for @stopFormErrorTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Times must be in 24-hour HH:mm form, e.g. 07:40.'**
  String get stopFormErrorTimeFormat;

  /// No description provided for @schoolSettingsLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading school'**
  String get schoolSettingsLoadingLabel;

  /// No description provided for @studentListImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get studentListImportButton;

  /// No description provided for @studentImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import students'**
  String get studentImportTitle;

  /// No description provided for @studentImportIntro.
  ///
  /// In en, this message translates to:
  /// **'Upload a spreadsheet of students, saved as CSV. Rows that are ready are enrolled straight away; anything that needs fixing is listed for you to correct and upload again.'**
  String get studentImportIntro;

  /// No description provided for @studentImportColumnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get studentImportColumnsTitle;

  /// No description provided for @studentImportColumnsBody.
  ///
  /// In en, this message translates to:
  /// **'Required: admissionNo, firstName, lastName. Optional: dateOfBirth (YYYY-MM-DD) and transportEligible (true or false — defaults to true). Column names are matched loosely, ignoring case and spaces. A column that isn\'t one of these stops the whole file — guardian and stop columns are not supported yet.'**
  String get studentImportColumnsBody;

  /// No description provided for @studentImportChooseFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV file'**
  String get studentImportChooseFileButton;

  /// No description provided for @studentImportUploadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploading and checking the file'**
  String get studentImportUploadingLabel;

  /// No description provided for @studentImportUploadingNamed.
  ///
  /// In en, this message translates to:
  /// **'Uploading {name}…'**
  String studentImportUploadingNamed(String name);

  /// A-12 result headline. Mirrors ADMIN_WEB.md's mock: '412 rows · 408 imported · 4 errors'.
  ///
  /// In en, this message translates to:
  /// **'{totalRows} rows · {successCount} imported · {errorCount} errors'**
  String studentImportSummary(int totalRows, int successCount, int errorCount);

  /// No description provided for @studentImportSummaryHintErrors.
  ///
  /// In en, this message translates to:
  /// **'The rows below were not enrolled. Fix them in your spreadsheet and upload again — only the corrected rows need to be in the next file.'**
  String get studentImportSummaryHintErrors;

  /// No description provided for @studentImportSummaryHintAllImported.
  ///
  /// In en, this message translates to:
  /// **'Every row was enrolled. They now appear on the register.'**
  String get studentImportSummaryHintAllImported;

  /// No description provided for @studentImportSummaryHintNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing was enrolled. Correct the rows below and upload again.'**
  String get studentImportSummaryHintNothing;

  /// No description provided for @studentImportDownloadErrorsButton.
  ///
  /// In en, this message translates to:
  /// **'Download error rows'**
  String get studentImportDownloadErrorsButton;

  /// No description provided for @studentImportAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Import another file'**
  String get studentImportAnotherButton;

  /// No description provided for @studentImportColRow.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get studentImportColRow;

  /// No description provided for @studentImportColField.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get studentImportColField;

  /// No description provided for @studentImportColProblem.
  ///
  /// In en, this message translates to:
  /// **'What to fix'**
  String get studentImportColProblem;

  /// No description provided for @studentImportErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'That file has no student rows. Check you saved the sheet with the students in it as CSV.'**
  String get studentImportErrorEmpty;

  /// No description provided for @studentImportErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read as a spreadsheet. Open it in your spreadsheet program and use “Save as… CSV”, then upload the CSV.'**
  String get studentImportErrorUnreadable;

  /// No description provided for @studentImportErrorUnsupportedColumn.
  ///
  /// In en, this message translates to:
  /// **'One of the columns in that file is not supported yet. Keep only admissionNo, firstName, lastName, dateOfBirth and transportEligible, then upload again.'**
  String get studentImportErrorUnsupportedColumn;

  /// No description provided for @studentImportErrorTooManyRows.
  ///
  /// In en, this message translates to:
  /// **'That file has too many rows for one upload. Split it into smaller files and import them one at a time.'**
  String get studentImportErrorTooManyRows;

  /// No description provided for @studentImportErrorNoFile.
  ///
  /// In en, this message translates to:
  /// **'No file was chosen. Pick a CSV file to upload.'**
  String get studentImportErrorNoFile;

  /// No description provided for @custodyPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Custody restrictions'**
  String get custodyPanelTitle;

  /// No description provided for @custodyAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add restriction'**
  String get custodyAddButton;

  /// No description provided for @custodyPanelWarning.
  ///
  /// In en, this message translates to:
  /// **'A restriction takes effect immediately and overrides every parent right — the person named cannot collect or see this child while it is in force. Every restriction is recorded with its reason.'**
  String get custodyPanelWarning;

  /// No description provided for @custodyLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading restrictions'**
  String get custodyLoadingLabel;

  /// No description provided for @custodyEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No restrictions. That is the normal state.'**
  String get custodyEmptyState;

  /// No description provided for @custodyLiftButton.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get custodyLiftButton;

  /// No description provided for @custodyStatusLifted.
  ///
  /// In en, this message translates to:
  /// **'Lifted'**
  String get custodyStatusLifted;

  /// No description provided for @custodyLiftConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Lift this restriction?'**
  String get custodyLiftConfirmTitle;

  /// No description provided for @custodyLiftConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The person named will be able to collect and see this child again, straight away. The restriction and its history are kept.'**
  String get custodyLiftConfirmBody;

  /// No description provided for @custodyLiftConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Lift restriction'**
  String get custodyLiftConfirmButton;

  /// No description provided for @custodyEffectiveLine.
  ///
  /// In en, this message translates to:
  /// **'In force from {from} until {until}'**
  String custodyEffectiveLine(String from, String until);

  /// No description provided for @custodyOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'no end date'**
  String get custodyOpenEnded;

  /// No description provided for @custodySubjectGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parent {id}'**
  String custodySubjectGuardian(String id);

  /// No description provided for @custodyTypeNoHandover.
  ///
  /// In en, this message translates to:
  /// **'Cannot collect the child'**
  String get custodyTypeNoHandover;

  /// No description provided for @custodyTypeNoVisibility.
  ///
  /// In en, this message translates to:
  /// **'Cannot see the child\'s journey'**
  String get custodyTypeNoVisibility;

  /// No description provided for @custodyTypeFull.
  ///
  /// In en, this message translates to:
  /// **'Cannot collect or see the child'**
  String get custodyTypeFull;

  /// No description provided for @custodyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a custody restriction'**
  String get custodyAddTitle;

  /// No description provided for @custodySubjectAGuardian.
  ///
  /// In en, this message translates to:
  /// **'A parent on file'**
  String get custodySubjectAGuardian;

  /// No description provided for @custodySubjectAPerson.
  ///
  /// In en, this message translates to:
  /// **'Someone else, by name'**
  String get custodySubjectAPerson;

  /// No description provided for @custodyGuardianLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get custodyGuardianLabel;

  /// No description provided for @custodyPersonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get custodyPersonNameLabel;

  /// No description provided for @custodyPersonNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the person\'s full name'**
  String get custodyPersonNameRequired;

  /// No description provided for @custodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Restriction'**
  String get custodyTypeLabel;

  /// No description provided for @custodyReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get custodyReasonLabel;

  /// No description provided for @custodyReasonHelper.
  ///
  /// In en, this message translates to:
  /// **'What authorises this — a court order and its reference, a school safeguarding decision. Kept on the audit record.'**
  String get custodyReasonHelper;

  /// No description provided for @custodyErrorReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required for every custody restriction.'**
  String get custodyErrorReasonRequired;

  /// No description provided for @custodyUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get custodyUntilLabel;

  /// No description provided for @custodyUntilFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use the format YYYY-MM-DD, or leave blank for no end date.'**
  String get custodyUntilFormatError;

  /// No description provided for @custodyAddSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Add restriction'**
  String get custodyAddSubmitButton;

  /// No description provided for @custodyErrorSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Name exactly one person — a parent on file, or someone by name.'**
  String get custodyErrorSubjectRequired;

  /// No description provided for @custodyErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That restriction could not be found. It may already have been lifted.'**
  String get custodyErrorNotFound;

  /// No description provided for @onboardingAddOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add organization'**
  String get onboardingAddOrganizationTitle;

  /// No description provided for @onboardingAddOrganizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the organization, then add its first school.'**
  String get onboardingAddOrganizationSubtitle;

  /// No description provided for @onboardingStepOrganizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get onboardingStepOrganizationLabel;

  /// No description provided for @onboardingStepFirstSchoolLabel.
  ///
  /// In en, this message translates to:
  /// **'First school'**
  String get onboardingStepFirstSchoolLabel;

  /// No description provided for @onboardingStepSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}: {label}, {status}'**
  String onboardingStepSemanticLabel(
    int number,
    int total,
    String label,
    String status,
  );

  /// No description provided for @onboardingStepStatusDone.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get onboardingStepStatusDone;

  /// No description provided for @onboardingStepStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'current step'**
  String get onboardingStepStatusCurrent;

  /// No description provided for @onboardingStepStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get onboardingStepStatusUpcoming;

  /// No description provided for @createOrgSectionIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get createOrgSectionIdentityTitle;

  /// No description provided for @createOrgSectionIdentityDescription.
  ///
  /// In en, this message translates to:
  /// **'How this organization is named and identified across the platform.'**
  String get createOrgSectionIdentityDescription;

  /// No description provided for @createOrgCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Short and unique. Fixed once the organization has schools or staff.'**
  String get createOrgCodeHelper;

  /// No description provided for @createOrgSectionRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get createOrgSectionRegionTitle;

  /// No description provided for @createOrgSectionRegionDescription.
  ///
  /// In en, this message translates to:
  /// **'Supplies phone, document, and data-retention defaults.'**
  String get createOrgSectionRegionDescription;

  /// No description provided for @createOrgRegionHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. IN'**
  String get createOrgRegionHelper;

  /// No description provided for @createOrgSectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get createOrgSectionContactTitle;

  /// No description provided for @createOrgSectionContactDescription.
  ///
  /// In en, this message translates to:
  /// **'Who the platform team reaches about this organization.'**
  String get createOrgSectionContactDescription;

  /// No description provided for @createOrgContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Create and continue'**
  String get createOrgContinueButton;

  /// No description provided for @createSchoolCreatedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{orgName} ({orgCode}) created'**
  String createSchoolCreatedBannerTitle(String orgName, String orgCode);

  /// No description provided for @createSchoolCreatedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'An organization needs at least one school before it can be used day to day. Add it now, or skip and add it later.'**
  String get createSchoolCreatedBannerBody;

  /// No description provided for @createSchoolSectionSchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get createSchoolSectionSchoolTitle;

  /// No description provided for @createSchoolSectionSchoolDescription.
  ///
  /// In en, this message translates to:
  /// **'The campus buses travel to and from.'**
  String get createSchoolSectionSchoolDescription;

  /// No description provided for @createSchoolCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Unique within this organization. Fixed once the school is in use.'**
  String get createSchoolCodeHelper;

  /// No description provided for @createSchoolSectionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get createSchoolSectionLocationTitle;

  /// No description provided for @createSchoolSectionLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Arrival alerts are measured from this point.'**
  String get createSchoolSectionLocationDescription;

  /// No description provided for @createSchoolPlusCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 7J4VXMQ5+8F'**
  String get createSchoolPlusCodeHint;

  /// No description provided for @createSchoolPlusCodeGuide.
  ///
  /// In en, this message translates to:
  /// **'Paste the school\'s full Plus Code from Google Maps. The latitude and longitude are worked out from it and shown here before you save.'**
  String get createSchoolPlusCodeGuide;

  /// No description provided for @createSchoolLocationFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Location found'**
  String get createSchoolLocationFoundTitle;

  /// No description provided for @createSchoolGeofenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius'**
  String get createSchoolGeofenceLabel;

  /// No description provided for @createSchoolGeofenceHelper.
  ///
  /// In en, this message translates to:
  /// **'Between 20 and 2000 metres around the school.'**
  String get createSchoolGeofenceHelper;

  /// No description provided for @unitMetresSuffix.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMetresSuffix;

  /// No description provided for @createSchoolSectionTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Local time'**
  String get createSchoolSectionTimeTitle;

  /// No description provided for @createSchoolSectionTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Every time shown for this school uses its time zone.'**
  String get createSchoolSectionTimeDescription;

  /// No description provided for @createSchoolTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get createSchoolTimezoneLabel;

  /// No description provided for @createSchoolTimezoneHelper.
  ///
  /// In en, this message translates to:
  /// **'IANA name, e.g. Asia/Kolkata'**
  String get createSchoolTimezoneHelper;

  /// No description provided for @createSchoolSkipForNowButton.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get createSchoolSkipForNowButton;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search students, parents, staff, vehicles…'**
  String get globalSearchHint;

  /// No description provided for @globalSearchShortcutMac.
  ///
  /// In en, this message translates to:
  /// **'⌘K'**
  String get globalSearchShortcutMac;

  /// No description provided for @globalSearchShortcutOther.
  ///
  /// In en, this message translates to:
  /// **'Ctrl K'**
  String get globalSearchShortcutOther;

  /// No description provided for @globalSearchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get globalSearchClearTooltip;

  /// No description provided for @globalSearchMinLength.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters to search'**
  String get globalSearchMinLength;

  /// No description provided for @globalSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get globalSearchLoading;

  /// No description provided for @globalSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches for “{query}”'**
  String globalSearchNoResults(String query);

  /// No description provided for @globalSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search is unavailable right now. Try again shortly.'**
  String get globalSearchError;

  /// No description provided for @globalSearchOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'That record could not be opened right now.'**
  String get globalSearchOpenFailed;

  /// No description provided for @globalSearchMoreResults.
  ///
  /// In en, this message translates to:
  /// **'More matches — keep typing to narrow them down'**
  String get globalSearchMoreResults;

  /// No description provided for @globalSearchSubtitleSeparator.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get globalSearchSubtitleSeparator;

  /// No description provided for @globalSearchGroupStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get globalSearchGroupStudents;

  /// No description provided for @globalSearchGroupGuardians.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get globalSearchGroupGuardians;

  /// No description provided for @globalSearchGroupStaff.
  ///
  /// In en, this message translates to:
  /// **'Drivers & attendants'**
  String get globalSearchGroupStaff;

  /// No description provided for @globalSearchGroupVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get globalSearchGroupVehicles;

  /// No description provided for @globalSearchGroupRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get globalSearchGroupRoutes;

  /// No description provided for @globalSearchGroupUsers.
  ///
  /// In en, this message translates to:
  /// **'Administrators'**
  String get globalSearchGroupUsers;

  /// No description provided for @globalSearchGroupSchools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get globalSearchGroupSchools;

  /// No description provided for @globalSearchGroupOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get globalSearchGroupOrganizations;

  /// No description provided for @globalSearchKindStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get globalSearchKindStudent;

  /// No description provided for @globalSearchKindGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get globalSearchKindGuardian;

  /// No description provided for @globalSearchKindDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get globalSearchKindDriver;

  /// No description provided for @globalSearchKindAttendant.
  ///
  /// In en, this message translates to:
  /// **'Attendant'**
  String get globalSearchKindAttendant;

  /// No description provided for @globalSearchKindVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get globalSearchKindVehicle;

  /// No description provided for @globalSearchKindRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get globalSearchKindRoute;

  /// No description provided for @globalSearchKindUser.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get globalSearchKindUser;

  /// No description provided for @globalSearchKindSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get globalSearchKindSchool;

  /// No description provided for @globalSearchKindOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get globalSearchKindOrganization;

  /// No description provided for @globalSearchLinkedChild.
  ///
  /// In en, this message translates to:
  /// **'Child: {studentName}'**
  String globalSearchLinkedChild(String studentName);

  /// No description provided for @globalSearchAdmissionNumber.
  ///
  /// In en, this message translates to:
  /// **'Adm {admissionNo}'**
  String globalSearchAdmissionNumber(String admissionNo);

  /// No description provided for @globalSearchNoScreen.
  ///
  /// In en, this message translates to:
  /// **'There is no screen for this record in your console.'**
  String get globalSearchNoScreen;
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
