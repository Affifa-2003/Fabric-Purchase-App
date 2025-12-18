import 'package:hive_flutter/hive_flutter.dart';

class PartyService {
  static final PartyService _instance = PartyService._internal();
  factory PartyService() => _instance;
  PartyService._internal();

  Future<List<Map<String, dynamic>>> getParties() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      final partiesData = box.get('parties');
      List<Map<String, dynamic>> parties = [];

      if (partiesData != null) {
        if (partiesData is List) {
          parties = partiesData
              .map((item) {
                if (item is Map) {
                  // Ensure all values have the correct types
                  Map<String, dynamic> partyMap = Map<String, dynamic>.from(
                    item,
                  );

                  // Ensure name is a string and not empty
                  if (partyMap['name'] is! String ||
                      partyMap['name'].toString().trim().isEmpty) {
                    // Skip items without a valid name
                    return null;
                  }

                  // Ensure code is a string
                  if (partyMap['code'] is! String) {
                    partyMap['code'] = '';
                  }

                  // Ensure partyType is a string
                  if (partyMap['partyType'] is! String) {
                    partyMap['partyType'] = 'PartyType.direct';
                  }

                  // Ensure agent is a string or null
                  if (partyMap['agent'] is! String &&
                      partyMap['agent'] != null) {
                    partyMap['agent'] = null;
                  }

                  // Ensure mobileNumbers is a list
                  if (partyMap['mobileNumbers'] is! List) {
                    partyMap['mobileNumbers'] = [];
                  }

                  // Ensure email is a string
                  if (partyMap['email'] is! String) {
                    partyMap['email'] = '';
                  }

                  // Ensure address is a string
                  if (partyMap['address'] is! String) {
                    partyMap['address'] = '';
                  }

                  // Ensure state is a string
                  if (partyMap['state'] is! String) {
                    partyMap['state'] = '';
                  }

                  // Ensure district is a string
                  if (partyMap['district'] is! String) {
                    partyMap['district'] = '';
                  }

                  // Keep other fields as they are (could be null)

                  // Ensure status is a string and default to 'Active' if not set
                  if (partyMap['status'] is! String ||
                      partyMap['status'].toString().trim().isEmpty) {
                    partyMap['status'] = 'PartyStatus.active';
                  }

                  // Ensure isMapped is a boolean
                  if (partyMap['isMapped'] is! bool) {
                    partyMap['isMapped'] = false;
                  }

                  return partyMap;
                }
                // Skip invalid items
                return null;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return parties;
    } catch (e) {
      print('Error getting parties: $e');
      return [];
    }
  }

  // Add methods to get agents and transports
  Future<List<String>> getAgents() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<String> agents = [];

      final agentsData = box.get('agents');
      if (agentsData != null && agentsData is List) {
        for (var agent in agentsData) {
          if (agent is Map) {
            agents.add(agent['name']?.toString() ?? '');
          } else if (agent is String) {
            agents.add(agent);
          }
        }
      }

      return agents;
    } catch (e) {
      print('Error getting agents: $e');
      return [];
    }
  }

  Future<List<String>> getTransports() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<String> transports = [];

      final transportsData = box.get('transports');
      if (transportsData != null && transportsData is List) {
        for (var transport in transportsData) {
          if (transport is Map) {
            transports.add(transport['name']?.toString() ?? '');
          } else if (transport is String) {
            transports.add(transport);
          }
        }
      }

      return transports;
    } catch (e) {
      print('Error getting transports: $e');
      return [];
    }
  }

  Future<void> addParty(
    String name,
    String code, {
    String? partyType,
    String? agent,
    List<String>? mobileNumbers,
    String? email,
    String? address,
    String? state,
    String? district,
    String? gstNo,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? branchName,
    String? accountHolderName,
    String? transport,
    String? status,
  }) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing parties
      List<Map<String, dynamic>> parties = await getParties();

      // Check if this party already exists
      bool exists = parties.any((p) => p['name'] == name || p['code'] == code);

      if (exists) {
        throw Exception('Party with this name or code already exists');
      }

      // Add new party
      parties.insert(0, {
        'name': name,
        'code': code,
        'partyType': partyType ?? 'PartyType.direct',
        'agent': agent,
        'mobileNumbers': mobileNumbers ?? [],
        'email': email ?? '',
        'address': address ?? '',
        'state': state ?? '',
        'district': district ?? '',
        'gstNo': gstNo,
        'bankName': bankName,
        'accountNo': accountNo,
        'ifscCode': ifscCode,
        'branchName': branchName,
        'accountHolderName': accountHolderName,
        'transport': transport,
        'status': status ?? 'PartyStatus.active',
        'isMapped': false,
      });

      // Save to Hive
      await box.put('parties', parties);
      await box.flush();

      print('Party added successfully');
    } catch (e) {
      print('Error adding party: $e');
      rethrow;
    }
  }

  Future<void> updateParty(
    String oldName,
    String oldCode,
    String newName,
    String newCode, {
    String? partyType,
    String? agent,
    List<String>? mobileNumbers,
    String? email,
    String? address,
    String? state,
    String? district,
    String? gstNo,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? branchName,
    String? accountHolderName,
    String? transport,
    String? status,
    bool? isMapped,
  }) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing parties
      List<Map<String, dynamic>> parties = await getParties();

      // Find the index of the party to update
      int index = parties.indexWhere(
        (p) => p['name'] == oldName && p['code'] == oldCode,
      );

      if (index == -1) {
        throw Exception('Party not found');
      }

      // Check if this party already exists (excluding current entry)
      bool exists = parties.any(
        (p) =>
            (p['name'] == newName || p['code'] == newCode) &&
            (p['name'] != oldName || p['code'] != oldCode),
      );

      if (exists) {
        throw Exception('Party with this name or code already exists');
      }

      // Update party
      parties[index] = {
        'name': newName,
        'code': newCode,
        'partyType': partyType ?? parties[index]['partyType'],
        'agent': agent ?? parties[index]['agent'],
        'mobileNumbers': mobileNumbers ?? parties[index]['mobileNumbers'],
        'email': email ?? parties[index]['email'],
        'address': address ?? parties[index]['address'],
        'state': state ?? parties[index]['state'],
        'district': district ?? parties[index]['district'],
        'gstNo': gstNo ?? parties[index]['gstNo'],
        'bankName': bankName ?? parties[index]['bankName'],
        'accountNo': accountNo ?? parties[index]['accountNo'],
        'ifscCode': ifscCode ?? parties[index]['ifscCode'],
        'branchName': branchName ?? parties[index]['branchName'],
        'accountHolderName':
            accountHolderName ?? parties[index]['accountHolderName'],
        'transport': transport ?? parties[index]['transport'],
        'status': status ?? parties[index]['status'],
        'isMapped': isMapped ?? parties[index]['isMapped'],
      };

      // Save to Hive
      await box.put('parties', parties);
      await box.flush();

      print('Party updated successfully');
    } catch (e) {
      print('Error updating party: $e');
      rethrow;
    }
  }

  Future<void> deleteParty(String name, String code) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing parties
      List<Map<String, dynamic>> parties = await getParties();

      // Find the party to delete
      int index = parties.indexWhere(
        (p) => p['name'] == name && p['code'] == code,
      );

      if (index == -1) {
        throw Exception('Party not found');
      }

      // Check if party is mapped
      if (parties[index]['isMapped'] == true) {
        throw Exception('Cannot delete party that is mapped to orders');
      }

      // Remove party
      parties.removeAt(index);

      // Save to Hive
      await box.put('parties', parties);
      await box.flush();

      print('Party deleted successfully');
    } catch (e) {
      print('Error deleting party: $e');
      rethrow;
    }
  }
}
