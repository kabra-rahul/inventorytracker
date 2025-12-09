//user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/User/Model/app_user_model.dart';
import '../../../Provider/app_store_provider.dart';
import '../Service/user_service.dart';


final userServiceProvider = FutureProvider<UserService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);

  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty');
  }
  return UserService(companyId: appStore.companyId);
});



/// Warehouse list stream from service
final userListProvider = StreamProvider.autoDispose<List<AppUser>>((ref,) async* {
  final userService = await ref.watch(userServiceProvider.future);
  yield* userService.getUserList();
});



final allUsersMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final usersList = await ref.watch(userListProvider.future);
  return {
          for (var u in usersList) u.id: u.userName
        };
});


/// Provider to hold the Category being edited (if any).
/// - If editing an existing category → holds that Category.
/// - If adding new → holds `null`.
final editUserProvider = StateProvider<AppUser?>((ref) => null);


/// Provider to control whether Inactive Categories should be shown in the UI.
/// - If `true`, UI will include inactive categories in the list.
/// - If `false`, UI will show only active categories.
final showInactiveUsersProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the category list
final userSearchQueryProvider = StateProvider<String>((ref) => '');


final selectedRoleProvider = StateProvider<String?>((ref) => null);


final selectedWarehousesProvider = StateProvider<List<String>>((ref) => []);


// Combined provider for filtered and searched categories
final filteredUserListProvider = Provider.autoDispose<AsyncValue<List<AppUser>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Category>>
  final usersAsync = ref.watch(userListProvider);
  final showDisabled = ref.watch(showInactiveUsersProvider);
  final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();

  return usersAsync.whenData((users) {
    final filtered = users.where((u) => u.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((u) => u.userName.toLowerCase().contains(searchQuery)).toList();
  });
});


final userByIdProvider = FutureProvider.family<AppUser, String> ((ref, userId) async {
  final userService = await ref.watch(userServiceProvider.future);
  return userService.getUserById(userId);
});