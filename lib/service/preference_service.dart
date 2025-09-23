import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static SharedPreferences? _prefs;
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userTokenKey = 'user_token';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isLoggedIn => _prefs?.getBool(_isLoggedInKey) ?? false;

  static String? get userToken => _prefs?.getString(_userTokenKey);

  static Future<void> setLoggedIn(bool value, {String? token}) async {
    await _prefs?.setBool(_isLoggedInKey, value);
    if (token != null) {
      await _prefs?.setString(_userTokenKey, token);
    }
    if (kDebugMode) {
      print("Token saved : $isLoggedIn, token $userToken");
    }
  }

  static Future<void> clearAuth() async {
    await _prefs?.remove(_isLoggedInKey);
    await _prefs?.remove(_userTokenKey);
  }
}
