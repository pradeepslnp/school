import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../bloc/set_password_bloc.dart';
import 'set_password_screen.dart';

/// Composes the accept-invitation page (ADR-0012, IAM-009), reached from an emailed link at
/// `/accept-invitation?token=…`. Public — the invitee has a link, not a session.
///
/// The route owns the wiring; [SetPasswordScreen] owns none of it. [onDone] is supplied by the
/// router so "where to go after activating" is answered in one place, matching `LoginScreen`.
class AcceptInvitationRoute extends StatelessWidget {
  const AcceptInvitationRoute({super.key, required this.token, required this.onDone});

  final String token;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<SetPasswordBloc>(
      create: (_) => SetPasswordBloc(
        repository: dependencies.authRecoveryRepository,
        token: token,
      ),
      child: SetPasswordScreen(
        title: context.l10n.acceptInvitationTitle,
        intro: context.l10n.acceptInvitationIntro,
        submitLabel: context.l10n.acceptInvitationSubmitLabel,
        doneTitle: context.l10n.acceptInvitationDoneTitle,
        doneBody: context.l10n.acceptInvitationDoneBody,
        onDone: onDone,
      ),
    );
  }
}
