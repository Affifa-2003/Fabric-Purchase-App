import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class AddWidthDialog extends StatefulWidget {
  final String? initialWidth;
  final bool isEditMode;
  final List<Map<String, dynamic>>? activeProducts;

  const AddWidthDialog({
    Key? key,
    this.initialWidth,
    this.isEditMode = false,
    this.activeProducts,
  }) : super(key: key);

  @override
  _AddWidthDialogState createState() => _AddWidthDialogState();
}

class _AddWidthDialogState extends State<AddWidthDialog> {
  TextEditingController widthController = TextEditingController();
  TextEditingController productController = TextEditingController();
  String? selectedProductValue;
  bool _showProductField = true; // Always show product field

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      widthController.text = widget.initialWidth?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    widthController.dispose();
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
                  widget.isEditMode ? 'Edit Width' : 'Add Width',
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
                // Product Name Field (always show)
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
                      // Show dropdown if products are provided, otherwise show text field
                      widget.activeProducts != null && widget.activeProducts!.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: selectedProductValue,
                              decoration: const InputDecoration(
                                hintText: 'Select a product',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: widget.activeProducts!.map((product) {
                                return DropdownMenuItem<String>(
                                  value: product['name'],
                                  child: Text(product['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedProductValue = value;
                                });
                              },
                            )
                          : TextField(
                              controller: productController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter product name',
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
                
                // Width Field
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
                            'Width (in inches): *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: widthController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 72',
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
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        // Get product name from dropdown or text field
                        String productName = selectedProductValue ?? 
                                       (widget.activeProducts != null && widget.activeProducts!.isNotEmpty 
                                           ? '' 
                                           : productController.text.trim());
                        
                        // Validate required fields
                        if (productName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a product name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (widthController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Width is required'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Parse width value
                        double? widthValue = double.tryParse(widthController.text.trim());
                        if (widthValue == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid width value'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Return the width data to caller
                        Navigator.pop(context, {
                          'product': productName,
                          'width': widthValue,
                        });
                      },
                      child: Text(
                        widget.isEditMode ? 'Update' : 'Save to Master',
                        style: const TextStyle(
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