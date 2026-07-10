import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/current_user_companies_gateway.dart';
import 'company_image_picker.dart';

class EditCompanyArguments {
  const EditCompanyArguments({required this.company, this.gateway});

  final CurrentUserCompany company;
  final CurrentUserCompaniesGateway? gateway;
}

class EditCompanyScreen extends StatefulWidget {
  const EditCompanyScreen({super.key, required this.company, this.gateway});

  final CurrentUserCompany company;
  final CurrentUserCompaniesGateway? gateway;

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;

  CurrentUserCompaniesGateway? _gateway;
  late String _businessType;
  late String _currency;
  late bool _isOpen;
  bool _isSubmitting = false;
  String? _errorMessage;
  _SelectedCompanyImage? _selectedImage;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _nameController = TextEditingController(text: company.name);
    _descriptionController = TextEditingController(text: company.description);
    _addressLine1Controller = TextEditingController(text: company.addressLine1);
    _addressLine2Controller = TextEditingController(text: company.addressLine2);
    _cityController = TextEditingController(text: company.city);
    _regionController = TextEditingController(text: company.region);
    _postalCodeController = TextEditingController(text: company.postalCode);
    _countryController = TextEditingController(text: company.country ?? 'CA');
    _businessType =
        _businessTypeOptions.any(
          (option) => option.value == company.businessType,
        )
        ? company.businessType
        : 'OTHER';
    _currency =
        _currencyOptions.any((option) => option.value == company.currency)
        ? company.currency
        : 'XOF';
    _isOpen = company.operationalStatus == 'OPEN';
  }

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
      return const _SignedOutEditCompanyCard();
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier l entreprise',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mettez a jour les informations visibles par les clients.',
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
                      'Photo',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CompanyPhotoPreview(
                      selectedImage: _selectedImage,
                      imageUrl: widget.company.imageUrl,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _selectedImage == null ? 'Choisir' : 'Changer',
                          ),
                        ),
                        if (_selectedImage != null)
                          OutlinedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() => _selectedImage = null),
                            icon: const Icon(Icons.close),
                            label: const Text('Retirer'),
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
                            value: _isOpen,
                            onChanged: _isSubmitting
                                ? null
                                : (value) => setState(() => _isOpen = value),
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
                        : const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await pickCompanyImage();
      if (pickedImage == null) {
        return;
      }
      if (pickedImage.bytes.length > _maxImageBytes) {
        setState(() {
          _errorMessage = 'La photo doit peser 5 Mo maximum.';
        });
        return;
      }

      setState(() {
        _selectedImage = _SelectedCompanyImage(
          bytes: pickedImage.bytes,
          filename: pickedImage.filename,
          contentType: pickedImage.contentType,
        );
        _errorMessage = null;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Impossible de choisir cette photo.';
      });
    }
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
      var company = await _gateway!.updateCompany(
        widget.company.id,
        CreateCompanyInput(
          name: _nameController.text,
          description: _descriptionController.text,
          imageUrl: widget.company.imageUrl,
          currency: _currency,
          businessType: _businessType,
          operationalStatus: _isOpen ? 'OPEN' : 'CLOSED',
          addressLine1: _addressLine1Controller.text,
          addressLine2: _addressLine2Controller.text,
          city: _cityController.text,
          region: _regionController.text,
          postalCode: _postalCodeController.text,
          country: _countryController.text,
        ),
      );

      final selectedImage = _selectedImage;
      if (selectedImage != null) {
        company = await _gateway!.uploadCompanyImage(
          company.id,
          CompanyImageUpload(
            bytes: selectedImage.bytes,
            filename: selectedImage.filename,
            contentType: selectedImage.contentType,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context, company);
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

  String _submitErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'La reponse de modification est illisible.';
    }
    return 'Impossible de modifier l entreprise pour le moment.';
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
    super.dispose();
  }
}

class _CompanyPhotoPreview extends StatelessWidget {
  const _CompanyPhotoPreview({
    required this.selectedImage,
    required this.imageUrl,
  });

  final _SelectedCompanyImage? selectedImage;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final selected = selectedImage;
    final normalizedImageUrl = _absoluteImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: selected != null
            ? Image.memory(selected.bytes, fit: BoxFit.cover)
            : normalizedImageUrl == null
            ? const _CompanyPhotoFallback()
            : Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CompanyPhotoFallback(),
              ),
      ),
    );
  }

  String? _absoluteImageUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme) {
      return trimmed;
    }
    return Uri.parse(
      AppEnvironment.current.apiBaseUrl,
    ).resolveUri(uri).toString();
  }
}

class _CompanyPhotoFallback extends StatelessWidget {
  const _CompanyPhotoFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.storefront_outlined, size: 42)),
    );
  }
}

class _SignedOutEditCompanyCard extends StatelessWidget {
  const _SignedOutEditCompanyCard();

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
              'Vous devez etre connecte pour modifier une entreprise.',
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

class _SelectedCompanyImage {
  const _SelectedCompanyImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
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
