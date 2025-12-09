import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class ContactMessage {
  final String userName;
  final String email;
  final String mobile;
  final String message;
  final DateTime messageSentOn;

  ContactMessage({
    required this.userName,
    required this.email,
    required this.mobile,
    required this.message,
    required this.messageSentOn,
  });

  Map<String, dynamic> toMap() => {
    FirestoreConstants.userNameField: userName,
    FirestoreConstants.userEmailField: email,
    FirestoreConstants.userMobileField: mobile,
    FirestoreConstants.messageField: message,
    FirestoreConstants.messageDateField: messageSentOn,
  };
}
