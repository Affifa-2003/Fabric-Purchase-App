import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter, TextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/service/order_service.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'dart:convert';
import 'dart:io';

enum PartyType { direct, agent }
enum PartyStatus { active, inactive }

class PartiesPage extends StatefulWidget {
  const PartiesPage({Key? key}) : super(key: key);

  @override
  _PartiesPageState createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  List<Party> parties = [];
  List<Party> filteredParties = [];
  List<String> agents = [];
  List<String> transports = [];
  bool _isLoading = true;
  late Box appDataBox;
  late Box ordersBox;
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final _searchController = TextEditingController();
  List<String> mobileNumbers = [];
  List<TextEditingController> mobileControllers = [TextEditingController()];
  List<FocusNode> _mobileFocusNodes = [FocusNode()];
  List<bool> _mobileErrors = [false];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterParties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mobileNumberController.dispose();
    for (var controller in mobileControllers) {
      controller.dispose();
    }
    for (var node in _mobileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load parties from JSON
      List<Map<String, dynamic>> jsonParties = [];
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        if (jsonData['parties'] != null) {
          for (var party in jsonData['parties']) {
            jsonParties.add({
              'name': party,
              'code': '',
              'partyType': PartyType.direct.toString(),
              'agent': null,
              'mobileNumbers': [],
              'email': '',
              'address': '',
              'state': '',
              'district': '',
              'gstNo': '',
              'bankName': '',
              'accountNo': '',
              'ifscCode': '',
              'branchName': '',
              'accountHolderName': '',
              'transport': null,
              'status': PartyStatus.active.toString(),
              'isMapped': false,
            });
          }
        }
        print('Loaded ${jsonParties.length} parties from JSON');
      } catch (e) {
        print('Error loading JSON parties: $e');
      }

      // Load agents and transports from Hive
      List<String> hiveAgents = [];
      List<String> hiveTransports = [];
      try {
        // Ensure box is open
        if (!Hive.isBoxOpen('appData')) {
          await Hive.openBox('appData');
        }
        if (!Hive.isBoxOpen('orders')) {
          await Hive.openBox('orders');
        }

        appDataBox = Hive.box('appData');
        ordersBox = Hive.box('orders');
        
        // Initialize with defaults if box is empty
        if (appDataBox.isEmpty) {
          await _initializeBoxWithDefaults(appDataBox);
        }
        
        // Load agents
        final agentsData = appDataBox.get('agents');
        if (agentsData != null && agentsData is List) {
          for (var agent in agentsData) {
            if (agent is Map) {
              hiveAgents.add(agent['name']?.toString() ?? '');
            } else if (agent is String) {
              hiveAgents.add(agent);
            }
          }
        }
        
        // Load transports
        final transportsData = appDataBox.get('transports');
        if (transportsData != null && transportsData is List) {
          for (var transport in transportsData) {
            if (transport is Map) {
              hiveTransports.add(transport['name']?.toString() ?? '');
            } else if (transport is String) {
              hiveTransports.add(transport);
            }
          }
        }
        
        print('Loaded ${hiveAgents.length} agents and ${hiveTransports.length} transports from Hive');
      } catch (e) {
        print('Error loading Hive data: $e');
      }

      // Load parties from Hive
      List<Map<String, dynamic>> hiveParties = [];
      try {
        final partiesData = appDataBox.get('parties');
        if (partiesData != null) {
          for (var party in partiesData) {
            if (party is Map) {
              hiveParties.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
              // Handle legacy data format
              hiveParties.add({
                'name': party,
                'code': '',
                'partyType': PartyType.direct.toString(),
                'agent': null,
                'mobileNumbers': [],
                'email': '',
                'address': '',
                'state': '',
                'district': '',
                'gstNo': '',
                'bankName': '',
                'accountNo': '',
                'ifscCode': '',
                'branchName': '',
                'accountHolderName': '',
                'transport': null,
                'status': PartyStatus.active.toString(),
                'isMapped': false,
              });
            }
          }
        }
        
        print('Loaded ${hiveParties.length} parties from Hive');
      } catch (e) {
        print('Error loading Hive parties: $e');
      }

      // Check which parties are mapped in orders
      final orders = ordersBox.values.toList();
      final Set<String> mappedParties = {};
      for (var order in orders) {
        if (order is Map && order['party'] != null) {
          mappedParties.add(order['party'] as String);
        }
      }
      
      // Update isMapped status for all parties
      for (var party in hiveParties) {
        if (mappedParties.contains(party['name'])) {
          party['isMapped'] = true;
        }
      }

      // Combine JSON and Hive data, removing duplicates
      Map<String, Map<String, dynamic>> combinedParties = {};
      
      // Add JSON parties
      for (var party in jsonParties) {
        combinedParties[party['name']] = party;
      }
      
      // Add Hive parties (overriding JSON if same name)
      for (var party in hiveParties) {
        combinedParties[party['name']] = party;
      }
      
      // Convert to list and sort
      parties = combinedParties.values.map((p) => Party.fromMap(p)).toList();
      
      // Sort parties - new ones first, then alphabetically
      parties.sort((a, b) {
        // First sort by isMapped (false first)
        if (a.isMapped != b.isMapped) {
          return a.isMapped ? 1 : -1;
        }
        // Then sort by name
        return a.name.compareTo(b.name);
      });
      
      // Combine agents and transports
      agents = hiveAgents.toSet().toList(); // Remove duplicates
      transports = hiveTransports.toSet().toList(); // Remove duplicates
      
      setState(() {
        filteredParties = List.from(parties);
        _isLoading = false;
      });
      
      print('Combined parties list: ${parties.map((p) => p.name).toList()}');
      print('Combined agents list: $agents');
      print('Combined transports list: $transports');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        parties = [];
        filteredParties = [];
        agents = [];
        transports = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default data');
      
      // Load default data from JSON if available
      List<String> defaultParties = [];
      List<String> defaultAgents = [];
      List<String> defaultTransports = [];
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        defaultParties = jsonData['parties'] != null ? List<String>.from(jsonData['parties']) : [];
        defaultAgents = jsonData['agents'] != null ? List<String>.from(jsonData['agents']) : [];
        defaultTransports = jsonData['transports'] != null ? List<String>.from(jsonData['transports']) : [];
      } catch (e) {
        print('Error loading default data from JSON: $e');
        // Fallback to hardcoded defaults
        defaultParties = [
          'Manish Textiles',
          'Raj Fabrics',
          'Kumar Mills',
          'Shree Textiles',
        ];
        defaultAgents = [
          'Raju Sharma',
          'Vijay Kumar',
          'Anil Reddy',
          'Sunil Patel',
        ];
        defaultTransports = [
          'DTDC',
          'FedEx',
          'Delhivery',
          'Blue Dart',
        ];
      }
      
      // Convert parties to the new format
      List<Map<String, dynamic>> partiesMap = defaultParties.map((party) => {
        'name': party,
        'code': '',
        'partyType': PartyType.direct.toString(),
        'agent': null,
        'mobileNumbers': [],
        'email': '',
        'address': '',
        'state': '',
        'district': '',
        'gstNo': '',
        'bankName': '',
        'accountNo': '',
        'ifscCode': '',
        'branchName': '',
        'accountHolderName': '',
        'transport': null,
        'status': PartyStatus.active.toString(),
        'isMapped': false,
      }).toList();
      
      // Convert agents to the new format
      List<Map<String, dynamic>> agentsMap = defaultAgents.map((agent) => {
        'name': agent,
        'code': agent.substring(0, 3).toUpperCase(),
        'mobileNumbers': ['9876543210'],
        'agentType': 'Sales',
        'status': 'Active',
      }).toList();
      
      // Convert transports to the new format
      List<Map<String, dynamic>> transportsMap = defaultTransports.map((transport) => {
        'name': transport,
        'mobileNumber': '9876543210',
        'status': 'Active',
      }).toList();
      
      // Set default values
      await box.put('parties', partiesMap);
      await box.put('agents', agentsMap);
      await box.put('transports', transportsMap);
      await box.flush();
      print('Hive box initialized with default data');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }

  Future<void> _savePartiesToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Convert all parties to List<Map<String, dynamic>> to ensure type safety
      final List<Map<String, dynamic>> partiesToSave = parties
          .map((party) => party.toMap())
          .toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('parties', partiesToSave);
      
      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved parties: ${box.get('parties')}');
      print('Parties data saved successfully');
    } catch (e) {
      print('Error saving parties data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving parties: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterParties() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredParties = parties.where((party) {
        return party.name.toLowerCase().contains(query) ||
               party.code.toLowerCase().contains(query);
      }).toList();
    });
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

  void _showAddNewPartyDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController codeController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController stateController = TextEditingController();
    TextEditingController districtController = TextEditingController();
    TextEditingController gstNoController = TextEditingController();
    TextEditingController bankNameController = TextEditingController();
    TextEditingController accountNoController = TextEditingController();
    TextEditingController ifscCodeController = TextEditingController();
    TextEditingController branchNameController = TextEditingController();
    TextEditingController accountHolderNameController = TextEditingController();
    
    PartyType? selectedPartyType = PartyType.direct;
    String? selectedAgent;
    String? selectedTransport;
    PartyStatus selectedStatus = PartyStatus.active;
    
    mobileNumbers = [''];
    mobileControllers = [TextEditingController()];
    _mobileFocusNodes = [FocusNode()];
    _mobileErrors = [false];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                            const Text(
                              'Add New Party',
                              style: TextStyle(
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
                                controller: nameController,
                                label: 'Party Name: *',
                                hintText: 'Enter party name',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter party name';
                                  }
                                  if (parties.any((party) => party.name.toLowerCase() == value.trim().toLowerCase())) {
                                    return 'Party name already exists';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Party Code Field
                              _buildTextFormField(
                                controller: codeController,
                                label: 'Party Code: *',
                                hintText: 'Enter unique party code',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter party code';
                                  }
                                  if (parties.any((party) => party.code.toLowerCase() == value.trim().toLowerCase())) {
                                    return 'Party code already exists';
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
                                      groupValue: selectedPartyType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPartyType = value;
                                          selectedAgent = null;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<PartyType>(
                                      title: const Text('Agent'),
                                      value: PartyType.agent,
                                      groupValue: selectedPartyType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPartyType = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Agent Field (conditional)
                              if (selectedPartyType == PartyType.agent)
                                _buildDropdownField(
                                  label: 'Agent: *',
                                  value: selectedAgent,
                                  items: agents,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAgent = value;
                                    });
                                  },
                                  validator: selectedPartyType == PartyType.agent
                                      ? (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select an agent';
                                          }
                                          return null;
                                        }
                                      : null,
                                ),
                              if (selectedPartyType == PartyType.agent) const SizedBox(height: 16),

                              // Mobile Numbers Field - Multiple
                              _buildSectionTitle('Mobile Numbers: *'),
                              Column(
                                children: [
                                  ...mobileNumbers.asMap().entries.map((entry) {
                                    int index = entry.key;

                                    // Initialize focus node if not already created
                                    if (index >= _mobileFocusNodes.length) {
                                      _mobileFocusNodes.add(FocusNode());
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: TextFormField(
                                        controller: mobileControllers[index],
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
                                          suffixIcon: index == mobileNumbers.length - 1
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      mobileNumbers.add('');
                                                      mobileControllers.add(TextEditingController());
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
                                                      if (mobileNumbers.length > 1) {
                                                        mobileNumbers.removeAt(index);
                                                        mobileControllers.removeAt(index).dispose();
                                                        _mobileErrors.removeAt(index);
                                                        _mobileFocusNodes.removeAt(index).dispose();
                                                      }
                                                    });
                                                  },
                                                ),
                                        ),
                                        onChanged: (value) {
                                          mobileNumbers[index] = value;
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
                                          if (mobileNumbers.every((num) => num.trim().isEmpty)) {
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
                                controller: emailController,
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
                                controller: addressController,
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
                                controller: stateController,
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
                                controller: districtController,
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
                                controller: gstNoController,
                                label: 'GST No:',
                                hintText: 'Enter GST number (optional)',
                              ),
                              const SizedBox(height: 16),

                              // Bank Details Section
                              _buildSectionTitle('Bank Details'),
                              const SizedBox(height: 8),
                              _buildTextFormField(
                                controller: bankNameController,
                                label: 'Bank Name:',
                                hintText: 'Enter bank name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: accountNoController,
                                label: 'Account No:',
                                hintText: 'Enter account number',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: ifscCodeController,
                                label: 'IFSC Code:',
                                hintText: 'Enter IFSC code',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: branchNameController,
                                label: 'Branch Name:',
                                hintText: 'Enter branch name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: accountHolderNameController,
                                label: 'Account Holder Name:',
                                hintText: 'Enter account holder name',
                              ),
                              const SizedBox(height: 16),

                              // Transport Field
                              _buildDropdownField(
                                label: 'Transport:',
                                value: selectedTransport,
                                items: transports,
                                onChanged: (value) {
                                  setState(() {
                                    selectedTransport = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Status Field
                              _buildSectionTitle('Status: *'),
                              _buildStatusDropdown(
                                value: selectedStatus,
                                onChanged: (value) {
                                  setState(() {
                                    selectedStatus = value!;
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
                                      List<String> validMobileNumbers = mobileNumbers
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

                                      // Create new party
                                      final newParty = Party(
                                        name: nameController.text.trim(),
                                        code: codeController.text.trim(),
                                        partyType: selectedPartyType!,
                                        agent: selectedAgent,
                                        mobileNumbers: validMobileNumbers,
                                        email: emailController.text.trim(),
                                        address: addressController.text.trim(),
                                        state: stateController.text.trim(),
                                        district: districtController.text.trim(),
                                        gstNo: gstNoController.text.trim().isNotEmpty 
                                            ? gstNoController.text.trim() 
                                            : null,
                                        bankName: bankNameController.text.trim().isNotEmpty 
                                            ? bankNameController.text.trim() 
                                            : null,
                                        accountNo: accountNoController.text.trim().isNotEmpty 
                                            ? accountNoController.text.trim() 
                                            : null,
                                        ifscCode: ifscCodeController.text.trim().isNotEmpty 
                                            ? ifscCodeController.text.trim() 
                                            : null,
                                        branchName: branchNameController.text.trim().isNotEmpty 
                                            ? branchNameController.text.trim() 
                                            : null,
                                        accountHolderName: accountHolderNameController.text.trim().isNotEmpty 
                                            ? accountHolderNameController.text.trim() 
                                            : null,
                                        transport: selectedTransport,
                                        status: selectedStatus,
                                        isMapped: false,
                                      );

                                      // Update local state immediately
                                      this.setState(() {
                                        // Add to the beginning of the list
                                        parties.insert(0, newParty);
                                        _filterParties(); // Update filtered list
                                      });

                                      // Save to Hive
                                      await _savePartiesToStorage();

                                      Navigator.pop(context);

                                      // Show success message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Party added successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
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
                ),
              ),
            );
          },
        );
      },
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
  void _showEditPartyDialog(Party party) {
    TextEditingController nameController = TextEditingController(text: party.name);
    TextEditingController codeController = TextEditingController(text: party.code);
    TextEditingController emailController = TextEditingController(text: party.email);
    TextEditingController addressController = TextEditingController(text: party.address);
    TextEditingController stateController = TextEditingController(text: party.state);
    TextEditingController districtController = TextEditingController(text: party.district);
    TextEditingController gstNoController = TextEditingController(text: party.gstNo ?? '');
    TextEditingController bankNameController = TextEditingController(text: party.bankName ?? '');
    TextEditingController accountNoController = TextEditingController(text: party.accountNo ?? '');
    TextEditingController ifscCodeController = TextEditingController(text: party.ifscCode ?? '');
    TextEditingController branchNameController = TextEditingController(text: party.branchName ?? '');
    TextEditingController accountHolderNameController = TextEditingController(text: party.accountHolderName ?? '');
    
    PartyType selectedPartyType = party.partyType;
    String? selectedAgent = party.agent;
    String? selectedTransport = party.transport;
    PartyStatus selectedStatus = party.status;
    String originalPartyName = party.name;
    
    mobileNumbers = List<String>.from(party.mobileNumbers);
    mobileControllers = mobileNumbers.map((number) => TextEditingController(text: number)).toList();
    _mobileFocusNodes = List.generate(mobileNumbers.length, (index) => FocusNode());
    _mobileErrors = List.filled(mobileNumbers.length, false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                            const Text(
                              'Edit Party',
                              style: TextStyle(
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
                                controller: nameController,
                                label: 'Party Name: *',
                                hintText: 'Enter party name',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter party name';
                                  }
                                  if (parties.any((p) => p.name.toLowerCase() == value.trim().toLowerCase() && p.name != originalPartyName)) {
                                    return 'Party name already exists';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Party Code Field
                              _buildTextFormField(
                                controller: codeController,
                                label: 'Party Code: *',
                                hintText: 'Enter unique party code',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter party code';
                                  }
                                  if (parties.any((p) => p.code.toLowerCase() == value.trim().toLowerCase() && p.name != originalPartyName)) {
                                    return 'Party code already exists';
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
                                      groupValue: selectedPartyType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPartyType = value!;
                                          selectedAgent = null;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<PartyType>(
                                      title: const Text('Agent'),
                                      value: PartyType.agent,
                                      groupValue: selectedPartyType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPartyType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Agent Field (conditional)
                              if (selectedPartyType == PartyType.agent)
                                _buildDropdownField(
                                  label: 'Agent: *',
                                  value: selectedAgent,
                                  items: agents,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAgent = value;
                                    });
                                  },
                                  validator: selectedPartyType == PartyType.agent
                                      ? (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select an agent';
                                          }
                                          return null;
                                        }
                                      : null,
                                ),
                              if (selectedPartyType == PartyType.agent) const SizedBox(height: 16),

                              // Mobile Numbers Field - Multiple
                              _buildSectionTitle('Mobile Numbers: *'),
                              Column(
                                children: [
                                  ...mobileNumbers.asMap().entries.map((entry) {
                                    int index = entry.key;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: TextFormField(
                                        controller: mobileControllers[index],
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
                                          suffixIcon: index == mobileNumbers.length - 1
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      mobileNumbers.add('');
                                                      mobileControllers.add(TextEditingController());
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
                                                      if (mobileNumbers.length > 1) {
                                                        mobileNumbers.removeAt(index);
                                                        mobileControllers.removeAt(index).dispose();
                                                        _mobileErrors.removeAt(index);
                                                        _mobileFocusNodes.removeAt(index).dispose();
                                                      }
                                                    });
                                                  },
                                                ),
                                        ),
                                        onChanged: (value) {
                                          mobileNumbers[index] = value;
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
                                          if (mobileNumbers.every((num) => num.trim().isEmpty)) {
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
                                controller: emailController,
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
                                controller: addressController,
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
                                controller: stateController,
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
                                controller: districtController,
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
                                controller: gstNoController,
                                label: 'GST No:',
                                hintText: 'Enter GST number (optional)',
                              ),
                              const SizedBox(height: 16),

                              // Bank Details Section
                              _buildSectionTitle('Bank Details'),
                              const SizedBox(height: 8),
                              _buildTextFormField(
                                controller: bankNameController,
                                label: 'Bank Name:',
                                hintText: 'Enter bank name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: accountNoController,
                                label: 'Account No:',
                                hintText: 'Enter account number',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: ifscCodeController,
                                label: 'IFSC Code:',
                                hintText: 'Enter IFSC code',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: branchNameController,
                                label: 'Branch Name:',
                                hintText: 'Enter branch name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: accountHolderNameController,
                                label: 'Account Holder Name:',
                                hintText: 'Enter account holder name',
                              ),
                              const SizedBox(height: 16),

                              // Transport Field
                              _buildDropdownField(
                                label: 'Transport:',
                                value: selectedTransport,
                                items: transports,
                                onChanged: (value) {
                                  setState(() {
                                    selectedTransport = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Status Field
                              _buildSectionTitle('Status: *'),
                              _buildStatusDropdown(
                                value: selectedStatus,
                                onChanged: (value) {
                                  setState(() {
                                    selectedStatus = value!;
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
                                      List<String> validMobileNumbers = mobileNumbers
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

                                      // Find party in list and update it
                                      final index = parties.indexWhere((p) => p.name == party.name);
                                      if (index != -1) {
                                        // Check if party name is being changed
                                        bool nameChanged = nameController.text.trim() != originalPartyName;
                                        
                                        // Update local state immediately
                                        this.setState(() {
                                          parties[index] = Party(
                                            name: nameController.text.trim(),
                                            code: codeController.text.trim(),
                                            partyType: selectedPartyType,
                                            agent: selectedAgent,
                                            mobileNumbers: validMobileNumbers,
                                            email: emailController.text.trim(),
                                            address: addressController.text.trim(),
                                            state: stateController.text.trim(),
                                            district: districtController.text.trim(),
                                            gstNo: gstNoController.text.trim().isNotEmpty 
                                                ? gstNoController.text.trim() 
                                                : null,
                                            bankName: bankNameController.text.trim().isNotEmpty 
                                                ? bankNameController.text.trim() 
                                                : null,
                                            accountNo: accountNoController.text.trim().isNotEmpty 
                                                ? accountNoController.text.trim() 
                                                : null,
                                            ifscCode: ifscCodeController.text.trim().isNotEmpty 
                                                ? ifscCodeController.text.trim() 
                                                : null,
                                            branchName: branchNameController.text.trim().isNotEmpty 
                                                ? branchNameController.text.trim() 
                                                : null,
                                            accountHolderName: accountHolderNameController.text.trim().isNotEmpty 
                                                ? accountHolderNameController.text.trim() 
                                                : null,
                                            transport: selectedTransport,
                                            status: selectedStatus,
                                            isMapped: party.isMapped,
                                          );
                                          _filterParties(); // Update filtered list
                                        });

                                        // Save to Hive
                                        await _savePartiesToStorage();

                                        // If name changed, update all related records
                                        if (nameChanged) {
                                          await _updatePartyNameInAllRecords(originalPartyName, nameController.text.trim());
                                        }

                                        Navigator.pop(context);

                                        // Show success message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Party updated successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Update to Master',
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updatePartyNameInAllRecords(String oldName, String newName) async {
    try {
      // Update party name in orders box
      if (Hive.isBoxOpen('orders')) {
        final ordersBox = Hive.box('orders');
        final orders = ordersBox.values.toList();
        
        for (var i = 0; i < orders.length; i++) {
          var order = orders[i];
          if (order is Map && order['party'] == oldName) {
            order['party'] = newName;
            await ordersBox.putAt(i, order);
          }
        }
        
        await ordersBox.flush();
        print('Updated party name in orders box');
      }
      
      // Update party name in designs box
      if (Hive.isBoxOpen('designs')) {
        final designsBox = Hive.box('designs');
        final keys = designsBox.keys.toList();
        
        for (var key in keys) {
          if (key is String && key.startsWith('designs_${oldName}_')) {
            // Get the design data
            final designData = designsBox.get(key);
            
            // Create new key with new party name
            String newKey = key.replaceFirst('designs_${oldName}_', 'designs_${newName}_');
            
            // Save with new key
            await designsBox.put(newKey, designData);
            
            // Delete old key
            await designsBox.delete(key);
          }
        }
        
        await designsBox.flush();
        print('Updated party name in designs box');
      }
      
      // Notify that orders have been updated
      OrderService().notifyOrderUpdated();
      
    } catch (e) {
      print('Error updating party name in all records: $e');
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    final party = parties[index];
    
    // Always show the delete icon, but check if mapped when clicked
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: party.isMapped 
              ? const Text('Already mapped, deletion not allowed')
              : Text('Are you sure you want to delete "${party.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            if (!party.isMapped)
              TextButton(
                onPressed: () async {
                  // Update local state immediately
                  this.setState(() {
                    parties.removeAt(index);
                    _filterParties(); // Update filtered list
                  });
                  
                  // Save to Hive
                  await _savePartiesToStorage();
                  
                  Navigator.of(context).pop(); // Close dialog
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Party deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Parties'),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, // Set fixed width for smaller circle
            height: 36, // Set fixed height for smaller circle
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero, // Remove default padding
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24), // Adjusted icon size
              onPressed: _showAddNewPartyDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field with reduced padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Party Name or Code',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                
                // Parties list with reduced padding
                Expanded(
                  child: filteredParties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                parties.isEmpty
                                    ? 'No parties found'
                                    : 'No matching parties',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                parties.isEmpty
                                    ? 'Add parties using the + button'
                                    : 'Try a different search term',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadData();
                            setState(() {});
                          },
                          child: ListView.builder(
                           padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredParties.length,
                            itemBuilder: (context, index) {
                              final party = filteredParties[index];
                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(
                                      Icons.business,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    party.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Code: ${party.code}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(index);
                                    },
                                  ),
                                  onTap: () {
                                    _showEditPartyDialog(party);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

}

class Party {
  final String name;
  final String code;
  final PartyType partyType;
  final String? agent;
  final List<String> mobileNumbers;
  final String email;
  final String address;
  final String state;
  final String district;
  final String? gstNo;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final String? branchName;
  final String? accountHolderName;
  final String? transport;
  final PartyStatus status;
  final bool isMapped;

  Party({
    required this.name,
    required this.code,
    required this.partyType,
    this.agent,
    required this.mobileNumbers,
    required this.email,
    required this.address,
    required this.state,
    required this.district,
    this.gstNo,
    this.bankName,
    this.accountNo,
    this.ifscCode,
    this.branchName,
    this.accountHolderName,
    this.transport,
    required this.status,
    this.isMapped = false,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      partyType: map['partyType'] == PartyType.agent.toString() 
          ? PartyType.agent 
          : PartyType.direct,
      agent: map['agent'],
      mobileNumbers: map['mobileNumbers'] != null 
          ? List<String>.from(map['mobileNumbers']) 
          : [],
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      state: map['state'] ?? '',
      district: map['district'] ?? '',
      gstNo: map['gstNo'],
      bankName: map['bankName'],
      accountNo: map['accountNo'],
      ifscCode: map['ifscCode'],
      branchName: map['branchName'],
      accountHolderName: map['accountHolderName'],
      transport: map['transport'],
      status: map['status'] == PartyStatus.inactive.toString() 
          ? PartyStatus.inactive 
          : PartyStatus.active,
      isMapped: map['isMapped'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'partyType': partyType.toString(),
      'agent': agent,
      'mobileNumbers': mobileNumbers,
      'email': email,
      'address': address,
      'state': state,
      'district': district,
      'gstNo': gstNo,
      'bankName': bankName,
      'accountNo': accountNo,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'accountHolderName': accountHolderName,
      'transport': transport,
      'status': status.toString(),
      'isMapped': isMapped,
    };
  }
}