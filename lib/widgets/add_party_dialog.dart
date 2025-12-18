import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/service/party_service.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _stateController = TextEditingController(text: widget.initialState ?? '');
    _districtController = TextEditingController(text: widget.initialDistrict ?? '');
    _gstNoController = TextEditingController(text: widget.initialGstNo ?? '');
    _bankNameController = TextEditingController(text: widget.initialBankName ?? '');
    _accountNoController = TextEditingController(text: widget.initialAccountNo ?? '');
    _ifscCodeController = TextEditingController(text: widget.initialIfscCode ?? '');
    _branchNameController = TextEditingController(text: widget.initialBranchName ?? '');
    _accountHolderNameController = TextEditingController(text: widget.initialAccountHolderName ?? '');
    
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
    if (widget.initialMobileNumbers != null && widget.initialMobileNumbers!.isNotEmpty) {
      _mobileNumbers = List<String>.from(widget.initialMobileNumbers!);
      _mobileControllers = _mobileNumbers.map((number) => TextEditingController(text: number)).toList();
      _mobileFocusNodes = List.generate(_mobileNumbers.length, (index) => FocusNode());
      _mobileErrors = List.filled(_mobileNumbers.length, false);
    } else {
      _mobileNumbers = [''];
      _mobileControllers = [TextEditingController()];
      _mobileFocusNodes = [FocusNode()];
      _mobileErrors = [false];
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

  // Validate mobile number (10 digits, starting with 6-9)
  bool _validateMobileNumber(String mobile) {
    // Remove any non-digit characters
    String digitsOnly = mobile.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's exactly 10 digits and starts with 6-9
    if (digitsOnly.length != 10) {
      return false;
    }
    
    // Check if first digit is between 6 and 9
    int firstDigit = int.parse(digitsOnly[0]);
    return firstDigit >= 6 && firstDigit <= 9;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      widget.isEditMode ? 'Edit Party' : 'Add Party',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                ),
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
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Party Name: *',
                        hintText: 'Enter party name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter party name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Party Code Field
                      _buildTextFormField(
                        controller: _codeController,
                        label: 'Party Code: *',
                        hintText: 'Enter unique party code',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter party code';
                          }
                          return null;
                        },
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

                      // Agent Field (conditional)
                      if (_selectedPartyType == PartyType.agent)
                        _buildDropdownField(
                          label: 'Agent: *',
                          value: _selectedAgent,
                          items: widget.agents ?? [],
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
                      if (_selectedPartyType == PartyType.agent) const SizedBox(height: 16),

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
                                ],
                                decoration: InputDecoration(
                                  hintText: 'e.g. 9876543210',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _mobileErrors[index] ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  errorText: _mobileErrors[index]
                                      ? 'Mobile number must start with 6, 7, 8, or 9'
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
                                              _mobileControllers.add(TextEditingController());
                                              _mobileErrors.add(false);
                                              _mobileFocusNodes.add(FocusNode());
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
                                                _mobileControllers.removeAt(index).dispose();
                                                _mobileErrors.removeAt(index);
                                                _mobileFocusNodes.removeAt(index).dispose();
                                              }
                                            });
                                          },
                                        ),
                                ),
                                onChanged: (value) {
                                  _mobileNumbers[index] = value;
                                  // Only update error state, don't trigger full rebuild
                                  if (value.trim().isNotEmpty && !_validateMobileNumber(value.trim())) {
                                    if (!_mobileErrors[index]) {
                                      setState(() {
                                        _mobileErrors[index] = true;
                                      });
                                    }
                                  } else {
                                    if (_mobileErrors[index]) {
                                      setState(() {
                                        _mobileErrors[index] = false;
                                      });
                                    }
                                  }
                                },
                                validator: (value) {
                                  if (_mobileNumbers.every((num) => num.trim().isEmpty)) {
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
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'Email: *',
                        hintText: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      _buildTextFormField(
                        controller: _addressController,
                        label: 'Address: *',
                        hintText: 'Enter full address',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // State Field
                      _buildTextFormField(
                        controller: _stateController,
                        label: 'State: *',
                        hintText: 'Enter state',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter state';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // District Field
                      _buildTextFormField(
                        controller: _districtController,
                        label: 'District: *',
                        hintText: 'Enter district',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter district';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // GST No Field
                      _buildTextFormField(
                        controller: _gstNoController,
                        label: 'GST No:',
                        hintText: 'Enter GST number (optional)',
                      ),
                      const SizedBox(height: 16),

                      // Bank Details Section
                      _buildSectionTitle('Bank Details'),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _bankNameController,
                        label: 'Bank Name:',
                        hintText: 'Enter bank name',
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _accountNoController,
                        label: 'Account No:',
                        hintText: 'Enter account number',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _ifscCodeController,
                        label: 'IFSC Code:',
                        hintText: 'Enter IFSC code',
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _branchNameController,
                        label: 'Branch Name:',
                        hintText: 'Enter branch name',
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _accountHolderNameController,
                        label: 'Account Holder Name:',
                        hintText: 'Enter account holder name',
                      ),
                      const SizedBox(height: 16),

                      // Transport Field
                      _buildDropdownField(
                        label: 'Transport:',
                        value: _selectedTransport,
                        items: widget.transports ?? [],
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
                        validator: (value) {
                          if (value == null) {
                            return 'Please select status';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                            if (_formKey.currentState!.validate()) {
                              // Filter out empty mobile numbers
                              List<String> validMobileNumbers = _mobileNumbers
                                  .where((number) => number.trim().isNotEmpty)
                                  .toList();
                              
                              // Validate each mobile number
                              for (int i = 0; i < validMobileNumbers.length; i++) {
                                if (!_validateMobileNumber(validMobileNumbers[i])) {
                                  setState(() {
                                    _mobileErrors[i] = true;
                                  });
                                  return;
                                }
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
                                'bankName': _bankNameController.text.trim().isNotEmpty 
                                    ? _bankNameController.text.trim() 
                                    : null,
                                'accountNo': _accountNoController.text.trim().isNotEmpty 
                                    ? _accountNoController.text.trim() 
                                    : null,
                                'ifscCode': _ifscCodeController.text.trim().isNotEmpty 
                                    ? _ifscCodeController.text.trim() 
                                    : null,
                                'branchName': _branchNameController.text.trim().isNotEmpty 
                                    ? _branchNameController.text.trim() 
                                    : null,
                                'accountHolderName': _accountHolderNameController.text.trim().isNotEmpty 
                                    ? _accountHolderNameController.text.trim() 
                                    : null,
                                'transport': _selectedTransport,
                                'status': _selectedStatus.toString(),
                              });
                            }
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onEditingComplete: () {
            // Trim trailing spaces when editing is complete
            controller.text = controller.text.trim();
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text('Select...'),
          isDense: true,
          style: const TextStyle(color: Colors.black),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF529FF3),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF767676),
          ),
          iconSize: 24,
          isExpanded: true,
        ),
      ],
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
        String statusText = status == PartyStatus.active ? 'Active' : 'Inactive';
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
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF529FF3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF767676),
      ),
      iconSize: 24,
      isExpanded: true,
    );
  }
}