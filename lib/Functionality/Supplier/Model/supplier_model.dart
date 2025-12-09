//supplier_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

/// A data model representing a Supplier document in Firestore.
class Supplier {
  final String id;
  final String companyName;
  final String address;
  final String gst;
  final bool active;

  Supplier({required this.id, required this.companyName, required this.address, required this.gst, required this.active});

  /// Factory method to convert Firestore DocumentSnapshot into a Supplier object.
  factory Supplier.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Supplier(
      id: doc.id,
      companyName: data[FirestoreConstants.companyNameField] ?? '',
      address: data[FirestoreConstants.companyAddressField] ?? '',
      gst: data[FirestoreConstants.companyGstField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }

  /// Converts the Supplier object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.companyNameField: companyName.toUpperCase(),
      FirestoreConstants.companyAddressField: address,
      FirestoreConstants.companyGstField : gst.toUpperCase(),
      FirestoreConstants.activeField: active
    };
  }

  // Add copyWith for easier state updates in forms/editing
  Supplier copyWith({
    String? id,
    String? companyName,
    String? address,
    String? gst,
    bool? active,
  }) {
    return Supplier(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      gst: gst ?? this.gst,
      active: active ?? this.active,
    );
  }
}