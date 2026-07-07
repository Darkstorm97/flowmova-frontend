import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RecentTicketStorage {
  Future<List<RecentTicketEntry>> load();

  Future<void> save(RecentTicketEntry ticket);

  Future<void> clear();
}

class SharedPreferencesRecentTicketStorage implements RecentTicketStorage {
  const SharedPreferencesRecentTicketStorage(this._preferences);

  static const _storageKey = 'flowmova.recent_tickets.v1';
  static const _maxRecentTickets = 20;

  final SharedPreferences _preferences;

  @override
  Future<List<RecentTicketEntry>> load() async {
    final rawValue = _preferences.getString(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RecentTicketEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> save(RecentTicketEntry ticket) async {
    final existing = await load();
    final next = [
      ticket,
      for (final entry in existing)
        if (entry.id != ticket.id && entry.ticketNumber != ticket.ticketNumber)
          entry,
    ].take(_maxRecentTickets).toList(growable: false);

    await _preferences.setString(
      _storageKey,
      jsonEncode(next.map((entry) => entry.toJson()).toList(growable: false)),
    );
  }

  @override
  Future<void> clear() => _preferences.remove(_storageKey);
}

class InMemoryRecentTicketStorage implements RecentTicketStorage {
  InMemoryRecentTicketStorage([
    List<RecentTicketEntry> initialTickets = const [],
  ]) : _tickets = [...initialTickets];

  final List<RecentTicketEntry> _tickets;

  @override
  Future<List<RecentTicketEntry>> load() async => List.unmodifiable(_tickets);

  @override
  Future<void> save(RecentTicketEntry ticket) async {
    _tickets
      ..removeWhere(
        (entry) =>
            entry.id == ticket.id || entry.ticketNumber == ticket.ticketNumber,
      )
      ..insert(0, ticket);
  }

  @override
  Future<void> clear() async => _tickets.clear();
}

class RecentTicketEntry {
  const RecentTicketEntry({
    required this.id,
    required this.ticketNumber,
    required this.serviceUnitId,
    required this.locationId,
    required this.companyId,
    required this.status,
    required this.createdAt,
    required this.companyName,
    required this.serviceUnitName,
    required this.locationName,
    required this.totalLabel,
    this.accessCode,
    this.guestName,
    this.customerPhone,
    this.items = const [],
  });

  factory RecentTicketEntry.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return RecentTicketEntry(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      accessCode: json['accessCode'] as String?,
      guestName: json['guestName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      serviceUnitId: json['serviceUnitId'] as String,
      locationId: json['locationId'] as String,
      companyId: json['companyId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      companyName: json['companyName'] as String,
      serviceUnitName: json['serviceUnitName'] as String,
      locationName: json['locationName'] as String,
      totalLabel: json['totalLabel'] as String,
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(RecentTicketItemEntry.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String ticketNumber;
  final String? accessCode;
  final String? guestName;
  final String? customerPhone;
  final String serviceUnitId;
  final String locationId;
  final String companyId;
  final String status;
  final DateTime createdAt;
  final String companyName;
  final String serviceUnitName;
  final String locationName;
  final String totalLabel;
  final List<RecentTicketItemEntry> items;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      if (accessCode != null) 'accessCode': accessCode,
      if (guestName != null) 'guestName': guestName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'serviceUnitId': serviceUnitId,
      'locationId': locationId,
      'companyId': companyId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'companyName': companyName,
      'serviceUnitName': serviceUnitName,
      'locationName': locationName,
      'totalLabel': totalLabel,
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  RecentTicketEntry copyWith({
    String? id,
    String? ticketNumber,
    String? accessCode,
    String? guestName,
    String? customerPhone,
    String? serviceUnitId,
    String? locationId,
    String? companyId,
    String? status,
    DateTime? createdAt,
    String? companyName,
    String? serviceUnitName,
    String? locationName,
    String? totalLabel,
    List<RecentTicketItemEntry>? items,
  }) {
    return RecentTicketEntry(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      accessCode: accessCode ?? this.accessCode,
      guestName: guestName ?? this.guestName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceUnitId: serviceUnitId ?? this.serviceUnitId,
      locationId: locationId ?? this.locationId,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      serviceUnitName: serviceUnitName ?? this.serviceUnitName,
      locationName: locationName ?? this.locationName,
      totalLabel: totalLabel ?? this.totalLabel,
      items: items ?? this.items,
    );
  }
}

class RecentTicketItemEntry {
  const RecentTicketItemEntry({
    required this.itemId,
    required this.name,
    required this.quantity,
  });

  factory RecentTicketItemEntry.fromJson(Map<String, dynamic> json) {
    return RecentTicketItemEntry(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
    );
  }

  final String itemId;
  final String name;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'itemId': itemId, 'name': name, 'quantity': quantity};
  }
}
