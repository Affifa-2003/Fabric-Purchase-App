// Create a new file: weave_type_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class WeaveTypeService {
  static final WeaveTypeService _instance = WeaveTypeService._internal();
  factory WeaveTypeService() => _instance;
  WeaveTypeService._internal();

  Future<List<Map<String, dynamic>>> getWeaveTypes() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      final weaveTypesData = box.get('weaveTypes');
      List<Map<String, dynamic>> weaveTypes = [];
      
      if (weaveTypesData != null) {
        if (weaveTypesData is List) {
          weaveTypes = weaveTypesData.map((item) {
            if (item is Map) {
              // Ensure all values have the correct types
              Map<String, dynamic> weaveTypeMap = Map<String, dynamic>.from(item);
              
              // Ensure product is a string and not empty
              if (weaveTypeMap['product'] is! String || weaveTypeMap['product'].toString().trim().isEmpty) {
                // Skip items without a valid product name
                return null;
              }
              
              // Ensure weaveType is a string
              if (weaveTypeMap['weaveType'] is! String) {
                weaveTypeMap['weaveType'] = weaveTypeMap['weaveType']?.toString() ?? '';
              }
              
              return weaveTypeMap;
            }
            // Skip invalid items
            return null;
          }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
        }
      }
      
      return weaveTypes;
    } catch (e) {
      print('Error getting weave types: $e');
      return [];
    }
  }

  Future<void> addWeaveType(String product, String weaveType) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();
      
      // Check if this weave type already exists for this product
      bool exists = weaveTypes.any((w) => 
        w['product'] == product && w['weaveType'] == weaveType);
      
      if (exists) {
        throw Exception('This weave type already exists for the selected product');
      }
      
      // Add new weave type
      weaveTypes.insert(0, {
        'product': product,
        'weaveType': weaveType,
      });
      
      // Save to Hive
      await box.put('weaveTypes', weaveTypes);
      await box.flush();
      
      print('Weave type added successfully');
    } catch (e) {
      print('Error adding weave type: $e');
      rethrow;
    }
  }

  Future<void> updateWeaveType(String oldProduct, String oldWeaveType, String newProduct, String newWeaveType) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();
      
      // Find the index of the weave type to update
      int index = weaveTypes.indexWhere((w) => 
        w['product'] == oldProduct && w['weaveType'] == oldWeaveType);
      
      if (index == -1) {
        throw Exception('Weave type not found');
      }
      
      // Check if this weave type already exists for this product (excluding current entry)
      bool exists = weaveTypes.any((w) => 
        w['product'] == newProduct && w['weaveType'] == newWeaveType && 
        (w['product'] != oldProduct || w['weaveType'] != oldWeaveType));
      
      if (exists) {
        throw Exception('This weave type already exists for the selected product');
      }
      
      // Update weave type
      weaveTypes[index] = {
        'product': newProduct,
        'weaveType': newWeaveType,
      };
      
      // Save to Hive
      await box.put('weaveTypes', weaveTypes);
      await box.flush();
      
      print('Weave type updated successfully');
    } catch (e) {
      print('Error updating weave type: $e');
      rethrow;
    }
  }

  Future<void> deleteWeaveType(String product, String weaveType) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();
      
      // Remove the weave type
      weaveTypes.removeWhere((w) => w['product'] == product && w['weaveType'] == weaveType);
      
      // Save to Hive
      await box.put('weaveTypes', weaveTypes);
      await box.flush();
      
      print('Weave type deleted successfully');
    } catch (e) {
      print('Error deleting weave type: $e');
      rethrow;
    }
  }
}