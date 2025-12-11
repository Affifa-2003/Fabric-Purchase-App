import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'dart:convert';

class AgentsPage extends StatefulWidget {
  const AgentsPage({Key? key}) : super(key: key);

  @override
  _AgentsPageState createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  List<String> agents = [];
  bool _isLoading = true;
  late Box appDataBox;

  @override
  void initState() {
    super.initState();
    _loadAgents();
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

  // In the _loadAgents method, update the code to properly handle the data format
  Future<void> _loadAgents() async {
    try {
      // Load data from JSON
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
      List<String> hiveAgents = [];
      try {
        // Ensure the box is open
        if (!Hive.isBoxOpen('appData')) {
          await Hive.openBox('appData');
        }

        appDataBox = Hive.box('appData');
        
        // Initialize with defaults if box is empty
        if (appDataBox.isEmpty) {
          await _initializeBoxWithDefaults(appDataBox);
        }
        
        final agentsData = appDataBox.get('agents');
        hiveAgents = agentsData != null ? List<String>.from(agentsData) : [];
        print('Loaded ${hiveAgents.length} agents from Hive');
      } catch (e) {
        print('Error loading Hive agents: $e');
      }

      // Combine JSON and Hive data, removing duplicates
      setState(() {
        agents = [...jsonAgents, ...hiveAgents];
        agents = agents.toSet().toList(); // Remove duplicates
        _isLoading = false;
      });
      
      print('Combined agents list: $agents');
    } catch (e) {
      print('Error loading agents: $e');
      setState(() {
        agents = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default agents');
      
      // Load default agents from JSON if available
      List<String> defaultAgents = [];
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        defaultAgents = jsonData['agents'] != null ? List<String>.from(jsonData['agents']) : [];
      } catch (e) {
        print('Error loading default agents from JSON: $e');
        // Fallback to hardcoded defaults
        defaultAgents = [
          'Raju Sharma',
          'Vijay Kumar',
          'Anil Reddy',
          'Sunil Patel',
        ];
      }
      
      // Set default agents
      await box.put('agents', defaultAgents);
      await box.flush();
      print('Hive box initialized with default agents');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }

  Future<void> _saveAgentsToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Convert all agents to List<String> to ensure type safety
      final List<String> agentsToSave = agents
          .map((e) => e.toString())
          .toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('agents', agentsToSave);
      
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
    TextEditingController newAgentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                    // Agent Name Field in a card
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
                                'Agent Name: *',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: newAgentController,
                            inputFormatters: [
                              NoLeadingOrMultipleSpacesFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'e.g. John Smith',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onEditingComplete: () {
                              // Trim trailing spaces when editing is complete
                              newAgentController.text = newAgentController.text.trim();
                            },
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
                            // Trim any trailing spaces before saving
                            String agentName = newAgentController.text.trim();
                            if (agentName.isNotEmpty) {
                              // Update local state immediately
                              setState(() {
                                // Add to the beginning of the list
                                agents.insert(0, agentName);
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
  }

  void _showEditAgentDialog(String agentName, int index) {
    TextEditingController agentNameController = TextEditingController(text: agentName);

    showDialog(
      context: context,
      builder: (context) {
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
                    // Agent Name Field in a card
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
                                'Agent Name: *',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: agentNameController,
                            inputFormatters: [
                              NoLeadingOrMultipleSpacesFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'e.g. John Smith',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onEditingComplete: () {
                              // Trim trailing spaces when editing is complete
                              agentNameController.text = agentNameController.text.trim();
                            },
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
                              'This will update the agent in master and all associated records.',
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
                            // Trim any trailing spaces before saving
                            String newAgentName = agentNameController.text.trim();
                            if (newAgentName.isNotEmpty) {
                              // Check if name is being changed
                              bool nameChanged = newAgentName != agentName;
                              
                              // Update local state immediately
                              setState(() {
                                // Remove the old agent
                                agents.removeAt(index);
                                // Add the updated agent at the beginning
                                agents.insert(0, newAgentName);
                              });

                              // Save to Hive
                              await _saveAgentsToStorage();

                              // If name changed, update all related records
                              if (nameChanged) {
                                await _updateAgentNameInAllRecords(agentName, newAgentName);
                              }

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Agent updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
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
  }

  Future<void> _updateAgentNameInAllRecords(String oldName, String newName) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 90,
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
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24), // Adjusted icon size
              onPressed: _showAddNewAgentDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : agents.isEmpty
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
                        'No agents found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add agents using the + button',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAgents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      final isMapped = _isAgentMapped(agent);
                      
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
                              Icons.person,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          title: Text(
                            agent,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Color(0xFFEF4444),
                            ),
                            onPressed: () {
                              _showDeleteConfirmationDialog(index, isMapped);
                            },
                          ),
                          onTap: () {
                            _showEditAgentDialog(agent, index);
                          },
                        ),
                      );
                    },
                  ),
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
              : Text('Are you sure you want to delete "$agent"?'),
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
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Update local state immediately
                  setState(() {
                    agents.removeAt(index);
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