import 'package:hive_flutter/hive_flutter.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  Future<List<String>> getAgents() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<String> agents = [];

      final agentsData = box.get('agents');
      if (agentsData != null && agentsData is List) {
        for (var agent in agentsData) {
          if (agent is String) {
            agents.add(agent);
          } else if (agent is Map && agent['name'] != null) {
            agents.add(agent['name'] as String);
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
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<String> transports = [];

      final transportsData = box.get('transports');
      if (transportsData != null && transportsData is List) {
        for (var transport in transportsData) {
          if (transport is String) {
            transports.add(transport);
          } else if (transport is Map && transport['name'] != null) {
            transports.add(transport['name'] as String);
          }
        }
      }

      return transports;
    } catch (e) {
      print('Error getting transports: $e');
      return [];
    }
  }
}
