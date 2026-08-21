import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/network/rest_client.dart';
import '../../../utils/utils.dart';
import '../bloc/login_bloc.dart';
import '../data_provider/login_data_provider.dart';
import '../repository/login_repository.dart';
import '../repository/models/session.dart';
import '../widgets/otp_entry_form.dart';
import '../widgets/phone_entry_form.dart';

/// The login route.
///
/// Owns the feature's wiring — data provider → repository → BLoC — so no other feature
/// needs to know how login is assembled. Composition happens here rather than in a global
/// container: the objects live and die with the route.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.apiBaseUrl,
    required this.onAuthenticated,
  });

  final String apiBaseUrl;

  /// Called once a session exists. Navigation is the caller's concern, which keeps this
  /// screen usable from a cold start and from a re-authentication prompt alike.
  final void Function(Session session) onAuthenticated;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<LoginRepository>(
      create: (_) => LoginRepository(
        dataProvider: LoginDataProvider(
          client: RestClient(baseUrl: apiBaseUrl, clientType: 'PARENT_APP'),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<LoginBloc>(
          create: (_) =>
              LoginBloc(repository: context.read<LoginRepository>()),
          child: LoginView(onAuthenticated: onAuthenticated),
        ),
      ),
    );
  }
}

/// The login view, separated from its wiring so tests can supply their own BLoC.
class LoginView extends StatelessWidget {
  const LoginView({super.key, required this.onAuthenticated});

  final void Function(Session session) onAuthenticated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              previous.step != current.step &&
              current.step == LoginStep.authenticated,
          listener: (context, state) {
            final session = state.session;
            if (session != null) onAuthenticated(session);
          },
          child: Center(
            child: SingleChildScrollView(
              // Gutter widens on a tablet instead of leaving the form against the edges.
              padding: EdgeInsets.symmetric(
                horizontal: context.gutter,
                vertical: GuardianSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocBuilder<LoginBloc, LoginState>(
                  buildWhen: (previous, current) =>
                      previous.step != current.step,
                  builder: (context, state) => switch (state.step) {
                    LoginStep.enteringPhone => const PhoneEntryForm(),
                    LoginStep.enteringOtp => const OtpEntryForm(),
                    // Briefly visible while the listener hands off to the caller.
                    LoginStep.authenticated =>
                      const Center(child: CircularProgressIndicator()),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
