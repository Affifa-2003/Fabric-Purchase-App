// lib/service/weave_type_service.dart
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
          weaveTypes = weaveTypesData
              .map((item) {
                if (item is Map) {
                  // Ensure all values have the correct types
                  Map<String, dynamic> weaveTypeMap = Map<String, dynamic>.from(
                    item,
                  );

                  // Ensure product is a string and not empty
                  if (weaveTypeMap['product'] is! String ||
                      weaveTypeMap['product'].toString().trim().isEmpty) {
                    // Skip items without a valid product name
                    return null;
                  }

                  // Ensure code is a string and not empty
                  if (weaveTypeMap['code'] is! String ||
                      weaveTypeMap['code'].toString().trim().isEmpty) {
                    // Skip items without a valid code
                    return null;
                  }

                  // Ensure name is a string
                  if (weaveTypeMap['name'] is! String) {
                    weaveTypeMap['name'] =
                        weaveTypeMap['name']?.toString() ?? '';
                  }

                  // Ensure description is a string (can be empty)
                  if (weaveTypeMap['description'] is! String) {
                    weaveTypeMap['description'] = '';
                  }

                  // Ensure status is a string and default to 'Active' if not set
                  if (weaveTypeMap['status'] is! String ||
                      weaveTypeMap['status'].toString().trim().isEmpty) {
                    weaveTypeMap['status'] = 'Active';
                  }

                  return weaveTypeMap;
                }
                // Skip invalid items
                return null;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return weaveTypes;
    } catch (e) {
      print('Error getting weave types: $e');
      return [];
    }
  }

  Future<void> addWeaveType(
    String product,
    String code, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();

      // Check if this weave type code already exists
      bool codeExists = weaveTypes.any((w) => w['code'] == code);

      if (codeExists) {
        throw Exception('This weave type code already exists');
      }

      // Add new weave type
      weaveTypes.insert(0, {
        'product': product,
        'code': code,
        'name': name ?? '', // Default to empty string if not provided
        'description':
            description ?? '', // Default to empty string if not provided
        'status': status ?? 'Active', // Default to 'Active' if not provided
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

  Future<void> updateWeaveType(
    String oldProduct,
    String oldCode,
    String newProduct,
    String newCode, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();

      // Find the index of the weave type to update
      int index = weaveTypes.indexWhere(
        (w) => w['product'] == oldProduct && w['code'] == oldCode,
      );

      if (index == -1) {
        throw Exception('Weave type not found');
      }

      // Check if this weave type code already exists (excluding current entry)
      bool codeExists = weaveTypes.any(
        (w) =>
            w['code'] == newCode &&
            (w['product'] != oldProduct || w['code'] != oldCode),
      );

      if (codeExists) {
        throw Exception('This weave type code already exists');
      }

      // Update weave type
      weaveTypes[index] = {
        'product': newProduct,
        'code': newCode,
        'name':
            name ??
            weaveTypes[index]['name'], // Use existing name if not provided
        'description':
            description ??
            weaveTypes[index]['description'], // Use existing description if not provided
        'status':
            status ??
            weaveTypes[index]['status'], // Use existing status if not provided
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

  Future<void> deleteWeaveType(String product, String code) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing weave types
      List<Map<String, dynamic>> weaveTypes = await getWeaveTypes();

      // Remove weave type
      weaveTypes.removeWhere(
        (w) => w['product'] == product && w['code'] == code,
      );

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
