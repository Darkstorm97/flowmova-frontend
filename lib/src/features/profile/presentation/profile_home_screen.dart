import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/auth_session_controller.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/profile_gateway.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({this.profileGateway, super.key});

  final ProfileGateway? profileGateway;

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  ProfileGateway? _profileGateway;
  Future<UserProfile>? _profileFuture;
  AuthSessionController? _sessionController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final sessionController = SessionScope.of(context);
    if (_sessionController != sessionController) {
      _sessionController?.removeListener(_handleSessionChanged);
      _sessionController = sessionController;
      _sessionController!.addListener(_handleSessionChanged);
    }

    _profileGateway ??=
        widget.profileGateway ??
        BackendProfileGateway(
          ApiClient(accessTokenProvider: sessionController.currentAccessToken),
        );

    if (sessionController.isAuthenticated && _profileFuture == null) {
      _profileFuture = _profileGateway!.getCurrentUserProfile();
    }
  }

  void _handleSessionChanged() {
    final session = _sessionController;
    if (session == null || !mounted) {
      return;
    }

    setState(() {
      _profileFuture = session.isAuthenticated
          ? _profileGateway!.getCurrentUserProfile()
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = SessionScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Connectez-vous pour retrouver vos tickets, vos entreprises et vos informations de compte.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        if (session.status == AuthSessionStatus.unknown)
          const _ProfileLoadingCard()
        else if (!session.isAuthenticated)
          _SignedOutProfileCard(
            isExpired: session.status == AuthSessionStatus.expired,
          )
        else
          FutureBuilder<UserProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _ProfileLoadingCard();
              }

              if (snapshot.hasError) {
                return _ProfileErrorCard(
                  message: _profileErrorMessage(snapshot.error),
                  onRetry: () {
                    setState(() {
                      _profileFuture = _profileGateway!.getCurrentUserProfile();
                    });
                  },
                  onSignOut: () => SessionScope.of(context).signOut(),
                );
              }

              return _SignedInProfileCard(
                profile: snapshot.requireData,
                onSignOut: () => SessionScope.of(context).signOut(),
              );
            },
          ),
      ],
    );
  }

  String _profileErrorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Profil indisponible pour le moment. Reessayez plus tard.';
  }

  @override
  void dispose() {
    _sessionController?.removeListener(_handleSessionChanged);
    super.dispose();
  }
}

class _SignedOutProfileCard extends StatelessWidget {
  const _SignedOutProfileCard({required this.isExpired});

  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpired ? 'Session expiree' : 'Vous n etes pas connecte',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'Reconnectez-vous pour acceder a vos informations.'
                  : 'Connectez-vous pour acceder a vos informations, retrouver vos tickets et gerer vos entreprises.',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Se connecter'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('Creer un compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInProfileCard extends StatelessWidget {
  const _SignedInProfileCard({required this.profile, required this.onSignOut});

  final UserProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes infos profil',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(label: 'Nom', value: profile.displayName),
            _ProfileInfoRow(label: 'Email', value: profile.email),
            if (profile.phone != null && profile.phone!.trim().isNotEmpty)
              _ProfileInfoRow(label: 'Telephone', value: profile.phone!),
            _ProfileInfoRow(label: 'Statut', value: profile.status),
            if (profile.preferredLanguage != null &&
                profile.preferredLanguage!.trim().isNotEmpty)
              _ProfileInfoRow(
                label: 'Langue',
                value: profile.preferredLanguage!,
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Se deconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: FlowMovaColors.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement du profil...'),
          ],
        ),
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil indisponible',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer'),
                ),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Se deconnecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
