import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';

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
  
  // Error state
  bool _nameError = false;

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
            Helpers.buildDialogHeader(
              widget.isEditMode
                  ? 'Edit Order Form Type'
                  : 'Add Order Form Type',
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
                    // Name Field
                    Helpers.buildFormField(
                      title: 'Name: *',
                      child: TextField(
                        controller: nameController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. Plain, Printed',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _nameError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _nameError
                              ? 'Name is required'
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

                    // Is Plain Mixed Field
                    Helpers.buildFormField(
                      title: 'Is Plain Mixed:',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          ? 'This will update order form type in master and all associated records.'
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
                });

                if (_nameError) {
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
            ),
          ],
        ),
      ),
    );
  }
}