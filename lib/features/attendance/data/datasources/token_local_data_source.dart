import 'package:shared_preferences/shared_preferences.dart';

import 'package:injectable/injectable.dart';

abstract class TokenLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
}

const cachedTokenKey = 'auth_token';

@LazySingleton(as: TokenLocalDataSource)
class TokenLocalDataSourceImpl implements TokenLocalDataSource {
  final SharedPreferences sharedPreferences;

  TokenLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getToken() async {
    try {
      return sharedPreferences.getString(cachedTokenKey);
    } catch (e) {
      throw CacheException('Failed to get token');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await sharedPreferences.setString(cachedTokenKey, token);
    } catch (e) {
      throw CacheException('Failed to save token');
    }
  }
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
