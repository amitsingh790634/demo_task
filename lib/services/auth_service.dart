import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_model.dart';
import 'dio_logging_interceptor.dart';
import 'logger_service.dart';

class AuthService {
  static const String _baseUrl = 'https://sptect.runasp.net/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  final LoggerService _logger = LoggerService();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _preferences;

  AuthService() {
    _dio.interceptors.add(DioLoggingInterceptor());
    _logger.appEvent('AuthService initialized');
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final startTime = DateTime.now();

    try {
      _logger.userAction('Login attempt', data: {
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _dio.post(
        '/Auth/login',
        data: loginRequest.toJson(),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        // Store tokens in secure storage
        await _secureStorage.write(
          key: _accessTokenKey,
          value: loginResponse.accessToken,
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: loginResponse.refreshToken,
        );

        // Todo Store user data in shared preferences (as JSON string)
        final userDataJson = jsonEncode({
          'name': loginResponse.data.name,
          'userName': loginResponse.data.userName,
          'mobile': loginResponse.data.mobile,
          'email': loginResponse.data.email,
        });

        await _preferences.setString(_userDataKey, userDataJson);
        await _preferences.setBool(_isLoggedInKey, true);

        _logger.authentication('Login successful', data: {
          'username': username,
          'name': loginResponse.data.name,
          'email': loginResponse.data.email,
          'duration': '${duration.inMilliseconds}ms',
          'timestamp': DateTime.now().toIso8601String(),
        });

        return loginResponse;
      } else {
        throw AuthException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Login failed - DioException', e);
      _logger.authentication('Login failed', data: {
        'username': username,
        'statusCode': e.response?.statusCode,
        'error': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      throw AuthException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.error('Login failed - General exception', e);
      throw AuthException(message: 'An unexpected error occurred: $e');
    }
  }

  Future<bool> register({
    required String name,
    required String userName,
    required String password,
    required String mobile,
    required String email,
  }) async {
    try {
      _logger.userAction('Registration attempt', data: {
        'username': userName,
        'email': email,
        'mobile': mobile,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final registerRequest = RegisterRequest(
        name: name,
        userName: userName,
        password: password,
        mobile: mobile,
        email: email,
      );

      final response = await _dio.post(
        '/Auth/register',
        data: registerRequest.toJson(),
      );

      if (response.statusCode == 200) {
        _logger.authentication('Registration successful', data: {
          'username': userName,
          'email': email,
          'name': name,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true;
      } else {
        throw AuthException(
          message: response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Registration failed - DioException', e);
      _logger.authentication('Registration failed', data: {
        'username': userName,
        'email': email,
        'statusCode': e.response?.statusCode,
        'error': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      throw AuthException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.error('Registration failed - General exception', e);
      throw AuthException(message: 'An unexpected error occurred: $e');
    }
  }

  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    _logger.debug('Access token retrieved: ${token?.substring(0, 20)}...');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final token = await _secureStorage.read(key: _refreshTokenKey);
    _logger.debug('Refresh token retrieved');
    return token;
  }

  Future<bool> isTokenExpired(String token) async {
    try {
      final isExpired = JwtDecoder.isExpired(token);
      _logger
          .debug('Token expiration check: ${isExpired ? 'Expired' : 'Valid'}');
      return isExpired;
    } catch (e) {
      _logger.error('Token expiration check failed', e);
      return true;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) {
      _logger.debug('User not logged in - No token found');
      return false;
    }
    final isValid = !await isTokenExpired(token);
    _logger.debug('User login status: $isValid');
    return isValid;
  }

  Future<UserData?> getUserData() async {
    try {
      final userDataJson = _preferences.getString(_userDataKey);
      if (userDataJson == null) {
        _logger.debug('No user data found in local storage');
        return null;
      }

      final userData = UserData.fromJson(jsonDecode(userDataJson));
      _logger.debug('User data retrieved from local storage: ${userData.name}');
      return userData;
    } catch (e) {
      _logger.error('Failed to retrieve user data from local storage', e);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      _logger.userAction('Logout initiated');

      // Todo Clear secure storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      // Todo Clear shared preferences
      await _preferences.remove(_userDataKey);
      await _preferences.remove(_isLoggedInKey);

      _logger.authentication('Logout successful', data: {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('Logout failed', e);
      rethrow;
    }
  }

  Future<bool> hasUserData() async {
    return _preferences.containsKey(_userDataKey);
  }

  Future<bool> isUserLoggedIn() async {
    return _preferences.getBool(_isLoggedInKey) ?? false;
  }
}
