//client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

/// A data model representing a Client document in Firestore.
class Client {
  final String id;
  final String companyName;
  final String address;
  final String gst;
  final bool active;

  Client({required this.id, required this.companyName, required this.address, required this.gst, required this.active});

  /// Factory method to convert Firestore DocumentSnapshot into a Client object.
  factory Client.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Client(
      id: doc.id,
      companyName: data[FirestoreConstants.companyNameField] ?? '',
      address: data[FirestoreConstants.companyAddressField] ?? '',
      gst: data[FirestoreConstants.companyGstField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }

  /// Converts the Client object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.companyNameField: companyName.toUpperCase(),
      FirestoreConstants.companyAddressField: address,
      FirestoreConstants.companyGstField : gst.toUpperCase(),
      FirestoreConstants.activeField: active
    };
  }

  // Add copyWith for easier state updates in forms/editing
  Client copyWith({
    String? id,
    String? companyName,
    String? address,
    String? gst,
    bool? active,
  }) {
    return Client(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      gst: gst ?? this.gst,
      active: active ?? this.active,
    );
  }
}