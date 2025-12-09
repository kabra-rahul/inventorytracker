import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import '../Model/contact_message_model.dart';

class ContactService {
  final _collection = FirebaseFirestore.instance.collection(FirestoreConstants.contactMessageCollection);

  Future<void> submitMessage(ContactMessage message) async {
    final currUser = FirebaseAuth.instance.currentUser;

    if (currUser == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await currUser.getIdToken(true);

      final docRef = await _collection.add(message.toMap());

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendContactEmail');

      final formattedDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(message.messageSentOn);

      await callable.call({
        'id': docRef.id,
        'userName': message.userName,
        'email': message.email,
        'mobile': message.mobile,
        'message': message.message,
        'messageSentOn': formattedDate,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Server Error [${e.code}]: ${e.message}');

    } catch (e) {
      // Catch network or other errors
      throw Exception('Failed to send mail: $e');
    }
  }
}
