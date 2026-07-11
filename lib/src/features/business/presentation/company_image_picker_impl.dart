import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/flow_mova_colors.dart';
import 'company_image_pick_result.dart';

Future<CompanyImagePickResult?> pickCompanyImage(
  BuildContext context, {
  CompanyImagePickProfile profile = CompanyImagePickProfile.company,
}) async {
  final source = await _pickSource(context);
  if (source == null) {
    return null;
  }

  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 96,
    maxWidth: profile._pickMaxWidth,
  );
  if (picked == null || !context.mounted) {
    return null;
  }

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    maxWidth: profile._outputMaxWidth,
    maxHeight: profile._maxHeight,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92,
    aspectRatio: profile._aspectRatio,
    uiSettings: _uiSettings(context, profile),
  );
  if (cropped == null) {
    return null;
  }

  return CompanyImagePickResult(
    bytes: await cropped.readAsBytes(),
    filename: _filenameFor(profile),
    contentType: 'image/jpeg',
  );
}

Future<ImageSource?> _pickSource(BuildContext context) async {
  if (!_canUseCamera) {
    return ImageSource.gallery;
  }

  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir depuis la galerie'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<PlatformUiSettings> _uiSettings(
  BuildContext context,
  CompanyImagePickProfile profile,
) {
  final title = switch (profile) {
    CompanyImagePickProfile.company => 'Recadrer la photo entreprise',
    CompanyImagePickProfile.catalog => 'Recadrer l\'article',
    CompanyImagePickProfile.avatar => 'Recadrer l\'avatar',
  };

  return [
    AndroidUiSettings(
      toolbarTitle: title,
      toolbarColor: FlowMovaColors.primaryAqua,
      toolbarWidgetColor: FlowMovaColors.white,
      activeControlsWidgetColor: FlowMovaColors.primaryAqua,
      lockAspectRatio: true,
      hideBottomControls: false,
    ),
    IOSUiSettings(
      title: title,
      doneButtonTitle: 'Valider',
      cancelButtonTitle: 'Annuler',
      aspectRatioLockEnabled: true,
      resetAspectRatioEnabled: false,
    ),
    WebUiSettings(
      context: context,
      presentStyle: WebPresentStyle.dialog,
      size: const CropperSize(width: 520, height: 520),
      viewwMode: WebViewMode.mode_1,
      dragMode: WebDragMode.move,
    ),
  ];
}

bool get _canUseCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

String _filenameFor(CompanyImagePickProfile profile) {
  final prefix = switch (profile) {
    CompanyImagePickProfile.company => 'company',
    CompanyImagePickProfile.catalog => 'catalog',
    CompanyImagePickProfile.avatar => 'avatar',
  };
  return 'flowmova-$prefix-${DateTime.now().millisecondsSinceEpoch}.jpg';
}

extension on CompanyImagePickProfile {
  CropAspectRatio get _aspectRatio => switch (this) {
    CompanyImagePickProfile.company => const CropAspectRatio(
      ratioX: 16,
      ratioY: 9,
    ),
    CompanyImagePickProfile.catalog || CompanyImagePickProfile.avatar =>
      const CropAspectRatio(ratioX: 1, ratioY: 1),
  };

  double get _pickMaxWidth => _outputMaxWidth.toDouble();

  int get _outputMaxWidth => switch (this) {
    CompanyImagePickProfile.company => 1920,
    CompanyImagePickProfile.catalog || CompanyImagePickProfile.avatar => 1200,
  };

  int get _maxHeight => switch (this) {
    CompanyImagePickProfile.company => 1080,
    CompanyImagePickProfile.catalog || CompanyImagePickProfile.avatar => 1200,
  };
}
