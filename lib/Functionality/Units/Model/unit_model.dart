//unit_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


/// A data model representing a Unit document in Firestore.
class Unit {
  final String id;
  final String name;
  final String symbol;
  final bool active;

  Unit({required this.id, required this.name, required this.symbol,required this.active,});

  /// Factory method to convert Firestore DocumentSnapshot into a Unit object.
  factory Unit.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Unit(
      id: doc.id,
      name: data[FirestoreConstants.nameField] ?? '',
      symbol: data[FirestoreConstants.symbolField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }


  /// Converts the Unit object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.nameField: name,
      FirestoreConstants.symbolField: symbol.toUpperCase(),
      FirestoreConstants.activeField: active
    };
  }


  // Add copyWith for easier state updates in forms/editing
  Unit copyWith({
    String? id,
    String? name,
    String? symbol,
    bool? active,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      active: active ?? this.active,
    );
  }
}