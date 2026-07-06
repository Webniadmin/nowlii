class RegisterRequest {
  final String email;
  final String username;
  final String password;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'username': username,
        'password': password,
      };
}

class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
      };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  final String refresh;
  final String access;
  final UserData user;

  LoginResponse({
    required this.refresh,
    required this.access,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        refresh: json['refresh'],
        access: json['access'],
        user: UserData.fromJson(json['user']),
      );
}

class UserData {
  final int userId;
  final String email;
  final String? username;
  final bool isSuperuser;

  UserData({
    required this.userId,
    required this.email,
    this.username,
    required this.isSuperuser,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        userId: json['user_id'],
        email: json['email'],
        username: json['username'],
        isSuperuser: json['is_superuser'] ?? false,
      );
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyForgotPasswordOtpRequest {
  final String email;
  final String otp;

  VerifyForgotPasswordOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
      };
}

class SetNewPasswordRequest {
  final String email;
  final String newPassword;
  final String confirmPassword;

  SetNewPasswordRequest({
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };
}
