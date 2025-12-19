import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        rootBundle,
        TextInputFormatter,
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/constants/app_constants.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/Modules/Purchase/features/services/agent_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_agent_dialog.dart';
import 'dart:convert';
// NEW: Import the UUID utility
import 'package:purchase_app/core/utils/uuid_utils.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterAgents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      agents = await AgentService().getAgents();
      print('agents: $agents');
      print('Loaded ${agents.length} agents from service');
      setState(() {
        filteredAgents = List.from(agents);
      });
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
      states = await AgentService().getStates();
      print('Loaded ${states.length} states');
    } catch (e) {
      print('Error loading states: $e');
      states = [];
    }
  }

  // Load districts data
  Future<void> _loadDistricts() async {
    try {
      districts = await AgentService().getDistricts();
      print('Loaded ${districts.length} districts');
    } catch (e) {
      print('Error loading districts: $e');
      districts = [];
    }
  }

  // Load grades data
  Future<void> _loadGrades() async {
    try {
      grades = await AgentService().getGrades();
      print('Loaded ${grades.length} grades');
    } catch (e) {
      print('Error loading grades: $e');
      grades = [];
    }
  }

  void _showAddNewAgentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddAgentDialog(
          states: states,
          districts: districts,
          grades: grades,
        );
      },
    ).then((result) {
      if (result != null) {
        // Add the agent using the service
        AgentService()
            .addAgent(result)
            .then((_) {
              // Reload the agents
              _loadAgents();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agent added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding agent: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  // MODIFIED: Now takes the agent map and finds it by ID.
  void _showEditAgentDialog(Map<String, dynamic> agent) {
    showDialog(
      context: context,
      builder: (context) {
        return AddAgentDialog(
          isEditMode: true,
          initialAgent: agent,
          states: states,
          districts: districts,
          grades: grades,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update the agent using the service, passing the agent's ID
        AgentService()
            .updateAgent(agent['id'], result)
            .then((_) {
              // Reload the agents
              _loadAgents();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agent updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating agent: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  // MODIFIED: Now takes the agent map and finds it by ID.
  void _showDeleteConfirmationDialog(Map<String, dynamic> agent, bool isMapped) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isMapped
              ? const Text(
                  'This agent is already mapped with parties and cannot be deleted.',
                )
              : Text('Are you sure you want to delete "${agent['name']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Delete the agent using the service, passing the agent's ID
                  AgentService()
                      .deleteAgent(agent['id'])
                      .then((_) {
                        // Reload the agents
                        _loadAgents();

                        Navigator.of(context).pop(); // Close dialog

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agent deleted successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting agent: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
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
      key: _scaffoldKey,
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
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
                color: Color(0xFF2563EB), // Blue color for the + icon
                size: 24,
              ),
              onPressed: _showAddNewAgentDialog,
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        primaryColor: const Color(0xFF2563EB),
        appTitle: 'Hyatt Purchase',
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
                              // MODIFIED: Use the agent's ID to check if it's mapped.
                              final isMapped = AgentService().isAgentMapped(
                                agent['name'],
                              );
                              // MODIFIED: Find the original agent by ID to ensure we have the full, correct data.
                              final originalAgent = agents.firstWhere(
                                (a) => a['id'] == agent['id'],
                                orElse: () => agent, // Fallback to the filtered agent if not found
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
                                      // MODIFIED: Pass the full original agent map.
                                      _showDeleteConfirmationDialog(
                                        originalAgent,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // MODIFIED: Pass the full original agent map.
                                    _showEditAgentDialog(originalAgent);
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