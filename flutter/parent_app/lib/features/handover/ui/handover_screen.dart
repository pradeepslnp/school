import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../bloc/handover_bloc.dart';
import '../repository/models/handover_code.dart';

/// P-12 — shown when the parent is collecting their child at a drop stop
/// (docs/05-ui/PARENT_APP.md § P-12).
///
/// Renders state it is given; it does not fetch (ENGINEERING_PRINCIPLES.md §8). The only
/// things this widget decides for itself are lifecycle-only, not business, concerns: it
/// raises the screen's own brightness while visible (the code is read outdoors, often in
/// sunlight) and ticks once a second so the expiry countdown stays current — neither changes
/// what is shown, only when it re-renders.
class HandoverScreen extends StatefulWidget {
  const HandoverScreen({
    super.key,
    required this.state,
    required this.onChildSelected,
    required this.onRequestNewCode,
  });

  final HandoverState state;
  final void Function(ChildOption) onChildSelected;
  final VoidCallback onRequestNewCode;

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _raiseBrightness();
    // Ticks the countdown text; the code itself only changes via the bloc.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _resetBrightness();
    super.dispose();
  }

  /// Best-effort. Desktop and web builds, and some devices, refuse this — the code is still
  /// fully usable at ordinary brightness, so a failure here is silent rather than surfaced.
  Future<void> _raiseBrightness() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (_) {
      // Not supported on this platform/device. Nothing else depends on it succeeding.
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // Same as above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedName = state.selected?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedName == null
              ? context.l10n.handoverCollectChildTitleNoName
              : context.l10n.handoverCollectChildTitleWithName(selectedName),
        ),
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final state = widget.state;
    final selectedName = state.selected?.displayName;

    if (state.children.isEmpty) {
      return _Message(
        icon: Icons.family_restroom,
        title: context.l10n.noChildrenLinkedTitle,
        detail: context.l10n.noChildrenLinkedDetail,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        GuardianSpacing.md,
        GuardianSpacing.md,
        GuardianSpacing.md,
        GuardianSpacing.xl,
      ),
      child: Column(
        children: [
          if (state.children.length > 1) ...[
            _ChildSelector(
              children: state.children,
              selected: state.selected,
              onChanged: widget.onChildSelected,
            ),
            const SizedBox(height: GuardianSpacing.lg),
          ],
          if (state.isLoading && state.code == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: GuardianSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.showsFailureInsteadOfContent)
            _FailureMessage(
              failure: state.failure!,
              onRetry: widget.onRequestNewCode,
            )
          else if (state.code != null)
            _CodeDisplay(
              code: state.code!,
              childName: selectedName ?? '',
              onRequestNewCode: widget.onRequestNewCode,
            ),
        ],
      ),
    );
  }
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({required this.children, this.selected, required this.onChanged});

  final List<ChildOption> children;
  final ChildOption? selected;
  final void Function(ChildOption) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ChildOption>(
      value: selected,
      decoration: InputDecoration(labelText: context.l10n.whichChildLabel),
      items: [
        for (final child in children)
          DropdownMenuItem(value: child, child: Text(child.displayName)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

/// The QR code, the numeric fallback, and the expiry — the screen's whole reason to exist.
///
/// **The numeric code is a fallback for a failed scan, not a lesser option** (BR-HAND-002),
/// so it is sized and weighted to be read as easily as the QR code is scanned, not tucked
/// away as a small-print alternative.
class _CodeDisplay extends StatelessWidget {
  const _CodeDisplay({
    required this.code,
    required this.childName,
    required this.onRequestNewCode,
  });

  final HandoverCode code;
  final String childName;
  final VoidCallback onRequestNewCode;

  @override
  Widget build(BuildContext context) {
    final expired = code.isExpired;

    return Column(
      children: [
        Text(
          context.l10n.handoverShowToAttendant,
          style: context.texts.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: GuardianSpacing.lg),
        Semantics(
          label: context.l10n.handoverQrSemanticLabel(childName),
          child: Container(
            padding: const EdgeInsets.all(GuardianSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(GuardianRadius.lg),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Opacity(
              // Dimmed rather than removed once expired: the shape stays recognisable while
              // the state below explains why it can no longer be scanned.
              opacity: expired ? 0.3 : 1.0,
              child: QrImageView(
                data: code.code,
                version: QrVersions.auto,
                size: 210,
                semanticsLabel: context.l10n.handoverQrSemanticsLabelPlain,
              ),
            ),
          ),
        ),
        const SizedBox(height: GuardianSpacing.lg),
        Text(
          context.l10n.handoverIfCannotScan,
          style: context.texts.labelMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: GuardianSpacing.xs),
        Text(
          code.grouped,
          style: context.texts.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: GuardianSpacing.lg),
        if (childName.isNotEmpty)
          Text(childName, style: context.texts.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: GuardianSpacing.sm),
        _ExpiryLabel(code: code),
        if (expired) ...[
          const SizedBox(height: GuardianSpacing.lg),
          FilledButton(
            onPressed: onRequestNewCode,
            child: Text(context.l10n.handoverGenerateNewCode),
          ),
        ],
      ],
    );
  }
}

class _ExpiryLabel extends StatelessWidget {
  const _ExpiryLabel({required this.code});

  final HandoverCode code;

  @override
  Widget build(BuildContext context) {
    if (code.isExpired) {
      return Text(
        context.l10n.handoverCodeExpired,
        style: context.texts.bodyMedium?.copyWith(color: context.status.warning),
      );
    }

    final remaining = code.remaining();
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final label = minutes > 0
        ? context.l10n.handoverExpiresInMinSec(minutes, seconds.toString().padLeft(2, '0'))
        : context.l10n.handoverExpiresInSeconds(seconds);

    return Text(
      label,
      style:
          context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
    );
  }
}

/// Plain language describing the situation, never a code (docs/05-ui/ACCESSIBILITY.md).
class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.failure, required this.onRetry});

  final Failure<void> failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (failure.code) {
      ErrorCode.guardianNotAuthorisedForHandover => l10n.handoverErrorNotAuthorised,
      ErrorCode.dependencyUnavailable => l10n.errorDependencyUnavailable,
      ErrorCode.rateLimitExceeded => l10n.errorRateLimited,
      _ => l10n.handoverGenericFailure,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GuardianSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizeConstants.emptyStateIcon,
            color: context.status.warning,
          ),
          const SizedBox(height: GuardianSpacing.md),
          Text(text, style: context.texts.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: GuardianSpacing.lg),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.tryAgainButton)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizeConstants.emptyStateIcon, color: context.colors.onSurfaceVariant),
            const SizedBox(height: GuardianSpacing.md),
            Text(title, style: context.texts.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              detail,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
