import 'package:flutter/cupertino.dart';

abstract class BaseState {
  const BaseState();
}

class BaseInitState extends BaseState{}

class LoadingState extends BaseState {}

class ErrorState extends BaseState {
  final String? errorMessage;

  const ErrorState({this.errorMessage});
}