import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/auth_token_store.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final AuthTokenStore _tokens;

  Future<void> login({
    required String username,
    required String password,
  }) =>
      guard(() async {
        final response = await _dio.post(
          '/auth/login',
          data: {'username': username, 'password': password},
        );
        final data = Map<String, dynamic>.from(response.data as Map);
        final token = data['accessToken'] as String?;
        if (token == null || token.isEmpty) {
          throw const ServerException('Сервер не вернул токен доступа.');
        }
        _tokens.setToken(token);
      });

  Future<void> loginAsLibrarian() => login(
        username: 'librarian',
        password: 'librarian123',
      );

  Future<void> loginAsAdmin() => login(
        username: 'admin',
        password: 'admin123',
      );

  void logout() => _tokens.clear();
}
