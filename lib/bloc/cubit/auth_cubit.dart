import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../service/preference_service.dart';
import '../state/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState.splash);


  void checkAuthStatus() async {
    // Always show splash for 3 seconds
    await Future.delayed(Duration(seconds: 1));
    if (kDebugMode) {
      print("is user login ${PrefsService.isLoggedIn}");
    }
    if (PrefsService.isLoggedIn) {
      emit(AuthState.authenticated);
    } else {
      emit(AuthState.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthState.loginLoading);

    try {
      // Your retrofit API call here
      // final response = await apiService.login(email, password);

      // Mock API call
      await Future.delayed(Duration(seconds: 1));

      if (email.isNotEmpty && password.isNotEmpty) {
        await PrefsService.setLoggedIn(true, token: 'mock_token_123');
        emit(AuthState.authenticated);
      } else {
        emit(AuthState.unauthenticated);
      }
    } catch (e) {
      emit(AuthState.unauthenticated);
    }
  }

  Future<void> register(String name, String email, String password) async {
    emit(AuthState.loginLoading);

    try {
      await Future.delayed(Duration(seconds: 1));

      if (email.isNotEmpty && password.isNotEmpty) {
        await PrefsService.setLoggedIn(true, token: 'mock_token_123');
        emit(AuthState.authenticated);
      } else {
        emit(AuthState.unauthenticated);
      }
    } catch (e) {
      emit(AuthState.unauthenticated);
    }
  }

  Future<void> logout() async {
    await PrefsService.clearAuth();
    emit(AuthState.unauthenticated);
  }
}