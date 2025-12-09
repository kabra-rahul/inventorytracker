//warehouse_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

/// A data model representing a Warehouse document in Firestore.
class Warehouse {
  final String id;
  final String name;
  final String location;
  final bool active;

  Warehouse({required this.id, required this.name, required this.location, required this.active,});

  /// Factory method to convert Firestore DocumentSnapshot into a Warehouse object.
  factory Warehouse.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Warehouse(
      id: doc.id,
      name: data[FirestoreConstants.nameField] ?? '',
      location: data[FirestoreConstants.locationField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }

  /// Converts the Warehouse object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.nameField : name.toUpperCase(),
      FirestoreConstants.locationField: location,
      FirestoreConstants.activeField: active
    };
  }

  // Add copyWith for easier state updates in forms/editing
  Warehouse copyWith({
    String? id,
    String? name,
    String? location,
    bool? active,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      active: active ?? this.active,
    );
  }
}