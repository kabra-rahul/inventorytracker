//hsn_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


/// A data model representing a Hsn document in Firestore.
class Hsn {
  final String id;
  final String code;
  final bool active;

  Hsn({required this.id, required this.code, required this.active,});

  /// Factory method to convert Firestore DocumentSnapshot into a Hsn object.
  factory Hsn.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Hsn(
      id: doc.id,
      code: data[FirestoreConstants.codeField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }


  /// Converts the Hsn object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.codeField: code.toUpperCase(),
      FirestoreConstants.activeField: active
    };
  }


  // Add copyWith for easier state updates in forms/editing
  Hsn copyWith({
    String? id,
    String? code,
    bool? active,
  }) {
    return Hsn(
      id: id ?? this.id,
      code: code ?? this.code,
      active: active ?? this.active,
    );
  }
}