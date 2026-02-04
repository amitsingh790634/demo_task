import 'package:flutter/material.dart';

import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LoggerService _logger = LoggerService();

  UserData? _userData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  UserData? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initializeAuth() async {
    _logger.appEvent('Initializing authentication state');
    _isLoading = true;
    notifyListeners();

    try {
      // Todo Check if user is logged in
      _isLoggedIn = await _authService.isLoggedIn();

      // Todo Load user data from local storage
      if (_isLoggedIn) {
        _userData = await _authService.getUserData();
        _logger.appEvent('User data loaded from local storage');
      }
    } catch (e) {
      _logger.error('Authentication initialization failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _logger.appEvent('Checking authentication status');
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn && _userData == null) {
        _userData = await _authService.getUserData();
      }
      notifyListeners();
    } catch (e) {
      _logger.error('Failed to check auth status', e);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );

      _userData = response.data;
      _isLoggedIn = true;
      _isLoading = false;

      _logger.appEvent('Login successful', data: {
        'username': username,
        'name': response.data.name,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;

      _logger.error('Login failed in AuthProvider', e);

      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String userName,
    required String password,
    required String mobile,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.register(
        name: name,
        userName: userName,
        password: password,
        mobile: mobile,
        email: email,
      );

      if (success) {
        _isLoading = false;

        _logger.appEvent('Registration successful', data: {
          'username': userName,
          'email': email,
        });

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;

      _logger.error('Registration failed in AuthProvider', e);

      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    _logger.userAction('Logout initiated');

    try {
      await _authService.logout();
      _userData = null;
      _isLoggedIn = false;
      _errorMessage = null;

      _logger.appEvent('Logout completed');
    } catch (e) {
      _logger.error('Logout failed', e);
      _errorMessage = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
