import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/services/quality_service.dart';

class QualityDialog extends StatefulWidget {
  final String? initialProduct;
  final String? initialQuality;
  final String? initialCode;
  final String? initialDescription;
  final String? initialStatus;
  final bool isEditMode;
  final List<Map<String, dynamic>>? activeProducts;

  const QualityDialog({
    Key? key,
    this.initialProduct,
    this.initialQuality,
    this.initialCode,
    this.initialDescription,
    this.initialStatus,
    this.isEditMode = false,
    this.activeProducts,
  }) : super(key: key);

  @override
  _QualityDialogState createState() => _QualityDialogState();
}

class _QualityDialogState extends State<QualityDialog> {
  TextEditingController qualityController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController productController = TextEditingController();
  String? selectedProductValue;
  String selectedStatus = 'Active'; // Default to Active
  
  // Error states
  bool _productError = false;
  bool _codeError = false;

  @override
  void initState() {
    super.initState();

    // Initialize quality field
    if (widget.isEditMode && widget.initialQuality != null) {
      qualityController.text = widget.initialQuality!;
    }

    // Initialize code field
    if (widget.isEditMode && widget.initialCode != null) {
      codeController.text = widget.initialCode!;
    }

    // Initialize description field
    if (widget.isEditMode && widget.initialDescription != null) {
      descriptionController.text = widget.initialDescription!;
    }

    // Initialize status field
    if (widget.isEditMode && widget.initialStatus != null) {
      selectedStatus = widget.initialStatus!;
    }

    // Initialize product field
    if (widget.isEditMode && widget.initialProduct != null) {
      // Set the selected product value
      selectedProductValue = widget.initialProduct;

      // If we're not using dropdown (no active products), set the text field
      if (widget.activeProducts == null || widget.activeProducts!.isEmpty) {
        productController.text = widget.initialProduct!;
      }
    }
  }

  @override
  void dispose() {
    qualityController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    productController.dispose();
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
              widget.isEditMode ? 'Edit Quality' : 'Add Quality',
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

                    // Code Field
                    Helpers.buildFormField(
                      title: 'Code: *',
                      child: TextField(
                        controller: codeController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter unique quality code',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _codeError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _codeError
                              ? 'Code is required'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _codeError = value.trim().isEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quality Name Field
                    Helpers.buildFormField(
                      title: 'Quality Name:',
                      child: TextField(
                        controller: qualityController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'e.g., Premium, Standard',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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
                          ? 'This will update quality in master and all associated records.'
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
                  _codeError = codeController.text.trim().isEmpty;
                });

                if (_productError || _codeError) {
                  return;
                }

                // Return the quality data to caller
                Navigator.pop(context, {
                  'product': productName,
                  'quality': qualityController.text.trim(),
                  'code': codeController.text.trim(),
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