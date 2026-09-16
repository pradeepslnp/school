# Translation status — English / Kannada (ADR-0013)

Per [ADR-0013](../../../documentation/00-governance/adr/ADR-0013-interim-client-bundled-flutter-localisation.md), `app_en.arb` is the complete, real source of truth. `app_kn.arb` currently carries the **English value as an explicit, tracked placeholder** for every key below — not a silent gap, not an inline `TODO`. Every key in `app_en.arb` has a mirrored key in `app_kn.arb` (parity is verified as part of this pass); none of the Kannada values are a real translation yet.

**Total resource keys: 521. Kannada status for all of them: `pending-kn-translation`.**

## Safety-critical — requires native-speaker sign-off before a Kannada value ships

The keys below are called out separately because they touch guardian handover authorisation (who may take a child off a bus), the audit/override register, incident visibility, self-release eligibility, or removing a student from transport — the admin-console equivalent of the `NTF-BOARD-*`/`NTF-HAND-*` family ADR-0013 names. A machine or unreviewed translation of any of these is a real safety risk, not a cosmetic one: a mistranslated "can collect" control, or a misread audit override note, is the kind of error that reaches a real child. **Do not ship a Kannada value for any key in this table without native-speaker review**, even after the rest of `app_kn.arb` has been translated.

| Key | English value | Kannada status |
|---|---|---|
| `addGuardianCanHandoverTitle` | Can collect the child | pending-kn-translation — native-speaker review required |
| `addGuardianCanHandoverSubtitle` | Authorised to receive the child at the stop — needed before the child can be put on a bus | pending-kn-translation — native-speaker review required |
| `guardianTileCanCollectChip` | Can collect | pending-kn-translation — native-speaker review required |
| `guardianTileCannotCollectChip` | Cannot collect | pending-kn-translation — native-speaker review required |
| `studentDetailNoHandoverGuardianWarning` | No parent here can collect the child yet — turn on "Can collect the child" for at least one before assigning a bus. | pending-kn-translation — native-speaker review required |
| `studentAssignErrorNoActiveGuardian` | Add a parent who can collect this child (turn on "Can collect the child") before assigning a bus. | pending-kn-translation — native-speaker review required |
| `permCategoryBoardingHandover` | Boarding & Handover | pending-kn-translation — native-speaker review required |
| `permNotePickupPersonManage` | A guardian's grant requires the "authorise handover" right on the relationship (BR-GRD-006). | pending-kn-translation — native-speaker review required |
| `permNoteHandoverCodeRequest` | Requires "can_authorise_handover" on the relationship (BR-GRD-006); redemption at the vehicle is the separate attendant-side flow (BR-HAND-001–007). | pending-kn-translation — native-speaker review required |
| `permNoteHandoverOverride` | Notifies all guardians and the transport manager (BR-HAND-003); always audited with a reason (BR-AUD-004). | pending-kn-translation — native-speaker review required |
| `permNoteBoardingCorrect` | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation — native-speaker review required |
| `permNoteBoardingOverride` | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation — native-speaker review required |
| `permNoteReconciliationResolve` | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation — native-speaker review required |
| `permNoteConfigSafetyEdit` | Governs safety-relevant thresholds; bounded by platform floors (BR-CFG-003). | pending-kn-translation — native-speaker review required |
| `permNoteIncidentView` | A guardian's grant is limited to incidents affecting their own child (BR-INC-004, BR-NTF-007). | pending-kn-translation — native-speaker review required |
| `permNoteAbsenceDeclare` | A guardian's grant requires the "declare absence" right (BR-ABS-001). | pending-kn-translation — native-speaker review required |
| `auditOverridesDescription` | Actions taken with an override reason — a person overrode a safety check and said why. | pending-kn-translation — native-speaker review required |
| `auditOverrideBadge` | Override | pending-kn-translation — native-speaker review required |
| `auditScopeOverrides` | Overrides | pending-kn-translation — native-speaker review required |
| `auditNoOverridesEmptyState` | No overrides recorded. That is the healthy state. | pending-kn-translation — native-speaker review required |
| `studentFormDateOfBirthHelper` | YYYY-MM-DD — used to decide self-release eligibility | pending-kn-translation — native-speaker review required |
| `studentWithdrawConfirmTitle` | Withdraw student? | pending-kn-translation — native-speaker review required |
| `studentWithdrawConfirmBody` | {name} ({admissionNo}) will be taken off the roll and removed from transport.<br><br>Their record is kept — safety records reference it — and can still be read. | pending-kn-translation — native-speaker review required |
| `studentWithdrawConfirmButton` | Withdraw | pending-kn-translation — native-speaker review required |
| `custodyPanelWarning` | A restriction takes effect immediately and overrides every parent right… | pending-kn-translation — native-speaker review required |
| `custodyTypeNoHandover` / `custodyTypeNoVisibility` / `custodyTypeFull` | Cannot collect / see / collect-or-see the child | pending-kn-translation — native-speaker review required |
| `custodyLiftConfirmBody` | The person named will be able to collect and see this child again, straight away… | pending-kn-translation — native-speaker review required |
| `custodyReasonHelper` | What authorises this — a court order and its reference… | pending-kn-translation — native-speaker review required |

Not included above because this admin console does not yet surface them: wrong-bus/missed-bus rider-facing alerts and incident/SOS screens are part of `parent_app`/`driver_attender_app`'s scope (see those apps' own `TRANSLATION_STATUS.md`) — this console currently has no dashboard, alerts, or SOS destination built (`NoModulesNotice`), so there is no equivalent in-app copy here to flag yet. If A-01/alerts/SOS land in a later build, extend this table then.

## All resource keys, by area

Every key below is `pending-kn-translation` in `app_kn.arb` (English-fallback placeholder). Keys already listed in the safety-critical table above are marked ⚠️ here too, so this full listing stays a complete single source rather than requiring a cross-reference.

### App shell & language

| Key | English value | Kannada status |
|---|---|---|
| `appTitle` | Guardian Admin | pending-kn-translation |
| `consoleHeaderBrand` | Guardian | pending-kn-translation |
| `consoleDestinationOrganizations` | Organizations | pending-kn-translation |
| `consoleDestinationSchool` | School | pending-kn-translation |
| `consoleDestinationStudents` | Students | pending-kn-translation |
| `consoleDestinationDrivers` | Drivers | pending-kn-translation |
| `consoleDestinationVehicles` | Vehicles | pending-kn-translation |
| `consoleDestinationRoutes` | Routes | pending-kn-translation |
| `consoleDestinationUsers` | Users | pending-kn-translation |
| `consoleDestinationRoles` | Roles | pending-kn-translation |
| `consoleDestinationPlatformHealth` | Platform health | pending-kn-translation |
| `consoleDestinationAuditTrail` | Audit trail | pending-kn-translation |
| `accountMenuSignOut` | Sign out | pending-kn-translation |
| `accountMenuSigningOut` | Signing out… | pending-kn-translation |
| `noModulesNoticeTitle` | No console modules in this build | pending-kn-translation |
| `noModulesNoticeBody` | You are signed in. The operations dashboard, alert inbox, and administration screens are not part of this build yet. | pending-kn-translation |
| `bootSplashLoadingLabel` | Loading the console | pending-kn-translation |
| `languageSwitcherTooltip` | Change language | pending-kn-translation |
| `languageNameEnglish` | English | pending-kn-translation |
| `languageNameKannada` | ಕನ್ನಡ | pending-kn-translation |
### Roles & permissions reference (A-44)

| Key | English value | Kannada status |
|---|---|---|
| `roleNameSuperAdmin` | Super Admin | pending-kn-translation |
| `roleNameOrgAdmin` | Organization Admin | pending-kn-translation |
| `roleNameSchoolAdmin` | School Admin | pending-kn-translation |
| `roleNamePrincipal` | Principal | pending-kn-translation |
| `roleNameTransportManager` | Transport Manager | pending-kn-translation |
| `roleNameVendorStaff` | Vendor Staff | pending-kn-translation |
| `roleNameDriver` | Driver | pending-kn-translation |
| `roleNameAttendant` | Attendant | pending-kn-translation |
| `roleNameGuardian` | Guardian | pending-kn-translation |
| `roleShortSuperAdmin` | Super<br>Admin | pending-kn-translation |
| `roleShortOrgAdmin` | Org<br>Admin | pending-kn-translation |
| `roleShortSchoolAdmin` | School<br>Admin | pending-kn-translation |
| `roleShortPrincipal` | Principal | pending-kn-translation |
| `roleShortTransportManager` | Transport<br>Mgr | pending-kn-translation |
| `roleShortVendorStaff` | Vendor<br>Staff | pending-kn-translation |
| `roleShortDriver` | Driver | pending-kn-translation |
| `roleShortAttendant` | Attendant | pending-kn-translation |
| `roleShortGuardian` | Guardian | pending-kn-translation |
| `permCategoryTenancyConfig` | Tenancy & Configuration | pending-kn-translation |
| `permCategoryIdentityAccess` | Identity & Access | pending-kn-translation |
| `permCategoryStudentsGuardians` | Students & Guardians | pending-kn-translation |
| `permCategoryFleetStaff` | Fleet & Staff | pending-kn-translation |
| `permCategoryRoutesTrips` | Routes & Trips | pending-kn-translation |
| `permCategoryBoardingHandover` ⚠️ | Boarding & Handover | pending-kn-translation |
| `permCategoryTrackingAlertsIncidents` | Tracking, Alerts, Incidents | pending-kn-translation |
| `permCategoryAbsenceNotificationReportingAudit` | Absence, Notification, Reporting, Audit | pending-kn-translation |
| `permCategoryPlatformOperations` | Platform Operations | pending-kn-translation |
| `permNoteConfigSafetyEdit` ⚠️ | Governs safety-relevant thresholds; bounded by platform floors (BR-CFG-003). | pending-kn-translation |
| `permNoteStudentView` | Non-admin roles see only the current trip manifest or their own children (BR-IAM-005); non-guardian access is logged (BR-IAM-012). | pending-kn-translation |
| `permNotePickupPersonManage` ⚠️ | A guardian's grant requires the "authorise handover" right on the relationship (BR-GRD-006). | pending-kn-translation |
| `permNoteHandoverCodeRequest` ⚠️ | Requires "can_authorise_handover" on the relationship (BR-GRD-006); redemption at the vehicle is the separate attendant-side flow (BR-HAND-001–007). | pending-kn-translation |
| `permNoteTripView` | A guardian's grant is limited to trips carrying one of their children (BR-TRACK-002). | pending-kn-translation |
| `permNoteBoardingCorrect` ⚠️ | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation |
| `permNoteBoardingOverride` ⚠️ | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation |
| `permNoteHandoverOverride` ⚠️ | Notifies all guardians and the transport manager (BR-HAND-003); always audited with a reason (BR-AUD-004). | pending-kn-translation |
| `permNoteReconciliationResolve` ⚠️ | Override-capable; always audited with a reason (BR-AUD-004). | pending-kn-translation |
| `permNoteIncidentView` ⚠️ | A guardian's grant is limited to incidents affecting their own child (BR-INC-004, BR-NTF-007). | pending-kn-translation |
| `permNoteAbsenceDeclare` ⚠️ | A guardian's grant requires the "declare absence" right (BR-ABS-001). | pending-kn-translation |
| `permNoteNotificationSelfView` | Everyone, scoped to their own notifications only — never a route to another family's child (BR-NTF-007). | pending-kn-translation |
| `permNoteDataExport` | Always audited with actor, scope, and record count (BR-RPT-002). | pending-kn-translation |
| `permNotePlatformTenantAccess` | The only path across the tenant boundary (BR-TEN-004); every use is audited with the target organization and justification (AUD-004). | pending-kn-translation |
| `roleReferenceTitle` | Roles & permissions | pending-kn-translation |
| `roleReferenceDescription` | What each system role can do, straight from the permission matrix this platform enforces server-side on every request. Reference only — roles cannot be edited here yet. | pending-kn-translation |
| `roleReferenceSearchLabel` | Search | pending-kn-translation |
| `roleReferenceSearchHint` | Filter by permission ID or category | pending-kn-translation |
| `roleReferenceClearSearchTooltip` | Clear search | pending-kn-translation |
| `roleReferenceRoleFilterLabel` | Role | pending-kn-translation |
| `roleReferenceEveryRoleOption` | Every role | pending-kn-translation |
| `roleReferenceNoResults` | No permission matches this search. | pending-kn-translation |
| `roleReferenceGrantNarrowerTooltip` | Granted, narrowed to a smaller scope than this role normally has | pending-kn-translation |
### School (A-41) & school-scope picker

| Key | English value | Kannada status |
|---|---|---|
| `schoolScopeOrganizationLabel` | Organization | pending-kn-translation |
| `schoolScopeLoadingHint` | Loading… | pending-kn-translation |
| `schoolScopeSelectOrganizationHint` | Select an organization | pending-kn-translation |
| `schoolScopeLabel` | School | pending-kn-translation |
| `schoolScopeSelectOrganizationFirstHint` | Select an organization first | pending-kn-translation |
| `schoolScopeSelectSchoolHint` | Select a school | pending-kn-translation |
| `schoolScopeLoadError` | Could not load your organizations or schools. | pending-kn-translation |
| `schoolSettingsScreenTitle` | School | pending-kn-translation |
| `schoolFieldNameLabel` | School name | pending-kn-translation |
| `schoolFieldTimezoneLabel` | Timezone (IANA identifier) | pending-kn-translation |
| `schoolFieldLatitudeLabel` | Latitude | pending-kn-translation |
| `schoolFieldLongitudeLabel` | Longitude | pending-kn-translation |
| `schoolFieldGeofenceLabel` | Geofence radius (metres, 20–2000) | pending-kn-translation |
| `createSchoolCodeLabel` | School code | pending-kn-translation |
| `createSchoolCodeHint` | e.g. GW-MAIN | pending-kn-translation |
| `createSchoolNameHint` | e.g. Greenwood Main Campus | pending-kn-translation |
| `createSchoolAddingSpinnerLabel` | Adding school | pending-kn-translation |
| `createSchoolSubmitButton` | Add school | pending-kn-translation |
| `schoolDetailsIdLabel` | School ID | pending-kn-translation |
| `schoolDetailsIdHelper` | Give this to whoever registers staff, vehicles, or routes for this school. | pending-kn-translation |
| `schoolDetailsCodeFixedLabel` | School code (fixed) | pending-kn-translation |
| `schoolDetailsSavingSpinnerLabel` | Saving school | pending-kn-translation |
| `schoolDetailsSaveButton` | Save school changes | pending-kn-translation |
| `addSchoolPromptIntro` | No school has been added yet. {orgName} needs at least one before it can be used day to day. | pending-kn-translation |
| `addSchoolPromptSkipButton` | Not now | pending-kn-translation |
| `schoolSettingsLoadingLabel` | Loading school | pending-kn-translation |
### Shared error copy

| Key | English value | Kannada status |
|---|---|---|
| `errorValidationRequiredField` | Fill in every required field. | pending-kn-translation |
| `errorValidationCheckDetails` | Check the details you entered. | pending-kn-translation |
| `errorApiUnreachable` | The Guardian API could not be reached. Check your connection, then try again. | pending-kn-translation |
| `errorSessionEnded` | That session has ended. Sign in again. | pending-kn-translation |
| `errorGenericRetryShortly` | That could not be saved right now. Try again shortly. | pending-kn-translation |
### Sign-in / auth recovery

| Key | English value | Kannada status |
|---|---|---|
| `loginErrorCredentialsInvalid` | Those details were not recognised. Check the email address and password. | pending-kn-translation |
| `loginErrorAccountLocked` | This account is locked after too many failed attempts. Contact your platform administrator to unlock it. | pending-kn-translation |
| `loginErrorRateLimitExceeded` | Too many sign-in attempts. Wait a minute, then try again. | pending-kn-translation |
| `loginErrorValidationRequiredField` | Enter both your email address and your password. | pending-kn-translation |
| `loginErrorGenericFailure` | Sign-in is not working right now. Contact your platform administrator. | pending-kn-translation |
| `loginSessionEndedRevoked` | Your session was ended by the platform. This happens when an account is deactivated or a session is revoked. | pending-kn-translation |
| `loginSessionEndedRefreshFailed` | Your session expired and could not be renewed. Sign in to continue. | pending-kn-translation |
| `loginSignInLabel` | Sign in | pending-kn-translation |
| `loginFormSubtitle` | Guardian administration console | pending-kn-translation |
| `loginPasswordLabel` | Password | pending-kn-translation |
| `loginSubmittingSpinnerLabel` | Signing in | pending-kn-translation |
| `loginForgotPasswordLink` | Forgot password? | pending-kn-translation |
| `emailAddressLabel` | Email address | pending-kn-translation |
| `passwordVisibilityShowTooltip` | Show password | pending-kn-translation |
| `passwordVisibilityHideTooltip` | Hide password | pending-kn-translation |
| `confirmPasswordFieldLabel` | Confirm password | pending-kn-translation |
| `passwordMismatchError` | The two passwords do not match. | pending-kn-translation |
| `passwordValidationTooShort` | Use at least {minLength} characters. | pending-kn-translation |
| `goToSignInButton` | Go to sign in | pending-kn-translation |
| `acceptInvitationTitle` | Set your password | pending-kn-translation |
| `acceptInvitationIntro` | Choose a password to activate your account and sign in. | pending-kn-translation |
| `acceptInvitationSubmitLabel` | Activate account | pending-kn-translation |
| `acceptInvitationDoneTitle` | Account activated | pending-kn-translation |
| `acceptInvitationDoneBody` | You can now sign in with your email address and new password. | pending-kn-translation |
| `setPasswordErrorLinkExpired` | This link has expired. Ask an administrator to send you a new one. | pending-kn-translation |
| `setPasswordErrorLinkAlreadyUsed` | This link has already been used. If you have set your password, just sign in. | pending-kn-translation |
| `setPasswordErrorLinkInvalid` | This link is not valid. Check you opened the most recent email, or ask for a new link. | pending-kn-translation |
| `authRecoveryErrorPasswordTooWeak` | That password is too weak. Use at least {minLength} characters and avoid common passwords. | pending-kn-translation |
| `authRecoveryErrorApiUnreachable` | We could not reach the server. Check your connection and try again. | pending-kn-translation |
| `authRecoveryErrorGeneric` | That could not be completed right now. Please try again. | pending-kn-translation |
| `newPasswordFieldLabel` | New password | pending-kn-translation |
| `newPasswordHelperText` | At least {minLength} characters. | pending-kn-translation |
| `forgotPasswordTitle` | Reset your password | pending-kn-translation |
| `forgotPasswordIntro` | Enter your email and we will send you a 6-digit code to reset your password. | pending-kn-translation |
| `forgotPasswordEmailValidationError` | Enter a valid email address. | pending-kn-translation |
| `forgotPasswordSendCodeButton` | Send code | pending-kn-translation |
| `forgotPasswordBackToSignIn` | Back to sign in | pending-kn-translation |
| `forgotPasswordEnterCodeTitle` | Enter your code | pending-kn-translation |
| `forgotPasswordCodeIntro` | If an account exists for {email}, we’ve emailed a 6-digit code. It is valid for 10 minutes. Enter it and choose a new password. | pending-kn-translation |
| `forgotPasswordCodeFieldLabel` | 6-digit code | pending-kn-translation |
| `forgotPasswordCodeValidationError` | Enter the 6-digit code from your email. | pending-kn-translation |
| `forgotPasswordDoneTitle` | Password changed | pending-kn-translation |
| `forgotPasswordDoneBody` | Your password has been reset and you’ve been signed out everywhere else. Sign in with your new password. | pending-kn-translation |
| `resetPasswordSubmitButton` | Reset password | pending-kn-translation |
| `forgotPasswordErrorOtpExpired` | That code has expired. Go back and request a new one. | pending-kn-translation |
| `forgotPasswordErrorOtpAlreadyUsed` | That code has already been used. Request a new one if you still need to reset. | pending-kn-translation |
| `forgotPasswordErrorAccountLocked` | Too many incorrect codes. Please wait 15 minutes and try again. | pending-kn-translation |
| `forgotPasswordErrorCredentialsInvalid` | That code is not correct. Check the latest email and try again. | pending-kn-translation |
### Guardians (parents) on a student record

| Key | English value | Kannada status |
|---|---|---|
| `guardianRelationshipMother` | Mother | pending-kn-translation |
| `guardianRelationshipFather` | Father | pending-kn-translation |
| `guardianRelationshipGuardian` | Guardian | pending-kn-translation |
| `guardianRelationshipGrandparent` | Grandparent | pending-kn-translation |
| `guardianRelationshipAuntUncle` | Aunt / Uncle | pending-kn-translation |
| `guardianRelationshipOther` | Other | pending-kn-translation |
| `guardianTilePrimaryChip` | Primary | pending-kn-translation |
| `guardianTileCanCollectChip` ⚠️ | Can collect | pending-kn-translation |
| `guardianTileCannotCollectChip` ⚠️ | Cannot collect | pending-kn-translation |
| `guardianTileNotifiedChip` | Notified | pending-kn-translation |
| `guardianTileCanReportAbsenceChip` | Can report absence | pending-kn-translation |
| `guardianTileCanSignInChip` | Can sign in | pending-kn-translation |
| `guardianTileNoSignInYetChip` | No sign-in yet | pending-kn-translation |
| `guardianTileRelationshipAndPhone` | {relationship} · {phone} | pending-kn-translation |
| `addGuardianFormTitle` | Add parent | pending-kn-translation |
| `addGuardianFormIntro` | The phone number becomes their sign-in straight away — they open the parent app, enter their number, and get a one-time code. Enter it carefully. | pending-kn-translation |
| `addGuardianRelationshipLabel` | Relationship | pending-kn-translation |
| `addGuardianFirstNameLabel` | First name | pending-kn-translation |
| `addGuardianLastNameLabel` | Last name | pending-kn-translation |
| `addGuardianPhoneLabel` | Phone (parent-app sign-in) | pending-kn-translation |
| `addGuardianPhoneHint` | e.g. 9990000001 | pending-kn-translation |
| `addGuardianEmailLabel` | Email (optional) | pending-kn-translation |
| `addGuardianCanViewTitle` | Can see this child | pending-kn-translation |
| `addGuardianCanViewSubtitle` | View the child and their journey in the app | pending-kn-translation |
| `addGuardianCanNotifyTitle` | Receives notifications | pending-kn-translation |
| `addGuardianCanNotifySubtitle` | Boarding, arrival, and alert messages | pending-kn-translation |
| `addGuardianCanHandoverTitle` ⚠️ | Can collect the child | pending-kn-translation |
| `addGuardianCanHandoverSubtitle` ⚠️ | Authorised to receive the child at the stop — needed before the child can be put on a bus | pending-kn-translation |
| `addGuardianCanAbsenceTitle` | Can report an absence | pending-kn-translation |
| `addGuardianCanAbsenceSubtitle` | Tell the school the child will not travel | pending-kn-translation |
| `addGuardianPrimaryTitle` | Primary contact | pending-kn-translation |
| `addGuardianPrimarySubtitle` | The first person the school reaches | pending-kn-translation |
| `addGuardianSubmitSpinnerLabel` | Adding | pending-kn-translation |
### Route assignment (pickup/drop)

| Key | English value | Kannada status |
|---|---|---|
| `assignRouteTitlePickup` | Set pickup | pending-kn-translation |
| `assignRouteTitleDrop` | Set drop | pending-kn-translation |
| `assignRoutePickupSubtitle` | Where this child is picked up in the morning. | pending-kn-translation |
| `assignRouteDropSubtitle` | Where this child is dropped in the afternoon. | pending-kn-translation |
| `assignRouteFieldLabel` | Route | pending-kn-translation |
| `assignRouteNoRoutesHint` | No routes on this school yet | pending-kn-translation |
| `assignRouteSelectRouteHint` | Select a route | pending-kn-translation |
| `assignRouteNameAndCode` | {name} · {code} | pending-kn-translation |
| `assignStopFieldLabel` | Stop | pending-kn-translation |
| `assignRouteStopsLoadError` | Could not load this route's stops. Try again. | pending-kn-translation |
| `assignRouteStopHintSelectRouteFirst` | Select a route first | pending-kn-translation |
| `assignRouteStopHintLoading` | Loading stops… | pending-kn-translation |
| `assignRouteStopHintNoStops` | This route has no stops yet | pending-kn-translation |
| `assignRouteStopHintSelectStop` | Select a stop | pending-kn-translation |
| `assignRouteSavingSpinnerLabel` | Saving | pending-kn-translation |
### Platform health (A-62)

| Key | English value | Kannada status |
|---|---|---|
| `platformHealthTitle` | Platform health | pending-kn-translation |
| `platformHealthRefreshButton` | Refresh | pending-kn-translation |
| `platformHealthIntro` | A quick pulse check — whether the platform is reachable, and how many organizations are on it. Not a full monitoring dashboard. | pending-kn-translation |
| `platformHealthCheckingLabel` | Checking platform health | pending-kn-translation |
| `platformHealthOrganizationsHeading` | Organizations on the platform | pending-kn-translation |
| `platformHealthCheckedAt` | Checked {relativeTime} | pending-kn-translation |
| `platformHealthJustNow` | just now | pending-kn-translation |
| `platformHealthSecondsAgo` | {seconds, plural, =1{1 second ago} other{{seconds} seconds ago}} | pending-kn-translation |
| `platformHealthMinutesAgo` | {minutes, plural, =1{1 minute ago} other{{minutes} minutes ago}} | pending-kn-translation |
| `platformHealthHoursAgo` | {hours, plural, =1{1 hour ago} other{{hours} hours ago}} | pending-kn-translation |
| `platformHealthReachableTitle` | Platform is reachable | pending-kn-translation |
| `platformHealthDegradedTitle` | Could not confirm platform health | pending-kn-translation |
| `platformHealthReachableBody` | The last check reached the database without issue. | pending-kn-translation |
| `platformHealthDegradedBody` | The last check could not read organization data. This can be transient — try refreshing in a moment. If it keeps failing, that's worth escalating. | pending-kn-translation |
| `platformHealthCountTotal` | Total | pending-kn-translation |
| `platformHealthCountActive` | Active | pending-kn-translation |
| `platformHealthCountSuspended` | Suspended | pending-kn-translation |
| `platformHealthCountClosed` | Closed | pending-kn-translation |
### Audit trail (A-54/A-55)

| Key | English value | Kannada status |
|---|---|---|
| `auditTrailTitle` | Audit trail | pending-kn-translation |
| `auditScopeAllActivity` | All activity | pending-kn-translation |
| `auditScopeOverrides` ⚠️ | Overrides | pending-kn-translation |
| `auditOverridesDescription` ⚠️ | Actions taken with an override reason — a person overrode a safety check and said why. | pending-kn-translation |
| `auditAllActivityDescription` | Every safety-relevant action, most recent first. Records cannot be edited or removed. | pending-kn-translation |
| `auditLoadingLabel` | Loading audit trail | pending-kn-translation |
| `auditLoadError` | The audit trail could not be loaded right now. Try again. | pending-kn-translation |
| `auditNoOverridesEmptyState` ⚠️ | No overrides recorded. That is the healthy state. | pending-kn-translation |
| `auditNoActivityEmptyState` | No activity recorded yet. | pending-kn-translation |
| `auditReasonPrefix` | Reason: {reason} | pending-kn-translation |
| `auditOverrideBadge` ⚠️ | Override | pending-kn-translation |
### Vehicles (A-20)

| Key | English value | Kannada status |
|---|---|---|
| `vehicleListTitle` | Vehicles | pending-kn-translation |
| `vehicleListLoadingLabel` | Loading fleet | pending-kn-translation |
| `vehicleListEmptyState` | No fleet loaded. Pick a school above, or add the first vehicle. | pending-kn-translation |
| `vehicleListRowSubtitle` | {registrationNo} · {vehicleType} · {seats} seats | pending-kn-translation |
| `vehicleListAddButton` | Add vehicle | pending-kn-translation |
| `createVehicleFormIntro` | The display name is what parents see in notifications — "Bus 12", not the plate number. Added to the school you have selected above. | pending-kn-translation |
| `vehicleTypeBus` | Bus | pending-kn-translation |
| `vehicleTypeVan` | Van | pending-kn-translation |
| `vehicleTypeMinibus` | Minibus | pending-kn-translation |
| `createVehicleRegistrationNoLabel` | Registration number | pending-kn-translation |
| `createVehicleRegistrationNoHint` | e.g. DL1PC1234 | pending-kn-translation |
| `createVehicleDisplayNameLabel` | Display name | pending-kn-translation |
| `createVehicleDisplayNameHint` | e.g. Bus 12 | pending-kn-translation |
| `createVehicleSeatingCapacityLabel` | Seating capacity | pending-kn-translation |
| `createVehicleVendorNameLabel` | Vendor name (optional, for outsourced fleets) | pending-kn-translation |
### Common / shared action labels

| Key | English value | Kannada status |
|---|---|---|
| `commonCancelButton` | Cancel | pending-kn-translation |
| `commonSaveButton` | Save | pending-kn-translation |
| `commonCloseButton` | Close | pending-kn-translation |
| `commonRetryButton` | Retry | pending-kn-translation |
| `commonAddButton` | Add | pending-kn-translation |
| `commonDoneButton` | Done | pending-kn-translation |
| `pickSchoolFirstTooltip` | Pick a school first | pending-kn-translation |
| `commonAddingSpinnerLabel` | Adding | pending-kn-translation |
| `commonSearchLabel` | Search | pending-kn-translation |
| `commonClearSearchTooltip` | Clear search | pending-kn-translation |
| `firstNameLabel` | First name | pending-kn-translation |
| `lastNameLabel` | Last name | pending-kn-translation |
| `commonSavingSpinnerLabel` | Saving | pending-kn-translation |
| `commonSaveChangesButton` | Save changes | pending-kn-translation |
| `commonChangesSavedSnackbar` | Changes saved | pending-kn-translation |
| `copyTooltip` | Copy | pending-kn-translation |
| `copiedSnackbar` | {label} copied | pending-kn-translation |
| `copiedToClipboardSnackbar` | Copied to clipboard | pending-kn-translation |
| `noneOptionLabel` | None | pending-kn-translation |
### Drivers / staff (A-23)

| Key | English value | Kannada status |
|---|---|---|
| `staffListTitle` | Drivers | pending-kn-translation |
| `staffListSearchHint` | Filter by name, phone, or employee code | pending-kn-translation |
| `staffListLoadingLabel` | Loading roster | pending-kn-translation |
| `staffListEmptyState` | No roster loaded. Pick a school above, or add the first driver. | pending-kn-translation |
| `staffListSearchNoMatches` | No one on this roster matches "{query}". | pending-kn-translation |
| `staffListRowSubtitle` | {staffType} · {phone} | pending-kn-translation |
| `staffListHasLoginTooltip` | Can sign in to the driver app | pending-kn-translation |
| `staffListNoLoginTooltip` | No driver-app sign-in yet | pending-kn-translation |
| `staffListAddButton` | Add driver | pending-kn-translation |
| `createStaffFormTitle` | Add driver or attendant | pending-kn-translation |
| `createStaffFormIntro` | Creates the roster record and a working driver-app sign-in in one step — the phone number below is what they sign in with (phone + one-time code). Added to the school you have selected above. | pending-kn-translation |
| `staffTypeDriver` | Driver | pending-kn-translation |
| `staffTypeAttendant` | Attendant | pending-kn-translation |
| `staffPhoneLabel` | Phone (driver-app sign-in) | pending-kn-translation |
| `staffPhoneHint` | e.g. 9990000001 | pending-kn-translation |
| `staffEmployeeCodeLabel` | Employee code (optional) | pending-kn-translation |
| `staffVendorNameLabel` | Vendor name (optional, for contracted staff) | pending-kn-translation |
| `editStaffTitle` | Edit {name} | pending-kn-translation |
### Students (A-10, A-11)

| Key | English value | Kannada status |
|---|---|---|
| `studentErrorAdmissionNoExists` | That admission number is already used at this school. Check whether the student is already enrolled before creating a second record for them. | pending-kn-translation |
| `studentErrorNotFound` | That student could not be found. They may have been moved to another school. | pending-kn-translation |
| `studentErrorNotActive` | That student is not on the active roll, so they cannot be assigned to transport. | pending-kn-translation |
| `studentErrorPermissionDenied` | Your account does not have permission to manage students. | pending-kn-translation |
| `studentErrorScopeDenied` | That student is outside the schools your account covers. | pending-kn-translation |
| `studentListTitle` | Students | pending-kn-translation |
| `studentListSearchHint` | Filter loaded students by name or admission number | pending-kn-translation |
| `studentWithdrawConfirmTitle` ⚠️ | Withdraw student? | pending-kn-translation |
| `studentWithdrawConfirmBody` ⚠️ | {name} ({admissionNo}) will be taken off the roll and removed from transport.<br><br>Their record is kept — safety records reference it — and can still be read. | pending-kn-translation |
| `studentWithdrawConfirmButton` ⚠️ | Withdraw | pending-kn-translation |
| `studentListLoadingLabel` | Loading register | pending-kn-translation |
| `studentListEmptyState` | No register loaded. Pick a school above, or enrol the first student. | pending-kn-translation |
| `studentListNoMatchWithMore` | No loaded student matches that. Scroll to load more of the register, then search again. | pending-kn-translation |
| `studentListNoMatch` | No student matches that. | pending-kn-translation |
| `studentListLoadingMoreLabel` | Loading more students | pending-kn-translation |
| `studentListCount` | {count, plural, =1{1 student} other{{count} students}} | pending-kn-translation |
| `studentListEnrolButton` | Enrol student | pending-kn-translation |
| `studentListEditTooltip` | Edit {name} | pending-kn-translation |
| `studentListWithdrawTooltip` | Withdraw {name} | pending-kn-translation |
| `studentStatusWithdrawn` | Withdrawn | pending-kn-translation |
| `studentStatusOnRollNoTransport` | On roll · not using transport | pending-kn-translation |
| `studentStatusOnRollTransport` | On roll · transport | pending-kn-translation |
| `studentListRowSubtitle` | {admissionNo} · {status} | pending-kn-translation |
| `studentFormEditTitle` | Edit student | pending-kn-translation |
| `studentFormAdmissionNoLabel` | Admission number | pending-kn-translation |
| `studentFormAdmissionNoHelperEditing` | Cannot be changed — safety records reference it | pending-kn-translation |
| `studentFormAdmissionNoHelperNew` | The number the school already uses for this student | pending-kn-translation |
| `studentFormAdmissionNoRequired` | Enter an admission number | pending-kn-translation |
| `studentFormFirstNameRequired` | Enter a first name | pending-kn-translation |
| `studentFormLastNameRequired` | Enter a last name | pending-kn-translation |
| `studentFormDateOfBirthLabel` | Date of birth | pending-kn-translation |
| `studentFormDateOfBirthHelper` ⚠️ | YYYY-MM-DD — used to decide self-release eligibility | pending-kn-translation |
| `studentFormDateOfBirthFormatError` | Use the format YYYY-MM-DD | pending-kn-translation |
| `studentFormDateOfBirthPastError` | Date of birth must be in the past | pending-kn-translation |
| `studentFormTransportEligibleTitle` | Eligible for transport | pending-kn-translation |
| `studentFormTransportEligibleSubtitle` | A student on the roll whose family has opted out stays enrolled but off the bus | pending-kn-translation |
| `studentDetailAdmissionLine` | Admission {admissionNo} | pending-kn-translation |
| `studentDetailDobLine` | Date of birth {date} | pending-kn-translation |
| `studentDetailStatusOnRollTransport` | On roll · using transport | pending-kn-translation |
| `studentDetailParentsTitle` | Parents | pending-kn-translation |
| `studentDetailLoadingParentsLabel` | Loading parents | pending-kn-translation |
| `studentDetailNoParentsEmptyState` | No parents yet. Add one so they can see this child and be reached — and so the child can be assigned to a bus. | pending-kn-translation |
| `studentDetailNoHandoverGuardianWarning` ⚠️ | No parent here can collect the child yet — turn on "Can collect the child" for at least one before assigning a bus. | pending-kn-translation |
| `studentDetailPickupDropTitle` | Pickup & drop | pending-kn-translation |
| `studentDetailLoadingAssignmentsLabel` | Loading assignments | pending-kn-translation |
| `studentDetailDirectionPickup` | Pickup | pending-kn-translation |
| `studentDetailDirectionDrop` | Drop | pending-kn-translation |
| `studentDetailAssignmentSummary` | {routeName} · {routeCode} → {stopName} | pending-kn-translation |
| `studentDetailAssignmentNotSet` | Not set | pending-kn-translation |
| `studentDetailRemoveAssignment` | Remove {label} | pending-kn-translation |
| `studentDetailChangeButton` | Change | pending-kn-translation |
| `studentDetailSetButton` | Set | pending-kn-translation |
| `studentAssignErrorNoActiveGuardian` ⚠️ | Add a parent who can collect this child (turn on "Can collect the child") before assigning a bus. | pending-kn-translation |
| `studentAssignErrorAlreadyAssigned` | This child already has that assignment — remove the current one first. | pending-kn-translation |
| `studentAssignErrorApiUnreachable` | The service is unreachable right now. Try again. | pending-kn-translation |
| `studentAssignErrorGeneric` | That could not be saved right now. Try again. | pending-kn-translation |

### Bulk student import (A-12, STU-002)

None of these are safety-critical: bulk import does not touch handover authorisation, the
audit/override register, or removing a student from transport. The `dateOfBirth` mention in
`studentImportColumnsBody` is a field description, not a control.

| Key | English value | Kannada status |
|---|---|---|
| `studentListImportButton` | Import | pending-kn-translation |
| `studentImportTitle` | Import students | pending-kn-translation |
| `studentImportIntro` | Upload a spreadsheet of students, saved as CSV. Rows that are ready are enrolled straight away; anything that needs fixing is listed for you to correct and upload again. | pending-kn-translation |
| `studentImportColumnsTitle` | Columns | pending-kn-translation |
| `studentImportColumnsBody` | Required: admissionNo, firstName, lastName. Optional: dateOfBirth (YYYY-MM-DD) and transportEligible (true or false — defaults to true). Column names are matched loosely, ignoring case and spaces. A column that isn't one of these stops the whole file — guardian and stop columns are not supported yet. | pending-kn-translation |
| `studentImportChooseFileButton` | Choose CSV file | pending-kn-translation |
| `studentImportUploadingLabel` | Uploading and checking the file | pending-kn-translation |
| `studentImportUploadingNamed` | Uploading {name}… | pending-kn-translation |
| `studentImportSummary` | {totalRows} rows · {successCount} imported · {errorCount} errors | pending-kn-translation |
| `studentImportSummaryHintErrors` | The rows below were not enrolled. Fix them in your spreadsheet and upload again — only the corrected rows need to be in the next file. | pending-kn-translation |
| `studentImportSummaryHintAllImported` | Every row was enrolled. They now appear on the register. | pending-kn-translation |
| `studentImportSummaryHintNothing` | Nothing was enrolled. Correct the rows below and upload again. | pending-kn-translation |
| `studentImportDownloadErrorsButton` | Download error rows | pending-kn-translation |
| `studentImportAnotherButton` | Import another file | pending-kn-translation |
| `studentImportColRow` | Row | pending-kn-translation |
| `studentImportColField` | Column | pending-kn-translation |
| `studentImportColProblem` | What to fix | pending-kn-translation |
| `studentImportErrorEmpty` | That file has no student rows. Check you saved the sheet with the students in it as CSV. | pending-kn-translation |
| `studentImportErrorUnreadable` | That file could not be read as a spreadsheet. Open it in your spreadsheet program and use “Save as… CSV”, then upload the CSV. | pending-kn-translation |
| `studentImportErrorUnsupportedColumn` | One of the columns in that file is not supported yet. Keep only admissionNo, firstName, lastName, dateOfBirth and transportEligible, then upload again. | pending-kn-translation |
| `studentImportErrorTooManyRows` | That file has too many rows for one upload. Split it into smaller files and import them one at a time. | pending-kn-translation |
| `studentImportErrorNoFile` | No file was chosen. Pick a CSV file to upload. | pending-kn-translation |

### Custody restrictions (A-14, GRD-006)

⚠️ marks the keys that describe the handover/visibility override itself — a machine or
unreviewed Kannada rendering of any of these is a real safety risk (see the safety-critical
table at the top).

| Key | English value | Kannada status |
|---|---|---|
| `custodyPanelTitle` | Custody restrictions | pending-kn-translation |
| `custodyAddButton` | Add restriction | pending-kn-translation |
| `custodyPanelWarning` ⚠️ | A restriction takes effect immediately and overrides every parent right — the person named cannot collect or see this child while it is in force. Every restriction is recorded with its reason. | pending-kn-translation |
| `custodyLoadingLabel` | Loading restrictions | pending-kn-translation |
| `custodyEmptyState` | No restrictions. That is the normal state. | pending-kn-translation |
| `custodyLiftButton` | Lift | pending-kn-translation |
| `custodyStatusLifted` | Lifted | pending-kn-translation |
| `custodyLiftConfirmTitle` | Lift this restriction? | pending-kn-translation |
| `custodyLiftConfirmBody` ⚠️ | The person named will be able to collect and see this child again, straight away. The restriction and its history are kept. | pending-kn-translation |
| `custodyLiftConfirmButton` | Lift restriction | pending-kn-translation |
| `custodyEffectiveLine` | In force from {from} until {until} | pending-kn-translation |
| `custodyOpenEnded` | no end date | pending-kn-translation |
| `custodySubjectGuardian` | Parent {id} | pending-kn-translation |
| `custodyTypeNoHandover` ⚠️ | Cannot collect the child | pending-kn-translation |
| `custodyTypeNoVisibility` ⚠️ | Cannot see the child's journey | pending-kn-translation |
| `custodyTypeFull` ⚠️ | Cannot collect or see the child | pending-kn-translation |
| `custodyAddTitle` | Add a custody restriction | pending-kn-translation |
| `custodySubjectAGuardian` | A parent on file | pending-kn-translation |
| `custodySubjectAPerson` | Someone else, by name | pending-kn-translation |
| `custodyGuardianLabel` | Parent | pending-kn-translation |
| `custodyPersonNameLabel` | Full name | pending-kn-translation |
| `custodyPersonNameRequired` | Enter the person's full name | pending-kn-translation |
| `custodyTypeLabel` | Restriction | pending-kn-translation |
| `custodyReasonLabel` | Reason (required) | pending-kn-translation |
| `custodyReasonHelper` ⚠️ | What authorises this — a court order and its reference, a school safeguarding decision. Kept on the audit record. | pending-kn-translation |
| `custodyErrorReasonRequired` | A reason is required for every custody restriction. | pending-kn-translation |
| `custodyUntilLabel` | End date (optional) | pending-kn-translation |
| `custodyUntilFormatError` | Use the format YYYY-MM-DD, or leave blank for no end date. | pending-kn-translation |
| `custodyAddSubmitButton` | Add restriction | pending-kn-translation |
| `custodyErrorSubjectRequired` | Name exactly one person — a parent on file, or someone by name. | pending-kn-translation |
| `custodyErrorNotFound` | That restriction could not be found. It may already have been lifted. | pending-kn-translation |

### Users / administrators (A-43)

| Key | English value | Kannada status |
|---|---|---|
| `userListTitle` | Users | pending-kn-translation |
| `userListAddButton` | Add administrator | pending-kn-translation |
| `userListSearchHint` | Filter by name, email, or role | pending-kn-translation |
| `userListLoadingLabel` | Loading users | pending-kn-translation |
| `userListPickOrgPrompt` | Pick an organization above to see its administrators. | pending-kn-translation |
| `userListEmptyState` | No administrators yet. Add the first one above. | pending-kn-translation |
| `userListNoSearchMatches` | No one matches "{query}". | pending-kn-translation |
| `userToggleReactivateTitle` | Reactivate {name}? | pending-kn-translation |
| `userToggleDeactivateTitle` | Deactivate {name}? | pending-kn-translation |
| `userToggleReactivateBody` | They will be able to sign in again. | pending-kn-translation |
| `userToggleDeactivateBody` | They will no longer be able to sign in. This can be reversed at any time. | pending-kn-translation |
| `userToggleReactivateButton` | Reactivate | pending-kn-translation |
| `userToggleDeactivateButton` | Deactivate | pending-kn-translation |
| `userStatusActive` | Active | pending-kn-translation |
| `userStatusPending` | Pending | pending-kn-translation |
| `userStatusInactive` | Inactive | pending-kn-translation |
| `userListRowSubtitle` | {email} · {role} | pending-kn-translation |
| `userMoreActionsTooltip` | More actions | pending-kn-translation |
| `userResendInvitationLabel` | Resend invitation | pending-kn-translation |
| `userSendResetCodeLabel` | Send reset code | pending-kn-translation |
| `createUserInviteDescription` | We email them a link to set their own password and activate the account. | pending-kn-translation |
| `createUserPasswordDescription` | You set a password now and share it with them yourself. | pending-kn-translation |
| `createUserSendInviteOption` | Send invite | pending-kn-translation |
| `createUserSetPasswordOption` | Set password | pending-kn-translation |
| `createUserSchoolHint` | Which school this role applies to | pending-kn-translation |
| `createUserEmailLabel` | Email (sign-in) | pending-kn-translation |
| `createUserEmailHint` | What this person signs in with | pending-kn-translation |
| `createUserPhoneLabel` | Phone (optional) | pending-kn-translation |
| `createUserPasswordLabel` | Initial password | pending-kn-translation |
| `createUserPasswordHint` | At least 12 characters | pending-kn-translation |
| `createUserGeneratePasswordTooltip` | Generate a password | pending-kn-translation |
| `invitationSentTitle` | Invitation sent | pending-kn-translation |
| `invitationSentBody` | We’ve emailed {email} a link to set their password. It is valid for 72 hours; you can re-send it from their row if it expires. | pending-kn-translation |
| `accountCreatedTitle` | Account created | pending-kn-translation |
| `accountCreatedBody` | Share these sign-in details with them now — this password will not be shown again. | pending-kn-translation |
| `credentialsEmailLabel` | Email | pending-kn-translation |
| `credentialsPasswordLabel` | Password | pending-kn-translation |
| `editUserLocaleLabel` | Preferred locale | pending-kn-translation |
| `editUserLocaleHint` | e.g. en | pending-kn-translation |
### Organizations (A-40/A-41)

| Key | English value | Kannada status |
|---|---|---|
| `onboardingErrorOrgCodeExists` | That organization code is already in use. Choose another — codes cannot be changed once operational data exists (BR-TEN-007). | pending-kn-translation |
| `onboardingErrorCannotSuspendOwnOrganization` | You cannot suspend the organization your own account belongs to — it would lock out every account able to reactivate it. | pending-kn-translation |
| `onboardingErrorSchoolCodeExists` | That school code is already used within this organization. Choose another. | pending-kn-translation |
| `onboardingErrorStaffEmployeeCodeExists` | That employee code is already used at this school. Choose another. | pending-kn-translation |
| `onboardingErrorPermissionDenied` | Your account does not have permission to create organizations. | pending-kn-translation |
| `orgListAddButton` | Add organization | pending-kn-translation |
| `orgListLoadingLabel` | Loading organizations | pending-kn-translation |
| `orgListEmptyState` | No organizations yet. Add the first one to get started. | pending-kn-translation |
| `orgListRowSubtitle` | {code} · {regionProfile} | pending-kn-translation |
| `orgSuspendedChip` | Suspended | pending-kn-translation |
| `orgListLoadError` | That could not be loaded right now. Try again shortly. | pending-kn-translation |
| `createOrgCodeLabel` | Organization code | pending-kn-translation |
| `createOrgCodeHint` | e.g. GREENWOOD | pending-kn-translation |
| `createOrgNameLabel` | Organization name | pending-kn-translation |
| `createOrgNameHint` | e.g. Greenwood Education Group | pending-kn-translation |
| `createOrgRegionLabel` | Region profile code | pending-kn-translation |
| `createOrgContactEmailLabel` | Contact email (optional) | pending-kn-translation |
| `createOrgContactPhoneLabel` | Contact phone (optional) | pending-kn-translation |
| `createOrgCreatingSpinnerLabel` | Creating organization | pending-kn-translation |
| `onboardingCompleteTitle` | Organization onboarded | pending-kn-translation |
| `onboardingSummaryOrgLabel` | Organization | pending-kn-translation |
| `onboardingNameAndCode` | {name} ({code}) | pending-kn-translation |
| `onboardingSummaryFirstSchoolLabel` | First school | pending-kn-translation |
| `onboardingNoSchoolYet` | No school was added yet. Add one from the Schools screen before this organization is used day to day (BR-TEN-002). | pending-kn-translation |
| `onboardingStartAnotherButton` | Onboard another organization | pending-kn-translation |
| `orgDetailsSectionTitle` | Organization details | pending-kn-translation |
| `orgStatusClosed` | Closed | pending-kn-translation |
| `orgStatusActive` | Active | pending-kn-translation |
| `orgConfirmSuspendTitle` | Suspend {name}? | pending-kn-translation |
| `orgConfirmSuspendBody` | This blocks sign-in and administrative access for everyone in {name}. No data is deleted, and any trip already in progress keeps recording safety events as normal (BR-TEN-006). You can reactivate at any time. | pending-kn-translation |
| `orgSuspendButton` | Suspend organization | pending-kn-translation |
| `orgConfirmReactivateTitle` | Reactivate {name}? | pending-kn-translation |
| `orgConfirmReactivateBody` | This restores sign-in and administrative access for everyone in {name}. | pending-kn-translation |
| `orgReactivateButton` | Reactivate organization | pending-kn-translation |
| `orgDetailsCodeFixedLabel` | Organization code (fixed, BR-TEN-007) | pending-kn-translation |
| `orgDetailsSavingSpinnerLabel` | Saving organization | pending-kn-translation |
| `orgDetailsSaveButton` | Save organization changes | pending-kn-translation |
| `onboardingAddOrganizationTitle` | Add organization | pending-kn-translation |
| `onboardingAddOrganizationSubtitle` | Create the organization, then add its first school. | pending-kn-translation |
| `onboardingStepOrganizationLabel` | Organization | pending-kn-translation |
| `onboardingStepFirstSchoolLabel` | First school | pending-kn-translation |
| `onboardingStepSemanticLabel` | Step {number} of {total}: {label}, {status} | pending-kn-translation |
| `onboardingStepStatusDone` | completed | pending-kn-translation |
| `onboardingStepStatusCurrent` | current step | pending-kn-translation |
| `onboardingStepStatusUpcoming` | not started | pending-kn-translation |
| `createOrgSectionIdentityTitle` | Identity | pending-kn-translation |
| `createOrgSectionIdentityDescription` | How this organization is named and identified across the platform. | pending-kn-translation |
| `createOrgCodeHelper` | Short and unique. Fixed once the organization has schools or staff. | pending-kn-translation |
| `createOrgSectionRegionTitle` | Region | pending-kn-translation |
| `createOrgSectionRegionDescription` | Supplies phone, document, and data-retention defaults. | pending-kn-translation |
| `createOrgRegionHelper` | e.g. IN | pending-kn-translation |
| `createOrgSectionContactTitle` | Contact | pending-kn-translation |
| `createOrgSectionContactDescription` | Who the platform team reaches about this organization. | pending-kn-translation |
| `createOrgContinueButton` | Create and continue | pending-kn-translation |
| `createSchoolCreatedBannerTitle` | {orgName} ({orgCode}) created | pending-kn-translation |
| `createSchoolCreatedBannerBody` | An organization needs at least one school before it can be used day to day. Add it now, or skip and add it later. | pending-kn-translation |
| `createSchoolSectionSchoolTitle` | Identity | pending-kn-translation |
| `createSchoolSectionSchoolDescription` | The campus buses travel to and from. | pending-kn-translation |
| `createSchoolCodeHelper` | Unique within this organization. Fixed once the school is in use. | pending-kn-translation |
| `createSchoolSectionLocationTitle` | Location | pending-kn-translation |
| `createSchoolSectionLocationDescription` | Arrival alerts are measured from this point. | pending-kn-translation |
| `createSchoolPlusCodeHint` | e.g. 7J4VXMQ5+8F | pending-kn-translation |
| `createSchoolPlusCodeGuide` | Paste the school's full Plus Code from Google Maps. The latitude and longitude are worked out from it and shown here before you save. | pending-kn-translation |
| `createSchoolLocationFoundTitle` | Location found | pending-kn-translation |
| `createSchoolGeofenceLabel` | Geofence radius | pending-kn-translation |
| `createSchoolGeofenceHelper` | Between 20 and 2000 metres around the school. | pending-kn-translation |
| `unitMetresSuffix` | m | pending-kn-translation |
| `createSchoolSectionTimeTitle` | Local time | pending-kn-translation |
| `createSchoolSectionTimeDescription` | Every time shown for this school uses its time zone. | pending-kn-translation |
| `createSchoolTimezoneLabel` | Time zone | pending-kn-translation |
| `createSchoolTimezoneHelper` | IANA name, e.g. Asia/Kolkata | pending-kn-translation |
| `createSchoolSkipForNowButton` | Skip for now | pending-kn-translation |

### Routes, stops, and crew (A-30/A-31, STF-004)

| Key | English value | Kannada status |
|---|---|---|
| `routeListLoadingLabel` | Loading routes | pending-kn-translation |
| `routeListEmptyState` | No routes loaded. Pick a school above, or add the first route. | pending-kn-translation |
| `routeStopsTooltip` | Stops on {name} | pending-kn-translation |
| `routeHasVehicleTooltip` | Has a default bus | pending-kn-translation |
| `routeNoVehicleTooltip` | No bus assigned yet | pending-kn-translation |
| `routeListAddButton` | Add route | pending-kn-translation |
| `createRouteIntro` | Creates the route itself. Stops are added separately once the map editor exists — this is enough for assigning a driver or attendant to it today. Added to the school you have selected above. | pending-kn-translation |
| `createRouteCodeLabel` | Route code | pending-kn-translation |
| `createRouteCodeHint` | e.g. R3 | pending-kn-translation |
| `createRouteNameLabel` | Route name | pending-kn-translation |
| `createRouteNameHint` | e.g. Green Park — Morning | pending-kn-translation |
| `createRouteDefaultVehicleLabel` | Default bus (optional) | pending-kn-translation |
| `createRouteNoVehiclesHint` | No vehicles on this school yet | pending-kn-translation |
| `createRouteVehicleOption` | {displayName} · {registrationNo} | pending-kn-translation |
| `routeCrewAssignButton` | Assign crew | pending-kn-translation |
| `routeCrewLoadingLabel` | Loading crew | pending-kn-translation |
| `routeCrewEmptyState` | No crew assigned yet. | pending-kn-translation |
| `routeCrewBothDirectionsLabel` | Both directions | pending-kn-translation |
| `dutyFormStaffLabel` | Driver or attendant | pending-kn-translation |
| `dutyFormNoRosterHint` | No roster loaded for this school | pending-kn-translation |
| `dutyFormSelectPersonHint` | Select a person | pending-kn-translation |
| `dutyFormStaffOption` | {name} · {staffType} | pending-kn-translation |
| `directionBoth` | Both | pending-kn-translation |
| `dutyFormAssigningSpinnerLabel` | Assigning | pending-kn-translation |
| `dutyFormAssignButton` | Assign | pending-kn-translation |
| `routeStopsDialogTitle` | Stops | pending-kn-translation |
| `routeStopsLoadingLabel` | Loading stops | pending-kn-translation |
| `routeStopsMinWarning` | A route needs at least two stops before students can be assigned to it. | pending-kn-translation |
| `routeStopsEmptyState` | No stops yet. Add the first one. | pending-kn-translation |
| `routeStopsAddButton` | Add stop | pending-kn-translation |
| `routeStopsRemoveTooltip` | Remove {name} | pending-kn-translation |
| `stopPickupTime` | pickup {time} | pending-kn-translation |
| `stopDropTime` | drop {time} | pending-kn-translation |
| `stopGeofenceRadiusMetres` | {radius} m | pending-kn-translation |
| `stopFormNameLabel` | Stop name | pending-kn-translation |
| `stopFormNameHint` | e.g. Green Park — parents see this | pending-kn-translation |
| `stopFormLatitudeHint` | e.g. 28.5494 | pending-kn-translation |
| `stopFormLongitudeHint` | e.g. 77.2001 | pending-kn-translation |
| `stopFormGeofenceLabel` | Geofence radius (metres) | pending-kn-translation |
| `stopFormGeofenceHint` | 20–500 | pending-kn-translation |
| `stopFormPickupTimeLabel` | Pickup time (optional) | pending-kn-translation |
| `stopFormDropTimeLabel` | Drop time (optional) | pending-kn-translation |
| `stopFormTimeHint` | HH:mm | pending-kn-translation |
| `stopFormLandmarkLabel` | Landmark (optional) | pending-kn-translation |
| `stopFormLandmarkHint` | Helps parents find the stop | pending-kn-translation |
| `stopFormErrorNameRequired` | Give the stop a name. | pending-kn-translation |
| `stopFormErrorLatitudeRange` | Latitude must be a number between -90 and 90. | pending-kn-translation |
| `stopFormErrorLongitudeRange` | Longitude must be a number between -180 and 180. | pending-kn-translation |
| `stopFormErrorGeofenceRange` | Geofence radius must be between 20 and 500 metres. | pending-kn-translation |
| `stopFormErrorTimeFormat` | Times must be in 24-hour HH:mm form, e.g. 07:40. | pending-kn-translation |

### Global search (SRC-001)

| Key | English value | Kannada status |
|---|---|---|
| `globalSearchHint` | Search students, parents, staff, vehicles… | pending-kn-translation |
| `globalSearchShortcutMac` | ⌘K | pending-kn-translation |
| `globalSearchShortcutOther` | Ctrl K | pending-kn-translation |
| `globalSearchClearTooltip` | Clear search | pending-kn-translation |
| `globalSearchMinLength` | Type at least 3 characters to search | pending-kn-translation |
| `globalSearchLoading` | Searching | pending-kn-translation |
| `globalSearchNoResults` | No matches for “{query}” | pending-kn-translation |
| `globalSearchError` | Search is unavailable right now. Try again shortly. | pending-kn-translation |
| `globalSearchNoScreen` | There is no screen for this record in your console. | pending-kn-translation |
| `globalSearchOpenFailed` | That record could not be opened right now. | pending-kn-translation |
| `globalSearchMoreResults` | More matches — keep typing to narrow them down | pending-kn-translation |
| `globalSearchSubtitleSeparator` | · | pending-kn-translation |
| `globalSearchGroupStudents` | Students | pending-kn-translation |
| `globalSearchGroupGuardians` | Parents | pending-kn-translation |
| `globalSearchGroupStaff` | Drivers & attendants | pending-kn-translation |
| `globalSearchGroupVehicles` | Vehicles | pending-kn-translation |
| `globalSearchGroupRoutes` | Routes | pending-kn-translation |
| `globalSearchGroupUsers` | Administrators | pending-kn-translation |
| `globalSearchGroupSchools` | Schools | pending-kn-translation |
| `globalSearchGroupOrganizations` | Organizations | pending-kn-translation |
| `globalSearchKindStudent` | Student | pending-kn-translation |
| `globalSearchKindGuardian` | Parent | pending-kn-translation |
| `globalSearchKindDriver` | Driver | pending-kn-translation |
| `globalSearchKindAttendant` | Attendant | pending-kn-translation |
| `globalSearchKindVehicle` | Vehicle | pending-kn-translation |
| `globalSearchKindRoute` | Route | pending-kn-translation |
| `globalSearchKindUser` | Administrator | pending-kn-translation |
| `globalSearchKindSchool` | School | pending-kn-translation |
| `globalSearchKindOrganization` | Organization | pending-kn-translation |
| `globalSearchLinkedChild` | Child: {studentName} | pending-kn-translation |
| `globalSearchAdmissionNumber` | Adm {admissionNo} | pending-kn-translation |

### Other

| Key | English value | Kannada status |
|---|---|---|
| `errorGenericLoadRetry` | That could not be loaded right now. Try again. | pending-kn-translation |

## Two keys that are deliberately not "pending"

`languageNameEnglish` ("English") and `languageNameKannada` ("ಕನ್ನಡ") are the language picker's own endonyms — the name a language uses for itself, shown in the switcher regardless of which locale is active (see `LanguageSwitcher`'s doc comment). Their `app_en.arb` and `app_kn.arb` values are identical by design, not because a translation is missing — there is nothing to translate.

