import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
// Import the UUID utility
import 'package:purchase_app/core/utils/uuid_utils.dart';

class AgentService {
  static final AgentService _instance = AgentService._internal();
  factory AgentService() => _instance;
  AgentService._internal();

  // Validate email format
  bool _isValidEmail(String email) {
    final RegExp _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
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
  bool isAgentMapped(String agentName) {
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

  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Initialize with defaults if box is empty
      if (box.isEmpty) {
        await _initializeBoxWithDefaults(box);
      }

      final agentsData = box.get('agents');
      List<Map<String, dynamic>> agents = [];

      if (agentsData != null && agentsData is List) {
        agents = agentsData.map((agent) {
          if (agent is Map) {
            return Map<String, dynamic>.from(agent);
          }
          return <String, dynamic>{'name': agent.toString()};
        }).toList();
      }

      return agents;
    } catch (e) {
      print('Error getting agents: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStates() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final statesData = box.get('states');

      if (statesData != null && statesData is List) {
        return statesData.map((state) {
          if (state is Map) {
            return Map<String, dynamic>.from(state);
          }
          return <String, dynamic>{'name': state.toString()};
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error getting states: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDistricts() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final districtsData = box.get('districts');

      if (districtsData != null && districtsData is List) {
        return districtsData.map((district) {
          if (district is Map) {
            return Map<String, dynamic>.from(district);
          }
          return <String, dynamic>{'name': district.toString()};
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error getting districts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGrades() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final gradesData = box.get('grades');

      if (gradesData != null && gradesData is List) {
        return gradesData.map((grade) {
          if (grade is Map) {
            return Map<String, dynamic>.from(grade);
          }
          return <String, dynamic>{'name': grade.toString()};
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }

  // MODIFIED: Now generates a UUID for the new agent and ensures it's the first key.
  Future<void> addAgent(Map<String, dynamic> agentData) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing agents
      List<Map<String, dynamic>> agents = await getAgents();

      // Check if agent with same name or code already exists
      bool exists = agents.any(
        (a) => a['name'] == agentData['name'] || a['code'] == agentData['code'],
      );

      if (exists) {
        throw Exception('Agent with this name or code already exists');
      }

      // MODIFIED: Create a new map with the ID as the first key
      final newAgentWithId = {
        'id': UUID.generate(),
        ...agentData, // Spread the existing agent data
      };

      // Add new agent
      agents.insert(0, newAgentWithId);

      // Save to Hive
      await box.put('agents', agents);
      await box.flush();

      print('Agent added successfully');
    } catch (e) {
      print('Error adding agent: $e');
      rethrow;
    }
  }

  // MODIFIED: Now takes agentId for identification and ensures it's the first key.
  Future<void> updateAgent(
    String agentId,
    Map<String, dynamic> updatedAgentData,
  ) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing agents
      List<Map<String, dynamic>> agents = await getAgents();

      // Find the index of the agent to update by its ID
      int index = agents.indexWhere((a) => a['id'] == agentId);

      if (index == -1) {
        throw Exception('Agent not found');
      }
      
      // Get the original agent to check for name/code conflicts
      final originalAgent = agents[index];
      bool exists = agents.any(
        (a) =>
            (a['name'] == updatedAgentData['name'] ||
                a['code'] == updatedAgentData['code']) &&
            a['id'] != agentId,
      );

      if (exists) {
        throw Exception('Agent with this name or code already exists');
      }

      // MODIFIED: Create a new map with the ID as the first key
      final updatedAgentWithId = {
        'id': agentId,
        // Spread all properties from the updated data, but exclude the original id if it exists
        ...updatedAgentData..remove('id'), 
      };

      // Update agent
      agents[index] = updatedAgentWithId;

      // Save to Hive
      await box.put('agents', agents);
      await box.flush();

      // If name changed, update all related records
      if (originalAgent['name'] != updatedAgentData['name']) {
        await _updateAgentNameInAllRecords(
          originalAgent['name'],
          updatedAgentData['name'],
        );
      }

      print('Agent updated successfully');
    } catch (e) {
      print('Error updating agent: $e');
      rethrow;
    }
  }

  // MODIFIED: Now takes agentId for identification.
  Future<void> deleteAgent(String agentId) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing agents
      List<Map<String, dynamic>> agents = await getAgents();

      // Remove agent by its ID
      agents.removeWhere((a) => a['id'] == agentId);

      // Save to Hive
      await box.put('agents', agents);
      await box.flush();

      print('Agent deleted successfully');
    } catch (e) {
      print('Error deleting agent: $e');
      rethrow;
    }
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

  // MODIFIED: Generates IDs for default agents and grades, ensuring ID is the first key.
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
            // MODIFIED: Create a new map with the ID as the first key
            return {
              'id': UUID.generate(),
              'name': agent,
              'code': agent.substring(0, 3).toUpperCase(),
              'mobileNumbers': ['9876543210'],
              'agentType': 'Sales',
            };
          }
          // MODIFIED: Create a new map with the ID as the first key
          final agentWithId = {
            'id': UUID.generate(),
            ...Map<String, dynamic>.from(agent),
          };
          return agentWithId;
        }).toList();
      } else {
        // Fallback to hardcoded defaults
        defaultAgents = [
          {
            'id': UUID.generate(),
            'name': 'Raju Sharma',
            'code': 'RAJ',
            'mobileNumbers': ['9876543210'],
            'agentType': 'Sales',
          },
          {
            'id': UUID.generate(),
            'name': 'Vijay Kumar',
            'code': 'VIJ',
            'mobileNumbers': ['9876543211'],
            'agentType': 'Purchase',
          },
          {
            'id': UUID.generate(),
            'name': 'Anil Reddy',
            'code': 'ANI',
            'mobileNumbers': ['9876543212'],
            'agentType': 'Both',
          },
          {
            'id': UUID.generate(),
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
          {'id': UUID.generate(), 'name': 'A', 'description': 'Grade A'},
          {'id': UUID.generate(), 'name': 'B', 'description': 'Grade B'},
          {'id': UUID.generate(), 'name': 'C', 'description': 'Grade C'},
          {'id': UUID.generate(), 'name': 'D', 'description': 'Grade D'},
        ];
        await box.put('grades', defaultGrades);
      }

      await box.flush();
      print('Hive box initialized with default data');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }
}