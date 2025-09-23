import 'package:esp/base/base_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../service/preference_service.dart';
import '../state/auth_state.dart';
import '../state/dashboard_state.dart';

class DashboardCubit extends Cubit<BaseState> {
  DashboardCubit() : super(BaseInitState());

  Future<void> logout() async {
    await PrefsService.clearAuth();
    emit(LogOutState());
  }
}