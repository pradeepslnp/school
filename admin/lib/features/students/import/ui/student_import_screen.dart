import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../../core/domain.dart';
import '../../../../l10n/app_localizations_extension.dart';
import '../bloc/student_import_bloc.dart';
import '../bloc/student_import_event.dart';
import '../bloc/student_import_state.dart';
import '../data_provider/student_import_file_gateway.dart';
import '../domain/student_import_models.dart';

/// A-12 — Bulk student import (STU-002). Choose a spreadsheet, upload it, and read back which
/// rows enrolled and which need fixing.
///
/// Rendering and operator actions only, no decisions (matching the other screens here). The
/// upload is the bloc's; choosing a file and saving the error report are the browser's, done
/// through [StudentImportFileGateway].
class StudentImportScreen extends StatelessWidget {
  const StudentImportScreen({
    super.key,
    required this.schoolId,
    required this.gateway,
  });

  final String schoolId;
  final StudentImportFileGateway gateway;

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<StudentImportBloc>();
    final picked = await gateway.pickCsv();
    if (picked == null) return;
    bloc.add(StudentImportSubmitted(schoolId: schoolId, file: picked));
  }

  void _download(StudentImportResult result) {
    gateway.downloadCsv(
      fileName: 'student-import-${result.jobId}-errors.csv',
      content: studentImportErrorRowsCsv(result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(
          context,
        ).pop(context.read<StudentImportBloc>().state.importedAnything);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.studentImportTitle)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AdminSpacing.xl),
              child: BlocBuilder<StudentImportBloc, StudentImportState>(
                builder: (context, state) => switch (state.phase) {
                  StudentImportPhase.uploading => _Uploading(
                    fileName: state.fileName,
                  ),
                  StudentImportPhase.done => _Result(
                    result: state.result!,
                    onDownload: () => _download(state.result!),
                    onImportAnother: () => context
                        .read<StudentImportBloc>()
                        .add(const StudentImportReset()),
                  ),
                  StudentImportPhase.choosing => _Chooser(
                    state: state,
                    onPick: () => _pick(context),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chooser extends StatelessWidget {
  const _Chooser({required this.state, required this.onPick});

  final StudentImportState state;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.studentImportIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AdminSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studentImportColumnsTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  l10n.studentImportColumnsBody,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton.icon(
          key: const Key('student_import_pick_button'),
          onPressed: onPick,
          icon: const Icon(Icons.upload_file),
          label: Text(l10n.studentImportChooseFileButton),
        ),
        if (state.error != null)
          _ImportError(
            code: state.error!,
            businessRule: state.errorBusinessRule,
          ),
      ],
    );
  }
}

class _Uploading extends StatelessWidget {
  const _Uploading({this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: AdminSpacing.xl),
        CircularProgressIndicator(
          semanticsLabel: context.l10n.studentImportUploadingLabel,
        ),
        const SizedBox(height: AdminSpacing.lg),
        Text(
          fileName == null
              ? context.l10n.studentImportUploadingLabel
              : context.l10n.studentImportUploadingNamed(fileName!),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.result,
    required this.onDownload,
    required this.onImportAnother,
  });

  final StudentImportResult result;
  final VoidCallback onDownload;
  final VoidCallback onImportAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasErrors = result.errors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.studentImportSummary(
              result.totalRows,
              result.successCount,
              result.errorCount,
            ),
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AdminSpacing.sm),
        Text(
          hasErrors
              ? l10n.studentImportSummaryHintErrors
              : (result.allImported
                    ? l10n.studentImportSummaryHintAllImported
                    : l10n.studentImportSummaryHintNothing),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (hasErrors) ...[
          const SizedBox(height: AdminSpacing.lg),
          _ErrorTable(errors: result.errors),
          const SizedBox(height: AdminSpacing.md),
          OutlinedButton.icon(
            key: const Key('student_import_download_button'),
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            label: Text(l10n.studentImportDownloadErrorsButton),
          ),
        ],
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            FilledButton(
              key: const Key('student_import_again_button'),
              onPressed: onImportAnother,
              child: Text(l10n.studentImportAnotherButton),
            ),
            const SizedBox(width: AdminSpacing.md),
            TextButton(
              key: const Key('student_import_done_button'),
              onPressed: () =>
                  Navigator.of(context).pop(result.successCount > 0),
              child: Text(l10n.commonDoneButton),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorTable extends StatelessWidget {
  const _ErrorTable({required this.errors});

  final List<StudentImportRowError> errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        // A data grid, so it scrolls inside its own box rather than growing the page.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: theme.textTheme.labelLarge,
            columns: [
              DataColumn(label: Text(context.l10n.studentImportColRow)),
              DataColumn(label: Text(context.l10n.studentImportColField)),
              DataColumn(label: Text(context.l10n.studentImportColProblem)),
            ],
            rows: [
              for (final error in errors)
                DataRow(
                  cells: [
                    DataCell(Text('${error.row}')),
                    DataCell(Text(error.field ?? '—')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(error.message),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A whole-file rejection — empty file, an unknown column, too many rows, or the API being
/// unreachable. Not `context.status.critical`: a rejected spreadsheet is something to fix, not
/// a safety event (DESIGN_SYSTEM.md).
class _ImportError extends StatelessWidget {
  const _ImportError({required this.code, this.businessRule});

  final ErrorCode code;
  final String? businessRule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AdminSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 20, color: color),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(
                _message(context),
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(BuildContext context) {
    final l10n = context.l10n;
    return switch (code) {
      ErrorCode.studentImportFileEmpty => l10n.studentImportErrorEmpty,
      ErrorCode.studentImportFileUnreadable =>
        l10n.studentImportErrorUnreadable,
      ErrorCode.studentImportUnsupportedColumn =>
        l10n.studentImportErrorUnsupportedColumn,
      ErrorCode.studentImportTooManyRows => l10n.studentImportErrorTooManyRows,
      ErrorCode.validationRequiredFieldMissing => l10n.studentImportErrorNoFile,
      ErrorCode.authPermissionDenied => l10n.studentErrorPermissionDenied,
      ErrorCode.authScopeDenied => l10n.studentErrorScopeDenied,
      ErrorCode.dependencyUnavailable => l10n.errorApiUnreachable,
      ErrorCode.authSessionRevoked ||
      ErrorCode.authRefreshReuseDetected => l10n.errorSessionEnded,
      _ => l10n.errorGenericRetryShortly,
    };
  }
}
