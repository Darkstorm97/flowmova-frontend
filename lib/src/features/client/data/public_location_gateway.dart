import '../../../core/api/api_client.dart';
import 'company_detail_gateway.dart';

abstract interface class PublicLocationGateway {
  Future<PublicLocationAccess> getAccess(String publicAccessSlug);
}

class BackendPublicLocationGateway implements PublicLocationGateway {
  const BackendPublicLocationGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PublicLocationAccess> getAccess(String publicAccessSlug) async {
    final response = await _apiClient.get(
      '/api/public/locations/$publicAccessSlug',
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid public location response payload.');
    }

    return PublicLocationAccess.fromJson(response);
  }
}

class PublicLocationAccess {
  const PublicLocationAccess({
    required this.company,
    required this.serviceUnit,
    required this.location,
    required this.items,
  });

  factory PublicLocationAccess.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    final serviceUnit = json['serviceUnit'];
    final location = json['location'];
    final items = json['items'];

    if (company is! Map<String, dynamic>) {
      throw const FormatException('Invalid public location company payload.');
    }
    if (serviceUnit is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid public location service unit payload.',
      );
    }
    if (location is! Map<String, dynamic>) {
      throw const FormatException('Invalid public location payload.');
    }
    if (items is! List) {
      throw const FormatException('Invalid public location items payload.');
    }

    return PublicLocationAccess(
      company: CompanyDetail.fromJson(company),
      serviceUnit: CompanyServiceUnitItem.fromJson(serviceUnit),
      location: CompanyServiceUnitLocation.fromJson(location),
      items: items
          .whereType<Map<String, dynamic>>()
          .map(CompanyServiceUnitAvailableItem.fromJson)
          .toList(growable: false),
    );
  }

  final CompanyDetail company;
  final CompanyServiceUnitItem serviceUnit;
  final CompanyServiceUnitLocation location;
  final List<CompanyServiceUnitAvailableItem> items;

  bool get canCreateTicket =>
      company.isOperationallyOpen && serviceUnit.status == 'OPEN';
}
