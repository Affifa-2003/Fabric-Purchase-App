import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        TextInputFormatter,
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter;
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';

class AddAgentDialog extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? initialAgent;
  final List<Map<String, dynamic>> states;
  final List<Map<String, dynamic>> districts;
  final List<Map<String, dynamic>> grades;

  const AddAgentDialog({
    Key? key,
    this.isEditMode = false,
    this.initialAgent,
    required this.states,
    required this.districts,
    required this.grades,
  }) : super(key: key);

  @override
  _AddAgentDialogState createState() => _AddAgentDialogState();
}

class _AddAgentDialogState extends State<AddAgentDialog> {
  late TextEditingController nameController;
  late TextEditingController codeController;
  late TextEditingController emailController;
  late TextEditingController stateController;
  late TextEditingController cityController;
  List<String> mobileNumbers = ['']; // Start with one empty mobile number field
  List<TextEditingController> mobileControllers = [TextEditingController()];
  String? selectedAgentType;
  // MODIFIED: Changed from selectedGrade to selectedGradeId
  String? selectedGradeId;
  String? selectedStatus = 'Active';

  // Focus nodes for mobile number fields
  List<FocusNode> _mobileFocusNodes = [];

  // Error states
  bool _nameError = false;
  bool _codeError = false;
  List<bool> _mobileErrors = [false];
  List<bool> _mobileDuplicateErrors = [
    false,
  ]; // Added for duplicate mobile validation
  bool _emailError = false;
  bool _emailDuplicateError = false; // Added for duplicate email validation
  bool _agentTypeError = false;
  bool _gradeError = false;
  bool _statusError = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController(
      text: widget.isEditMode ? widget.initialAgent!['name'] : '',
    );
    codeController = TextEditingController(
      text: widget.isEditMode ? widget.initialAgent!['code'] : '',
    );
    emailController = TextEditingController(
      text: widget.isEditMode ? widget.initialAgent!['email'] : '',
    );
    stateController = TextEditingController(
      text: widget.isEditMode ? widget.initialAgent!['state'] ?? '' : '',
    );
    cityController = TextEditingController(
      text: widget.isEditMode ? widget.initialAgent!['city'] ?? '' : '',
    );

    // Initialize mobile numbers
    if (widget.isEditMode) {
      if (widget.initialAgent!['mobileNumbers'] != null &&
          widget.initialAgent!['mobileNumbers'].isNotEmpty) {
        mobileNumbers = List<String>.from(widget.initialAgent!['mobileNumbers']);
        mobileControllers = mobileNumbers
            .map((number) => TextEditingController(text: number))
            .toList();
        _mobileDuplicateErrors = List.filled(mobileNumbers.length, false);
        _mobileErrors = List.filled(mobileNumbers.length, false);
      } else {
        mobileNumbers = [''];
        mobileControllers = [TextEditingController()];
        _mobileDuplicateErrors = [false];
        _mobileErrors = [false];
      }
    }

    // Initialize dropdown values
    if (widget.isEditMode) {
      selectedAgentType = widget.initialAgent!['agentType'];
      // MODIFIED: Initialize with grade_id instead of grade name
      selectedGradeId = widget.initialAgent!['grade_id'];
      selectedStatus = widget.initialAgent!['status'];
    }

    // Initialize focus nodes
    _mobileFocusNodes = List.generate(
      mobileControllers.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    emailController.dispose();
    stateController.dispose();
    cityController.dispose();

    // Dispose mobile controllers and focus nodes
    for (var controller in mobileControllers) {
      controller.dispose();
    }
    for (var node in _mobileFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // Check if email already exists (placeholder - implement actual checking)
  Future<bool> _checkEmailExists(String email) async {
    // In a real app, you would call a service to check if the email already exists
    // For now, we'll just return false
    return false;
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
              widget.isEditMode ? 'Edit Agent' : 'Add Agent',
              context,
            ),

            // Horizontal divider
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Agent Name Field
                    Helpers.buildFormField(
                      title: 'Agent Name: *',
                      child: TextField(
                        controller: nameController,
                        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
                        decoration: InputDecoration(
                          hintText: 'e.g. John Smith',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _nameError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _nameError
                              ? 'Agent name is required'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nameError = value.trim().isEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Agent Code Field
                    Helpers.buildFormField(
                      title: 'Agent Code: *',
                      child: TextField(
                        controller: codeController,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. JSM',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _codeError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _codeError
                              ? 'Agent code is required'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _codeError = value.trim().isEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile Numbers Field - Multiple
                    Helpers.buildFormField(
                      title: 'Mobile Numbers: *',
                      child: Column(
                        children: [
                          for (int index = 0; index < mobileControllers.length; index++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextField(
                                controller: mobileControllers[index],
                                focusNode: _mobileFocusNodes[index],
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                  FirstDigitMobileNumberFormatter(
                                    onValidFirstDigit: () {},
                                    onInvalidFirstDigit: () {
                                      setState(() {
                                        _mobileErrors[index] = true;
                                      });
                                    },
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'e.g. 9876543210',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          (_mobileErrors[index] ||
                                              _mobileDuplicateErrors[index])
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  errorText: _mobileErrors[index]
                                      ? 'Mobile number must start with 6, 7, 8, or 9'
                                      : _mobileDuplicateErrors[index]
                                      ? 'Duplicate mobile number'
                                      : null,
                                  suffixIcon: index == mobileControllers.length - 1
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              mobileNumbers.add('');
                                              mobileControllers.add(
                                                TextEditingController(),
                                              );
                                              _mobileErrors.add(false);
                                              _mobileDuplicateErrors.add(false);
                                              _mobileFocusNodes.add(
                                                FocusNode(),
                                              );
                                            });
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (mobileControllers.length > 1) {
                                                mobileNumbers.removeAt(index);
                                                mobileControllers
                                                    .removeAt(index)
                                                    .dispose();
                                                _mobileErrors.removeAt(index);
                                                _mobileDuplicateErrors.removeAt(
                                                  index,
                                                );
                                                _mobileFocusNodes
                                                    .removeAt(index)
                                                    .dispose();
                                              }
                                            });
                                          },
                                        ),
                                ),
                                onChanged: (value) {
                                  if (index < mobileNumbers.length) {
                                    mobileNumbers[index] = value;

                                    bool isDuplicate = Validators.checkDuplicateMobile(
                                      index,
                                      value,
                                      mobileNumbers,
                                    );

                                    if (value.trim().isNotEmpty) {
                                      bool isValid = Validators.validateMobileNumber(
                                        value.trim(),
                                      );
                                      if (!isValid && !_mobileErrors[index]) {
                                        setState(() {
                                          _mobileErrors[index] = true;
                                        });
                                      } else if (isValid &&
                                          _mobileErrors[index]) {
                                        setState(() {
                                          _mobileErrors[index] = false;
                                        });
                                      }

                                      if (isDuplicate &&
                                          !_mobileDuplicateErrors[index]) {
                                        setState(() {
                                          _mobileDuplicateErrors[index] = true;
                                        });
                                      } else if (!isDuplicate &&
                                          _mobileDuplicateErrors[index]) {
                                        setState(() {
                                          _mobileDuplicateErrors[index] = false;
                                        });
                                      }
                                    } else {
                                      if (_mobileErrors[index]) {
                                        setState(() {
                                          _mobileErrors[index] = false;
                                        });
                                      }
                                      if (_mobileDuplicateErrors[index]) {
                                        setState(() {
                                          _mobileDuplicateErrors[index] = false;
                                        });
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Helpers.buildFormField(
                      title: 'Email: *',
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. john@example.com',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: (_emailError || _emailDuplicateError)
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          errorText: _emailError
                              ? 'Please enter a valid email address'
                              : _emailDuplicateError
                              ? 'Email already exists'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _emailError =
                                value.trim().isEmpty ||
                                !Validators.validateEmail(value.trim());
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // State Field - Non-mandatory Text Input
                    Helpers.buildFormField(
                      title: 'State:',
                      child: TextField(
                        controller: stateController,
                        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
                        decoration: const InputDecoration(
                          hintText: 'e.g. Tamil Nadu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City Field - Non-mandatory
                    Helpers.buildFormField(
                      title: 'City:',
                      child: TextField(
                        controller: cityController,
                        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
                        decoration: const InputDecoration(
                          hintText: 'e.g. Chennai',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Agent Type Dropdown
                    Helpers.buildFormField(
                      title: 'Agent Type: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedAgentType,
                        hint: const Text('Select Agent Type'),
                        items: ['Sales', 'Purchase', 'Both']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAgentType = value;
                            _agentTypeError = false;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _agentTypeError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _agentTypeError
                              ? 'Agent type is required'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MODIFIED: Grade Dropdown now uses grade_id as value
                    Helpers.buildFormField(
                      title: 'Grade: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedGradeId,
                        hint: const Text('Select Grade'),
                        // MODIFIED: The value is the grade's ID, but the display text is the grade's name
                        items: widget.grades
                            .map(
                              (grade) => DropdownMenuItem(
                                value: grade['id'].toString(),
                                child: Text(grade['name'].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGradeId = value;
                            _gradeError = false;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _gradeError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _gradeError ? 'Grade is required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    Helpers.buildFormField(
                      title: 'Status: *',
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: ['Active', 'Inactive']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                            _statusError = false;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _statusError ? Colors.red : Colors.grey,
                            ),
                          ),
                          errorText: _statusError ? 'Status is required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information text with icon in a box
                    Helpers.buildInfoBox(
                      widget.isEditMode
                          ? 'This will update agent in master and all associated records.'
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
                // Validate all fields
                setState(() {
                  _nameError = nameController.text.trim().isEmpty;
                  _codeError = codeController.text.trim().isEmpty;

                  bool hasValidMobileNumber = mobileNumbers.any(
                    (number) => number.trim().isNotEmpty,
                  );
                  if (!hasValidMobileNumber) {
                    _mobileErrors[0] = true;
                  } else {
                    for (int i = 0; i < mobileNumbers.length; i++) {
                      _mobileErrors[i] =
                          mobileNumbers[i].trim().isNotEmpty &&
                          !Validators.validateMobileNumber(
                            mobileNumbers[i].trim(),
                          );

                      _mobileDuplicateErrors[i] =
                          Validators.checkDuplicateMobile(i, mobileNumbers[i], mobileNumbers);
                    }
                  }

                  _emailError =
                      emailController.text.trim().isEmpty ||
                      !Validators.validateEmail(emailController.text.trim());
                  _agentTypeError = selectedAgentType == null;
                  // MODIFIED: Check for selectedGradeId
                  _gradeError = selectedGradeId == null;
                  _statusError = selectedStatus == null;
                });

                // Check if there are any errors
                if (_nameError ||
                    _codeError ||
                    _mobileErrors.any((error) => error) ||
                    _mobileDuplicateErrors.any((error) => error) ||
                    _emailError ||
                    _emailDuplicateError ||
                    _agentTypeError ||
                    _gradeError ||
                    _statusError) {
                  return;
                }

                // Check if email already exists
                bool emailExists = await _checkEmailExists(
                  emailController.text.trim(),
                );
                if (emailExists) {
                  setState(() {
                    _emailDuplicateError = true;
                  });
                  return;
                }

                // Filter out empty mobile numbers
                List<String> validMobileNumbers = mobileNumbers
                    .where((number) => number.trim().isNotEmpty)
                    .toList();

                // Create agent object
                final agentData = {
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim().toUpperCase(),
                  'mobileNumbers': validMobileNumbers,
                  'email': emailController.text.trim(),
                  'state': stateController.text.trim(),
                  'city': cityController.text.trim(),
                  'agentType': selectedAgentType,
                  // MODIFIED: Save grade_id instead of grade name
                  'grade_id': selectedGradeId,
                  'status': selectedStatus,
                };

                // Return the agent data to caller
                Navigator.pop(context, agentData);
              },
            ),
          ],
        ),
      ),
    );
  }
}