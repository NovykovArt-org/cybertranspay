import 'dart:convert';

import 'package:cybertranspay/config.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.email,
    required this.localId,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.emailVerified,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        email: json['email'] as String? ?? '',
        localId: json['localId'] as String? ?? '',
        idToken: json['idToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        expiresIn: int.tryParse(json['expiresIn']?.toString() ?? '') ?? 3600,
        emailVerified: json['emailVerified'] as bool? ?? false,
      );

  final String email;
  final String localId;
  final String idToken;
  final String refreshToken;
  final int expiresIn;
  final bool emailVerified;
}

class AuthClient {
  AuthClient({http.Client? client, String? firebaseWebApiKey})
      : _client = client ?? http.Client(),
        _firebaseWebApiKey = firebaseWebApiKey ?? AppConfig.firebaseWebApiKey;

  final http.Client _client;
  final String _firebaseWebApiKey;

  bool get isConfigured => _firebaseWebApiKey.isNotEmpty;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    return _identityRequest(
      'accounts:signInWithPassword',
      {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) {
    return _identityRequest(
      'accounts:signUp',
      {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
  }

  Future<void> sendEmailVerification(String idToken) async {
    await _identityRequest(
      'accounts:sendOobCode',
      {
        'requestType': 'VERIFY_EMAIL',
        'idToken': idToken,
      },
      expectSession: false,
    );
  }

  Future<AuthSession> _identityRequest(
    String method,
    Map<String, dynamic> body, {
    bool expectSession = true,
  }) async {
    if (!isConfigured) {
      throw AuthException(
        'FIREBASE_WEB_API_KEY не задан. Передайте его через --dart-define.',
      );
    }

    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/$method',
      {'key': _firebaseWebApiKey},
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(_firebaseError(payload));
    }

    if (!expectSession) {
      return const AuthSession(
        email: '',
        localId: '',
        idToken: '',
        refreshToken: '',
        expiresIn: 0,
        emailVerified: false,
      );
    }

    return AuthSession.fromJson(payload);
  }

  String _firebaseError(Map<String, dynamic> payload) {
    final error = payload['error'];
    final code = error is Map<String, dynamic>
        ? error['message'] as String? ?? 'UNKNOWN'
        : 'UNKNOWN';

    return switch (code) {
      'EMAIL_EXISTS' => 'Аккаунт с таким email уже существует',
      'EMAIL_NOT_FOUND' => 'Пользователь с таким email не найден',
      'INVALID_PASSWORD' => 'Неверный пароль',
      'INVALID_EMAIL' => 'Некорректный email',
      'WEAK_PASSWORD : Password should be at least 6 characters' =>
        'Пароль должен быть минимум 6 символов',
      'USER_DISABLED' => 'Аккаунт отключен',
      _ => 'Firebase Auth error: $code',
    };
  }
}
