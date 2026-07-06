import '../../../core/api/api_client.dart';

abstract interface class ProfileGateway {
  Future<UserProfile> getCurrentUserProfile();
}

class BackendProfileGateway implements ProfileGateway {
  const BackendProfileGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<UserProfile> getCurrentUserProfile() async {
    final response = await _apiClient.get('/api/users/me');

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile response payload.');
    }

    return UserProfile.fromJson(response);
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phone,
    this.profilePicture,
    this.preferredLanguage,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      profilePicture: json['profilePicture'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      status: json['status'] as String,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePicture;
  final String? preferredLanguage;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
