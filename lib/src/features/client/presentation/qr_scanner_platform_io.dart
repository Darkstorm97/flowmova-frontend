import 'dart:io';

bool get canUseQrCameraScanner {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}
