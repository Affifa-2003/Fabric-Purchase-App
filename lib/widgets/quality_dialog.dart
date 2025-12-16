// Create a new file: quality_dialog.dart
import 'package:flutter/material.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/service/quality_service.dart';

class QualityDialog extends StatefulWidget {
  final String? initialProduct;
  final String? initialQuality;
  final bool isEditMode;
  final List<Map<String, dynamic>>? activeProducts;

  const QualityDialog({
    Key? key,
    this.initialProduct,
    this.initialQuality,
    this.isEditMode = false,
    this.activeProducts,
  }) : super(key: key);

  @override
  _QualityDialogState createState() => _QualityDialogState();
}

class _QualityDialogState extends State<QualityDialog> {
  TextEditingController qualityController = TextEditingController();
  TextEditingController productController = TextEditingController();
  String? selectedProductValue;
  bool _showProductField = true; // Always show product field

  @override
  void initState() {
    super.initState();
    
    // Initialize quality field
    if (widget.isEditMode && widget.initialQuality != null) {
      qualityController.text = widget.initialQuality!;
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
    productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and close button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEditMode ? 'Edit Quality' : 'Add Quality',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close, color: Color(0xFF767676)),
                ),
              ],
            ),
          ),

          // Horizontal divider
          const Divider(color: Color(0xFFE5E7EB), thickness: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name Field (always show as dropdown)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Product Name: *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Always show dropdown, but disable when no products
                      DropdownButtonFormField<String>(
                        value: selectedProductValue,
                        decoration: InputDecoration(
                          hintText: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                              ? 'Select a product'
                              : 'No products available',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                              ? Colors.white
                              : Colors.grey[100],
                        ),
                        items: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                            ? widget.activeProducts!.map((product) {
                                return DropdownMenuItem<String>(
                                  value: product['name'],
                                  child: Text(product['name']),
                                );
                              }).toList()
                            : [], // Empty list when no products
                        onChanged: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                            ? (value) {
                                setState(() {
                                  selectedProductValue = value;
                                });
                              }
                            : null, // Disable when no products
                        isExpanded: true,
                        icon: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                            ? const Icon(Icons.arrow_drop_down)
                            : null, // Hide dropdown icon when disabled
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quality Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Quality: *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: qualityController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'e.g., Poly Cotton',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Information text with icon in a box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3182CE)),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF3182CE),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This will be added to master and available for future orders.',
                          style: TextStyle(color: Color(0xFF3182CE)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal divider
          const Divider(color: Color(0xFFE5E7EB), thickness: 1),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                          ? const Color(0xFF10B981)
                          : Colors.grey[400], // Grey out button when no products
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                          ? () async {
                              // Get product name from dropdown
                              String productName = selectedProductValue ?? '';
                              
                              // Validate required fields
                              if (productName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a product'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (qualityController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quality is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Return the quality data to caller
                              Navigator.pop(context, {
                                'product': productName,
                                'quality': qualityController.text.trim(),
                              });
                            }
                          : null, // Disable button when no products
                      child: const Text(
                        'Save to Master',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}