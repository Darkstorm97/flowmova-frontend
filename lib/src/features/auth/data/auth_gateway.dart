import '../../../core/api/api_client.dart';

abstract interface class AuthGateway {
  Future<RegisterUserResult> register(RegisterUserCommand command);

  Future<LoginUserResult> login(LoginUserCommand command);
}

class BackendAuthGateway implements AuthGateway {
  const BackendAuthGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<RegisterUserResult> register(RegisterUserCommand command) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      body: command.toJson(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid register response payload.');
    }

    return RegisterUserResult.fromJson(response);
  }

  @override
  Future<LoginUserResult> login(LoginUserCommand command) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: command.toJson(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response payload.');
    }

    return LoginUserResult.fromJson(response);
  }
}

class RegisterUserCommand {
  const RegisterUserCommand({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
  };
}

class LoginUserCommand {
  const LoginUserCommand({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class RegisterUserResult {
  const RegisterUserResult({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
  });

  factory RegisterUserResult.fromJson(Map<String, dynamic> json) {
    return RegisterUserResult(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String status;
}

class LoginUserResult {
  const LoginUserResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory LoginUserResult.fromJson(Map<String, dynamic> json) {
    return LoginUserResult(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresIn;
}
