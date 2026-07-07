import '../../../core/api/api_client.dart';

abstract interface class TicketLookupGateway {
  Future<PublicTicket> getGuestTicket({
    required String ticketNumber,
    required String accessCode,
  });
}

class BackendTicketLookupGateway implements TicketLookupGateway {
  const BackendTicketLookupGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PublicTicket> getGuestTicket({
    required String ticketNumber,
    required String accessCode,
  }) async {
    final response = await _apiClient.post(
      '/api/tickets/guest-access',
      body: {
        'ticketNumber': ticketNumber.trim(),
        'accessCode': accessCode.trim(),
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid ticket lookup response payload.');
    }

    return PublicTicket.fromJson(response);
  }
}

class PublicTicket {
  const PublicTicket({
    required this.ticketNumber,
    required this.serviceUnitId,
    required this.locationId,
    required this.status,
    required this.currency,
    required this.totalAmount,
    required this.lines,
    required this.createdAt,
    this.guestName,
    this.customerPhone,
    this.notes,
    this.updatedAt,
  });

  factory PublicTicket.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];

    return PublicTicket(
      ticketNumber: json['ticketNumber'] as String,
      guestName: json['guestName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      serviceUnitId: json['serviceUnitId'] as String,
      locationId: json['locationId'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      currency: json['currency'] as String,
      totalAmount: json['totalAmount'] as num,
      lines: rawLines is List
          ? rawLines
                .whereType<Map<String, dynamic>>()
                .map(PublicTicketLine.fromJson)
                .toList(growable: false)
          : const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  final String ticketNumber;
  final String? guestName;
  final String? customerPhone;
  final String serviceUnitId;
  final String locationId;
  final String status;
  final String? notes;
  final String currency;
  final num totalAmount;
  final List<PublicTicketLine> lines;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get totalLabel => '${totalAmount.toStringAsFixed(2)} $currency';
}

class PublicTicketLine {
  const PublicTicketLine({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.unitPriceAmount,
    required this.lineTotalAmount,
    this.notes,
  });

  factory PublicTicketLine.fromJson(Map<String, dynamic> json) {
    return PublicTicketLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      quantity: json['quantity'] as int,
      unitPriceAmount: json['unitPriceAmount'] as num,
      lineTotalAmount: json['lineTotalAmount'] as num,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String itemId;
  final int quantity;
  final num unitPriceAmount;
  final num lineTotalAmount;
  final String? notes;
}
