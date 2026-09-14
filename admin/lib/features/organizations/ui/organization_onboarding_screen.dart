import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../../app/acting_organization.dart';
import '../../../app/dependencies.dart';
import '../bloc/organization_onboarding_bloc.dart';
import '../bloc/organization_onboarding_event.dart';
import '../bloc/organization_onboarding_state.dart';
import '../widgets/create_organization_form.dart';
import '../widgets/create_school_form.dart';
import '../widgets/onboarding_error_text.dart';
import '../widgets/organization_details_view.dart';
import '../widgets/onboarding_scaffold.dart';

/// A-40 — Organizations: create a new tenant, then optionally its first school (TEN-001,
/// TEN-002). `PERM-ORG-CREATE` and `PERM-SCHOOL-CREATE` are held only by `SUPER_ADMIN`
/// (PERMISSION_MATRIX.md), which is what actually restricts who reaches this screen — see
/// `ConsoleDestinations`.
///
/// Renders [OrganizationOnboardingState] and dispatches what the operator did — plus the one
/// piece of navigation that belongs here rather than in the bloc: leaving this screen once an
/// edit to the organization's own details has saved. See [_savingOrganization].
class OrganizationOnboardingScreen extends StatefulWidget {
  const OrganizationOnboardingScreen({
    super.key,
    required this.actorRoles,
    required this.actorOrganizationId,
  });

  /// The signed-in operator's own roles — passed straight through to
  /// `OrganizationDetailsView` to gate the suspend/reactivate control. See that widget's
  /// `_canManageLifecycle`.
  final List<String> actorRoles;

  /// The organization the operator's own account belongs to — passed straight through to
  /// `OrganizationDetailsView`, which withholds Suspend on it.
  final String? actorOrganizationId;

  @override
  State<OrganizationOnboardingScreen> createState() =>
      _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState
    extends State<OrganizationOnboardingScreen> {
  /// Set just before dispatching [OrganizationDetailsEdited], cleared once its result
  /// arrives. [OnboardingStep.complete] also handles school-save, add-school, and
  /// skip-school — none of which should navigate the operator away, so a plain "isSubmitting
  /// went back to false" is not enough to know *which* action just finished.
  bool _savingOrganization = false;

  /// Captured in [didChangeDependencies] so [dispose] can clear the elevation without
  /// touching `context`, which is no longer safe to read by then.
  ActingOrganization? _actingOrganization;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actingOrganization = DependencyScope.of(context).actingOrganization;
  }

  @override
  void dispose() {
    // Leaving this screen leaves the organization. An elevation that outlived the screen that
    // established it would silently apply to the next thing the operator opened (ADR-0016).
    _actingOrganization?.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationOnboardingBloc, OrganizationOnboardingState>(
      // A platform operator working on an organization must act *inside* it: the school they
      // add belongs to that organization, and creating it from their own tenant is what
      // produced schools stamped to the wrong tenant and then hidden by row-level security.
      listenWhen: (previous, current) =>
          previous.organization?.id != current.organization?.id,
      listener: (context, state) =>
          _actingOrganization?.enter(state.organization?.id),
      child: BlocListener<OrganizationOnboardingBloc, OrganizationOnboardingState>(
      listenWhen: (previous, current) =>
          _savingOrganization && previous.isSubmitting && !current.isSubmitting,
      listener: (context, state) {
        _savingOrganization = false;
        // A validation failure (e.g. an empty name) leaves the operator on the form to fix
        // it — only a genuinely successful save takes them back to the list.
        if (state.error == null && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
        child: BlocBuilder<OrganizationOnboardingBloc, OrganizationOnboardingState>(
        builder: (context, state) {
          final l10n = context.l10n;
          // The page names what the operator is doing: adding an organization while either
          // create step is open, and the organization itself once it exists.
          final viewing = state.step == OnboardingStep.complete ? state.organization : null;
          // This screen is pushed over the console shell by `OrganizationListRoute`, so
          // popping is what returns the operator to the Organizations list.
          final leave = Navigator.of(context).canPop()
              ? () => Navigator.of(context).maybePop()
              : null;

          return OnboardingScaffold(
            backLabel: l10n.consoleDestinationOrganizations,
            title: viewing != null ? viewing.name : l10n.onboardingAddOrganizationTitle,
            subtitle: viewing != null
                ? l10n.orgListRowSubtitle(viewing.code, viewing.regionProfileCode)
                : l10n.onboardingAddOrganizationSubtitle,
            stepLabels: viewing != null
                ? null
                : [l10n.onboardingStepOrganizationLabel, l10n.onboardingStepFirstSchoolLabel],
            currentStep: state.step == OnboardingStep.schoolDetails ? 1 : 0,
            onBack: leave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              switch (state.step) {
                OnboardingStep.organizationDetails => CreateOrganizationForm(
                    isSubmitting: state.isSubmitting,
                    onCancel: leave,
                    error: state.error == null
                        ? null
                        : OnboardingErrorText(
                            code: state.error!,
                            messageKey: state.errorMessageKey,
                          ),
                    onSubmit: ({
                      required String code,
                      required String name,
                      required String regionProfileCode,
                      String? contactEmail,
                      String? contactPhone,
                    }) =>
                        context.read<OrganizationOnboardingBloc>().add(
                              OrganizationDetailsSubmitted(
                                code: code,
                                name: name,
                                regionProfileCode: regionProfileCode,
                                contactEmail: contactEmail,
                                contactPhone: contactPhone,
                              ),
                            ),
                  ),
                OnboardingStep.schoolDetails => CreateSchoolForm(
                    // Set by the bloc the moment step 1 succeeds and never cleared before
                    // step 2 — see OrganizationOnboardingState.organization.
                    organization: state.organization!,
                    isSubmitting: state.isSubmitting,
                    error: state.error == null
                        ? null
                        : OnboardingErrorText(
                            code: state.error!,
                            messageKey: state.errorMessageKey,
                          ),
                    onSubmit: ({
                      required String code,
                      required String name,
                      required String timezone,
                      required double latitude,
                      required double longitude,
                      required int geofenceRadiusM,
                    }) =>
                        context.read<OrganizationOnboardingBloc>().add(
                              SchoolDetailsSubmitted(
                                code: code,
                                name: name,
                                timezone: timezone,
                                latitude: latitude,
                                longitude: longitude,
                                geofenceRadiusM: geofenceRadiusM,
                              ),
                            ),
                    onSkip: () => context
                        .read<OrganizationOnboardingBloc>()
                        .add(const SchoolStepSkipped()),
                  ),
                OnboardingStep.complete => OrganizationDetailsView(
                    organization: state.organization!,
                    school: state.school,
                    isSubmitting: state.isSubmitting,
                    actorRoles: widget.actorRoles,
                    actorOrganizationId: widget.actorOrganizationId,
                    onOrganizationSave: ({
                      required String name,
                      required String regionProfileCode,
                      String? contactEmail,
                      String? contactPhone,
                    }) {
                      _savingOrganization = true;
                      context.read<OrganizationOnboardingBloc>().add(
                            OrganizationDetailsEdited(
                              name: name,
                              regionProfileCode: regionProfileCode,
                              contactEmail: contactEmail,
                              contactPhone: contactPhone,
                            ),
                          );
                    },
                    onSchoolSave: ({
                      required String name,
                      required String timezone,
                      required double latitude,
                      required double longitude,
                      required int geofenceRadiusM,
                    }) =>
                        context.read<OrganizationOnboardingBloc>().add(
                              SchoolDetailsEdited(
                                name: name,
                                timezone: timezone,
                                latitude: latitude,
                                longitude: longitude,
                                geofenceRadiusM: geofenceRadiusM,
                              ),
                            ),
                    onAddSchool: ({
                      required String code,
                      required String name,
                      required String timezone,
                      required double latitude,
                      required double longitude,
                      required int geofenceRadiusM,
                    }) =>
                        context.read<OrganizationOnboardingBloc>().add(
                              SchoolDetailsSubmitted(
                                code: code,
                                name: name,
                                timezone: timezone,
                                latitude: latitude,
                                longitude: longitude,
                                geofenceRadiusM: geofenceRadiusM,
                              ),
                            ),
                    onSkipSchool: () => context
                        .read<OrganizationOnboardingBloc>()
                        .add(const SchoolStepSkipped()),
                    onStartAnother: () => context
                        .read<OrganizationOnboardingBloc>()
                        .add(const OnboardingReset()),
                    onSuspend: () => context
                        .read<OrganizationOnboardingBloc>()
                        .add(const OrganizationSuspendRequested()),
                    onReactivate: () => context
                        .read<OrganizationOnboardingBloc>()
                        .add(const OrganizationReactivateRequested()),
                  ),
              },
              // The two create steps show their error inside the form, above its actions.
              if (state.error != null && state.step == OnboardingStep.complete)
                OnboardingErrorText(code: state.error!, messageKey: state.errorMessageKey),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}
