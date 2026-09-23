import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../bloc/route_list_bloc.dart';
import '../bloc/route_list_event.dart';
import '../bloc/route_list_state.dart';
import '../domain/route_models.dart';
import '../widgets/operating_days_field.dart';

/// Edits a route's name and the days it runs (A-30, RTE-001).
///
/// Exists because V22 gave routes an operating-days field that decides whether MOD-08 generates
/// a trip at all (BR-TRIP-011). Without a screen, every route would sit on the Mon–Fri default
/// for ever and a school running a Saturday service would have no way to say so.
///
/// **The route code is shown, not edited.** A code is printed on lists, quoted to parents, and
/// stamped on every trip generated under it; changing one silently re-labels history that has
/// already been acted on. The server refuses it too — this dialog agrees with that rather than
/// offering a field the API would ignore.
class RouteEditDialog extends StatefulWidget {
  const RouteEditDialog({super.key, required this.route, required this.schoolId});

  final CreatedRoute route;
  final String schoolId;

  @override
  State<RouteEditDialog> createState() => _RouteEditDialogState();
}

class _RouteEditDialogState extends State<RouteEditDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.route.name);
  late String _operatingDays = widget.route.operatingDays;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != widget.route.name ||
      _operatingDays != widget.route.operatingDays;

  void _submit(RouteListBloc bloc) {
    bloc.add(
      RouteEdited(
        schoolId: widget.schoolId,
        routeId: widget.route.id,
        // Only what actually changed is sent, so this dialog cannot overwrite a field a
        // colleague edited while it was open.
        name: _name.text.trim() == widget.route.name ? null : _name.text.trim(),
        operatingDays:
            _operatingDays == widget.route.operatingDays ? null : _operatingDays,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<RouteListBloc>();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: BlocBuilder<RouteListBloc, RouteListState>(
            bloc: bloc,
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.routeEditTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  widget.route.code,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),
                TextField(
                  key: const Key('route_edit_name_field'),
                  controller: _name,
                  enabled: !state.isSubmitting,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.l10n.createRouteNameLabel,
                    border: const OutlineInputBorder(),
                    constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                ),
                const SizedBox(height: AdminSpacing.md),
                OperatingDaysField(
                  value: _operatingDays,
                  enabled: !state.isSubmitting,
                  onChanged: (value) => setState(() => _operatingDays = value),
                ),
                const SizedBox(height: AdminSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('route_edit_cancel_button'),
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(context.l10n.commonCancelButton),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: FilledButton(
                        key: const Key('route_edit_submit_button'),
                        // Disabled on an unchanged form and on an empty day set: a PATCH that
                        // changes nothing is a wasted round trip, and a route running no days
                        // never runs at all.
                        onPressed:
                            state.isSubmitting || !_dirty || _operatingDays.isEmpty
                                ? null
                                : () => _submit(bloc),
                        child: state.isSubmitting
                            ? OnboardingButtonSpinner(
                                semanticsLabel: context.l10n.commonAddingSpinnerLabel,
                              )
                            : Text(context.l10n.routeEditSubmitButton),
                      ),
                    ),
                  ],
                ),
                if (state.error != null)
                  OnboardingErrorText(
                    code: state.error!,
                    messageKey: state.errorMessageKey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
