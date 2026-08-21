import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/vehicle_models.dart';
import '../repository/vehicle_repository.dart';
import 'vehicle_list_event.dart';
import 'vehicle_list_state.dart';

/// Registers and lists vehicles for one school (A-20, FLT-001).
///
/// Depends on a repository only, never a data provider — matching `StaffListBloc`, so this is
/// tested with no HTTP and no fake server.
class VehicleListBloc extends Bloc<VehicleListEvent, VehicleListState> {
  VehicleListBloc({required VehicleRepository repository})
      : _repository = repository,
        super(const VehicleListState()) {
    on<VehicleListRequested>(_onRequested);
    on<VehicleCreated>(_onCreated);
  }

  final VehicleRepository _repository;

  Future<void> _onRequested(VehicleListRequested event, Emitter<VehicleListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listVehicles(schoolId: event.schoolId);

    switch (result) {
      case Success<List<CreatedVehicle>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, vehicles: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onCreated(VehicleCreated event, Emitter<VehicleListState> emit) async {
    if (event.schoolId.trim().isEmpty ||
        event.registrationNo.trim().isEmpty ||
        event.displayName.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createVehicle(
      schoolId: event.schoolId,
      registrationNo: event.registrationNo,
      displayName: event.displayName,
      vehicleType: event.vehicleType,
      seatingCapacity: event.seatingCapacity,
      vendorName: event.vendorName,
    );

    switch (result) {
      case Success<CreatedVehicle>(:final value):
        // Prepended rather than re-fetched, matching StaffListBloc's own reasoning: the
        // operator just created this row and should see it immediately.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          vehicles: [value, ...state.vehicles],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
