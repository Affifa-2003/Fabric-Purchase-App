// lib/widgets/add_order_form_type_dialog.dart
import 'package:flutter/material.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class AddOrderFormTypeDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final bool? initialIsPlainMixed;
  final String? initialStatus;
  final bool isEditMode;

  const AddOrderFormTypeDialog({
    Key? key,
    this.initialName,
    this.initialDescription,
    this.initialIsPlainMixed,
    this.initialStatus,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  _AddOrderFormTypeDialogState createState() => _AddOrderFormTypeDialogState();
}

class _AddOrderFormTypeDialogState extends State<AddOrderFormTypeDialog> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isPlainMixed = false;
  String selectedStatus = 'Active'; // Default to Active

  @override
  void initState() {
    super.initState();

    // Initialize name field
    if (widget.isEditMode && widget.initialName != null) {
      nameController.text = widget.initialName!;
    }

    // Initialize description field
    if (widget.isEditMode && widget.initialDescription != null) {
      descriptionController.text = widget.initialDescription!;
    }

    // Initialize isPlainMixed field
    if (widget.isEditMode && widget.initialIsPlainMixed != null) {
      isPlainMixed = widget.initialIsPlainMixed!;
    }

    // Initialize status field
    if (widget.isEditMode && widget.initialStatus != null) {
      selectedStatus = widget.initialStatus!;
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
                    widget.isEditMode
                        ? 'Edit Order Form Type'
                        : 'Add Order Form Type',
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

            // Content with SingleChildScrollView to make it scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Field
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
                                'Name: *',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            inputFormatters: [
                              NoLeadingOrMultipleSpacesFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'e.g. Plain, Printed',
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

                    // Description Field
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
                          const Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Is Plain Mixed Field
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
                          const Text(
                            'Is Plain Mixed:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: isPlainMixed,
                                onChanged: (value) {
                                  setState(() {
                                    isPlainMixed = value;
                                  });
                                },
                                activeColor: const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPlainMixed ? 'Yes' : 'No',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Indicates whether plain items can be mixed with other items',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Field
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
                                'Status: *',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
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
            ),

            // Horizontal divider
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),

            // Buttons - Fixed at bottom
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
                          // Validate required fields
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Name is required'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Return the order form type data to caller
                          Navigator.pop(context, {
                            'name': nameController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'isPlainMixed': isPlainMixed,
                            'status': selectedStatus,
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
      ),
    );
  }
}
