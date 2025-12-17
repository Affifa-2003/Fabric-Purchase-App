import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        rootBundle,
        TextInputFormatter,
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'dart:convert';

class AgentsPage extends StatefulWidget {
  const AgentsPage({Key? key}) : super(key: key);

  @override
  _AgentsPageState createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  List<Map<String, dynamic>> agents = [];
  List<Map<String, dynamic>> filteredAgents = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> grades = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  
  // Focus nodes for mobile number fields
  List<FocusNode> _mobileFocusNodes = [];

  // Email validation regex
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterAgents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose focus nodes
    for (var node in _mobileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
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

  // Check if an agent is mapped to any party
  bool _isAgentMapped(String agentName) {
    try {
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final partiesData = box.get('parties');

      if (partiesData != null) {
        if (partiesData is List) {
          for (var party in partiesData) {
            if (party is Map && party['agent'] == agentName) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking if agent is mapped: $e');
      return false;
    }
  }

  // Filter agents based on search query
  void _filterAgents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredAgents = agents.where((agent) {
        return agent['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // In this method, update code to properly handle data format
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadAgents(),
        _loadStates(),
        _loadDistricts(),
        _loadGrades(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  // Load agents data
  Future<void> _loadAgents() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveAgents = [];
      try {
        // Ensure box is open
        if (!Hive.isBoxOpen('appData')) {
          await Hive.openBox('appData');
        }

        appDataBox = Hive.box('appData');

        // Initialize with defaults if box is empty
        if (appDataBox.isEmpty) {
          await _initializeBoxWithDefaults(appDataBox);
        }

        final agentsData = appDataBox.get('agents');
        if (agentsData != null && agentsData is List) {
          hiveAgents = agentsData.map((agent) {
            if (agent is Map) {
              return Map<String, dynamic>.from(agent);
            }
            return <String, dynamic>{'name': agent.toString()};
          }).toList();
        }
        print('Loaded ${hiveAgents.length} agents from Hive');
      } catch (e) {
        print('Error loading Hive agents: $e');
      }

      setState(() {
        agents = hiveAgents;
        filteredAgents = List.from(agents);
      });

      print('Agents list: $agents');
    } catch (e) {
      print('Error loading agents: $e');
      setState(() {
        agents = [];
        filteredAgents = [];
      });
    }
  }

  // Load states data
  Future<void> _loadStates() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final statesData = box.get('states');

      if (statesData != null && statesData is List) {
        states = statesData.map((state) {
          if (state is Map) {
            return Map<String, dynamic>.from(state);
          }
          return <String, dynamic>{'name': state.toString()};
        }).toList();
      }

      print('Loaded ${states.length} states');
    } catch (e) {
      print('Error loading states: $e');
      states = [];
    }
  }

  // Load districts data
  Future<void> _loadDistricts() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final districtsData = box.get('districts');

      if (districtsData != null && districtsData is List) {
        districts = districtsData.map((district) {
          if (district is Map) {
            return Map<String, dynamic>.from(district);
          }
          return <String, dynamic>{'name': district.toString()};
        }).toList();
      }

      print('Loaded ${districts.length} districts');
    } catch (e) {
      print('Error loading districts: $e');
      districts = [];
    }
  }

  // Load grades data
  Future<void> _loadGrades() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final gradesData = box.get('grades');

      if (gradesData != null && gradesData is List) {
        grades = gradesData.map((grade) {
          if (grade is Map) {
            return Map<String, dynamic>.from(grade);
          }
          return <String, dynamic>{'name': grade.toString()};
        }).toList();
      }

      print('Loaded ${grades.length} grades');
    } catch (e) {
      print('Error loading grades: $e');
      grades = [];
    }
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default data');

      // Load default data from JSON if available
      Map<String, dynamic> defaultData = {};
      try {
        final String response = await rootBundle.loadString(
          'assets/order_data.json',
        );
        defaultData = json.decode(response);
      } catch (e) {
        print('Error loading default data from JSON: $e');
      }

      // Set default agents
      List<Map<String, dynamic>> defaultAgents = [];
      if (defaultData.containsKey('agents') && defaultData['agents'] is List) {
        defaultAgents = defaultData['agents'].map((agent) {
          if (agent is String) {
            return {
              'name': agent,
              'code': agent.substring(0, 3).toUpperCase(),
              'mobileNumbers': ['9876543210'], // Default mobile number
              'agentType': 'Sales', // Default agent type
            };
          }
          return Map<String, dynamic>.from(agent);
        }).toList();
      } else {
        // Fallback to hardcoded defaults
        defaultAgents = [
          {
            'name': 'Raju Sharma',
            'code': 'RAJ',
            'mobileNumbers': ['9876543210'],
            'agentType': 'Sales',
          },
          {
            'name': 'Vijay Kumar',
            'code': 'VIJ',
            'mobileNumbers': ['9876543211'],
            'agentType': 'Purchase',
          },
          {
            'name': 'Anil Reddy',
            'code': 'ANI',
            'mobileNumbers': ['9876543212'],
            'agentType': 'Both',
          },
          {
            'name': 'Sunil Patel',
            'code': 'SUN',
            'mobileNumbers': ['9876543213'],
            'agentType': 'Sales',
          },
        ];
      }

      await box.put('agents', defaultAgents);

      // Set default states if not exists
      if (!box.containsKey('states')) {
        List<Map<String, dynamic>> defaultStates = [
          {'name': 'Tamil Nadu', 'code': 'TN'},
          {'name': 'Karnataka', 'code': 'KA'},
          {'name': 'Kerala', 'code': 'KL'},
          {'name': 'Andhra Pradesh', 'code': 'AP'},
        ];
        await box.put('states', defaultStates);
      }

      // Set default districts if not exists
      if (!box.containsKey('districts')) {
        List<Map<String, dynamic>> defaultDistricts = [
          {'name': 'Chennai', 'state': 'Tamil Nadu'},
          {'name': 'Bangalore', 'state': 'Karnataka'},
          {'name': 'Thiruvananthapuram', 'state': 'Kerala'},
          {'name': 'Visakhapatnam', 'state': 'Andhra Pradesh'},
        ];
        await box.put('districts', defaultDistricts);
      }

      // Set default grades if not exists
      if (!box.containsKey('grades')) {
        List<Map<String, dynamic>> defaultGrades = [
          {'name': 'A'},
          {'name': 'B'},
          {'name': 'C'},
          {'name': 'D'},
        ];
        await box.put('grades', defaultGrades);
      }

      await box.flush();
      print('Hive box initialized with default data');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }

  Future<void> _saveAgentsToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Save data with explicit await to ensure it's written to disk
      await box.put('agents', agents);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved agents: ${box.get('agents')}');
      print('Agents data saved successfully');
    } catch (e) {
      print('Error saving agents data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving agents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddNewAgentDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController codeController = TextEditingController();
    List<String> mobileNumbers = [
      '',
    ]; // Start with one empty mobile number field
    List<TextEditingController> mobileControllers = [TextEditingController()];
    TextEditingController emailController = TextEditingController();
    TextEditingController stateController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    String? selectedAgentType;
    String? selectedGrade;
    String? selectedStatus = 'Active';

    // Error states
    bool _nameError = false;
    bool _codeError = false;
    List<bool> _mobileErrors = [false];
    bool _emailError = false;
    bool _agentTypeError = false;
    bool _gradeError = false;
    bool _statusError = false;

    // Initialize focus nodes
    _mobileFocusNodes = List.generate(1, (index) => FocusNode());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                          'Add Agent',
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

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Agent Name Field
                          _buildFormField(
                            title: 'Agent Name: *',
                            child: TextField(
                              controller: nameController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: 'e.g. John Smith',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _nameError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                errorText: _nameError ? 'Agent name is required' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _nameError = value.trim().isEmpty;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Agent Code Field
                          _buildFormField(
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
                                errorText: _codeError ? 'Agent code is required' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _codeError = value.trim().isEmpty;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mobile Numbers Field - Multiple
                          _buildFormField(
                            title: 'Mobile Numbers: *',
                            child: Column(
                              children: [
                                ...mobileNumbers.asMap().entries.map((entry) {
                                  int index = entry.key;

                                  // Initialize focus node if not already created
                                  if (index >= _mobileFocusNodes.length) {
                                    _mobileFocusNodes.add(FocusNode());
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TextField(
                                      controller: mobileControllers[index],
                                      focusNode: _mobileFocusNodes[index],
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                        // Custom mobile number formatter that validates first digit
                                        FirstDigitMobileNumberFormatter(
                                          onValidFirstDigit: () {
                                            // Just validate, don't move focus
                                          },
                                          onInvalidFirstDigit: () {
                                            // Show error when first digit is invalid
                                            setDialogState(() {
                                              _mobileErrors[index] = true;
                                            });
                                          },
                                        ),
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
                                                  setDialogState(() {
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
                                                  setDialogState(() {
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
                                            setDialogState(() {
                                              _mobileErrors[index] = true;
                                            });
                                          }
                                        } else {
                                          if (_mobileErrors[index]) {
                                            setDialogState(() {
                                              _mobileErrors[index] = false;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildFormField(
                            title: 'Email: *',
                            child: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'e.g. john@example.com',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _emailError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                errorText: _emailError ? 'Please enter a valid email address' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _emailError = value.trim().isEmpty || !_isValidEmail(value.trim());
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // State Field - Non-mandatory Text Input
                          _buildFormField(
                            title: 'State:',
                            child: TextField(
                              controller: stateController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'e.g. Tamil Nadu',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // City Field - Non-mandatory
                          _buildFormField(
                            title: 'City:',
                            child: TextField(
                              controller: cityController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'e.g. Chennai',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Agent Type Dropdown - Updated to include "Both"
                          _buildFormField(
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
                                setDialogState(() {
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
                                errorText: _agentTypeError ? 'Agent type is required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Grade Dropdown
                          _buildFormField(
                            title: 'Grade: *',
                            child: DropdownButtonFormField<String>(
                              value: selectedGrade,
                              hint: const Text('Select Grade'),
                              items: grades
                                  .map(
                                    (grade) => DropdownMenuItem(
                                      value: grade['name'].toString(),
                                      child: Text(grade['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedGrade = value;
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
                          _buildFormField(
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
                                setDialogState(() {
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
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3182CE),
                              ),
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
                                // Validate all fields
                                setDialogState(() {
                                  _nameError = nameController.text.trim().isEmpty;
                                  _codeError = codeController.text.trim().isEmpty;
                                  
                                  // Validate mobile numbers
                                  bool hasValidMobileNumber = mobileNumbers.any(
                                    (number) => number.trim().isNotEmpty,
                                  );
                                  if (!hasValidMobileNumber) {
                                    _mobileErrors[0] = true;
                                  } else {
                                    for (int i = 0; i < mobileNumbers.length; i++) {
                                      _mobileErrors[i] = mobileNumbers[i].trim().isNotEmpty && 
                                          !_validateMobileNumber(mobileNumbers[i].trim());
                                    }
                                  }
                                  
                                  _emailError = emailController.text.trim().isEmpty || 
                                      !_isValidEmail(emailController.text.trim());
                                  _agentTypeError = selectedAgentType == null;
                                  _gradeError = selectedGrade == null;
                                  _statusError = selectedStatus == null;
                                });

                                // Check if there are any errors
                                if (_nameError || _codeError || _mobileErrors.any((error) => error) || 
                                    _emailError || _agentTypeError || _gradeError || _statusError) {
                                  return;
                                }

                                // Filter out empty mobile numbers
                                List<String> validMobileNumbers = mobileNumbers
                                    .where((number) => number.trim().isNotEmpty)
                                    .toList();

                                // Create new agent object
                                final newAgent = {
                                  'name': nameController.text.trim(),
                                  'code': codeController.text.trim().toUpperCase(),
                                  'mobileNumbers': validMobileNumbers,
                                  'email': emailController.text.trim(),
                                  'state': stateController.text.trim(),
                                  'city': cityController.text.trim(),
                                  'agentType': selectedAgentType,
                                  'grade': selectedGrade,
                                  'status': selectedStatus,
                                };

                                // Update local state immediately
                                setState(() {
                                  agents.insert(0, newAgent);
                                  _filterAgents(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveAgentsToStorage();

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Agent added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
          );
        },
      ),
    );
  }

  void _showEditAgentDialog(Map<String, dynamic> agent, int index) {
    TextEditingController nameController = TextEditingController(
      text: agent['name'],
    );
    TextEditingController codeController = TextEditingController(
      text: agent['code'],
    );
    List<String> mobileNumbers = List<String>.from(
      agent['mobileNumbers'] ?? [''],
    );
    List<TextEditingController> mobileControllers = mobileNumbers
        .map((number) => TextEditingController(text: number))
        .toList();
    TextEditingController emailController = TextEditingController(
      text: agent['email'],
    );
    TextEditingController stateController = TextEditingController(
      text: agent['state'] ?? '',
    );
    TextEditingController cityController = TextEditingController(
      text: agent['city'] ?? '',
    );
    String? selectedAgentType = agent['agentType'];
    String? selectedGrade = agent['grade'];
    String? selectedStatus = agent['status'];

    // Error states
    bool _nameError = false;
    bool _codeError = false;
    List<bool> _mobileErrors = List.filled(mobileNumbers.length, false);
    bool _emailError = false;
    bool _agentTypeError = false;
    bool _gradeError = false;
    bool _statusError = false;

    // Initialize focus nodes for existing mobile numbers
    _mobileFocusNodes = List.generate(mobileNumbers.length, (index) => FocusNode());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                          'Edit Agent',
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

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Agent Name Field
                          _buildFormField(
                            title: 'Agent Name: *',
                            child: TextField(
                              controller: nameController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: 'e.g. John Smith',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _nameError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                errorText: _nameError ? 'Agent name is required' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _nameError = value.trim().isEmpty;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Agent Code Field
                          _buildFormField(
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
                                errorText: _codeError ? 'Agent code is required' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _codeError = value.trim().isEmpty;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mobile Numbers Field - Multiple
                          _buildFormField(
                            title: 'Mobile Numbers: *',
                            child: Column(
                              children: [
                                ...mobileNumbers.asMap().entries.map((entry) {
                                  int index = entry.key;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TextField(
                                      controller: mobileControllers[index],
                                      focusNode: _mobileFocusNodes[index],
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                        // Custom mobile number formatter that validates first digit
                                        FirstDigitMobileNumberFormatter(
                                          onValidFirstDigit: () {
                                            // Just validate, don't move focus
                                          },
                                          onInvalidFirstDigit: () {
                                            // Show error when first digit is invalid
                                            setDialogState(() {
                                              _mobileErrors[index] = true;
                                            });
                                          },
                                        ),
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
                                                  setDialogState(() {
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
                                                  setDialogState(() {
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
                                            setDialogState(() {
                                              _mobileErrors[index] = true;
                                            });
                                          }
                                        } else {
                                          if (_mobileErrors[index]) {
                                            setDialogState(() {
                                              _mobileErrors[index] = false;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildFormField(
                            title: 'Email: *',
                            child: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'e.g. john@example.com',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _emailError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                errorText: _emailError ? 'Please enter a valid email address' : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  _emailError = value.trim().isEmpty || !_isValidEmail(value.trim());
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // State Field - Non-mandatory Text Input
                          _buildFormField(
                            title: 'State:',
                            child: TextField(
                              controller: stateController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'e.g. Tamil Nadu',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // City Field - Non-mandatory
                          _buildFormField(
                            title: 'City:',
                            child: TextField(
                              controller: cityController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'e.g. Chennai',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Agent Type Dropdown - Updated to include "Both"
                          _buildFormField(
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
                                setDialogState(() {
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
                                errorText: _agentTypeError ? 'Agent type is required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Grade Dropdown
                          _buildFormField(
                            title: 'Grade: *',
                            child: DropdownButtonFormField<String>(
                              value: selectedGrade,
                              hint: const Text('Select Grade'),
                              items: grades
                                  .map(
                                    (grade) => DropdownMenuItem(
                                      value: grade['name'].toString(),
                                      child: Text(grade['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedGrade = value;
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
                          _buildFormField(
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
                                setDialogState(() {
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
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3182CE),
                              ),
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
                                    'This will update agent in master and all associated records.',
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
                                // Validate all fields
                                setDialogState(() {
                                  _nameError = nameController.text.trim().isEmpty;
                                  _codeError = codeController.text.trim().isEmpty;
                                  
                                  // Validate mobile numbers
                                  bool hasValidMobileNumber = mobileNumbers.any(
                                    (number) => number.trim().isNotEmpty,
                                  );
                                  if (!hasValidMobileNumber) {
                                    _mobileErrors[0] = true;
                                  } else {
                                    for (int i = 0; i < mobileNumbers.length; i++) {
                                      _mobileErrors[i] = mobileNumbers[i].trim().isNotEmpty && 
                                          !_validateMobileNumber(mobileNumbers[i].trim());
                                    }
                                  }
                                  
                                  _emailError = emailController.text.trim().isEmpty || 
                                      !_isValidEmail(emailController.text.trim());
                                  _agentTypeError = selectedAgentType == null;
                                  _gradeError = selectedGrade == null;
                                  _statusError = selectedStatus == null;
                                });

                                // Check if there are any errors
                                if (_nameError || _codeError || _mobileErrors.any((error) => error) || 
                                    _emailError || _agentTypeError || _gradeError || _statusError) {
                                  return;
                                }

                                // Filter out empty mobile numbers
                                List<String> validMobileNumbers = mobileNumbers
                                    .where((number) => number.trim().isNotEmpty)
                                    .toList();

                                // Create updated agent object
                                final updatedAgent = {
                                  'name': nameController.text.trim(),
                                  'code': codeController.text.trim().toUpperCase(),
                                  'mobileNumbers': validMobileNumbers,
                                  'email': emailController.text.trim(),
                                  'state': stateController.text.trim(),
                                  'city': cityController.text.trim(),
                                  'agentType': selectedAgentType,
                                  'grade': selectedGrade,
                                  'status': selectedStatus,
                                };

                                // Check if name is being changed
                                bool nameChanged =
                                    updatedAgent['name'] != agent['name'];

                                // Update local state immediately
                                setState(() {
                                  agents[index] = updatedAgent;
                                  _filterAgents(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveAgentsToStorage();

                                // If name changed, update all related records
                                if (nameChanged) {
                                  await _updateAgentNameInAllRecords(
                                    agent['name'].toString(),
                                    updatedAgent['name'].toString(),
                                  );
                                }

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Agent updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
          );
        },
      ),
    );
  }

  Future<void> _updateAgentNameInAllRecords(
    String oldName,
    String newName,
  ) async {
    try {
      // Update agent name in parties box
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final partiesData = appDataBox.get('parties');

        if (partiesData != null && partiesData is List) {
          List<Map<String, dynamic>> updatedPartiesData = [];

          for (var party in partiesData) {
            Map<String, dynamic> partyMap = Map<String, dynamic>.from(party);
            if (partyMap['agent'] == oldName) {
              partyMap['agent'] = newName;
            }
            updatedPartiesData.add(partyMap);
          }

          await appDataBox.put('parties', updatedPartiesData);
          await appDataBox.flush();
          print('Updated agent name in parties box');
        }
      }
    } catch (e) {
      print('Error updating agent name in all records: $e');
    }
  }

  // Helper widget to build form fields with consistent styling
  Widget _buildFormField({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Agents'),
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
              icon: const Icon(
                Icons.add,
                color: Color(0xFF2563EB),
                size: 24,
              ), // Adjusted icon size
              onPressed: _showAddNewAgentDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Agents',
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

                // Agent list
                Expanded(
                  child: filteredAgents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                agents.isEmpty
                                    ? 'No agents found'
                                    : 'No matching agents',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                agents.isEmpty
                                    ? 'Add agents using + button'
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
                          onRefresh: _loadAllData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredAgents.length,
                            itemBuilder: (context, index) {
                              final agent = filteredAgents[index];
                              final isMapped = _isAgentMapped(agent['name']);
                              final originalIndex = agents.indexWhere(
                                (a) => a['name'] == agent['name'],
                              );

                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(
                                      Icons.person,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    agent['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    agent['agentType'] ?? 'Sales',
                                    style: TextStyle(
                                      color: agent['status'] == 'Active'
                                          ? Colors.green[600]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        originalIndex,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    _showEditAgentDialog(agent, originalIndex);
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

  void _showDeleteConfirmationDialog(int index, bool isMapped) {
    final agent = agents[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isMapped
              ? const Text('Already mapped')
              : Text('Are you sure you want to delete "${agent['name']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Update local state immediately
                  setState(() {
                    agents.removeAt(index);
                    _filterAgents(); // Update filtered list
                  });

                  // Save to Hive
                  await _saveAgentsToStorage();

                  Navigator.of(context).pop(); // Close dialog

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agent deleted successfully'),
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
}

// Add this formatter for uppercase text
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// Custom mobile number formatter that validates first digit without moving focus
class FirstDigitMobileNumberFormatter extends TextInputFormatter {
  final VoidCallback onValidFirstDigit;
  final VoidCallback onInvalidFirstDigit;

  FirstDigitMobileNumberFormatter({
    required this.onValidFirstDigit,
    required this.onInvalidFirstDigit,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // If empty, allow
    if (text.isEmpty) {
      return newValue;
    }
    
    // Check first digit
    if (text.length == 1) {
      int firstDigit = int.tryParse(text) ?? 0;
      
      // If first digit is valid (6-9), just allow it
      if (firstDigit >= 6 && firstDigit <= 9) {
        // Don't move focus automatically, just validate
        return newValue;
      } else {
        // If first digit is invalid, prevent further input
        onInvalidFirstDigit();
        return oldValue; // Return old value to prevent invalid input
      }
    }
    
    // Limit to 10 digits
    if (text.length > 10) {
      return TextEditingValue(
        text: text.substring(0, 10),
        selection: const TextSelection.collapsed(offset: 10),
      );
    }
    
    return newValue;
  }
}