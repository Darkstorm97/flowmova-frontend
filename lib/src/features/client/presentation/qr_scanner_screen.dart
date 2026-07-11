import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import 'qr_public_location_parser.dart';
import 'qr_scanner_platform.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _manualController = TextEditingController();
  late final MobileScannerController? _scannerController = canUseQrCameraScanner
      ? MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
          detectionTimeoutMs: 700,
        )
      : null;

  String? _errorMessage;
  bool _handlingScan = false;

  @override
  Widget build(BuildContext context) {
    final scannerController = _scannerController;

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScannerIntroCard(scannerAvailable: scannerController != null),
                if (scannerController != null) ...[
                  const SizedBox(height: 16),
                  _ScannerPreview(
                    controller: scannerController,
                    onDetect: _handleCapture,
                  ),
                ],
                const SizedBox(height: 16),
                _ManualQrCard(
                  controller: _manualController,
                  onSubmit: _submitManualQr,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(message: _errorMessage!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_handlingScan) {
      return;
    }

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) {
      return;
    }

    _openQrValue(rawValue, fromScanner: true);
  }

  void _submitManualQr() {
    _openQrValue(_manualController.text, fromScanner: false);
  }

  Future<void> _openQrValue(
    String rawValue, {
    required bool fromScanner,
  }) async {
    final slug = publicLocationSlugFromQrValue(rawValue);
    if (slug == null) {
      setState(
        () => _errorMessage = fromScanner
            ? 'Ce QR code ne correspond pas a un emplacement FlowMova.'
            : 'Collez un lien QR FlowMova ou un code emplacement valide.',
      );
      return;
    }

    setState(() {
      _handlingScan = true;
      _errorMessage = null;
    });

    await _scannerController?.stop();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.publicLocationDetail,
      arguments: slug,
    );
  }

  @override
  void dispose() {
    _manualController.dispose();
    unawaited(_scannerController?.dispose());
    super.dispose();
  }
}

class _ScannerIntroCard extends StatelessWidget {
  const _ScannerIntroCard({required this.scannerAvailable});

  final bool scannerAvailable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.white,
        borderRadius: BorderRadius.circular(FlowMovaRadii.large),
        border: Border.all(color: FlowMovaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_scanner_outlined,
                color: FlowMovaColors.primaryAqua,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner un QR code',
                    style: textTheme.titleLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scannerAvailable
                        ? 'Cadrez le QR code de l emplacement pour ouvrir la commande sur place.'
                        : 'Collez le lien ou le code de l emplacement pour continuer.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerPreview extends StatelessWidget {
  const _ScannerPreview({required this.controller, required this.onDetect});

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FlowMovaRadii.large),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: controller, onDetect: onDetect),
            const _ScannerFrame(),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filledTonal(
                tooltip: 'Activer la lampe',
                onPressed: controller.toggleTorch,
                icon: const Icon(Icons.flashlight_on_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: FlowMovaColors.primaryAqua.withValues(alpha: 0.55),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(FlowMovaRadii.large),
      ),
      child: Center(
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            border: Border.all(color: FlowMovaColors.white, width: 3),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _ManualQrCard extends StatelessWidget {
  const _ManualQrCard({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.white,
        borderRadius: BorderRadius.circular(FlowMovaRadii.large),
        border: Border.all(color: FlowMovaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Code ou lien QR',
                prefixIcon: const Icon(Icons.link_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Continuer',
                  onPressed: onSubmit,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.qr_code_2_outlined),
              label: const Text('Ouvrir la commande'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FlowMovaRadii.large),
        border: Border.all(color: FlowMovaColors.error.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: FlowMovaColors.error),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
