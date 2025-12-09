import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Service/contact_service.dart';

final contactServiceProvider = Provider((ref) => ContactService());