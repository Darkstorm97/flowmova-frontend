// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'company_image_pick_result.dart';

Future<CompanyImagePickResult?> pickCompanyImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp'
    ..multiple = false;

  final change = input.onChange.first;
  input.click();
  await change;

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null;
  }

  final bytes = await _readFileBytes(file);
  return CompanyImagePickResult(
    bytes: bytes,
    filename: file.name,
    contentType: file.type.isEmpty ? _contentTypeFor(file.name) : file.type,
  );
}

Future<Uint8List> _readFileBytes(html.File file) {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Unable to read image file.'));
    }
  });
  reader.onLoad.first.then((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(Uint8List.view(result));
    } else if (result is Uint8List) {
      completer.complete(result);
    } else {
      completer.completeError(StateError('Invalid image file result.'));
    }
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
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
