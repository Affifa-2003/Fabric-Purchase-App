// lib/service/order_form_type_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class OrderFormTypeService {
  static final OrderFormTypeService _instance = OrderFormTypeService._internal();
  factory OrderFormTypeService() => _instance;
  OrderFormTypeService._internal();

  Future<List<Map<String, dynamic>>> getOrderFormTypes() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      final orderFormTypesData = box.get('orderFormTypes');
      List<Map<String, dynamic>> orderFormTypes = [];
      
      if (orderFormTypesData != null) {
        if (orderFormTypesData is List) {
          orderFormTypes = orderFormTypesData.map((item) {
            if (item is Map) {
              // Ensure all values have the correct types
              Map<String, dynamic> orderFormTypeMap = Map<String, dynamic>.from(item);
              
              // Ensure name is a string and not empty
              if (orderFormTypeMap['name'] is! String || orderFormTypeMap['name'].toString().trim().isEmpty) {
                // Skip items without a valid name
                return null;
              }
              
              // Ensure description is a string (can be empty)
              if (orderFormTypeMap['description'] is! String) {
                orderFormTypeMap['description'] = '';
              }
              
              // Ensure isPlainMixed is a boolean
              if (orderFormTypeMap['isPlainMixed'] is! bool) {
                orderFormTypeMap['isPlainMixed'] = false;
              }
              
              // Ensure status is a string and default to 'Active' if not set
              if (orderFormTypeMap['status'] is! String || orderFormTypeMap['status'].toString().trim().isEmpty) {
                orderFormTypeMap['status'] = 'Active';
              }
              
              return orderFormTypeMap;
            }
            // Skip invalid items
            return null;
          }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
        }
      }
      
      return orderFormTypes;
    } catch (e) {
      print('Error getting order form types: $e');
      return [];
    }
  }

  Future<void> addOrderFormType(String name, {String? description, bool? isPlainMixed, String? status}) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing order form types
      List<Map<String, dynamic>> orderFormTypes = await getOrderFormTypes();
      
      // Check if this order form type already exists
      bool exists = orderFormTypes.any((type) => 
        type['name'] == name);
      
      if (exists) {
        throw Exception('This order form type already exists');
      }
      
      // Add new order form type
      orderFormTypes.insert(0, {
        'name': name,
        'description': description ?? '', // Default to empty string if not provided
        'isPlainMixed': isPlainMixed ?? false, // Default to false if not provided
        'status': status ?? 'Active', // Default to 'Active' if not provided
      });
      
      // Save to Hive
      await box.put('orderFormTypes', orderFormTypes);
      await box.flush();
      
      print('Order form type added successfully');
    } catch (e) {
      print('Error adding order form type: $e');
      rethrow;
    }
  }

  Future<void> updateOrderFormType(String oldName, String newName, {String? description, bool? isPlainMixed, String? status}) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing order form types
      List<Map<String, dynamic>> orderFormTypes = await getOrderFormTypes();
      
      // Find the index of the order form type to update
      int index = orderFormTypes.indexWhere((type) => 
        type['name'] == oldName);
      
      if (index == -1) {
        throw Exception('Order form type not found');
      }
      
      // Check if this order form type already exists (excluding current entry)
      bool exists = orderFormTypes.any((type) => 
        type['name'] == newName && type['name'] != oldName);
      
      if (exists) {
        throw Exception('This order form type already exists');
      }
      
      // Update order form type
      orderFormTypes[index] = {
        'name': newName,
        'description': description ?? orderFormTypes[index]['description'], // Use existing description if not provided
        'isPlainMixed': isPlainMixed ?? orderFormTypes[index]['isPlainMixed'], // Use existing isPlainMixed if not provided
        'status': status ?? orderFormTypes[index]['status'], // Use existing status if not provided
      };
      
      // Save to Hive
      await box.put('orderFormTypes', orderFormTypes);
      await box.flush();
      
      print('Order form type updated successfully');
    } catch (e) {
      print('Error updating order form type: $e');
      rethrow;
    }
  }

  Future<void> deleteOrderFormType(String name) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing order form types
      List<Map<String, dynamic>> orderFormTypes = await getOrderFormTypes();
      
      // Remove order form type
      orderFormTypes.removeWhere((type) => type['name'] == name);
      
      // Save to Hive
      await box.put('orderFormTypes', orderFormTypes);
      await box.flush();
      
      print('Order form type deleted successfully');
    } catch (e) {
      print('Error deleting order form type: $e');
      rethrow;
    }
  }
}