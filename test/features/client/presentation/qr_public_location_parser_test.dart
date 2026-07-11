import 'package:flutter_test/flutter_test.dart';
import 'package:flowmova_frontend/src/features/client/presentation/qr_public_location_parser.dart';

void main() {
  group('publicLocationSlugFromQrValue', () {
    test('accepts a direct slug', () {
      expect(publicLocationSlugFromQrValue('loc-42'), 'loc-42');
    });

    test('accepts app route query links', () {
      expect(
        publicLocationSlugFromQrValue(
          'https://flowmova.test/locations/public?slug=counter-1',
        ),
        'counter-1',
      );
    });

    test('accepts app hash links', () {
      expect(
        publicLocationSlugFromQrValue(
          'https://flowmova.test/#/locations/public?slug=table-7',
        ),
        'table-7',
      );
    });

    test('accepts backend public location links', () {
      expect(
        publicLocationSlugFromQrValue(
          'https://flowmova.test/public/locations/default-qr',
        ),
        'default-qr',
      );
    });

    test('rejects unrelated values', () {
      expect(
        publicLocationSlugFromQrValue('https://example.test/nope'),
        isNull,
      );
      expect(publicLocationSlugFromQrValue('hello world'), isNull);
    });
  });
}
