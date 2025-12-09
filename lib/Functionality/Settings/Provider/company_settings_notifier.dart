import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Settings/Provider/settings_provider.dart';
import '../Service/company_service.dart';

class CompanySettingsState {
  final bool isLoading;
  final String? error;
  final String? success;

  const CompanySettingsState({
    this.isLoading = false,
    this.error,
    this.success,
  });

  CompanySettingsState copyWith({
    bool? isLoading,
    String? error,
    String? success,
  }) => CompanySettingsState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    success: success,
  );
}

class CompanySettingsNotifier extends StateNotifier<CompanySettingsState> {
  final CompanyService _svc;
  //final Ref _ref;

  CompanySettingsNotifier(this._svc) : super(const CompanySettingsState());


  Future<String?> update({
    required String companyId,
    required String name,
    required String gst,
    required String address,
    required WidgetRef ref
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: null);
    try {
      await _svc.updateCompany(
        companyId,
        name: name,
        gst: gst,
        address: address,
      );

      ref.invalidate(companyProvider(companyId));

      state = state.copyWith(
        isLoading: false,
        success: 'Company settings saved',
        error: null
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), success: null);
      return e.toString();
    }
  }


  void clearMessages() {
    state = state.copyWith(
      error: null,
      success: null,
      isLoading: false,
    );
  }
}


final companySettingsProvider =
    StateNotifierProvider<CompanySettingsNotifier, CompanySettingsState>(
      (ref) => CompanySettingsNotifier(ref.read(companyServiceProvider)),
    );
