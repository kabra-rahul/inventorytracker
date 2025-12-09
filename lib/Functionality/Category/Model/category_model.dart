//category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


/// A data model representing a Category document in Firestore.
class Category {
  final String id;
  final String name;
  final bool active;

  Category({required this.id, required this.name, required this.active,});

  /// Factory method to convert Firestore DocumentSnapshot into a Category object.
  factory Category.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category(
      id: doc.id,
      name: data[FirestoreConstants.nameField] ?? '',
      active: data[FirestoreConstants.activeField] ?? true,
    );
  }


  /// Converts the Category object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.nameField: name.toUpperCase(),
      FirestoreConstants.activeField: active
    };
  }


  // Add copyWith for easier state updates in forms/editing
  Category copyWith({
    String? id,
    String? name,
    bool? active,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}