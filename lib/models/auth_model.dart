class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String name;
  final String userName;
  final String password;
  final String mobile;
  final String email;

  RegisterRequest({
    required this.name,
    required this.userName,
    required this.password,
    required this.mobile,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userName': userName,
      'password': password,
      'mobile': mobile,
      'email': email,
    };
  }
}

class LoginResponse {
  final int statusCode;
  final String accessToken;
  final String refreshToken;
  final UserData data;

  LoginResponse({
    required this.statusCode,
    required this.accessToken,
    required this.refreshToken,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      statusCode: json['statusCode'] ?? 0,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      data: UserData.fromJson(json['data'] ?? {}),
    );
  }
}

class UserData {
  final String name;
  final String userName;
  final String mobile;
  final String email;

  UserData({
    required this.name,
    required this.userName,
    required this.mobile,
    required this.email,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      userName: json['userName'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
