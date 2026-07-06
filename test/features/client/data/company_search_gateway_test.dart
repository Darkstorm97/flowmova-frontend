import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/client/data/company_search_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test(
    'search sends public company filters and maps paginated response',
    () async {
      late Uri capturedUrl;
      final gateway = BackendCompanySearchGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            capturedUrl = request.url;
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'items': [
                      {
                        'id': 'company-1',
                        'name': 'Cafe Flow',
                        'description': 'Coffee and service queue.',
                        'currency': 'CAD',
                        'businessType': 'RESTAURANT',
                        'city': 'Montreal',
                        'region': 'Quebec',
                        'country': 'CA',
                        'status': 'ACTIVE',
                      },
                    ],
                    'page': 1,
                    'size': 10,
                    'totalItems': 12,
                    'totalPages': 2,
                  }),
                ),
              ),
              200,
            );
          }),
        ),
      );

      final result = await gateway.search(
        const CompanySearchQuery(
          text: ' cafe ',
          businessType: 'RESTAURANT',
          city: ' Montreal ',
          region: ' Quebec ',
          country: ' ca ',
          page: 1,
          size: 10,
        ),
      );

      expect(capturedUrl.path, '/api/companies');
      expect(capturedUrl.queryParameters['q'], 'cafe');
      expect(capturedUrl.queryParameters['businessType'], 'RESTAURANT');
      expect(capturedUrl.queryParameters['city'], 'Montreal');
      expect(capturedUrl.queryParameters['region'], 'Quebec');
      expect(capturedUrl.queryParameters['country'], 'ca');
      expect(capturedUrl.queryParameters['page'], '1');
      expect(capturedUrl.queryParameters['size'], '10');
      expect(capturedUrl.queryParameters['sort'], 'name,asc');

      expect(result.items, hasLength(1));
      expect(result.items.single.name, 'Cafe Flow');
      expect(result.items.single.locationLabel, 'Montreal, Quebec, CA');
      expect(result.page, 1);
      expect(result.totalItems, 12);
      expect(result.hasPreviousPage, isTrue);
      expect(result.hasNextPage, isFalse);
    },
  );
}
