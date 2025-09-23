import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit/auth_cubit.dart';
import '../bloc/state/auth_state.dart';
import '../component/custom_button.dart';
import '../component/custom_text_button.dart';
import '../component/custom_text_field.dart';
import '../router/AppRouter.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    var authCubit = AuthCubit();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocListener<AuthCubit, AuthState>(
        bloc: authCubit,
        listener: (context, state) {
          if (state == AuthState.authenticated) {
            AppRouter.navigateToDashboard(context);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      SizedBox(height: 30),

                      Text(
                        'SmartSip',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your daily water intake and stay hydrated',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Email
                      CustomTextField(
                        title: 'Email',
                        hintText: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(Icons.mail),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),
                      CustomTextField(
                        title: 'Password',
                        hintText: 'Enter your Password',
                        controller: _passwordController,
                        prefixIcon: Icon(Icons.lock),
                        obscureText: true,
                        validator: (value) =>
                        value?.isEmpty == true ? 'Enter password' : null,
                      ),
                      Align(alignment: Alignment.centerRight,child: CustomTextButton(text: 'Forgot password', onPressed: () {  },),),

                      SizedBox(height: 32),

                      // Login Button
                      BlocBuilder<AuthCubit, AuthState>(
                        bloc: authCubit,
                        builder: (context, state) {
                          final isLoading = state == AuthState.loginLoading;
                          return CustomButton(
                            text: "Login",
                            isLoading: isLoading,
                            onPressed: isLoading ? null : (){
                              if (_formKey.currentState?.validate() == true) {
                                authCubit.login(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                              }
                            },
                          );
                        },
                      ),
                      CustomTextButton(text: 'Create account', onPressed: () { Navigator.pushNamed(context, AppRouter.createAccount); },)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}