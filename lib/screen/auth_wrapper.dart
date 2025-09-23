import 'package:esp/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit/auth_cubit.dart';
import '../bloc/state/auth_state.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: AuthCubit()..checkAuthStatus(),
      builder: (context, state) {
        switch (state) {
          case AuthState.splash:
            return SplashScreen();
          case AuthState.authenticated:
            return DashboardScreen();
          case AuthState.unauthenticated:
          case AuthState.loginLoading:
            return LoginScreen();
        }
      },
    );
  }
}