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
