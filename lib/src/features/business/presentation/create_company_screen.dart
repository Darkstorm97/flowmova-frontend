import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/current_user_companies_gateway.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key, this.gateway});

  final CurrentUserCompaniesGateway? gateway;

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'CA');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  CurrentUserCompaniesGateway? _gateway;
  String _businessType = 'RESTAURANT';
  String _currency = _currencyOptions.first.value;
  _SelectedCompanyImage? _selectedImage;
  bool _startsOpen = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendCurrentUserCompaniesGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (!session.isAuthenticated) {
      return const _SignedOutCreateCompanyCard();
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle entreprise',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Creez l entreprise, puis configurez ses services, emplacements et catalogues.',
              style: textTheme.titleMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations principales',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: _requiredName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CompanyImagePicker(
                      image: _selectedImage,
                      isDisabled: _isSubmitting,
                      onPick: _pickImage,
                      onClear: () => setState(() => _selectedImage = null),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _businessType,
                      decoration: const InputDecoration(
                        labelText: 'Domaine',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _businessTypeOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(
                              () => _businessType = value ?? _businessType,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Devise',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            selectedItemBuilder: (context) => _currencyOptions
                                .map((option) => Text(option.value))
                                .toList(growable: false),
                            items: _currencyOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: _isSubmitting
                                ? null
                                : (value) => setState(
                                    () => _currency = value ?? _currency,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ouverte'),
                            value: _startsOpen,
                            onChanged: _isSubmitting
                                ? null
                                : (value) =>
                                      setState(() => _startsOpen = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adresse',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressLine1Controller,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressLine2Controller,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Complement',
                        prefixIcon: Icon(Icons.add_location_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _regionController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Code postal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pays',
                        counterText: '',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            validator: (value) =>
                                _optionalCoordinate(value, -90, 90),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            validator: (value) =>
                                _optionalCoordinate(value, -180, 180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Creer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Le nom est requis.';
    }
    if (trimmed.length > 150) {
      return 'Le nom doit contenir 150 caracteres maximum.';
    }
    return null;
  }

  String? _optionalCoordinate(String? value, num min, num max) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed < min || parsed > max) {
      return 'Valeur invalide.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final company = await _gateway!.createCompany(
        CreateCompanyInput(
          name: _nameController.text,
          description: _descriptionController.text,
          currency: _currency,
          businessType: _businessType,
          operationalStatus: _startsOpen ? 'OPEN' : 'CLOSED',
          addressLine1: _addressLine1Controller.text,
          addressLine2: _addressLine2Controller.text,
          city: _cityController.text,
          region: _regionController.text,
          postalCode: _postalCodeController.text,
          country: _countryController.text,
          latitude: _parseCoordinate(_latitudeController.text),
          longitude: _parseCoordinate(_longitudeController.text),
        ),
      );
      final selectedImage = _selectedImage;
      if (selectedImage != null) {
        try {
          await _gateway!.uploadCompanyImage(
            company.id,
            CompanyImageUpload(
              bytes: selectedImage.bytes,
              filename: selectedImage.name,
              contentType: selectedImage.contentType,
            ),
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Entreprise creee, mais la photo n a pas pu etre envoyee.',
                ),
              ),
            );
          }
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.businessDashboard,
        arguments: company.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _submitErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  double? _parseCoordinate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.parse(trimmed.replaceAll(',', '.'));
  }

  String _submitErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'La reponse de creation est illisible.';
    }
    return 'Impossible de creer l entreprise pour le moment.';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setState(() {
        _errorMessage = 'La photo doit peser 5 Mo maximum.';
      });
      return;
    }

    setState(() {
      _selectedImage = _SelectedCompanyImage(
        name: file.name,
        bytes: bytes,
        contentType: _contentTypeFor(file.name),
      );
      _errorMessage = null;
    });
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}

class _SignedOutCreateCompanyCard extends StatelessWidget {
  const _SignedOutCreateCompanyCard();

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
              'Connectez-vous',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devez etre connecte pour creer une entreprise.',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
            const SizedBox(height: 16),
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

class _CompanyImagePicker extends StatelessWidget {
  const _CompanyImagePicker({
    required this.image,
    required this.isDisabled,
    required this.onPick,
    required this.onClear,
  });

  final _SelectedCompanyImage? image;
  final bool isDisabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedImage = image;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlowMovaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (selectedImage == null)
              AspectRatio(
                aspectRatio: 16 / 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: FlowMovaColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 42,
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 8,
                  child: Image.memory(selectedImage.bytes, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedImage?.name ?? 'Aucune photo selectionnee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (selectedImage != null)
                  IconButton(
                    tooltip: 'Retirer la photo',
                    onPressed: isDisabled ? null : onClear,
                    icon: const Icon(Icons.close),
                  ),
                FilledButton.icon(
                  onPressed: isDisabled ? null : onPick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(selectedImage == null ? 'Choisir' : 'Changer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCompanyImage {
  const _SelectedCompanyImage({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

class _CompanyTypeOption {
  const _CompanyTypeOption(this.value, this.label);

  final String value;
  final String label;
}

const _businessTypeOptions = [
  _CompanyTypeOption('RESTAURANT', 'Restauration'),
  _CompanyTypeOption('HAIR_SALON', 'Salon de coiffure'),
  _CompanyTypeOption('RETAIL', 'Commerce'),
  _CompanyTypeOption('HEALTHCARE', 'Sante'),
  _CompanyTypeOption('ADMINISTRATION', 'Administration'),
  _CompanyTypeOption('SERVICE', 'Service'),
  _CompanyTypeOption('OTHER', 'Autre'),
];

class _CurrencyOption {
  const _CurrencyOption(this.value, this.label);

  final String value;
  final String label;
}

const _currencyOptions = [
  _CurrencyOption('XOF', 'XOF - Franc CFA BCEAO'),
  _CurrencyOption('XAF', 'XAF - Franc CFA BEAC'),
  _CurrencyOption('CDF', 'CDF - Franc congolais'),
  _CurrencyOption('GNF', 'GNF - Franc guineen'),
  _CurrencyOption('RWF', 'RWF - Franc rwandais'),
  _CurrencyOption('BIF', 'BIF - Franc burundais'),
  _CurrencyOption('KES', 'KES - Shilling kenyan'),
  _CurrencyOption('TZS', 'TZS - Shilling tanzanien'),
  _CurrencyOption('UGX', 'UGX - Shilling ougandais'),
  _CurrencyOption('GHS', 'GHS - Cedi ghaneen'),
  _CurrencyOption('NGN', 'NGN - Naira nigerian'),
  _CurrencyOption('ZAR', 'ZAR - Rand sud-africain'),
  _CurrencyOption('CAD', 'CAD - Dollar canadien'),
  _CurrencyOption('USD', 'USD - Dollar americain'),
  _CurrencyOption('EUR', 'EUR - Euro'),
];
