import 'package:hive_flutter/hive_flutter.dart';

class VarietyService {
  static final VarietyService _instance = VarietyService._internal();
  factory VarietyService() => _instance;
  VarietyService._internal();

  Future<List<Map<String, dynamic>>> getVarieties() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      final varietiesData = box.get('varieties');
      List<Map<String, dynamic>> varieties = [];

      if (varietiesData != null) {
        // Handle different types of data
        if (varietiesData is List) {
          varieties = varietiesData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      return varieties;
    } catch (e) {
      print('Error getting varieties: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      final productsData = box.get('products');
      List<Map<String, dynamic>> products = [];

      if (productsData != null) {
        // Handle different types of data
        if (productsData is List) {
          products = productsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      // Filter only active products
      return products
          .where((product) => product['status'] == 'Active')
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<void> addVariety(Map<String, dynamic> varietyData) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing varieties
      List<Map<String, dynamic>> varieties = await getVarieties();

      // Check if variety with same name already exists
      bool exists = varieties.any((v) => v['name'] == varietyData['name']);

      if (exists) {
        throw Exception('Variety with this name already exists');
      }

      // Add new variety
      varieties.insert(0, varietyData);

      // Save to Hive
      await box.put('varieties', varieties);
      await box.flush();

      print('Variety added successfully');
    } catch (e) {
      print('Error adding variety: $e');
      rethrow;
    }
  }

  Future<void> updateVariety(
    String oldName,
    Map<String, dynamic> updatedVarietyData,
  ) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing varieties
      List<Map<String, dynamic>> varieties = await getVarieties();

      // Find the index of the variety to update
      int index = varieties.indexWhere((v) => v['name'] == oldName);

      if (index == -1) {
        throw Exception('Variety not found');
      }

      // Check if variety with same name already exists (excluding current entry)
      bool exists = varieties.any(
        (v) => v['name'] == updatedVarietyData['name'] && v['name'] != oldName,
      );

      if (exists) {
        throw Exception('Variety with this name already exists');
      }

      // Update variety
      varieties[index] = updatedVarietyData;

      // Save to Hive
      await box.put('varieties', varieties);
      await box.flush();

      print('Variety updated successfully');
    } catch (e) {
      print('Error updating variety: $e');
      rethrow;
    }
  }

  Future<void> deleteVariety(String varietyName) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing varieties
      List<Map<String, dynamic>> varieties = await getVarieties();

      // Remove variety
      varieties.removeWhere((v) => v['name'] == varietyName);

      // Save to Hive
      await box.put('varieties', varieties);
      await box.flush();

      print('Variety deleted successfully');
    } catch (e) {
      print('Error deleting variety: $e');
      rethrow;
    }
  }
}
