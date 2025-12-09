import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/confirmation_dialog.dart';
import 'package:inventorytracker/Shared/Widgets/custom_dropdown_field.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import '../../../Service/user_management_service.dart';
import '../Model/app_user_model.dart';
import '../Provider/user_provider.dart';
import '../Widget/warehouse_checkbox_list.dart';


class UserEditPage extends ConsumerStatefulWidget {

  const UserEditPage({super.key});

  @override
  ConsumerState<UserEditPage> createState() => _UserEditPageState();
}


class _UserEditPageState extends ConsumerState<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  AppUser? _initialUser ;

  bool active = true;

  @override
  void initState() {
    super.initState();

    _initialUser = ref.read(editUserProvider);

    if (_initialUser != null) {
      _nameController.text = _initialUser!.userName;
      _emailController.text = _initialUser!.email;
      _mobileController.text = _initialUser!.mobile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedRoleProvider.notifier).state = _initialUser!.role;
        ref.read(selectedWarehousesProvider.notifier).state = _initialUser!.warehouseIds;
      });
      active = _initialUser!.active;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedRoleProvider.notifier).state = null;
        ref.read(selectedWarehousesProvider.notifier).state = [];
      });
    }
  }


  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);

    final userService = await ref.read(userServiceProvider.future);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    final warehouseIds = ref.read(selectedWarehousesProvider);
    final role = ref.read(selectedRoleProvider);

    if (role == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Please select a role.'), backgroundColor: SnackBarColor.errorMessage)
      );
      return;
    }

    if(!mounted) return;

    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialUser == null ? 'Add User' : 'Update User',
      content:
      _initialUser == null
          ? 'Are you sure you want to add this User?'
          : 'Are you sure you want to update this User?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    final newUser = AppUser(
      id: _initialUser?.id ?? '',
      userName: name,
      mobile: mobile,
      email: email,
      warehouseIds: warehouseIds,
      role: role,
      active: active,
    );

    try {
      if (_initialUser == null) {
        if (_passwordController.text.isEmpty) {
          messenger.showSnackBar(SnackBar(
              content: Text('Password is required for new users.'), backgroundColor: SnackBarColor.errorMessage));
          // Add new product
        }
        await userService.addUser(newUser, _passwordController.text.trim());
        messenger.showSnackBar(SnackBar(content: Text('New User Added'), backgroundColor: SnackBarColor.successMessage,));
      } else {
        if(_initialUser?.email != email) {
          await UserManagementService.updateUserEmail(_initialUser!.id, email);
        }

        if(_initialUser?.userName != name ) {
          await UserManagementService.updateUserDisplayName(_initialUser!.id, name);
        }
        // Update product
        await userService.updateUser(newUser);
        messenger.showSnackBar(SnackBar(content: Text('User Updated'), backgroundColor: SnackBarColor.successMessage,));

        if (active == false && active != _initialUser!.active) {
          await UserManagementService.disableUser(_initialUser!.id);
        } else if(active == true && active != _initialUser!.active) {
          await UserManagementService.enableUser(_initialUser!.id);
        }
      }
      _passwordController.clear();

      if (!mounted) return;

      context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _initialUser != null;
    final selectedRole = ref.read(selectedRoleProvider);
    final selectedWarehouses = ref.watch(selectedWarehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              CustomTextField(
                label: 'Full Name',
                controller: _nameController,
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Mobile Number',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                validator: validateEmail,
              ),
              if (!isEditing) const SizedBox(height: SizeConstants.spaceBetweenFields),
              if (!isEditing)
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: validatePassword,
                ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              WarehouseCheckboxList(selectedWarehousesCount: selectedWarehouses.length),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomDropdownField(
                label: 'Role',
                value: selectedRole,
                hint: 'Choose a role',
                onChanged: (value) => ref.read(selectedRoleProvider.notifier).state = value,
                items: AsyncValue.data(
                  [RoleConstants.adminRole, RoleConstants.staffRole]
                      .map((role) => DropdownItem(id: role, name: role)) // Convert to DropdownItem
                      .toList(),
                ),
              ),
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active'),
                  Switch(
                    value: active,
                    onChanged: (val) {
                      setState(() {
                        active = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomElevatedButton(
          text: isEditing ? 'Update User' : 'Add User',
          onPressed: saveUser
      ),
    );
  }
}