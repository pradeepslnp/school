import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../organizations/widgets/school_edit_form.dart';
import '../bloc/school_settings_bloc.dart';
import '../bloc/school_settings_event.dart';
import '../bloc/school_settings_state.dart';

/// A-41 — School: view and edit the signed-in operator's own school (TEN-002).
///
/// Exists for `SCHOOL_ADMIN`, who holds `PERM-SCHOOL-EDIT` but — unlike `ORG_ADMIN` or
/// `SUPER_ADMIN` — not `PERM-ORG-VIEW`, so the Organizations screen (A-40) that
/// `OrganizationDetailsView` is normally reached through is not an option (`ConsoleDestinations`
/// gates A-40 to `SUPER_ADMIN` alone). There is exactly one school here — [schoolId] — never a
/// list or a pasted id to look up, matching a `SCHOOL_ADMIN`'s single-school scope
/// (`AuthenticatedUser.schoolScopeId`).
class SchoolSettingsScreen extends StatefulWidget {
  const SchoolSettingsScreen({super.key, required this.schoolId});

  /// The signed-in operator's own school (`AuthenticatedUser.schoolScopeId`). Non-null by
  /// construction — see `ConsoleRouterDelegate._screenFor`, which does not route here at all
  /// when it is null.
  final String schoolId;

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SchoolSettingsBloc>().add(SchoolSettingsRequested(schoolId: widget.schoolId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.schoolSettingsScreenTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AdminSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: BlocBuilder<SchoolSettingsBloc, SchoolSettingsState>(
                  builder: (context, state) {
                    if (state.isLoading && state.school == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: context.l10n.schoolSettingsLoadingLabel,
                        ),
                      );
                    }

                    final school = state.school;
                    if (school == null) {
                      if (state.error != null) {
                        return OnboardingErrorText(
                          code: state.error!,
                          messageKey: state.errorMessageKey,
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SchoolEditForm(
                          key: ValueKey('school_settings_${school.id}'),
                          school: school,
                          isSubmitting: state.isSubmitting,
                          onSave: ({
                            required String name,
                            required String timezone,
                            required double latitude,
                            required double longitude,
                            required int geofenceRadiusM,
                          }) {
                            context.read<SchoolSettingsBloc>().add(
                                  SchoolSettingsSaved(
                                    schoolId: school.id,
                                    organizationId: school.organizationId,
                                    name: name,
                                    timezone: timezone,
                                    latitude: latitude,
                                    longitude: longitude,
                                    geofenceRadiusM: geofenceRadiusM,
                                  ),
                                );
                          },
                        ),
                        if (state.error != null)
                          OnboardingErrorText(
                            code: state.error!,
                            messageKey: state.errorMessageKey,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
