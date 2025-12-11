import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:purchase_app/service/order_service.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'dart:convert';
import 'dart:io';

class PartiesPage extends StatefulWidget {
  const PartiesPage({Key? key}) : super(key: key);

  @override
  _PartiesPageState createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  List<Party> parties = [];
  List<String> agents = [];
  bool _isLoading = true;
  late Box appDataBox;
  late Box ordersBox;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
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
              'agent': null,
              'visitingCardImage': null,
              'isMapped': false,
            });
          }
        }
        print('Loaded ${jsonParties.length} parties from JSON');
      } catch (e) {
        print('Error loading JSON parties: $e');
      }

      // Load agents from JSON
      List<String> jsonAgents = [];
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        jsonAgents = jsonData['agents'] != null ? List<String>.from(jsonData['agents']) : [];
        print('Loaded ${jsonAgents.length} agents from JSON');
      } catch (e) {
        print('Error loading JSON agents: $e');
      }

      // Load data from Hive
      List<Map<String, dynamic>> hiveParties = [];
      List<String> hiveAgents = [];
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
        
        final partiesData = appDataBox.get('parties');
        if (partiesData != null) {
          for (var party in partiesData) {
            if (party is Map) {
              hiveParties.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
              // Handle legacy data format
              hiveParties.add({
                'name': party,
                'agent': null,
                'visitingCardImage': null,
                'isMapped': false,
              });
            }
          }
        }
        
        final agentsData = appDataBox.get('agents');
        hiveAgents = agentsData != null ? List<String>.from(agentsData) : [];
        print('Loaded ${hiveParties.length} parties and ${hiveAgents.length} agents from Hive');
      } catch (e) {
        print('Error loading Hive data: $e');
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
      
      // Convert to list and sort by creation date (newest first)
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
      
      // Combine agents
      agents = [...jsonAgents, ...hiveAgents];
      agents = agents.toSet().toList(); // Remove duplicates
      
      setState(() {
        _isLoading = false;
      });
      
      print('Combined parties list: ${parties.map((p) => p.name).toList()}');
      print('Combined agents list: $agents');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        parties = [];
        agents = [];
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
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        defaultParties = jsonData['parties'] != null ? List<String>.from(jsonData['parties']) : [];
        defaultAgents = jsonData['agents'] != null ? List<String>.from(jsonData['agents']) : [];
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
      }
      
      // Convert parties to the new format
      List<Map<String, dynamic>> partiesMap = defaultParties.map((party) => {
        'name': party,
        'agent': null,
        'visitingCardImage': null,
        'isMapped': false,
      }).toList();
      
      // Set default values
      await box.put('parties', partiesMap);
      await box.put('agents', defaultAgents);
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

  void _showAddNewPartyDialog() {
    TextEditingController newPartyController = TextEditingController();
    String? selectedAgent;
    File? visitingCardImage;

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

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Party Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Party Name: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: newPartyController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter party name',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onEditingComplete: () {
                                  // Trim trailing spaces when editing is complete
                                  newPartyController.text = newPartyController.text.trim();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Agent Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Agent: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedAgent,
                                hint: const Text('Select agent...'),
                                isDense: true,
                                style: const TextStyle(color: Colors.black),
                                items: agents.map((agent) {
                                  return DropdownMenuItem<String>(
                                    value: agent,
                                    child: Text(agent),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedAgent = value;
                                  });
                                },
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
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Visiting Card Photo Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visiting Card Photo: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final XFile? pickedFile = await _imagePicker.pickImage(
                                    source: ImageSource.camera,
                                    preferredCameraDevice: CameraDevice.rear,
                                  );
                                  if (pickedFile != null) {
                                    setState(() {
                                      visitingCardImage = File(pickedFile.path);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo,
                                        color: Color(0xFF529FF3),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          visitingCardImage != null
                                              ? 'Photo captured'
                                              : 'Tap to capture visiting card',
                                          style: TextStyle(
                                            color: visitingCardImage != null
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (visitingCardImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      visitingCardImage!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
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
                                // Trim any trailing spaces before saving
                                String partyName = newPartyController.text.trim();
                                if (partyName.isNotEmpty) {
                                  // Create new party
                                  final newParty = Party(
                                    name: partyName,
                                    agent: selectedAgent,
                                    visitingCardImage: visitingCardImage?.path,
                                    isMapped: false,
                                  );

                                  // Update local state immediately
                                  this.setState(() {
                                    // Add to the beginning of the list
                                    parties.insert(0, newParty);
                                  });

                                  // Save to Hive
                                  await _savePartiesToStorage();

                                  // Force a UI update
                                  this.setState(() {});

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
            );
          },
        );
      },
    );
  }

  void _showEditPartyDialog(Party party) {
  TextEditingController partyNameController = TextEditingController(text: party.name);
  String? selectedAgent = party.agent;
  File? visitingCardImage;
  String? originalImagePath = party.visitingCardImage;
  String originalPartyName = party.name; // Store the original name

  // If there's an existing image path, create a File object
  if (originalImagePath != null) {
    visitingCardImage = File(originalImagePath);
  }

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

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Party Name Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Party Name: *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: partyNameController,
                              inputFormatters: [
                                NoLeadingOrMultipleSpacesFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter party name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onEditingComplete: () {
                                // Trim trailing spaces when editing is complete
                                partyNameController.text = partyNameController.text.trim();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Agent Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agent: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedAgent,
                              hint: const Text('Select agent...'),
                              isDense: true,
                              style: const TextStyle(color: Colors.black),
                              items: agents.map((agent) {
                                return DropdownMenuItem<String>(
                                  value: agent,
                                  child: Text(agent),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedAgent = value;
                                });
                              },
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visiting Card Photo Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visiting Card Photo: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final XFile? pickedFile = await _imagePicker.pickImage(
                                  source: ImageSource.camera,
                                  preferredCameraDevice: CameraDevice.rear,
                                );
                                if (pickedFile != null) {
                                  setState(() {
                                    visitingCardImage = File(pickedFile.path);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo,
                                      color: Color(0xFF529FF3),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        visitingCardImage != null
                                            ? 'Photo captured'
                                            : 'Tap to capture visiting card',
                                        style: TextStyle(
                                          color: visitingCardImage != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (visitingCardImage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    visitingCardImage!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
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
                              // Trim any trailing spaces before saving
                              String partyName = partyNameController.text.trim();
                              if (partyName.isNotEmpty) {
                                // Find party in list and update it
                                final index = parties.indexWhere((p) => p.name == party.name);
                                if (index != -1) {
                                  // Check if party name is being changed
                                  bool nameChanged = partyName != originalPartyName;
                                  
                                  // Update local state immediately
                                  this.setState(() {
                                    parties[index] = Party(
                                      name: partyName,
                                      agent: selectedAgent,
                                      visitingCardImage: visitingCardImage?.path,
                                      isMapped: party.isMapped,
                                    );
                                  });

                                  // Save to Hive
                                  await _savePartiesToStorage();

                                  // If name changed, update all related records
                                  if (nameChanged) {
                                    await _updatePartyNameInAllRecords(originalPartyName, partyName);
                                  }

                                  // Force a UI update
                                  this.setState(() {});

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
                  });
                  
                  // Save to Hive
                  await _savePartiesToStorage();
                  
                  // Force a UI update
                  this.setState(() {});
                  
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
        toolbarHeight: 90,
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
          : parties.isEmpty
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
                        'No parties found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add parties using the + button',
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
                    padding: const EdgeInsets.all(16.0),
                    itemCount: parties.length,
                    itemBuilder: (context, index) {
                      final party = parties[index];
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
                            child: party.visitingCardImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.file(
                                      File(party.visitingCardImage!),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.business,
                                          color: const Color(0xFF2563EB),
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
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
                          // Removed subtitle that showed agent name
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
    );
  }
}

class Party {
  final String name;
  final String? agent;
  final String? visitingCardImage;
  final bool isMapped;

  Party({
    required this.name,
    this.agent,
    this.visitingCardImage,
    this.isMapped = false,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      name: map['name'] ?? '',
      agent: map['agent'],
      visitingCardImage: map['visitingCardImage'],
      isMapped: map['isMapped'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'agent': agent,
      'visitingCardImage': visitingCardImage,
      'isMapped': isMapped,
    };
  }
}

