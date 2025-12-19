import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';

class AddWidthDialog extends StatefulWidget {
  final String? initialWidth;
  final String? initialProduct;
  final String? initialDescription;
  final String? initialStatus;
  final bool isEditMode;
  final List<Map<String, dynamic>>? activeProducts;

  const AddWidthDialog({
    Key? key,
    this.initialWidth,
    this.initialProduct,
    this.initialDescription,
    this.initialStatus,
    this.isEditMode = false,
    this.activeProducts,
  }) : super(key: key);

  @override
  _AddWidthDialogState createState() => _AddWidthDialogState();
}

class _AddWidthDialogState extends State<AddWidthDialog> {
  TextEditingController widthController = TextEditingController();
  TextEditingController productController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? selectedProductValue;
  String selectedStatus = 'Active'; // Default to Active
  bool _showProductField = true; // Always show product field
  
  // Error states
  bool _productError = false;
  bool _widthError = false;

  @override
  void initState() {
    super.initState();

    // Initialize width field
    if (widget.isEditMode && widget.initialWidth != null) {
      // If initialWidth is a string, use it directly
      // If it's a number, convert it to string
      if (widget.initialWidth is String) {
        widthController.text = widget.initialWidth!;
      } else {
        widthController.text = widget.initialWidth?.toString() ?? '';
      }
    }

    // Initialize product field
    if (widget.isEditMode && widget.initialProduct != null) {
      // Set the selected product value
      selectedProductValue = widget.initialProduct;

      // If we're not using dropdown (no active products), set text field
      if (widget.activeProducts == null || widget.activeProducts!.isEmpty) {
        productController.text = widget.initialProduct!;
      }
    }

    // Initialize description field
    if (widget.isEditMode && widget.initialDescription != null) {
      descriptionController.text = widget.initialDescription!;
    }

    // Initialize status field
    if (widget.isEditMode && widget.initialStatus != null) {
      selectedStatus = widget.initialStatus!;
    }
  }

  @override
  void dispose() {
    widthController.dispose();
    productController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Set constraints to make dialog responsive
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Helpers.buildDialogHeader(
              widget.isEditMode ? 'Edit Width' : 'Add Width',
              context,
            ),

            // Horizontal divider
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),

            // Content with SingleChildScrollView to make it scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name Field (always show as dropdown)
                    Helpers.buildFormField(
                      title: 'Product Name: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedProductValue,
                        decoration: InputDecoration(
                          hintText:
                              widget.activeProducts != null &&
                                  widget.activeProducts!.isNotEmpty
                              ? 'Select a product'
                              : 'No products available',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _productError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _productError
                              ? 'Please select a product'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor:
                              widget.activeProducts != null &&
                                  widget.activeProducts!.isNotEmpty
                              ? Colors.white
                              : Colors.grey[100],
                        ),
                        items:
                            widget.activeProducts != null &&
                                widget.activeProducts!.isNotEmpty
                            ? widget.activeProducts!.map((product) {
                                return DropdownMenuItem<String>(
                                  value: product['name'],
                                  child: Text(product['name']),
                                );
                              }).toList()
                            : [], // Empty list when no products
                        onChanged:
                            widget.activeProducts != null &&
                                widget.activeProducts!.isNotEmpty
                            ? (value) {
                                setState(() {
                                  selectedProductValue = value;
                                  _productError = false;
                                });
                              }
                            : null, // Disable when no products
                        isExpanded: true,
                        icon:
                            widget.activeProducts != null &&
                                widget.activeProducts!.isNotEmpty
                            ? const Icon(Icons.arrow_drop_down)
                            : null, // Hide dropdown icon when disabled
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Width Field
                    Helpers.buildFormField(
                      title: 'Width (in inches): *',
                      child: TextField(
                        controller: widthController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number, // Only allow integers
                        decoration: InputDecoration(
                          hintText: 'e.g. 72',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _widthError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _widthError
                              ? 'Width is required'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _widthError = value.trim().isEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    Helpers.buildFormField(
                      title: 'Description:',
                      child: TextField(
                        controller: descriptionController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter description (optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Field
                    Helpers.buildFormField(
                      title: 'Status: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information text with icon in a box
                    Helpers.buildInfoBox(
                      widget.isEditMode
                          ? 'This will update width in master and all associated records.'
                          : 'This will be added to master and available for future orders.',
                      isEditing: widget.isEditMode,
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal divider
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),

            // Buttons - Fixed at bottom
            Helpers.buildDialogActions(
              context,
              widget.isEditMode,
              () async {
                // Get product name from dropdown
                String productName = selectedProductValue ?? '';

                // Validate required fields
                setState(() {
                  _productError = productName.isEmpty;
                  _widthError = widthController.text.trim().isEmpty;
                });

                if (_productError || _widthError) {
                  return;
                }

                // Parse width value as integer
                int? widthValue = int.tryParse(
                  widthController.text.trim(),
                );
                if (widthValue == null) {
                  setState(() {
                    _widthError = true;
                  });
                  Helpers.showErrorSnackBar(
                    context,
                    'Please enter a valid width value',
                  );
                  return;
                }

                // Return the width data to caller
                Navigator.pop(context, {
                  'product': productName,
                  'width': widthValue, // This is now an integer
                  'description': descriptionController.text.trim(),
                  'status': selectedStatus,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}