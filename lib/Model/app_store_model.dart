// app_store_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';

class AppStore {
  final String uid;
  final String companyId;
  final String plan;
  final String role;
  final bool active;
  final List<String> warehouseIds;
  final DateTime? planExpiry;

  AppStore({
    required this.uid,
    required this.companyId,
    required this.plan,
    required this.role,
    required this.active,
    required this.warehouseIds,
    this.planExpiry
  });


  AppStore copyWith({
    String? uid,
    String? companyId,
    String? plan,
    String? role,
    bool? active,
    List<String>? warehouseIds,
    DateTime? planExpiry
  }) {
    return AppStore(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      plan: plan ?? this.plan,
      role: role ?? this.role,
      active: active ?? this.active,
      warehouseIds: warehouseIds ?? this.warehouseIds,
      planExpiry: planExpiry ?? this.planExpiry
    );
  }


  factory AppStore.fromMap({
    required String uid,
    required String companyId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> companyData,
  }) {
    final timestamp = companyData[FirestoreConstants.companyPlanExpiryField];
    DateTime? expiryDate;

    // 2. Check if the value is a Firestore Timestamp and convert it.
    if (timestamp is Timestamp) {
      expiryDate = timestamp.toDate();
    }

    return AppStore(
      uid: uid,
      companyId: companyId,
      role: userData[FirestoreConstants.userRoleField],
      plan: companyData[FirestoreConstants.companyPlanField],
      active: userData[FirestoreConstants.activeField],
      warehouseIds: List<String>.from(userData[FirestoreConstants.userWarehousIdsField] ?? []),
      planExpiry: expiryDate
    );
  }

  bool get hasAccess => active && companyId.isNotEmpty;
  bool get isAdmin => role == RoleConstants.adminRole;
  bool get isStaff => role == RoleConstants.staffRole;


  // Convenience for an empty/default state
  static AppStore empty() => AppStore(
    uid: '',
    companyId: '',
    plan: '',
    role: '',
    active: false,
    warehouseIds: [],
    planExpiry: null
  );
}