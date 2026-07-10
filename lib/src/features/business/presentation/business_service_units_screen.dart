import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/admin_service_units_gateway.dart';
import '../data/business_dashboard_gateway.dart';

class BusinessServiceUnitsArguments {
  const BusinessServiceUnitsArguments({required this.companyId});

  final String companyId;
}

class BusinessServiceUnitLocationsArguments {
  const BusinessServiceUnitLocationsArguments({
    required this.companyId,
    required this.serviceUnit,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
}

class BusinessServiceUnitsScreen extends StatefulWidget {
  const BusinessServiceUnitsScreen({
    super.key,
    required this.companyId,
    this.gateway,
  });

  final String companyId;
  final AdminServiceUnitsGateway? gateway;

  @override
  State<BusinessServiceUnitsScreen> createState() =>
      _BusinessServiceUnitsScreenState();
}

class _BusinessServiceUnitsScreenState
    extends State<BusinessServiceUnitsScreen> {
  AdminServiceUnitsGateway? _gateway;
  Future<BusinessServiceUnitPage>? _future;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendAdminServiceUnitsGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _future ??= _gateway!.listServiceUnits(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const _SignedOutCard();
    }

    return FutureBuilder<BusinessServiceUnitPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingCard(label: 'Chargement des services...');
        }
        if (snapshot.hasError) {
          return _ErrorCard(
            message: _errorMessage(snapshot.error),
            onRetry: _reload,
          );
        }

        final page = snapshot.requireData;
        final services = _filtered(page.items);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Services',
                subtitle:
                    '${page.totalItems} service${page.totalItems > 1 ? 's' : ''} configures',
                actionLabel: 'Nouveau',
                onAction: () => _openServiceForm(),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Rechercher un service',
                ),
              ),
              const SizedBox(height: 14),
              if (services.isEmpty)
                _EmptyCard(
                  title: page.items.isEmpty
                      ? 'Aucun service'
                      : 'Aucun resultat',
                  message: page.items.isEmpty
                      ? 'Creez un premier service pour commencer a recevoir des tickets.'
                      : 'Aucun service ne correspond a votre recherche.',
                )
              else
                for (final service in services) ...[
                  _ServiceCard(
                    service: service,
                    onEdit: () => _openServiceForm(service: service),
                    onLocations: () => Navigator.pushNamed(
                      context,
                      AppRoutes.businessServiceUnitLocations,
                      arguments: BusinessServiceUnitLocationsArguments(
                        companyId: widget.companyId,
                        serviceUnit: service,
                      ),
                    ),
                    onOpen: service.status == 'OPEN'
                        ? null
                        : () => _confirmAndRun(
                            title: 'Ouvrir ce service ?',
                            message:
                                'Il sera visible dans les parcours publics si l entreprise est ouverte.',
                            actionLabel: 'Ouvrir',
                            action: () => _gateway!.openServiceUnit(
                              widget.companyId,
                              service.id,
                            ),
                          ),
                    onClose: service.status == 'OPEN'
                        ? () => _confirmAndRun(
                            title: 'Fermer ce service ?',
                            message:
                                'Les clients ne pourront plus creer de ticket sur ce service.',
                            actionLabel: 'Fermer',
                            action: () => _gateway!.closeServiceUnit(
                              widget.companyId,
                              service.id,
                            ),
                          )
                        : null,
                    onArchive: service.status == 'ARCHIVED'
                        ? null
                        : () => _confirmAndRun(
                            title: 'Archiver ce service ?',
                            message:
                                'Le service sera retire des parcours actifs. Cette action est a utiliser avec prudence.',
                            actionLabel: 'Archiver',
                            action: () => _gateway!.archiveServiceUnit(
                              widget.companyId,
                              service.id,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  List<BusinessServiceUnit> _filtered(List<BusinessServiceUnit> services) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return services;
    }
    return services
        .where(
          (service) =>
              service.name.toLowerCase().contains(needle) ||
              (service.location ?? '').toLowerCase().contains(needle) ||
              _serviceStatusLabel(
                service.status,
              ).toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  void _reload() {
    setState(() {
      _future = _gateway!.listServiceUnits(widget.companyId);
    });
  }

  Future<void> _openServiceForm({BusinessServiceUnit? service}) async {
    final input = await showModalBottomSheet<ServiceUnitInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceUnitFormSheet(service: service),
    );
    if (input == null) {
      return;
    }

    await _runMutation(() {
      if (service == null) {
        return _gateway!.createServiceUnit(widget.companyId, input);
      }
      return _gateway!.updateServiceUnit(widget.companyId, service.id, input);
    });
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String actionLabel,
    required Future<Object?> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runMutation(action);
    }
  }

  Future<void> _runMutation(Future<Object?> Function() action) async {
    try {
      await action();
      if (mounted) {
        _reload();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }
}

class BusinessServiceUnitLocationsScreen extends StatefulWidget {
  const BusinessServiceUnitLocationsScreen({
    super.key,
    required this.companyId,
    required this.serviceUnit,
    this.gateway,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
  final AdminServiceUnitsGateway? gateway;

  @override
  State<BusinessServiceUnitLocationsScreen> createState() =>
      _BusinessServiceUnitLocationsScreenState();
}

class _BusinessServiceUnitLocationsScreenState
    extends State<BusinessServiceUnitLocationsScreen> {
  AdminServiceUnitsGateway? _gateway;
  Future<BusinessServiceUnitLocationPage>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendAdminServiceUnitsGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _future ??= _gateway!.listLocations(
      widget.companyId,
      widget.serviceUnit.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const _SignedOutCard();
    }

    return FutureBuilder<BusinessServiceUnitLocationPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingCard(label: 'Chargement des emplacements...');
        }
        if (snapshot.hasError) {
          return _ErrorCard(
            message: _errorMessage(snapshot.error),
            onRetry: _reload,
          );
        }

        final page = snapshot.requireData;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: widget.serviceUnit.name,
                subtitle:
                    '${page.totalItems} emplacement${page.totalItems > 1 ? 's' : ''}',
                actionLabel: 'Nouvel emplacement',
                onAction: _openLocationForm,
              ),
              const SizedBox(height: 12),
              if (page.items.isEmpty)
                const _EmptyCard(
                  title: 'Aucun emplacement',
                  message:
                      'Le service a normalement un emplacement par defaut. Rafraichissez ou creez un emplacement.',
                )
              else
                for (final location in page.items) ...[
                  _LocationCard(location: location),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _future = _gateway!.listLocations(
        widget.companyId,
        widget.serviceUnit.id,
      );
    });
  }

  Future<void> _openLocationForm() async {
    final input = await showModalBottomSheet<ServiceUnitLocationInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _LocationFormSheet(),
    );
    if (input == null) {
      return;
    }

    try {
      await _gateway!.createLocation(
        widget.companyId,
        widget.serviceUnit.id,
        input,
      );
      if (mounted) {
        _reload();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onLocations,
    required this.onOpen,
    required this.onClose,
    required this.onArchive,
  });

  final BusinessServiceUnit service;
  final VoidCallback onEdit;
  final VoidCallback onLocations;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          _serviceTypeLabel(service.type),
                          if (service.location != null &&
                              service.location!.trim().isNotEmpty)
                            service.location!,
                          _entryModeLabel(service.creationEntryMode),
                        ].join(' - '),
                        style: textTheme.bodySmall?.copyWith(
                          color: FlowMovaColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: _serviceStatusLabel(service.status),
                  color: service.status == 'OPEN'
                      ? FlowMovaColors.leafGreen
                      : FlowMovaColors.slate,
                ),
              ],
            ),
            if (service.description != null &&
                service.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(service.description!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onLocations,
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Emplacements'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                if (onOpen != null)
                  FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Ouvrir'),
                  ),
                if (onClose != null)
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.pause_outlined),
                    label: const Text('Fermer'),
                  ),
                if (onArchive != null)
                  TextButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archiver'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final BusinessServiceUnitLocation location;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final publicLink = location.publicUrl ?? location.publicAccessSlug;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (location.defaultLocation)
                  const _StatusPill(
                    label: 'Defaut',
                    color: FlowMovaColors.primaryAqua,
                  ),
              ],
            ),
            if (location.description != null &&
                location.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(location.description!),
            ],
            if (publicLink != null && publicLink.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                publicLink,
                style: textTheme.bodySmall?.copyWith(
                  color: FlowMovaColors.slate,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceUnitFormSheet extends StatefulWidget {
  const _ServiceUnitFormSheet({this.service});

  final BusinessServiceUnit? service;

  @override
  State<_ServiceUnitFormSheet> createState() => _ServiceUnitFormSheetState();
}

class _ServiceUnitFormSheetState extends State<_ServiceUnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late String _guardMode;
  late String _entryMode;
  late bool _allowTicketWithoutItems;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name);
    _descriptionController = TextEditingController(text: service?.description);
    _locationController = TextEditingController(text: service?.location);
    _guardMode = service?.ticketCreationGuardMode ?? 'NONE';
    _entryMode = service?.creationEntryMode ?? 'PUBLIC_AND_QR';
    _allowTicketWithoutItems = service?.allowTicketWithoutItems ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service == null ? 'Nouveau service' : 'Modifier service',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le nom est requis.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu court',
                  hintText: 'Ex: comptoir, salon, accueil',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _entryMode,
                decoration: const InputDecoration(labelText: 'Creation ticket'),
                items: const [
                  DropdownMenuItem(
                    value: 'PUBLIC_AND_QR',
                    child: Text('Depuis fiche et QR code'),
                  ),
                  DropdownMenuItem(
                    value: 'QR_ONLY',
                    child: Text('QR code seulement'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _entryMode = value ?? _entryMode),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _guardMode,
                decoration: const InputDecoration(labelText: 'Anti-spam'),
                items: const [
                  DropdownMenuItem(
                    value: 'NONE',
                    child: Text('Aucune restriction'),
                  ),
                  DropdownMenuItem(
                    value: 'AUTHENTICATED_ONLY_ONE_OPEN_TICKET',
                    child: Text('Connecte: un ticket ouvert'),
                  ),
                  DropdownMenuItem(
                    value: 'AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET',
                    child: Text('Compte ou appareil limite'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _guardMode = value ?? _guardMode),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowTicketWithoutItems,
                title: const Text('Autoriser les tickets sans article'),
                subtitle: const Text(
                  'Desactivez cette option si le client doit choisir au moins un article.',
                ),
                onChanged: (value) =>
                    setState(() => _allowTicketWithoutItems = value),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      ServiceUnitInput(
        name: _nameController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        ticketCreationGuardMode: _guardMode,
        creationEntryMode: _entryMode,
        allowTicketWithoutItems: _allowTicketWithoutItems,
      ),
    );
  }
}

class _LocationFormSheet extends StatefulWidget {
  const _LocationFormSheet();

  @override
  State<_LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<_LocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvel emplacement',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le nom est requis.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Creer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      ServiceUnitLocationInput(
        name: _nameController.text,
        description: _descriptionController.text,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chargement impossible',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 12),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connectez-vous',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Vous devez etre connecte pour gerer les services.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is FormatException) {
    return 'Les donnees recues sont illisibles.';
  }
  return 'Une erreur est survenue. Reessayez plus tard.';
}

String _serviceTypeLabel(String type) {
  return switch (type) {
    'TICKET_QUEUE' => 'File / commande',
    _ => type,
  };
}

String _serviceStatusLabel(String status) {
  return switch (status) {
    'OPEN' => 'Ouvert',
    'CLOSED' => 'Ferme',
    'ARCHIVED' => 'Archive',
    _ => status,
  };
}

String _entryModeLabel(String mode) {
  return switch (mode) {
    'QR_ONLY' => 'QR seulement',
    'PUBLIC_AND_QR' => 'Fiche + QR',
    _ => mode,
  };
}
