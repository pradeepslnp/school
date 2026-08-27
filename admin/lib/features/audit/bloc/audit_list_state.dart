import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/audit_models.dart';

/// The audit trail screen (A-54/A-55), including its loading and error conditions.
class AuditListState extends Equatable {
  const AuditListState({
    this.isLoading = false,
    this.overridesOnly = false,
    this.records = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;

  /// Whether the override register (A-55) is showing rather than the full trail (A-54).
  final bool overridesOnly;

  final List<AuditRecord> records;

  final ErrorCode? error;
  final String? errorMessageKey;

  AuditListState copyWith({
    bool? isLoading,
    bool? overridesOnly,
    List<AuditRecord>? records,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return AuditListState(
      isLoading: isLoading ?? this.isLoading,
      overridesOnly: overridesOnly ?? this.overridesOnly,
      records: records ?? this.records,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, overridesOnly, records, error, errorMessageKey];
}
