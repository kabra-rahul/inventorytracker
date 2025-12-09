// category_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Util/validators.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/category_model.dart';
import '../Provider/category_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation


class CategoryEditPage extends ConsumerStatefulWidget {
  const CategoryEditPage({super.key});

  @override
  ConsumerState<CategoryEditPage> createState() => _CategoryEditPageState();
}


class _CategoryEditPageState extends ConsumerState<CategoryEditPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Category? _initialCategory; // To hold the category being edited


  @override
  void initState() {
    super.initState();
    // Read the initial category when the widget is initialized
    _initialCategory = ref.read(editCategoryProvider);

    if (_initialCategory != null) {
      _nameController.text = _initialCategory!.name;
      _isActive = _initialCategory!.active;
    } else {
      _isActive = true; // Default for new category
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final companyId = ref.read(appStoreProvider).value?.companyId;
    final categoryService = ref.read(categoryServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialCategory == null ? 'Add Category' : 'Update Category',
      content: _initialCategory == null
              ? 'Are you sure you want to add this category?'
              : 'Are you sure you want to update this category?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      final isDuplicate = await categoryService.isDuplicate(
        companyId.toString(),
        name,
        _initialCategory?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(SnackBar(content: Text('Category name already exists!'), backgroundColor: SnackBarColor.errorMessage,));
        return;
      }

      if (_initialCategory == null) {
        // Add new category
        final newCategory = Category(id: '', name: name, active: _isActive);

        await categoryService.addCategory(companyId.toString(), newCategory);

        messenger.showSnackBar(SnackBar(content: Text('Category added successfully!'), backgroundColor: SnackBarColor.successMessage));
      } else {
        final updatedCategory = _initialCategory!.copyWith(name: name, active: _isActive,);

        await categoryService.updateCategory(
          companyId.toString(),
          updatedCategory,
        );

        messenger.showSnackBar(SnackBar(content: Text('Category updated successfully!'), backgroundColor: SnackBarColor.successMessage));
      }

      // Clear selected category
      ref.read(editCategoryProvider.notifier).state = null;

      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error saving category: ${e.toString()}'),backgroundColor: SnackBarColor.errorMessage));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _initialCategory == null ? 'Add Category' : 'Edit Category',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              CustomTextField(
                label: 'Category Name',
                controller: _nameController,
                hintText: 'Enter category name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
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
          text: _initialCategory == null
              ? 'Add Category'
              : 'Update Category',
          onPressed: _saveCategory
      ),
    );
  }
}