import '../../../core/api/api_client.dart';

abstract interface class TicketCreationGateway {
  Future<TicketCreationResult> createTicket(
    String serviceUnitId,
    CreateTicketCommand command,
  );
}

class BackendTicketCreationGateway implements TicketCreationGateway {
  const BackendTicketCreationGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<TicketCreationResult> createTicket(
    String serviceUnitId,
    CreateTicketCommand command,
  ) async {
    final response = await _apiClient.post(
      '/api/service-units/$serviceUnitId/tickets',
      body: command.toJson(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid ticket creation response payload.');
    }

    return TicketCreationResult.fromJson(response);
  }
}

class CreateTicketCommand {
  const CreateTicketCommand({
    required this.locationId,
    this.guestName,
    this.customerPhone,
    this.notes,
    this.lines = const [],
  });

  final String locationId;
  final String? guestName;
  final String? customerPhone;
  final String? notes;
  final List<CreateTicketLineCommand> lines;

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      if (guestName != null && guestName!.trim().isNotEmpty)
        'guestName': guestName!.trim(),
      if (customerPhone != null && customerPhone!.trim().isNotEmpty)
        'customerPhone': customerPhone!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
  }
}

class CreateTicketLineCommand {
  const CreateTicketLineCommand({
    required this.itemId,
    this.quantity = 1,
    this.notes,
  });

  final String itemId;
  final int quantity;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}

class TicketCreationResult {
  const TicketCreationResult({
    required this.id,
    required this.ticketNumber,
    required this.serviceUnitId,
    required this.locationId,
    required this.status,
    required this.currency,
    required this.totalAmount,
    this.accessCode,
    this.guestName,
    this.customerPhone,
  });

  factory TicketCreationResult.fromJson(Map<String, dynamic> json) {
    return TicketCreationResult(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      accessCode: json['accessCode'] as String?,
      guestName: json['guestName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      serviceUnitId: json['serviceUnitId'] as String,
      locationId: json['locationId'] as String,
      status: json['status'] as String,
      currency: json['currency'] as String,
      totalAmount: json['totalAmount'] as num,
    );
  }

  final String id;
  final String ticketNumber;
  final String? accessCode;
  final String? guestName;
  final String? customerPhone;
  final String serviceUnitId;
  final String locationId;
  final String status;
  final String currency;
  final num totalAmount;

  String get totalLabel => '${totalAmount.toStringAsFixed(2)} $currency';
}
