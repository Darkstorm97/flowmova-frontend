import 'dart:typed_data';

class CompanyImagePickResult {
  const CompanyImagePickResult({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

enum CompanyImagePickProfile { company, catalog, avatar }
