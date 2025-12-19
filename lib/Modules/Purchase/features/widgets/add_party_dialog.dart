import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter,
        TextInputFormatter;
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/services/party_service.dart';

enum PartyType { direct, agent }

enum PartyStatus { active, inactive }

class AddPartyDialog extends StatefulWidget {
  final String? initialName;
  final String? initialCode;
  final String? initialPartyType;
  final String? initialAgent;
  final List<String>? initialMobileNumbers;
  final String? initialEmail;
  final String? initialAddress;
  final String? initialState;
  final String? initialDistrict;
  final String? initialGstNo;
  final String? initialBankName;
  final String? initialAccountNo;
  final String? initialIfscCode;
  final String? initialBranchName;
  final String? initialAccountHolderName;
  final String? initialTransport;
  final String? initialStatus;
  final bool isEditMode;
  final List<String>? agents;
  final List<String>? transports;

  const AddPartyDialog({
    Key? key,
    this.initialName,
    this.initialCode,
    this.initialPartyType,
    this.initialAgent,
    this.initialMobileNumbers,
    this.initialEmail,
    this.initialAddress,
    this.initialState,
    this.initialDistrict,
    this.initialGstNo,
    this.initialBankName,
    this.initialAccountNo,
    this.initialIfscCode,
    this.initialBranchName,
    this.initialAccountHolderName,
    this.initialTransport,
    this.initialStatus,
    this.isEditMode = false,
    this.agents,
    this.transports,
  }) : super(key: key);

  @override
  _AddPartyDialogState createState() => _AddPartyDialogState();
}

class _AddPartyDialogState extends State<AddPartyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _gstNoController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _branchNameController;
  late TextEditingController _accountHolderNameController;

  late PartyType _selectedPartyType;
  String? _selectedAgent;
  String? _selectedTransport;
  late PartyStatus _selectedStatus;

  List<String> _mobileNumbers = [];
  List<TextEditingController> _mobileControllers = [TextEditingController()];
  List<FocusNode> _mobileFocusNodes = [FocusNode()];
  List<bool> _mobileErrors = [false];
  List<bool> _mobileDuplicateErrors = [false];

  // Add lists to store unique agents and transports
  late List<String> _uniqueAgents;
  late List<String> _uniqueTransports;

  @override
  void initState() {
    super.initState();

    // Remove duplicates from agents and transports lists
    _uniqueAgents = (widget.agents ?? []).toSet().toList();
    _uniqueTransports = (widget.transports ?? []).toSet().toList();

    // Initialize controllers
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
    _stateController = TextEditingController(text: widget.initialState ?? '');
    _districtController = TextEditingController(
      text: widget.initialDistrict ?? '',
    );
    _gstNoController = TextEditingController(text: widget.initialGstNo ?? '');
    _bankNameController = TextEditingController(
      text: widget.initialBankName ?? '',
    );
    _accountNoController = TextEditingController(
      text: widget.initialAccountNo ?? '',
    );
    _ifscCodeController = TextEditingController(
      text: widget.initialIfscCode ?? '',
    );
    _branchNameController = TextEditingController(
      text: widget.initialBranchName ?? '',
    );
    _accountHolderNameController = TextEditingController(
      text: widget.initialAccountHolderName ?? '',
    );

    // Initialize dropdown values
    _selectedPartyType = widget.initialPartyType == 'PartyType.agent'
        ? PartyType.agent
        : PartyType.direct;
    _selectedAgent = widget.initialAgent;
    _selectedTransport = widget.initialTransport;
    _selectedStatus = widget.initialStatus == 'PartyStatus.inactive'
        ? PartyStatus.inactive
        : PartyStatus.active;

    // Initialize mobile numbers
    if (widget.initialMobileNumbers != null &&
        widget.initialMobileNumbers!.isNotEmpty) {
      _mobileNumbers = List<String>.from(widget.initialMobileNumbers!);
      _mobileControllers = _mobileNumbers
          .map((number) => TextEditingController(text: number))
          .toList();
      _mobileFocusNodes = List.generate(
        _mobileNumbers.length,
        (index) => FocusNode(),
      );
      _mobileErrors = List.filled(_mobileNumbers.length, false);
      _mobileDuplicateErrors = List.filled(_mobileNumbers.length, false);
    } else {
      _mobileNumbers = [''];
      _mobileControllers = [TextEditingController()];
      _mobileFocusNodes = [FocusNode()];
      _mobileErrors = [false];
      _mobileDuplicateErrors = [false];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _gstNoController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscCodeController.dispose();
    _branchNameController.dispose();
    _accountHolderNameController.dispose();

    for (var controller in _mobileControllers) {
      controller.dispose();
    }
    for (var node in _mobileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Check if email already exists (this is a placeholder, you would need to implement actual checking)
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Helpers.buildDialogHeader(
                widget.isEditMode ? 'Edit Party' : 'Add Party',
                context,
              ),

              // Horizontal divider
              const Divider(color: Color(0xFFE5E7EB), thickness: 1),

              // Content with SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Party Name Field
                      Helpers.buildTextFormField(
                        controller: _nameController,
                        label: 'Party Name: *',
                        hintText: 'Enter party name',
                        validator: (value) => Validators.validatePartyName(value),
                      ),
                      const SizedBox(height: 16),

                      // Party Code Field
                      Helpers.buildTextFormField(
                        controller: _codeController,
                        label: 'Party Code: *',
                        hintText: 'Enter unique party code',
                        validator: (value) => Validators.validatePartyCode(value),
                      ),
                      const SizedBox(height: 16),

                      // Party Type Field
                      _buildSectionTitle('Party Type: *'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<PartyType>(
                              title: const Text('Direct'),
                              value: PartyType.direct,
                              groupValue: _selectedPartyType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPartyType = value!;
                                  _selectedAgent = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<PartyType>(
                              title: const Text('Agent'),
                              value: PartyType.agent,
                              groupValue: _selectedPartyType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPartyType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Agent Field (conditional) - Use unique agents list
                      if (_selectedPartyType == PartyType.agent)
                        Helpers.buildDropdownField(
                          label: 'Agent: *',
                          value: _selectedAgent,
                          items: _uniqueAgents, // Use the unique agents list
                          onChanged: (value) {
                            setState(() {
                              _selectedAgent = value;
                            });
                          },
                          validator: _selectedPartyType == PartyType.agent
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select an agent';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      if (_selectedPartyType == PartyType.agent)
                        const SizedBox(height: 16),

                      // Mobile Numbers Field - Multiple
                      _buildSectionTitle('Mobile Numbers: *'),
                      Column(
                        children: [
                          ..._mobileNumbers.asMap().entries.map((entry) {
                            int index = entry.key;

                            // Initialize focus node if not already created
                            if (index >= _mobileFocusNodes.length) {
                              _mobileFocusNodes.add(FocusNode());
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextFormField(
                                controller: _mobileControllers[index],
                                focusNode: _mobileFocusNodes[index],
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                  NoLeadingOrMultipleSpacesFormatter(),
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
                                  suffixIcon: index == _mobileNumbers.length - 1
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _mobileNumbers.add('');
                                              _mobileControllers.add(
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
                                              if (_mobileNumbers.length > 1) {
                                                _mobileNumbers.removeAt(index);
                                                _mobileControllers
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
                                  _mobileNumbers[index] = value;

                                  // Check for duplicate mobile numbers
                                  bool isDuplicate = Validators.checkDuplicateMobile(
                                    index,
                                    value,
                                    _mobileNumbers,
                                  );

                                  // Only update error state if needed
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
                                },
                                validator: (value) {
                                  if (_mobileNumbers.every(
                                    (num) => num.trim().isEmpty,
                                  )) {
                                    return 'Please add at least one mobile number';
                                  }
                                  return null;
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      Helpers.buildTextFormField(
                        controller: _emailController,
                        label: 'Email: *',
                        hintText: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!Validators.validateEmail(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      Helpers.buildTextFormField(
                        controller: _addressController,
                        label: 'Address: *',
                        hintText: 'Enter full address',
                        maxLines: 3,
                        validator: (value) => Validators.validateRequired(value, 'address'),
                      ),
                      const SizedBox(height: 16),

                      // State Field
                      Helpers.buildTextFormField(
                        controller: _stateController,
                        label: 'State: *',
                        hintText: 'Enter state',
                        validator: (value) => Validators.validateRequired(value, 'state'),
                      ),
                      const SizedBox(height: 16),

                      // District Field
                      Helpers.buildTextFormField(
                        controller: _districtController,
                        label: 'District: *',
                        hintText: 'Enter district',
                        validator: (value) => Validators.validateRequired(value, 'district'),
                      ),
                      const SizedBox(height: 16),

                      // GST No Field
                      Helpers.buildTextFormField(
                        controller: _gstNoController,
                        label: 'GST No:',
                        hintText: 'Enter GST number (optional)',
                      ),
                      const SizedBox(height: 16),

                      // Bank Details Section
                      _buildSectionTitle('Bank Details'),
                      const SizedBox(height: 8),
                      Helpers.buildTextFormField(
                        controller: _bankNameController,
                        label: 'Bank Name:',
                        hintText: 'Enter bank name',
                      ),
                      const SizedBox(height: 16),
                      Helpers.buildTextFormField(
                        controller: _accountNoController,
                        label: 'Account No:',
                        hintText: 'Enter account number',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          NoLeadingOrMultipleSpacesFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Helpers.buildTextFormField(
                        controller: _ifscCodeController,
                        label: 'IFSC Code:',
                        hintText: 'Enter IFSC code',
                      ),
                      const SizedBox(height: 16),
                      Helpers.buildTextFormField(
                        controller: _branchNameController,
                        label: 'Branch Name:',
                        hintText: 'Enter branch name',
                      ),
                      const SizedBox(height: 16),
                      Helpers.buildTextFormField(
                        controller: _accountHolderNameController,
                        label: 'Account Holder Name:',
                        hintText: 'Enter account holder name',
                      ),
                      const SizedBox(height: 16),

                      // Transport Field - Use unique transports list
                      Helpers.buildDropdownField(
                        label: 'Transport:',
                        value: _selectedTransport,
                        items: _uniqueTransports, // Use the unique transports list
                        onChanged: (value) {
                          setState(() {
                            _selectedTransport = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status Field
                      _buildSectionTitle('Status: *'),
                      _buildStatusDropdown(
                        value: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                        validator: (value) => Validators.validateStatus(value?.toString()),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal divider
              const Divider(color: Color(0xFFE5E7EB), thickness: 1),

              // Buttons
              Helpers.buildDialogActions(
                context,
                widget.isEditMode,
                () async {
                  if (_formKey.currentState!.validate()) {
                    // Filter out empty mobile numbers
                    List<String> validMobileNumbers = _mobileNumbers
                        .where((number) => number.trim().isNotEmpty)
                        .toList();

                    // Validate each mobile number
                    for (
                      int i = 0;
                      i < validMobileNumbers.length;
                      i++
                    ) {
                      if (!Validators.validateMobileNumber(
                        validMobileNumbers[i],
                      )) {
                        setState(() {
                          _mobileErrors[i] = true;
                        });
                        return;
                      }

                      // Check for duplicates
                      if (Validators.checkDuplicateMobile(
                        i,
                        validMobileNumbers[i],
                        _mobileNumbers,
                      )) {
                        setState(() {
                          _mobileDuplicateErrors[i] = true;
                        });
                        return;
                      }
                    }

                    // Check if email already exists
                    bool emailExists = await _checkEmailExists(
                      _emailController.text.trim(),
                    );
                    if (emailExists) {
                      Helpers.showErrorSnackBar(
                        context,
                        'Email already exists',
                      );
                      return;
                    }

                    // Return the party data to caller
                    Navigator.pop(context, {
                      'name': _nameController.text.trim(),
                      'code': _codeController.text.trim(),
                      'partyType': _selectedPartyType.toString(),
                      'agent': _selectedAgent,
                      'mobileNumbers': validMobileNumbers,
                      'email': _emailController.text.trim(),
                      'address': _addressController.text.trim(),
                      'state': _stateController.text.trim(),
                      'district': _districtController.text.trim(),
                      'gstNo': _gstNoController.text.trim().isNotEmpty
                          ? _gstNoController.text.trim()
                          : null,
                      'bankName':
                          _bankNameController.text.trim().isNotEmpty
                          ? _bankNameController.text.trim()
                          : null,
                      'accountNo':
                          _accountNoController.text.trim().isNotEmpty
                          ? _accountNoController.text.trim()
                          : null,
                      'ifscCode':
                          _ifscCodeController.text.trim().isNotEmpty
                          ? _ifscCodeController.text.trim()
                          : null,
                      'branchName':
                          _branchNameController.text.trim().isNotEmpty
                          ? _branchNameController.text.trim()
                          : null,
                      'accountHolderName':
                          _accountHolderNameController.text
                              .trim()
                              .isNotEmpty
                          ? _accountHolderNameController.text.trim()
                          : null,
                      'transport': _selectedTransport,
                      'status': _selectedStatus.toString(),
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildStatusDropdown({
    required PartyStatus value,
    required Function(PartyStatus?) onChanged,
    String? Function(PartyStatus?)? validator,
  }) {
    return DropdownButtonFormField<PartyStatus>(
      value: value,
      hint: const Text('Select Status'),
      isDense: true,
      style: const TextStyle(color: Colors.black),
      items: PartyStatus.values.map((status) {
        String statusText = status == PartyStatus.active
            ? 'Active'
            : 'Inactive';
        return DropdownMenuItem<PartyStatus>(
          value: status,
          child: Text(statusText),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF529FF3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF767676)),
      iconSize: 24,
      isExpanded: true,
    );
  }
}