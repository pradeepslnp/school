import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/forgot_password_bloc.dart';
import 'forgot_password_screen.dart';

/// Composes the forgot-password page (ADR-0012, IAM-010), reached from the sign-in screen at
/// `/forgot-password`.
class ForgotPasswordRoute extends StatelessWidget {
  const ForgotPasswordRoute({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => ForgotPasswordBloc(repository: dependencies.authRecoveryRepository),
      child: ForgotPasswordScreen(onBack: onBack),
    );
  }
}
