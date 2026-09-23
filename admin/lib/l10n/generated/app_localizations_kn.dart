// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'Guardian Admin';

  @override
  String get consoleHeaderBrand => 'Guardian';

  @override
  String get consoleDestinationOrganizations => 'Organizations';

  @override
  String get consoleDestinationSchool => 'School';

  @override
  String get consoleDestinationStudents => 'Students';

  @override
  String get consoleDestinationDrivers => 'Drivers';

  @override
  String get consoleDestinationVehicles => 'Vehicles';

  @override
  String get consoleDestinationRoutes => 'Routes';

  @override
  String get consoleDestinationUsers => 'Users';

  @override
  String get consoleDestinationRoles => 'Roles';

  @override
  String get consoleDestinationPlatformHealth => 'Platform health';

  @override
  String get consoleDestinationAuditTrail => 'Audit trail';

  @override
  String get accountMenuSignOut => 'Sign out';

  @override
  String get accountMenuSigningOut => 'Signing out…';

  @override
  String get noModulesNoticeTitle => 'No console modules in this build';

  @override
  String get noModulesNoticeBody =>
      'You are signed in. The operations dashboard, alert inbox, and administration screens are not part of this build yet.';

  @override
  String get bootSplashLoadingLabel => 'Loading the console';

  @override
  String get languageSwitcherTooltip => 'Change language';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameKannada => 'ಕನ್ನಡ';

  @override
  String get roleNameSuperAdmin => 'Super Admin';

  @override
  String get roleNameOrgAdmin => 'Organization Admin';

  @override
  String get roleNameSchoolAdmin => 'School Admin';

  @override
  String get roleNamePrincipal => 'Principal';

  @override
  String get roleNameTransportManager => 'Transport Manager';

  @override
  String get roleNameVendorStaff => 'Vendor Staff';

  @override
  String get roleNameDriver => 'Driver';

  @override
  String get roleNameAttendant => 'Attendant';

  @override
  String get roleNameGuardian => 'Guardian';

  @override
  String get roleShortSuperAdmin => 'Super\nAdmin';

  @override
  String get roleShortOrgAdmin => 'Org\nAdmin';

  @override
  String get roleShortSchoolAdmin => 'School\nAdmin';

  @override
  String get roleShortPrincipal => 'Principal';

  @override
  String get roleShortTransportManager => 'Transport\nMgr';

  @override
  String get roleShortVendorStaff => 'Vendor\nStaff';

  @override
  String get roleShortDriver => 'Driver';

  @override
  String get roleShortAttendant => 'Attendant';

  @override
  String get roleShortGuardian => 'Guardian';

  @override
  String get permCategoryTenancyConfig => 'Tenancy & Configuration';

  @override
  String get permCategoryIdentityAccess => 'Identity & Access';

  @override
  String get permCategoryStudentsGuardians => 'Students & Guardians';

  @override
  String get permCategoryFleetStaff => 'Fleet & Staff';

  @override
  String get permCategoryRoutesTrips => 'Routes & Trips';

  @override
  String get permCategoryBoardingHandover => 'Boarding & Handover';

  @override
  String get permCategoryTrackingAlertsIncidents =>
      'Tracking, Alerts, Incidents';

  @override
  String get permCategoryAbsenceNotificationReportingAudit =>
      'Absence, Notification, Reporting, Audit';

  @override
  String get permCategoryPlatformOperations => 'Platform Operations';

  @override
  String get permNoteConfigSafetyEdit =>
      'Governs safety-relevant thresholds; bounded by platform floors (BR-CFG-003).';

  @override
  String get permNoteStudentView =>
      'Non-admin roles see only the current trip manifest or their own children (BR-IAM-005); non-guardian access is logged (BR-IAM-012).';

  @override
  String get permNotePickupPersonManage =>
      'A guardian\'s grant requires the \"authorise handover\" right on the relationship (BR-GRD-006).';

  @override
  String get permNoteHandoverCodeRequest =>
      'Requires \"can_authorise_handover\" on the relationship (BR-GRD-006); redemption at the vehicle is the separate attendant-side flow (BR-HAND-001–007).';

  @override
  String get permNoteTripView =>
      'A guardian\'s grant is limited to trips carrying one of their children (BR-TRACK-002).';

  @override
  String get permNoteBoardingCorrect =>
      'Override-capable; always audited with a reason (BR-AUD-004).';

  @override
  String get permNoteBoardingOverride =>
      'Override-capable; always audited with a reason (BR-AUD-004).';

  @override
  String get permNoteHandoverOverride =>
      'Notifies all guardians and the transport manager (BR-HAND-003); always audited with a reason (BR-AUD-004).';

  @override
  String get permNoteReconciliationResolve =>
      'Override-capable; always audited with a reason (BR-AUD-004).';

  @override
  String get permNoteIncidentView =>
      'A guardian\'s grant is limited to incidents affecting their own child (BR-INC-004, BR-NTF-007).';

  @override
  String get permNoteAbsenceDeclare =>
      'A guardian\'s grant requires the \"declare absence\" right (BR-ABS-001).';

  @override
  String get permNoteNotificationSelfView =>
      'Everyone, scoped to their own notifications only — never a route to another family\'s child (BR-NTF-007).';

  @override
  String get permNoteDataExport =>
      'Always audited with actor, scope, and record count (BR-RPT-002).';

  @override
  String get permNotePlatformTenantAccess =>
      'The only path across the tenant boundary (BR-TEN-004); every use is audited with the target organization and justification (AUD-004).';

  @override
  String get roleReferenceTitle => 'Roles & permissions';

  @override
  String get roleReferenceDescription =>
      'What each system role can do, straight from the permission matrix this platform enforces server-side on every request. Reference only — roles cannot be edited here yet.';

  @override
  String get roleReferenceSearchLabel => 'Search';

  @override
  String get roleReferenceSearchHint => 'Filter by permission ID or category';

  @override
  String get roleReferenceClearSearchTooltip => 'Clear search';

  @override
  String get roleReferenceRoleFilterLabel => 'Role';

  @override
  String get roleReferenceEveryRoleOption => 'Every role';

  @override
  String get roleReferenceNoResults => 'No permission matches this search.';

  @override
  String get roleReferenceGrantNarrowerTooltip =>
      'Granted, narrowed to a smaller scope than this role normally has';

  @override
  String get errorValidationRequiredField => 'Fill in every required field.';

  @override
  String get errorValidationCheckDetails => 'Check the details you entered.';

  @override
  String get errorApiUnreachable =>
      'The Guardian API could not be reached. Check your connection, then try again.';

  @override
  String get errorSessionEnded => 'That session has ended. Sign in again.';

  @override
  String get errorGenericRetryShortly =>
      'That could not be saved right now. Try again shortly.';

  @override
  String get onboardingErrorOrgCodeExists =>
      'That organization code is already in use. Choose another — codes cannot be changed once operational data exists (BR-TEN-007).';

  @override
  String get onboardingErrorCannotSuspendOwnOrganization =>
      'You cannot suspend the organization your own account belongs to — it would lock out every account able to reactivate it.';

  @override
  String get onboardingErrorSchoolCodeExists =>
      'That school code is already used within this organization. Choose another.';

  @override
  String get onboardingErrorStaffEmployeeCodeExists =>
      'That employee code is already used at this school. Choose another.';

  @override
  String get onboardingErrorPermissionDenied =>
      'Your account does not have permission to create organizations.';

  @override
  String get studentErrorAdmissionNoExists =>
      'That admission number is already used at this school. Check whether the student is already enrolled before creating a second record for them.';

  @override
  String get studentErrorNotFound =>
      'That student could not be found. They may have been moved to another school.';

  @override
  String get studentErrorNotActive =>
      'That student is not on the active roll, so they cannot be assigned to transport.';

  @override
  String get studentErrorPermissionDenied =>
      'Your account does not have permission to manage students.';

  @override
  String get studentErrorScopeDenied =>
      'That student is outside the schools your account covers.';

  @override
  String get loginErrorCredentialsInvalid =>
      'Those details were not recognised. Check the email address and password.';

  @override
  String get loginErrorAccountLocked =>
      'This account is locked after too many failed attempts. Contact your platform administrator to unlock it.';

  @override
  String get loginErrorRateLimitExceeded =>
      'Too many sign-in attempts. Wait a minute, then try again.';

  @override
  String get loginErrorValidationRequiredField =>
      'Enter both your email address and your password.';

  @override
  String get loginErrorGenericFailure =>
      'Sign-in is not working right now. Contact your platform administrator.';

  @override
  String get schoolScopeOrganizationLabel => 'Organization';

  @override
  String get schoolScopeLoadingHint => 'Loading…';

  @override
  String get schoolScopeSelectOrganizationHint => 'Select an organization';

  @override
  String get schoolScopeLabel => 'School';

  @override
  String get schoolScopeSelectOrganizationFirstHint =>
      'Select an organization first';

  @override
  String get schoolScopeSelectSchoolHint => 'Select a school';

  @override
  String get schoolScopeLoadError =>
      'Could not load your organizations or schools.';

  @override
  String get schoolScopeNoSchoolsNotice =>
      'This organization has no schools yet. Add a school before enrolling students or registering vehicles, staff and routes.';

  @override
  String get schoolScopeCrossTenantNotice =>
      'A platform operator cannot open another organization\'s schools. To manage students, staff, vehicles or routes, sign in with an account belonging to that organization.';

  @override
  String get commonCancelButton => 'Cancel';

  @override
  String get commonSaveButton => 'Save';

  @override
  String get commonCloseButton => 'Close';

  @override
  String get commonRetryButton => 'Retry';

  @override
  String get commonAddButton => 'Add';

  @override
  String get commonDoneButton => 'Done';

  @override
  String get schoolSettingsScreenTitle => 'School';

  @override
  String get loginSessionEndedRevoked =>
      'Your session was ended by the platform. This happens when an account is deactivated or a session is revoked.';

  @override
  String get loginSessionEndedRefreshFailed =>
      'Your session expired and could not be renewed. Sign in to continue.';

  @override
  String get loginSignInLabel => 'Sign in';

  @override
  String get loginFormSubtitle => 'Guardian administration console';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmittingSpinnerLabel => 'Signing in';

  @override
  String get loginForgotPasswordLink => 'Forgot password?';

  @override
  String get emailAddressLabel => 'Email address';

  @override
  String get passwordVisibilityShowTooltip => 'Show password';

  @override
  String get passwordVisibilityHideTooltip => 'Hide password';

  @override
  String get confirmPasswordFieldLabel => 'Confirm password';

  @override
  String get passwordMismatchError => 'The two passwords do not match.';

  @override
  String passwordValidationTooShort(int minLength) {
    return 'Use at least $minLength characters.';
  }

  @override
  String get goToSignInButton => 'Go to sign in';

  @override
  String get acceptInvitationTitle => 'Set your password';

  @override
  String get acceptInvitationIntro =>
      'Choose a password to activate your account and sign in.';

  @override
  String get acceptInvitationSubmitLabel => 'Activate account';

  @override
  String get acceptInvitationDoneTitle => 'Account activated';

  @override
  String get acceptInvitationDoneBody =>
      'You can now sign in with your email address and new password.';

  @override
  String get setPasswordErrorLinkExpired =>
      'This link has expired. Ask an administrator to send you a new one.';

  @override
  String get setPasswordErrorLinkAlreadyUsed =>
      'This link has already been used. If you have set your password, just sign in.';

  @override
  String get setPasswordErrorLinkInvalid =>
      'This link is not valid. Check you opened the most recent email, or ask for a new link.';

  @override
  String authRecoveryErrorPasswordTooWeak(int minLength) {
    return 'That password is too weak. Use at least $minLength characters and avoid common passwords.';
  }

  @override
  String get authRecoveryErrorApiUnreachable =>
      'We could not reach the server. Check your connection and try again.';

  @override
  String get authRecoveryErrorGeneric =>
      'That could not be completed right now. Please try again.';

  @override
  String get newPasswordFieldLabel => 'New password';

  @override
  String newPasswordHelperText(int minLength) {
    return 'At least $minLength characters.';
  }

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordIntro =>
      'Enter your email and we will send you a 6-digit code to reset your password.';

  @override
  String get forgotPasswordEmailValidationError =>
      'Enter a valid email address.';

  @override
  String get forgotPasswordSendCodeButton => 'Send code';

  @override
  String get forgotPasswordBackToSignIn => 'Back to sign in';

  @override
  String get forgotPasswordEnterCodeTitle => 'Enter your code';

  @override
  String forgotPasswordCodeIntro(String email) {
    return 'If an account exists for $email, we’ve emailed a 6-digit code. It is valid for 10 minutes. Enter it and choose a new password.';
  }

  @override
  String get forgotPasswordCodeFieldLabel => '6-digit code';

  @override
  String get forgotPasswordCodeValidationError =>
      'Enter the 6-digit code from your email.';

  @override
  String get forgotPasswordDoneTitle => 'Password changed';

  @override
  String get forgotPasswordDoneBody =>
      'Your password has been reset and you’ve been signed out everywhere else. Sign in with your new password.';

  @override
  String get resetPasswordSubmitButton => 'Reset password';

  @override
  String get forgotPasswordErrorOtpExpired =>
      'That code has expired. Go back and request a new one.';

  @override
  String get forgotPasswordErrorOtpAlreadyUsed =>
      'That code has already been used. Request a new one if you still need to reset.';

  @override
  String get forgotPasswordErrorAccountLocked =>
      'Too many incorrect codes. Please wait 15 minutes and try again.';

  @override
  String get forgotPasswordErrorCredentialsInvalid =>
      'That code is not correct. Check the latest email and try again.';

  @override
  String get guardianRelationshipMother => 'Mother';

  @override
  String get guardianRelationshipFather => 'Father';

  @override
  String get guardianRelationshipGuardian => 'Guardian';

  @override
  String get guardianRelationshipGrandparent => 'Grandparent';

  @override
  String get guardianRelationshipAuntUncle => 'Aunt / Uncle';

  @override
  String get guardianRelationshipOther => 'Other';

  @override
  String get guardianTilePrimaryChip => 'Primary';

  @override
  String get guardianTileCanCollectChip => 'Can collect';

  @override
  String get guardianTileCannotCollectChip => 'Cannot collect';

  @override
  String get guardianTileNotifiedChip => 'Notified';

  @override
  String get guardianTileCanReportAbsenceChip => 'Can report absence';

  @override
  String get guardianTileCanSignInChip => 'Can sign in';

  @override
  String get guardianTileNoSignInYetChip => 'No sign-in yet';

  @override
  String guardianTileRelationshipAndPhone(String relationship, String phone) {
    return '$relationship · $phone';
  }

  @override
  String get addGuardianFormTitle => 'Add parent';

  @override
  String get addGuardianFormIntro =>
      'The phone number becomes their sign-in straight away — they open the parent app, enter their number, and get a one-time code. Enter it carefully.';

  @override
  String get addGuardianRelationshipLabel => 'Relationship';

  @override
  String get addGuardianFirstNameLabel => 'First name';

  @override
  String get addGuardianLastNameLabel => 'Last name';

  @override
  String get addGuardianPhoneLabel => 'Phone (parent-app sign-in)';

  @override
  String get addGuardianPhoneHint => 'e.g. 9990000001';

  @override
  String get addGuardianEmailLabel => 'Email (optional)';

  @override
  String get addGuardianCanViewTitle => 'Can see this child';

  @override
  String get addGuardianCanViewSubtitle =>
      'View the child and their journey in the app';

  @override
  String get addGuardianCanNotifyTitle => 'Receives notifications';

  @override
  String get addGuardianCanNotifySubtitle =>
      'Boarding, arrival, and alert messages';

  @override
  String get addGuardianCanHandoverTitle => 'Can collect the child';

  @override
  String get addGuardianCanHandoverSubtitle =>
      'Authorised to receive the child at the stop — needed before the child can be put on a bus';

  @override
  String get addGuardianCanAbsenceTitle => 'Can report an absence';

  @override
  String get addGuardianCanAbsenceSubtitle =>
      'Tell the school the child will not travel';

  @override
  String get addGuardianPrimaryTitle => 'Primary contact';

  @override
  String get addGuardianPrimarySubtitle =>
      'The first person the school reaches';

  @override
  String get addGuardianSubmitSpinnerLabel => 'Adding';

  @override
  String get assignRouteTitlePickup => 'Set pickup';

  @override
  String get assignRouteTitleDrop => 'Set drop';

  @override
  String get assignRoutePickupSubtitle =>
      'Where this child is picked up in the morning.';

  @override
  String get assignRouteDropSubtitle =>
      'Where this child is dropped in the afternoon.';

  @override
  String get assignRouteFieldLabel => 'Route';

  @override
  String get assignRouteNoRoutesHint => 'No routes on this school yet';

  @override
  String get assignRouteSelectRouteHint => 'Select a route';

  @override
  String assignRouteNameAndCode(String name, String code) {
    return '$name · $code';
  }

  @override
  String get assignStopFieldLabel => 'Stop';

  @override
  String get assignRouteStopsLoadError =>
      'Could not load this route\'s stops. Try again.';

  @override
  String get assignRouteStopHintSelectRouteFirst => 'Select a route first';

  @override
  String get assignRouteStopHintLoading => 'Loading stops…';

  @override
  String get assignRouteStopHintNoStops => 'This route has no stops yet';

  @override
  String get assignRouteStopHintSelectStop => 'Select a stop';

  @override
  String get assignRouteSavingSpinnerLabel => 'Saving';

  @override
  String get platformHealthTitle => 'Platform health';

  @override
  String get platformHealthRefreshButton => 'Refresh';

  @override
  String get platformHealthIntro =>
      'A quick pulse check — whether the platform is reachable, and how many organizations are on it. Not a full monitoring dashboard.';

  @override
  String get platformHealthCheckingLabel => 'Checking platform health';

  @override
  String get platformHealthOrganizationsHeading =>
      'Organizations on the platform';

  @override
  String platformHealthCheckedAt(String relativeTime) {
    return 'Checked $relativeTime';
  }

  @override
  String get platformHealthJustNow => 'just now';

  @override
  String platformHealthSecondsAgo(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds ago',
      one: '1 second ago',
    );
    return '$_temp0';
  }

  @override
  String platformHealthMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String platformHealthHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get platformHealthReachableTitle => 'Platform is reachable';

  @override
  String get platformHealthDegradedTitle => 'Could not confirm platform health';

  @override
  String get platformHealthReachableBody =>
      'The last check reached the database without issue.';

  @override
  String get platformHealthDegradedBody =>
      'The last check could not read organization data. This can be transient — try refreshing in a moment. If it keeps failing, that\'s worth escalating.';

  @override
  String get platformHealthCountTotal => 'Total';

  @override
  String get platformHealthCountActive => 'Active';

  @override
  String get platformHealthCountSuspended => 'Suspended';

  @override
  String get platformHealthCountClosed => 'Closed';

  @override
  String get auditTrailTitle => 'Audit trail';

  @override
  String get auditScopeAllActivity => 'All activity';

  @override
  String get auditScopeOverrides => 'Overrides';

  @override
  String get auditOverridesDescription =>
      'Actions taken with an override reason — a person overrode a safety check and said why.';

  @override
  String get auditAllActivityDescription =>
      'Every safety-relevant action, most recent first. Records cannot be edited or removed.';

  @override
  String get auditLoadingLabel => 'Loading audit trail';

  @override
  String get auditLoadError =>
      'The audit trail could not be loaded right now. Try again.';

  @override
  String get auditNoOverridesEmptyState =>
      'No overrides recorded. That is the healthy state.';

  @override
  String get auditNoActivityEmptyState => 'No activity recorded yet.';

  @override
  String auditReasonPrefix(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get auditOverrideBadge => 'Override';

  @override
  String get errorGenericLoadRetry =>
      'That could not be loaded right now. Try again.';

  @override
  String get pickSchoolFirstTooltip => 'Pick a school first';

  @override
  String get vehicleListTitle => 'Vehicles';

  @override
  String get vehicleListLoadingLabel => 'Loading fleet';

  @override
  String get vehicleListEmptyState =>
      'No fleet loaded. Pick a school above, or add the first vehicle.';

  @override
  String vehicleListRowSubtitle(
    String registrationNo,
    String vehicleType,
    int seats,
  ) {
    return '$registrationNo · $vehicleType · $seats seats';
  }

  @override
  String get vehicleListAddButton => 'Add vehicle';

  @override
  String get commonAddingSpinnerLabel => 'Adding';

  @override
  String get createVehicleFormIntro =>
      'The display name is what parents see in notifications — \"Bus 12\", not the plate number. Added to the school you have selected above.';

  @override
  String get vehicleTypeBus => 'Bus';

  @override
  String get vehicleTypeVan => 'Van';

  @override
  String get vehicleTypeMinibus => 'Minibus';

  @override
  String get createVehicleRegistrationNoLabel => 'Registration number';

  @override
  String get createVehicleRegistrationNoHint => 'e.g. DL1PC1234';

  @override
  String get createVehicleDisplayNameLabel => 'Display name';

  @override
  String get createVehicleDisplayNameHint => 'e.g. Bus 12';

  @override
  String get createVehicleSeatingCapacityLabel => 'Seating capacity';

  @override
  String get createVehicleVendorNameLabel =>
      'Vendor name (optional, for outsourced fleets)';

  @override
  String get commonSearchLabel => 'Search';

  @override
  String get commonClearSearchTooltip => 'Clear search';

  @override
  String get staffListTitle => 'Drivers';

  @override
  String get staffListSearchHint => 'Filter by name, phone, or employee code';

  @override
  String get staffListLoadingLabel => 'Loading roster';

  @override
  String get staffListEmptyState =>
      'No roster loaded. Pick a school above, or add the first driver.';

  @override
  String staffListSearchNoMatches(String query) {
    return 'No one on this roster matches \"$query\".';
  }

  @override
  String staffListRowSubtitle(String staffType, String phone) {
    return '$staffType · $phone';
  }

  @override
  String get staffListHasLoginTooltip => 'Can sign in to the driver app';

  @override
  String get staffListNoLoginTooltip => 'No driver-app sign-in yet';

  @override
  String get staffListAddButton => 'Add driver';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get commonSavingSpinnerLabel => 'Saving';

  @override
  String get commonSaveChangesButton => 'Save changes';

  @override
  String get commonChangesSavedSnackbar => 'Changes saved';

  @override
  String get createStaffFormTitle => 'Add driver or attendant';

  @override
  String get createStaffFormIntro =>
      'Creates the roster record and a working driver-app sign-in in one step — the phone number below is what they sign in with (phone + one-time code). Added to the school you have selected above.';

  @override
  String get staffTypeDriver => 'Driver';

  @override
  String get staffTypeAttendant => 'Attendant';

  @override
  String get staffPhoneLabel => 'Phone (driver-app sign-in)';

  @override
  String get staffPhoneHint => 'e.g. 9990000001';

  @override
  String get staffEmployeeCodeLabel => 'Employee code (optional)';

  @override
  String get staffVendorNameLabel =>
      'Vendor name (optional, for contracted staff)';

  @override
  String editStaffTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get studentListTitle => 'Students';

  @override
  String get studentListSearchHint =>
      'Filter loaded students by name or admission number';

  @override
  String get studentWithdrawConfirmTitle => 'Withdraw student?';

  @override
  String studentWithdrawConfirmBody(String name, String admissionNo) {
    return '$name ($admissionNo) will be taken off the roll and removed from transport.\n\nTheir record is kept — safety records reference it — and can still be read.';
  }

  @override
  String get studentWithdrawConfirmButton => 'Withdraw';

  @override
  String get studentListLoadingLabel => 'Loading register';

  @override
  String get studentListEmptyState =>
      'No register loaded. Pick a school above, or enrol the first student.';

  @override
  String get studentListNoMatchWithMore =>
      'No loaded student matches that. Scroll to load more of the register, then search again.';

  @override
  String get studentListNoMatch => 'No student matches that.';

  @override
  String get studentListLoadingMoreLabel => 'Loading more students';

  @override
  String studentListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get studentListEnrolButton => 'Enrol student';

  @override
  String studentListEditTooltip(String name) {
    return 'Edit $name';
  }

  @override
  String studentListWithdrawTooltip(String name) {
    return 'Withdraw $name';
  }

  @override
  String get studentStatusWithdrawn => 'Withdrawn';

  @override
  String get studentStatusOnRollNoTransport => 'On roll · not using transport';

  @override
  String get studentStatusOnRollTransport => 'On roll · transport';

  @override
  String studentListRowSubtitle(String admissionNo, String status) {
    return '$admissionNo · $status';
  }

  @override
  String get studentFormEditTitle => 'Edit student';

  @override
  String get studentFormAdmissionNoLabel => 'Admission number';

  @override
  String get studentFormAdmissionNoHelperEditing =>
      'Cannot be changed — safety records reference it';

  @override
  String get studentFormAdmissionNoHelperNew =>
      'The number the school already uses for this student';

  @override
  String get studentFormAdmissionNoRequired => 'Enter an admission number';

  @override
  String get studentFormFirstNameRequired => 'Enter a first name';

  @override
  String get studentFormLastNameRequired => 'Enter a last name';

  @override
  String get studentFormDateOfBirthLabel => 'Date of birth';

  @override
  String get studentFormDateOfBirthHelper =>
      'YYYY-MM-DD — used to decide self-release eligibility';

  @override
  String get studentFormDateOfBirthFormatError => 'Use the format YYYY-MM-DD';

  @override
  String get studentFormDateOfBirthPastError =>
      'Date of birth must be in the past';

  @override
  String get studentFormTransportEligibleTitle => 'Eligible for transport';

  @override
  String get studentFormTransportEligibleSubtitle =>
      'A student on the roll whose family has opted out stays enrolled but off the bus';

  @override
  String studentDetailAdmissionLine(String admissionNo) {
    return 'Admission $admissionNo';
  }

  @override
  String studentDetailDobLine(String date) {
    return 'Date of birth $date';
  }

  @override
  String get studentDetailStatusOnRollTransport => 'On roll · using transport';

  @override
  String get studentDetailParentsTitle => 'Parents';

  @override
  String get studentDetailLoadingParentsLabel => 'Loading parents';

  @override
  String get studentDetailNoParentsEmptyState =>
      'No parents yet. Add one so they can see this child and be reached — and so the child can be assigned to a bus.';

  @override
  String get studentDetailNoHandoverGuardianWarning =>
      'No parent here can collect the child yet — turn on \"Can collect the child\" for at least one before assigning a bus.';

  @override
  String get studentDetailPickupDropTitle => 'Pickup & drop';

  @override
  String get studentDetailLoadingAssignmentsLabel => 'Loading assignments';

  @override
  String get studentDetailDirectionPickup => 'Pickup';

  @override
  String get studentDetailDirectionDrop => 'Drop';

  @override
  String studentDetailAssignmentSummary(
    String routeName,
    String routeCode,
    String stopName,
  ) {
    return '$routeName · $routeCode → $stopName';
  }

  @override
  String get studentDetailAssignmentNotSet => 'Not set';

  @override
  String studentDetailRemoveAssignment(String label) {
    return 'Remove $label';
  }

  @override
  String get studentDetailChangeButton => 'Change';

  @override
  String get studentDetailSetButton => 'Set';

  @override
  String get studentAssignErrorNoActiveGuardian =>
      'Add a parent who can collect this child (turn on \"Can collect the child\") before assigning a bus.';

  @override
  String get studentAssignErrorAlreadyAssigned =>
      'This child already has that assignment — remove the current one first.';

  @override
  String get studentAssignErrorApiUnreachable =>
      'The service is unreachable right now. Try again.';

  @override
  String get studentAssignErrorGeneric =>
      'That could not be saved right now. Try again.';

  @override
  String get userListTitle => 'Users';

  @override
  String get userListAddButton => 'Add administrator';

  @override
  String get userListSearchHint => 'Filter by name, email, or role';

  @override
  String get userListLoadingLabel => 'Loading users';

  @override
  String get userListPickOrgPrompt =>
      'Pick an organization above to see its administrators.';

  @override
  String get userListEmptyState =>
      'No administrators yet. Add the first one above.';

  @override
  String userListNoSearchMatches(String query) {
    return 'No one matches \"$query\".';
  }

  @override
  String userToggleReactivateTitle(String name) {
    return 'Reactivate $name?';
  }

  @override
  String userToggleDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get userToggleReactivateBody => 'They will be able to sign in again.';

  @override
  String get userToggleDeactivateBody =>
      'They will no longer be able to sign in. This can be reversed at any time.';

  @override
  String get userToggleReactivateButton => 'Reactivate';

  @override
  String get userToggleDeactivateButton => 'Deactivate';

  @override
  String get userStatusActive => 'Active';

  @override
  String get userStatusPending => 'Pending';

  @override
  String get userStatusInactive => 'Inactive';

  @override
  String userListRowSubtitle(String email, String role) {
    return '$email · $role';
  }

  @override
  String get userMoreActionsTooltip => 'More actions';

  @override
  String get userResendInvitationLabel => 'Resend invitation';

  @override
  String get userSendResetCodeLabel => 'Send reset code';

  @override
  String get createUserInviteDescription =>
      'We email them a link to set their own password and activate the account.';

  @override
  String get createUserPasswordDescription =>
      'You set a password now and share it with them yourself.';

  @override
  String get createUserSendInviteOption => 'Send invite';

  @override
  String get createUserSetPasswordOption => 'Set password';

  @override
  String get createUserSchoolHint => 'Which school this role applies to';

  @override
  String get createUserEmailLabel => 'Email (sign-in)';

  @override
  String get createUserEmailHint => 'What this person signs in with';

  @override
  String get createUserPhoneLabel => 'Phone (optional)';

  @override
  String get createUserPasswordLabel => 'Initial password';

  @override
  String get createUserPasswordHint => 'At least 12 characters';

  @override
  String get createUserGeneratePasswordTooltip => 'Generate a password';

  @override
  String get invitationSentTitle => 'Invitation sent';

  @override
  String invitationSentBody(String email) {
    return 'We’ve emailed $email a link to set their password. It is valid for 72 hours; you can re-send it from their row if it expires.';
  }

  @override
  String get accountCreatedTitle => 'Account created';

  @override
  String get accountCreatedBody =>
      'Share these sign-in details with them now — this password will not be shown again.';

  @override
  String get credentialsEmailLabel => 'Email';

  @override
  String get credentialsPasswordLabel => 'Password';

  @override
  String get copyTooltip => 'Copy';

  @override
  String copiedSnackbar(String label) {
    return '$label copied';
  }

  @override
  String get editUserLocaleLabel => 'Preferred locale';

  @override
  String get editUserLocaleHint => 'e.g. en';

  @override
  String get orgListAddButton => 'Add organization';

  @override
  String get orgListLoadingLabel => 'Loading organizations';

  @override
  String get orgListEmptyState =>
      'No organizations yet. Add the first one to get started.';

  @override
  String orgListRowSubtitle(String code, String regionProfile) {
    return '$code · $regionProfile';
  }

  @override
  String get orgSuspendedChip => 'Suspended';

  @override
  String get orgListLoadError =>
      'That could not be loaded right now. Try again shortly.';

  @override
  String get createOrgCodeLabel => 'Organization code';

  @override
  String get createOrgCodeHint => 'e.g. GREENWOOD';

  @override
  String get createOrgNameLabel => 'Organization name';

  @override
  String get createOrgNameHint => 'e.g. Greenwood Education Group';

  @override
  String get createOrgRegionLabel => 'Region profile code';

  @override
  String get createOrgContactEmailLabel => 'Contact email (optional)';

  @override
  String get createOrgContactPhoneLabel => 'Contact phone (optional)';

  @override
  String get createOrgCreatingSpinnerLabel => 'Creating organization';

  @override
  String get schoolFieldNameLabel => 'School name';

  @override
  String get schoolFieldTimezoneLabel => 'Timezone (IANA identifier)';

  @override
  String get schoolFieldLatitudeLabel => 'Latitude';

  @override
  String get schoolFieldLongitudeLabel => 'Longitude';

  @override
  String get schoolFieldGeofenceLabel => 'Geofence radius (metres, 20–2000)';

  @override
  String get schoolFieldPlusCodeLabel => 'Plus Code';

  @override
  String schoolFieldPlusCodeResolved(
    String latitude,
    String longitude,
    String metres,
  ) {
    return 'Resolved to $latitude, $longitude — accurate to about $metres m';
  }

  @override
  String get schoolFieldPlusCodeInvalid =>
      'Not a complete Plus Code. A short code like 8F+6W needs a town name, which this field cannot resolve — use the full code.';

  @override
  String get createSchoolCodeLabel => 'School code';

  @override
  String get createSchoolCodeHint => 'e.g. GW-MAIN';

  @override
  String get createSchoolNameHint => 'e.g. Greenwood Main Campus';

  @override
  String get createSchoolAddingSpinnerLabel => 'Adding school';

  @override
  String get createSchoolSubmitButton => 'Add school';

  @override
  String get schoolDetailsIdLabel => 'School ID';

  @override
  String get schoolDetailsIdHelper =>
      'Give this to whoever registers staff, vehicles, or routes for this school.';

  @override
  String get schoolDetailsCodeFixedLabel => 'School code (fixed)';

  @override
  String get schoolDetailsSavingSpinnerLabel => 'Saving school';

  @override
  String get schoolDetailsSaveButton => 'Save school changes';

  @override
  String get copiedToClipboardSnackbar => 'Copied to clipboard';

  @override
  String get onboardingCompleteTitle => 'Organization onboarded';

  @override
  String get onboardingSummaryOrgLabel => 'Organization';

  @override
  String onboardingNameAndCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get onboardingSummaryFirstSchoolLabel => 'First school';

  @override
  String get onboardingNoSchoolYet =>
      'No school was added yet. Add one from the Schools screen before this organization is used day to day (BR-TEN-002).';

  @override
  String get onboardingStartAnotherButton => 'Onboard another organization';

  @override
  String get orgDetailsSectionTitle => 'Organization details';

  @override
  String get orgStatusClosed => 'Closed';

  @override
  String get orgStatusActive => 'Active';

  @override
  String orgConfirmSuspendTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String orgConfirmSuspendBody(String name) {
    return 'This blocks sign-in and administrative access for everyone in $name. No data is deleted, and any trip already in progress keeps recording safety events as normal (BR-TEN-006). You can reactivate at any time.';
  }

  @override
  String get orgSuspendButton => 'Suspend organization';

  @override
  String orgConfirmReactivateTitle(String name) {
    return 'Reactivate $name?';
  }

  @override
  String orgConfirmReactivateBody(String name) {
    return 'This restores sign-in and administrative access for everyone in $name.';
  }

  @override
  String get orgReactivateButton => 'Reactivate organization';

  @override
  String get orgDetailsCodeFixedLabel =>
      'Organization code (fixed, BR-TEN-007)';

  @override
  String get orgDetailsSavingSpinnerLabel => 'Saving organization';

  @override
  String get orgDetailsSaveButton => 'Save organization changes';

  @override
  String addSchoolPromptIntro(String orgName) {
    return 'No school has been added yet. $orgName needs at least one before it can be used day to day.';
  }

  @override
  String get addSchoolPromptSkipButton => 'Not now';

  @override
  String get routeListLoadingLabel => 'Loading routes';

  @override
  String get routeListEmptyState =>
      'No routes loaded. Pick a school above, or add the first route.';

  @override
  String routeStopsTooltip(String name) {
    return 'Stops on $name';
  }

  @override
  String get routeHasVehicleTooltip => 'Has a default bus';

  @override
  String get routeNoVehicleTooltip => 'No bus assigned yet';

  @override
  String get routeListAddButton => 'Add route';

  @override
  String get createRouteIntro =>
      'Creates the route itself. Stops are added separately once the map editor exists — this is enough for assigning a driver or attendant to it today. Added to the school you have selected above.';

  @override
  String get createRouteCodeLabel => 'Route code';

  @override
  String get createRouteCodeHint => 'e.g. R3';

  @override
  String get createRouteNameLabel => 'Route name';

  @override
  String get createRouteNameHint => 'e.g. Green Park — Morning';

  @override
  String get createRouteDefaultVehicleLabel => 'Default bus (optional)';

  @override
  String get createRouteNoVehiclesHint => 'No vehicles on this school yet';

  @override
  String get noneOptionLabel => 'None';

  @override
  String createRouteVehicleOption(String displayName, String registrationNo) {
    return '$displayName · $registrationNo';
  }

  @override
  String get routeCrewAssignButton => 'Assign crew';

  @override
  String get routeCrewLoadingLabel => 'Loading crew';

  @override
  String get routeCrewEmptyState => 'No crew assigned yet.';

  @override
  String get routeCrewBothDirectionsLabel => 'Both directions';

  @override
  String get dutyFormStaffLabel => 'Driver or attendant';

  @override
  String get dutyFormNoRosterHint => 'No roster loaded for this school';

  @override
  String get dutyFormSelectPersonHint => 'Select a person';

  @override
  String dutyFormStaffOption(String name, String staffType) {
    return '$name · $staffType';
  }

  @override
  String get directionBoth => 'Both';

  @override
  String get dutyFormAssigningSpinnerLabel => 'Assigning';

  @override
  String get dutyFormAssignButton => 'Assign';

  @override
  String get routeStopsDialogTitle => 'Stops';

  @override
  String get routeStopsLoadingLabel => 'Loading stops';

  @override
  String get routeStopsMinWarning =>
      'A route needs at least two stops before students can be assigned to it.';

  @override
  String get routeStopsEmptyState => 'No stops yet. Add the first one.';

  @override
  String get routeStopsAddButton => 'Add stop';

  @override
  String routeStopsRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String stopPickupTime(String time) {
    return 'pickup $time';
  }

  @override
  String stopDropTime(String time) {
    return 'drop $time';
  }

  @override
  String stopGeofenceRadiusMetres(int radius) {
    return '$radius m';
  }

  @override
  String get stopFormNameLabel => 'Stop name';

  @override
  String get stopFormNameHint => 'e.g. Green Park — parents see this';

  @override
  String get stopFormLatitudeHint => 'e.g. 28.5494';

  @override
  String get stopFormLongitudeHint => 'e.g. 77.2001';

  @override
  String get stopFormGeofenceLabel => 'Geofence radius (metres)';

  @override
  String get stopFormGeofenceHint => '20–500';

  @override
  String get stopFormPickupTimeLabel => 'Pickup time (optional)';

  @override
  String get stopFormDropTimeLabel => 'Drop time (optional)';

  @override
  String get stopFormTimeHint => 'HH:mm';

  @override
  String get stopFormLandmarkLabel => 'Landmark (optional)';

  @override
  String get stopFormLandmarkHint => 'Helps parents find the stop';

  @override
  String get stopFormErrorNameRequired => 'Give the stop a name.';

  @override
  String get stopFormErrorLatitudeRange =>
      'Latitude must be a number between -90 and 90.';

  @override
  String get stopFormErrorLongitudeRange =>
      'Longitude must be a number between -180 and 180.';

  @override
  String get stopFormErrorGeofenceRange =>
      'Geofence radius must be between 20 and 500 metres.';

  @override
  String get stopFormErrorTimeFormat =>
      'Times must be in 24-hour HH:mm form, e.g. 07:40.';

  @override
  String get schoolSettingsLoadingLabel => 'Loading school';

  @override
  String get studentListImportButton => 'Import';

  @override
  String get studentImportTitle => 'Import students';

  @override
  String get studentImportIntro =>
      'Upload a spreadsheet of students, saved as CSV. Rows that are ready are enrolled straight away; anything that needs fixing is listed for you to correct and upload again.';

  @override
  String get studentImportColumnsTitle => 'Columns';

  @override
  String get studentImportColumnsBody =>
      'Required: admissionNo, firstName, lastName. Optional: dateOfBirth (YYYY-MM-DD) and transportEligible (true or false — defaults to true). Column names are matched loosely, ignoring case and spaces. A column that isn\'t one of these stops the whole file — guardian and stop columns are not supported yet.';

  @override
  String get studentImportChooseFileButton => 'Choose CSV file';

  @override
  String get studentImportUploadingLabel => 'Uploading and checking the file';

  @override
  String studentImportUploadingNamed(String name) {
    return 'Uploading $name…';
  }

  @override
  String studentImportSummary(int totalRows, int successCount, int errorCount) {
    return '$totalRows rows · $successCount imported · $errorCount errors';
  }

  @override
  String get studentImportSummaryHintErrors =>
      'The rows below were not enrolled. Fix them in your spreadsheet and upload again — only the corrected rows need to be in the next file.';

  @override
  String get studentImportSummaryHintAllImported =>
      'Every row was enrolled. They now appear on the register.';

  @override
  String get studentImportSummaryHintNothing =>
      'Nothing was enrolled. Correct the rows below and upload again.';

  @override
  String get studentImportDownloadErrorsButton => 'Download error rows';

  @override
  String get studentImportAnotherButton => 'Import another file';

  @override
  String get studentImportColRow => 'Row';

  @override
  String get studentImportColField => 'Column';

  @override
  String get studentImportColProblem => 'What to fix';

  @override
  String get studentImportErrorEmpty =>
      'That file has no student rows. Check you saved the sheet with the students in it as CSV.';

  @override
  String get studentImportErrorUnreadable =>
      'That file could not be read as a spreadsheet. Open it in your spreadsheet program and use “Save as… CSV”, then upload the CSV.';

  @override
  String get studentImportErrorUnsupportedColumn =>
      'One of the columns in that file is not supported yet. Keep only admissionNo, firstName, lastName, dateOfBirth and transportEligible, then upload again.';

  @override
  String get studentImportErrorTooManyRows =>
      'That file has too many rows for one upload. Split it into smaller files and import them one at a time.';

  @override
  String get studentImportErrorNoFile =>
      'No file was chosen. Pick a CSV file to upload.';

  @override
  String get custodyPanelTitle => 'Custody restrictions';

  @override
  String get custodyAddButton => 'Add restriction';

  @override
  String get custodyPanelWarning =>
      'A restriction takes effect immediately and overrides every parent right — the person named cannot collect or see this child while it is in force. Every restriction is recorded with its reason.';

  @override
  String get custodyLoadingLabel => 'Loading restrictions';

  @override
  String get custodyEmptyState => 'No restrictions. That is the normal state.';

  @override
  String get custodyLiftButton => 'Lift';

  @override
  String get custodyStatusLifted => 'Lifted';

  @override
  String get custodyLiftConfirmTitle => 'Lift this restriction?';

  @override
  String get custodyLiftConfirmBody =>
      'The person named will be able to collect and see this child again, straight away. The restriction and its history are kept.';

  @override
  String get custodyLiftConfirmButton => 'Lift restriction';

  @override
  String custodyEffectiveLine(String from, String until) {
    return 'In force from $from until $until';
  }

  @override
  String get custodyOpenEnded => 'no end date';

  @override
  String custodySubjectGuardian(String id) {
    return 'Parent $id';
  }

  @override
  String get custodyTypeNoHandover => 'Cannot collect the child';

  @override
  String get custodyTypeNoVisibility => 'Cannot see the child\'s journey';

  @override
  String get custodyTypeFull => 'Cannot collect or see the child';

  @override
  String get custodyAddTitle => 'Add a custody restriction';

  @override
  String get custodySubjectAGuardian => 'A parent on file';

  @override
  String get custodySubjectAPerson => 'Someone else, by name';

  @override
  String get custodyGuardianLabel => 'Parent';

  @override
  String get custodyPersonNameLabel => 'Full name';

  @override
  String get custodyPersonNameRequired => 'Enter the person\'s full name';

  @override
  String get custodyTypeLabel => 'Restriction';

  @override
  String get custodyReasonLabel => 'Reason (required)';

  @override
  String get custodyReasonHelper =>
      'What authorises this — a court order and its reference, a school safeguarding decision. Kept on the audit record.';

  @override
  String get custodyErrorReasonRequired =>
      'A reason is required for every custody restriction.';

  @override
  String get custodyUntilLabel => 'End date (optional)';

  @override
  String get custodyUntilFormatError =>
      'Use the format YYYY-MM-DD, or leave blank for no end date.';

  @override
  String get custodyAddSubmitButton => 'Add restriction';

  @override
  String get custodyErrorSubjectRequired =>
      'Name exactly one person — a parent on file, or someone by name.';

  @override
  String get custodyErrorNotFound =>
      'That restriction could not be found. It may already have been lifted.';

  @override
  String get onboardingAddOrganizationTitle => 'Add organization';

  @override
  String get onboardingAddOrganizationSubtitle =>
      'Create the organization, then add its first school.';

  @override
  String get onboardingStepOrganizationLabel => 'Organization';

  @override
  String get onboardingStepFirstSchoolLabel => 'First school';

  @override
  String onboardingStepSemanticLabel(
    int number,
    int total,
    String label,
    String status,
  ) {
    return 'Step $number of $total: $label, $status';
  }

  @override
  String get onboardingStepStatusDone => 'completed';

  @override
  String get onboardingStepStatusCurrent => 'current step';

  @override
  String get onboardingStepStatusUpcoming => 'not started';

  @override
  String get createOrgSectionIdentityTitle => 'Identity';

  @override
  String get createOrgSectionIdentityDescription =>
      'How this organization is named and identified across the platform.';

  @override
  String get createOrgCodeHelper =>
      'Short and unique. Fixed once the organization has schools or staff.';

  @override
  String get createOrgSectionRegionTitle => 'Region';

  @override
  String get createOrgSectionRegionDescription =>
      'Supplies phone, document, and data-retention defaults.';

  @override
  String get createOrgRegionHelper => 'e.g. IN';

  @override
  String get createOrgSectionContactTitle => 'Contact';

  @override
  String get createOrgSectionContactDescription =>
      'Who the platform team reaches about this organization.';

  @override
  String get createOrgContinueButton => 'Create and continue';

  @override
  String createSchoolCreatedBannerTitle(String orgName, String orgCode) {
    return '$orgName ($orgCode) created';
  }

  @override
  String get createSchoolCreatedBannerBody =>
      'An organization needs at least one school before it can be used day to day. Add it now, or skip and add it later.';

  @override
  String get createSchoolSectionSchoolTitle => 'Identity';

  @override
  String get createSchoolSectionSchoolDescription =>
      'The campus buses travel to and from.';

  @override
  String get createSchoolCodeHelper =>
      'Unique within this organization. Fixed once the school is in use.';

  @override
  String get createSchoolSectionLocationTitle => 'Location';

  @override
  String get createSchoolSectionLocationDescription =>
      'Arrival alerts are measured from this point.';

  @override
  String get createSchoolPlusCodeHint => 'e.g. 7J4VXMQ5+8F';

  @override
  String get createSchoolPlusCodeGuide =>
      'Paste the school\'s full Plus Code from Google Maps. The latitude and longitude are worked out from it and shown here before you save.';

  @override
  String get createSchoolLocationFoundTitle => 'Location found';

  @override
  String get createSchoolGeofenceLabel => 'Geofence radius';

  @override
  String get createSchoolGeofenceHelper =>
      'Between 20 and 2000 metres around the school.';

  @override
  String get unitMetresSuffix => 'm';

  @override
  String get createSchoolSectionTimeTitle => 'Local time';

  @override
  String get createSchoolSectionTimeDescription =>
      'Every time shown for this school uses its time zone.';

  @override
  String get createSchoolTimezoneLabel => 'Time zone';

  @override
  String get createSchoolTimezoneHelper => 'IANA name, e.g. Asia/Kolkata';

  @override
  String get createSchoolSkipForNowButton => 'Skip for now';

  @override
  String get globalSearchHint => 'Search students, parents, staff, vehicles…';

  @override
  String get globalSearchShortcutMac => '⌘K';

  @override
  String get globalSearchShortcutOther => 'Ctrl K';

  @override
  String get globalSearchClearTooltip => 'Clear search';

  @override
  String get globalSearchMinLength => 'Type at least 3 characters to search';

  @override
  String get globalSearchLoading => 'Searching';

  @override
  String globalSearchNoResults(String query) {
    return 'No matches for “$query”';
  }

  @override
  String get globalSearchError =>
      'Search is unavailable right now. Try again shortly.';

  @override
  String get globalSearchOpenFailed =>
      'That record could not be opened right now.';

  @override
  String get globalSearchMoreResults =>
      'More matches — keep typing to narrow them down';

  @override
  String get globalSearchSubtitleSeparator => ' · ';

  @override
  String get globalSearchGroupStudents => 'Students';

  @override
  String get globalSearchGroupGuardians => 'Parents';

  @override
  String get globalSearchGroupStaff => 'Drivers & attendants';

  @override
  String get globalSearchGroupVehicles => 'Vehicles';

  @override
  String get globalSearchGroupRoutes => 'Routes';

  @override
  String get globalSearchGroupUsers => 'Administrators';

  @override
  String get globalSearchGroupSchools => 'Schools';

  @override
  String get globalSearchGroupOrganizations => 'Organizations';

  @override
  String get globalSearchKindStudent => 'Student';

  @override
  String get globalSearchKindGuardian => 'Parent';

  @override
  String get globalSearchKindDriver => 'Driver';

  @override
  String get globalSearchKindAttendant => 'Attendant';

  @override
  String get globalSearchKindVehicle => 'Vehicle';

  @override
  String get globalSearchKindRoute => 'Route';

  @override
  String get globalSearchKindUser => 'Administrator';

  @override
  String get globalSearchKindSchool => 'School';

  @override
  String get globalSearchKindOrganization => 'Organization';

  @override
  String globalSearchLinkedChild(String studentName) {
    return 'Child: $studentName';
  }

  @override
  String globalSearchAdmissionNumber(String admissionNo) {
    return 'Adm $admissionNo';
  }

  @override
  String get globalSearchNoScreen =>
      'There is no screen for this record in your console.';

  @override
  String get discardEntryTitle => 'Delete this entry?';

  @override
  String get discardEntryReasonLabel => 'Reason';

  @override
  String get discardEntryReasonHelper =>
      'Required. Say what the mistake was, e.g. \"Duplicate of admission 2024-118\". It is kept on the audit trail.';

  @override
  String get discardEntryConfirmButton => 'Delete permanently';

  @override
  String get discardEntryDeletingSpinnerLabel => 'Deleting entry';

  @override
  String get discardEntryDeletedSnackbar => 'Entry deleted';

  @override
  String studentDiscardTooltip(String name) {
    return 'Delete entry for $name';
  }

  @override
  String studentDiscardBody(String name, String admissionNo) {
    return 'Use this only for a student entered by mistake, such as a duplicate or a wrong admission number.\n\n$name ($admissionNo) will be permanently removed, with their parent links, pickup and drop, and boarding credentials. Parent records are kept.\n\nA student with any history (boarding, absences, notifications) cannot be deleted. Withdraw them instead.';
  }

  @override
  String get studentErrorHasSafetyRecords =>
      'This student has history and cannot be deleted. A school admin can withdraw them instead.';

  @override
  String staffDiscardTooltip(String name) {
    return 'Delete entry for $name';
  }

  @override
  String staffDiscardBody(String name) {
    return 'Use this only for a driver or attendant entered by mistake.\n\n$name will be permanently removed, with their credential documents and duty assignments, and their app sign-in will be switched off.\n\nSomeone who has signed in to the app, or has any history, cannot be deleted. Deactivate them instead.';
  }

  @override
  String get staffErrorHasSafetyRecords =>
      'This person has signed in or has history, so they cannot be deleted. A school admin or transport manager can deactivate them instead.';

  @override
  String get staffErrorNotFound =>
      'This driver or attendant no longer exists, or is outside your school. Refresh the list.';

  @override
  String get staffEditPhoneHelper =>
      'Changing the number moves their app sign-in to it and signs the old number out.';

  @override
  String guardianEditTooltip(String name) {
    return 'Edit $name\'s details';
  }

  @override
  String editGuardianTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get editGuardianPhoneHelper =>
      'Changing the number moves this parent\'s app sign-in to it and signs the old number out straight away.';

  @override
  String get studentErrorGuardianPhoneInUse =>
      'That number already belongs to another parent on file. Check which record is right before changing it.';

  @override
  String get studentErrorGuardianNotFound =>
      'This parent\'s record could not be found. Refresh the page and try again.';

  @override
  String get studentTransportCaption =>
      'Bus and crew shown are the route\'s usual assignment for today. Where the child is right now will appear here once trips are running.';

  @override
  String studentTransportBus(String name, String registration) {
    return 'Bus: $name ($registration)';
  }

  @override
  String studentTransportBusNotInService(String name, String registration) {
    return 'Bus: $name ($registration), not in service. Set another bus on the route.';
  }

  @override
  String get studentTransportNoBus => 'No bus set for this route';

  @override
  String studentTransportDriver(String names) {
    return 'Driver: $names';
  }

  @override
  String get studentTransportNoDriver =>
      'No driver on duty for this route today';

  @override
  String studentTransportAttendant(String names) {
    return 'Attendant: $names';
  }

  @override
  String get studentTransportNoAttendant =>
      'No attendant on duty for this route today';

  @override
  String get studentTransportLoadError =>
      'Couldn\'t load the assigned bus and crew. Reopen the record to try again.';

  @override
  String get routeStopsUnsavedHint =>
      'Not saved yet. Press Save to keep these stops.';

  @override
  String get routeStopsDiscardTitle => 'Discard unsaved stops?';

  @override
  String get routeStopsDiscardBody =>
      'The stops you added or removed have not been saved. If you close now, the changes are lost and students cannot be given these stops.';

  @override
  String get routeStopsKeepEditingButton => 'Keep editing';

  @override
  String get routeStopsDiscardButton => 'Discard changes';

  @override
  String get routeStopsErrorMinimum =>
      'A route needs at least two stops. Add another stop, then save.';

  @override
  String get routeStopsErrorGeofence =>
      'A stop\'s arrival radius must be between 20 and 500 metres. Correct it, then save.';

  @override
  String get routeStopsErrorTimesNotIncreasing =>
      'Pickup times must get later going down the list of stops. Drop times run the other way: the afternoon bus drops the last stop first, so drop times must get later going up the list. Check the times, then save.';

  @override
  String get stopFormDropTimeHelper =>
      'Afternoon runs in reverse: the last stop is dropped first.';

  @override
  String get routeStopsSavedSnackbar =>
      'Stops saved. Students can now be given these stops for pickup and drop.';

  @override
  String get routeStopsErrorStale =>
      'These stops were changed somewhere else since you opened them. Close and reopen the stops, then make your change again.';

  @override
  String get routeStopsErrorHasAssignedStudents =>
      'A stop you removed still has students assigned to it. Move those students to another stop from their student record first, then remove the stop.';

  @override
  String get routeCrewUnfilledSlot => 'Nobody assigned';

  @override
  String get routeCrewReplaceTooltip => 'Put someone else on this duty';

  @override
  String get routeCrewRemoveTooltip => 'Take off this route';

  @override
  String get routeCrewRemoveTitle => 'Take this crew member off the route?';

  @override
  String routeCrewRemoveBody(String name, String role, String routeName) {
    return '$name will no longer be the $role on $routeName. The route is left with nobody in that role until you assign someone.';
  }

  @override
  String get routeCrewRemoveButton => 'Take off route';

  @override
  String replaceDutyTitle(String name, String role) {
    return 'Replace $name as $role';
  }

  @override
  String get replaceDutyStandingRosterNote =>
      'This changes who normally runs this route. A stand-in for a single day is recorded against that day\'s trip, which this build cannot do yet.';

  @override
  String replaceDutyStaffLabel(String role) {
    return 'New $role';
  }

  @override
  String get replaceDutyReasonLabel => 'Reason';

  @override
  String get replaceDutyReasonHelper =>
      'Required, e.g. \"Suresh on leave from today\". Kept on the audit trail with both names.';

  @override
  String get replaceDutySubmitButton => 'Replace';

  @override
  String get routeOperatingDaysLabel => 'Operating days';

  @override
  String get routeOperatingDaysHelper => 'Trips are generated only for the days selected here. School holidays are set separately, on the school calendar.';

  @override
  String get routeOperatingDaysNoneSelected => 'Select at least one day, or this route will never run.';

  @override
  String get routeOperatingDaysWeekdaysPreset => 'Mon–Fri';

  @override
  String get routeOperatingDaysAllPreset => 'Every day';

  @override
  String get routeDayMonShort => 'Mon';

  @override
  String get routeDayTueShort => 'Tue';

  @override
  String get routeDayWedShort => 'Wed';

  @override
  String get routeDayThuShort => 'Thu';

  @override
  String get routeDayFriShort => 'Fri';

  @override
  String get routeDaySatShort => 'Sat';

  @override
  String get routeDaySunShort => 'Sun';

  @override
  String get routeListOperatingDaysColumn => 'Runs';

  @override
  String get routeEditTitle => 'Edit route';

  @override
  String get routeEditSubmitButton => 'Save changes';

  @override
  String get routeListEditTooltip => 'Edit this route';
}
