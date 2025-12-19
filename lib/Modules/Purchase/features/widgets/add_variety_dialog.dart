import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';

class AddVarietyDialog extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? initialVariety;
  final List<Map<String, dynamic>> products;

  const AddVarietyDialog({
    Key? key,
    this.isEditMode = false,
    this.initialVariety,
    required this.products,
  }) : super(key: key);

  @override
  _AddVarietyDialogState createState() => _AddVarietyDialogState();
}

class _AddVarietyDialogState extends State<AddVarietyDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  String? selectedProduct;
  String statusValue = 'Active';

  // Error states
  bool _nameError = false;
  bool _productError = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController(
      text: widget.isEditMode ? widget.initialVariety!['name'] : '',
    );
    descriptionController = TextEditingController(
      text: widget.isEditMode
          ? widget.initialVariety!['description'] ?? ''
          : '',
    );

    // Initialize product and status values
    if (widget.isEditMode) {
      selectedProduct = widget.initialVariety!['productName'];
      statusValue = widget.initialVariety!['status'];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              widget.isEditMode ? 'Edit Variety' : 'Add Variety',
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
                    // Variety Name Field
                    Helpers.buildFormField(
                      title: 'Variety Name: *',
                      child: TextField(
                        controller: nameController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. Cotton Variety',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _nameError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _nameError
                              ? 'Variety name is required'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nameError = value.trim().isEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Name Field - Standard Dropdown
                    Helpers.buildFormField(
                      title: 'Product Name: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedProduct,
                        hint: const Text('Select a product'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _productError
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          errorText: _productError
                              ? 'Product name is required'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: widget.products.isEmpty
                            ? []
                            : widget.products
                                  .map(
                                    (product) => DropdownMenuItem<String>(
                                      value: product['name'],
                                      child: Text(product['name']),
                                    ),
                                  )
                                  .toList(),
                        onChanged: widget.products.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  selectedProduct = value;
                                  _productError = false;
                                });
                              },
                        disabledHint: const Text('No products available'),
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
                          hintText: 'Optional variety description',
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
                        value: statusValue,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['Active', 'Inactive']
                            .map(
                              (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            statusValue = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information text with icon in a box
                    Helpers.buildInfoBox(
                      widget.isEditMode
                          ? 'This will update variety in master and all associated records.'
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
                // Validate required fields
                setState(() {
                  _nameError = nameController.text.trim().isEmpty;
                  _productError = selectedProduct == null || selectedProduct!.isEmpty;
                });

                if (_nameError || _productError) {
                  return;
                }

                // Create variety object
                final varietyData = {
                  'name': nameController.text.trim(),
                  'productName': selectedProduct,
                  'description': descriptionController.text.trim(),
                  'status': statusValue,
                };

                // Return the variety data to caller
                Navigator.pop(context, varietyData);
              },
            ),
          ],
        ),
      ),
    );
  }
}