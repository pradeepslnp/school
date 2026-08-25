import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../school_scope/widgets/school_picker_field.dart';
import '../bloc/vehicle_list_bloc.dart';
import '../bloc/vehicle_list_event.dart';
import '../bloc/vehicle_list_state.dart';
import '../domain/vehicle_models.dart';
import '../widgets/create_vehicle_form.dart';

/// A-20 — Vehicle register: the school's fleet (FLT-001). Reached only by roles holding
/// `PERM-VEHICLE-MANAGE` (PERMISSION_MATRIX.md) — see `ConsoleDestinations`.
///
/// Holds the "which school" text the operator is looking at — everything else is
/// [VehicleListState]. Matching `StaffListScreen`: no decisions here, only rendering and
/// reporting what the operator did.
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key, this.initialSchoolId});

  /// The signed-in operator's own school (`AuthenticatedUser.schoolScopeId`), when they hold
  /// a school-scoped role. Pre-fills the field and loads immediately, so a `TRANSPORT_MANAGER`
  /// or `SCHOOL_ADMIN` sees their own fleet without pasting an id first — an `ORG_ADMIN` or
  /// `SUPER_ADMIN`, who oversees more than one school, still has to enter one.
  final String? initialSchoolId;

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  /// The school currently loaded — from [widget.initialSchoolId], from `WorkspaceContext`, or
  /// from `SchoolPickerField` (shown only when neither of those is set; see [build]).
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    // The role's own school wins if known; otherwise fall back to whatever school the
    // operator last looked at on another of these screens (WorkspaceContext) — either way,
    // the point is to not make them pick it again.
    final remembered = DependencyScope.readOnce(context).workspaceContext.value;
    final schoolId = widget.initialSchoolId ?? remembered;
    _selectedSchoolId = schoolId;
    if (schoolId != null && schoolId.isNotEmpty) {
      context.read<VehicleListBloc>().add(VehicleListRequested(schoolId: schoolId));
    }
  }

  void _load(BuildContext context, String schoolId) {
    if (schoolId.isEmpty) return;
    setState(() => _selectedSchoolId = schoolId);
    DependencyScope.of(context).workspaceContext.value = schoolId;
    context.read<VehicleListBloc>().add(VehicleListRequested(schoolId: schoolId));
  }

  Future<void> _openAddForm(BuildContext context) async {
    final bloc = context.read<VehicleListBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<VehicleListBloc, VehicleListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateVehicleForm(
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String schoolId,
                        required String registrationNo,
                        required String displayName,
                        required String vehicleType,
                        required int seatingCapacity,
                        String? vendorName,
                      }) {
                        bloc.add(VehicleCreated(
                          schoolId: schoolId,
                          registrationNo: registrationNo,
                          displayName: displayName,
                          vehicleType: vehicleType,
                          seatingCapacity: seatingCapacity,
                          vendorName: vendorName,
                        ));
                      },
                    ),
                    if (state.error != null)
                      OnboardingErrorText(code: state.error!, messageKey: state.errorMessageKey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<VehicleListBloc, VehicleListState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Vehicles', style: theme.textTheme.headlineSmall),
                ),
                FilledButton.icon(
                  key: const Key('vehicle_list_add_button'),
                  onPressed: () => _openAddForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add vehicle'),
                ),
              ],
            ),
            if (widget.initialSchoolId == null) ...[
              const SizedBox(height: AdminSpacing.lg),
              SchoolPickerField(
                onSchoolSelected: (schoolId) => _load(context, schoolId),
              ),
            ],
            const SizedBox(height: AdminSpacing.lg),
            Expanded(
              child: BlocBuilder<VehicleListBloc, VehicleListState>(
                builder: (context, state) {
                  if (state.isLoading && state.vehicles.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(semanticsLabel: 'Loading fleet'),
                    );
                  }

                  if (state.error != null && state.vehicles.isEmpty) {
                    final color = context.status.critical;
                    return Center(
                      child: Text(
                        'That could not be loaded right now. Try again.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: color),
                      ),
                    );
                  }

                  if (state.vehicles.isEmpty) {
                    return Center(
                      child: Text(
                        'No fleet loaded. Pick a school above, or add the first vehicle.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return _VehicleTable(vehicles: state.vehicles);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTable extends StatelessWidget {
  const _VehicleTable({required this.vehicles});

  final List<CreatedVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        key: const Key('vehicle_list_table'),
        itemCount: vehicles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          final statusColor = vehicle.status == 'ACTIVE'
              ? context.status.safe
              : context.status.warning;

          return ListTile(
            key: Key('vehicle_list_row_${vehicle.id}'),
            minVerticalPadding: AdminSpacing.md,
            title: Text(vehicle.displayName),
            subtitle: Text(
              '${vehicle.registrationNo} · ${vehicle.vehicleType} · '
              '${vehicle.seatingCapacity} seats',
            ),
            trailing: Tooltip(
              message: vehicle.status,
              child: Icon(Icons.circle, size: 12, color: statusColor),
            ),
          );
        },
      ),
    );
  }
}
