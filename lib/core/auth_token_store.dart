/// Хранит access-токен в памяти процесса (для Authorization).
class AuthTokenStore {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void setToken(String? token) => _accessToken = token;

  void clear() => _accessToken = null;
}
