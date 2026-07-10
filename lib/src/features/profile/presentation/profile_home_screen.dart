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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos informations de compte FlowMova.',
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
                        _profileFuture = _profileGateway!
                            .getCurrentUserProfile();
                      });
                    },
                  );
                }

                return _SignedInProfileCard(profile: snapshot.requireData);
              },
            ),
        ],
      ),
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
    final title = isExpired ? 'Session expiree' : 'Utilisateur FlowMova';
    final status = isExpired ? 'Session expiree' : 'Non connecte';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHero(
          initials: 'FM',
          title: title,
          subtitle: isExpired
              ? 'Reconnectez-vous pour actualiser vos informations.'
              : 'Connectez-vous pour afficher vos informations.',
          statusLabel: status,
        ),
        const SizedBox(height: 16),
        _ProfileInfoCard(
          rows: [
            _ProfileInfoRowData(label: 'Statut du compte', value: status),
            const _ProfileInfoRowData(
              label: 'Informations',
              value: 'Profil non charge',
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          icon: const Icon(Icons.login),
          label: const Text('Se connecter'),
        ),
      ],
    );
  }
}

class _SignedInProfileCard extends StatelessWidget {
  const _SignedInProfileCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ProfileInfoRowData(label: 'Nom', value: profile.displayName),
      _ProfileInfoRowData(label: 'Email', value: profile.email),
      if (profile.phone != null && profile.phone!.trim().isNotEmpty)
        _ProfileInfoRowData(label: 'Telephone', value: profile.phone!),
      _ProfileInfoRowData(
        label: 'Statut du compte',
        value: _statusLabel(profile.status),
      ),
      if (profile.preferredLanguage != null &&
          profile.preferredLanguage!.trim().isNotEmpty)
        _ProfileInfoRowData(
          label: 'Langue preferee',
          value: profile.preferredLanguage!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHero(
          initials: _profileInitials(profile),
          title: profile.displayName,
          subtitle: profile.email,
          statusLabel: _statusLabel(profile.status),
        ),
        const SizedBox(height: 16),
        _ProfileInfoCard(rows: rows),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Se deconnecter'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se deconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour acceder a vos espaces personnels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await SessionScope.of(context).signOut();
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
  });

  final String initials;
  final String title;
  final String subtitle;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.08),
        border: Border.all(
          color: FlowMovaColors.primaryAqua.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: FlowMovaColors.primaryAqua,
              child: Text(
                initials,
                style: textTheme.titleMedium?.copyWith(
                  color: FlowMovaColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileStatusPill(label: statusLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.rows});

  final List<_ProfileInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations du profil',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final row in rows) _ProfileInfoRow(row: row),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRowData {
  const _ProfileInfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.row});

  final _ProfileInfoRowData row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: textTheme.labelMedium?.copyWith(
              color: FlowMovaColors.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(row.value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ProfileStatusPill extends StatelessWidget {
  const _ProfileStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Compte actif' => FlowMovaColors.leafGreen,
      'Session expiree' => FlowMovaColors.softApricot,
      _ => FlowMovaColors.slate,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
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
  const _ProfileErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _profileInitials(UserProfile profile) {
  final first = profile.firstName.trim();
  final last = profile.lastName.trim();
  final source = [if (first.isNotEmpty) first, if (last.isNotEmpty) last];

  if (source.isEmpty) {
    final email = profile.email.trim();
    return email.isEmpty ? 'FM' : email.characters.first.toUpperCase();
  }

  return source
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
}

String _statusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Compte actif',
    'INACTIVE' => 'Compte inactif',
    _ => status,
  };
}
