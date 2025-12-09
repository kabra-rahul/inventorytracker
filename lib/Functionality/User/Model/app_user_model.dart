//app_user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';

class AppUser {
  final String id;
  final String userName;
  final String mobile;
  final String email;
  final String role;
  final List<String> warehouseIds;
  final bool active;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.userName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.warehouseIds,
    required this.active,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      userName: data[FirestoreConstants.userNameField] ?? '',
      mobile: data[FirestoreConstants.userMobileField] ?? '',
      email: data[FirestoreConstants.userEmailField] ?? '',
      role: data[FirestoreConstants.userRoleField] ?? RoleConstants.staffRole,
      warehouseIds: List<String>.from(data[FirestoreConstants.userWarehousIdsField] ?? []),
      active: data[FirestoreConstants.activeField] ?? true,
      createdAt: (data[FirestoreConstants.userCreatedOnField] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.userNameField: userName,
      FirestoreConstants.userMobileField: mobile,
      FirestoreConstants.userEmailField: email,
      FirestoreConstants.userRoleField: role,
      FirestoreConstants.userWarehousIdsField: warehouseIds,
      FirestoreConstants.activeField: active,
      FirestoreConstants.userCreatedOnField: createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }


  // Add copyWith for easier state updates in forms/editing
  AppUser copyWith({
    String? id,
    String? userName,
    String? mobile,
    String? email,
    String? role,
    List<String>? warehouseIds,
    bool? active,
    DateTime? createdAt
  }) {
    return AppUser(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      warehouseIds: warehouseIds ?? this.warehouseIds,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
