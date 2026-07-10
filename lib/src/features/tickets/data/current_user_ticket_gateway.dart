import '../../../core/api/api_client.dart';

abstract interface class CurrentUserTicketGateway {
  Future<CurrentUserTicketPage> listTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? ticketNumber,
  });

  Future<CurrentUserTicket> cancelTicket(String ticketId);

  Future<CurrentUserTicket> confirmTicketTreatment(String ticketId);
}

class BackendCurrentUserTicketGateway implements CurrentUserTicketGateway {
  const BackendCurrentUserTicketGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CurrentUserTicketPage> listTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? ticketNumber,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }
    if (ticketNumber != null && ticketNumber.trim().isNotEmpty) {
      queryParameters['ticketNumber'] = ticketNumber.trim();
    }

    final response = await _apiClient.get(
      '/api/users/me/tickets',
      queryParameters: queryParameters,
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid current user tickets payload.');
    }

    return CurrentUserTicketPage.fromJson(response);
  }

  @override
  Future<CurrentUserTicket> cancelTicket(String ticketId) async {
    final response = await _apiClient.patch(
      '/api/users/me/tickets/${ticketId.trim()}/cancel',
    );
    return _parseTicket(response);
  }

  @override
  Future<CurrentUserTicket> confirmTicketTreatment(String ticketId) async {
    final response = await _apiClient.patch(
      '/api/users/me/tickets/${ticketId.trim()}/confirm-treatment',
    );
    return _parseTicket(response);
  }

  CurrentUserTicket _parseTicket(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid current user ticket payload.');
    }

    return CurrentUserTicket.fromJson(response);
  }
}

class CurrentUserTicketPage {
  const CurrentUserTicketPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory CurrentUserTicketPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return CurrentUserTicketPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CurrentUserTicket.fromJson)
                .toList(growable: false)
          : const [],
      page: json['page'] as int,
      size: json['size'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<CurrentUserTicket> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
}

class CurrentUserTicket {
  const CurrentUserTicket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.companyId,
    required this.companyName,
    required this.serviceUnitId,
    required this.serviceUnitName,
    required this.locationId,
    required this.locationName,
    required this.locationDefault,
    required this.status,
    required this.currency,
    required this.totalAmount,
    required this.lines,
    required this.createdAt,
    this.customerPhone,
    this.notes,
    this.updatedAt,
    this.closedAt,
  });

  factory CurrentUserTicket.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];

    return CurrentUserTicket(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      userId: json['userId'] as String,
      customerPhone: json['customerPhone'] as String?,
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      serviceUnitId: json['serviceUnitId'] as String,
      serviceUnitName: json['serviceUnitName'] as String? ?? '',
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String? ?? '',
      locationDefault: json['locationDefault'] as bool? ?? false,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      currency: json['currency'] as String,
      totalAmount: json['totalAmount'] as num,
      lines: rawLines is List
          ? rawLines
                .whereType<Map<String, dynamic>>()
                .map(CurrentUserTicketLine.fromJson)
                .toList(growable: false)
          : const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: _parseDateTime(json['updatedAt']),
      closedAt: _parseDateTime(json['closedAt']),
    );
  }

  final String id;
  final String ticketNumber;
  final String userId;
  final String? customerPhone;
  final String companyId;
  final String companyName;
  final String serviceUnitId;
  final String serviceUnitName;
  final String locationId;
  final String locationName;
  final bool locationDefault;
  final String status;
  final String? notes;
  final String currency;
  final num totalAmount;
  final List<CurrentUserTicketLine> lines;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  String get totalLabel => '${totalAmount.toStringAsFixed(2)} $currency';

  CurrentUserTicket copyWith({String? status}) {
    return CurrentUserTicket(
      id: id,
      ticketNumber: ticketNumber,
      userId: userId,
      customerPhone: customerPhone,
      companyId: companyId,
      companyName: companyName,
      serviceUnitId: serviceUnitId,
      serviceUnitName: serviceUnitName,
      locationId: locationId,
      locationName: locationName,
      locationDefault: locationDefault,
      status: status ?? this.status,
      notes: notes,
      currency: currency,
      totalAmount: totalAmount,
      lines: lines,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }
}

class CurrentUserTicketLine {
  const CurrentUserTicketLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPriceAmount,
    required this.lineTotalAmount,
    this.notes,
    this.itemImageUrl,
  });

  factory CurrentUserTicketLine.fromJson(Map<String, dynamic> json) {
    return CurrentUserTicketLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String? ?? '',
      itemImageUrl: json['itemImageUrl'] as String?,
      quantity: json['quantity'] as int,
      unitPriceAmount: json['unitPriceAmount'] as num,
      lineTotalAmount: json['lineTotalAmount'] as num,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String itemId;
  final String itemName;
  final String? itemImageUrl;
  final int quantity;
  final num unitPriceAmount;
  final num lineTotalAmount;
  final String? notes;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
