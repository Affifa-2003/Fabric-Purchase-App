import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';

class AddProductDialog extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? initialProduct;

  const AddProductDialog({
    Key? key,
    this.isEditMode = false,
    this.initialProduct,
  }) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late TextEditingController nameController;
  late TextEditingController consumptionController;
  late TextEditingController descriptionController;
  String statusValue = 'Active';

  // Error states
  bool _nameError = false;
  bool _consumptionError = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController(
      text: widget.isEditMode ? widget.initialProduct!['name'] : '',
    );
    consumptionController = TextEditingController(
      text: widget.isEditMode
          ? widget.initialProduct!['consumption'].toString()
          : '',
    );
    descriptionController = TextEditingController(
      text: widget.isEditMode
          ? widget.initialProduct!['description'] ?? ''
          : '',
    );

    // Initialize status value
    if (widget.isEditMode) {
      statusValue = widget.initialProduct!['status'];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    consumptionController.dispose();
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
              widget.isEditMode ? 'Edit Product' : 'Add Product',
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
                    // Product Name Field
                    Helpers.buildFormField(
                      title: 'Product Name: *',
                      child: TextField(
                        controller: nameController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. Cotton Shirt',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _nameError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _nameError
                              ? 'Product name is required'
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

                    // Consumption Meter Field
                    Helpers.buildFormField(
                      title: 'Consumption Meter: *',
                      child: TextField(
                        controller: consumptionController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1.5',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _consumptionError
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          errorText: _consumptionError
                              ? 'Consumption meter is required'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _consumptionError = value.trim().isEmpty;
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
                          hintText: 'Optional product description',
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
                          ? 'This will update product in master and all associated records.'
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
                  _consumptionError = consumptionController.text
                      .trim()
                      .isEmpty;
                });

                if (_nameError || _consumptionError) {
                  return;
                }

                // Parse consumption value
                double? consumption = double.tryParse(
                  consumptionController.text.trim(),
                );
                if (consumption == null) {
                  setState(() {
                    _consumptionError = true;
                  });
                  Helpers.showErrorSnackBar(
                    context,
                    'Please enter a valid consumption value',
                  );
                  return;
                }

                // Create product object
                final productData = {
                  'name': nameController.text.trim(),
                  'consumption': consumption,
                  'description': descriptionController.text.trim(),
                  'status': statusValue,
                };

                // Return product data to caller
                Navigator.pop(context, productData);
              },
            ),
          ],
        ),
      ),
    );
  }
}