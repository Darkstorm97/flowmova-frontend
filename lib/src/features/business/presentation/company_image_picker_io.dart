import 'package:file_picker/file_picker.dart';

import 'company_image_pick_result.dart';

Future<CompanyImagePickResult?> pickCompanyImage() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    withData: true,
  );
  final file = result?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null) {
    return null;
  }

  return CompanyImagePickResult(
    bytes: bytes,
    filename: file.name,
    contentType: _contentTypeFor(file.name),
  );
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
