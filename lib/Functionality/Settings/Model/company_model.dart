import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


/// A data model representing a Company document in Firestore.
class Company {
  final String id;
  final String companyName;
  final String address;
  final String gst;
  final String userId;
  final DateTime createdAt;
  final String plan;
  final DateTime? planExpiry;

  Company({
    required this.id,
    required this.companyName,
    required this.address,
    required this.gst,
    required this.userId,
    required this.createdAt,
    required this.plan,
    this.planExpiry
  });

  /// Factory method to convert Firestore DocumentSnapshot into a Company object.
  factory Company.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data
    return Company(
      id         : doc.id,
      companyName: data[FirestoreConstants.companyNameField] ?? '',
      address    : data[FirestoreConstants.companyAddressField] ?? '',
      gst        : data[FirestoreConstants.companyGstField] ?? '',
      userId     : data[FirestoreConstants.companyCreatedByField] ?? '',
      createdAt  : (data[FirestoreConstants.companyCreatedOnField] as Timestamp?)?.toDate() ?? DateTime.now(),
      plan       : data[FirestoreConstants.companyPlanField] ?? '',
      planExpiry : (data[FirestoreConstants.companyPlanExpiryField] as Timestamp?)?.toDate()
    );
  }

  /// Converts the Company object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.companyNameField       : companyName.toUpperCase(),
      FirestoreConstants.companyAddressField    : address,
      FirestoreConstants.companyGstField        : gst.toUpperCase(),
      FirestoreConstants.companyCreatedByField  : userId,
      FirestoreConstants.companyCreatedOnField  : Timestamp.fromDate(createdAt),
      FirestoreConstants.companyPlanField       : plan,
      FirestoreConstants.companyPlanExpiryField : planExpiry != null ? Timestamp.fromDate(planExpiry!) : null,
    };
  }

  /// Returns a new Company object with the specified properties replaced.
  Company copyWith({
    String? id,
    String? companyName,
    String? address,
    String? gst,
    String? userId,
    DateTime? createdAt,
    String? plan,
    DateTime? planExpiry
  }) {
    return Company(
      id         : id ?? this.id,
      companyName: companyName ?? this.companyName,
      address    : address ?? this.address,
      gst        : gst ?? this.gst,
      userId     : userId ?? this.userId,
      createdAt  : createdAt ?? this.createdAt,
      plan       : plan ?? this.plan,
      planExpiry : planExpiry ?? this.planExpiry
    );
  }
}