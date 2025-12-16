import 'package:hive_flutter/hive_flutter.dart';

class WidthService {
  static final WidthService _instance = WidthService._internal();
  factory WidthService() => _instance;
  WidthService._internal();

  Future<List<Map<String, dynamic>>> getWidths() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      final widthsData = box.get('widths');
      List<Map<String, dynamic>> widths = [];
      
      if (widthsData != null) {
        if (widthsData is List) {
          widths = widthsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            // If it's a string (old format), convert to map
            if (item is String) {
              // Remove the " at the end if it exists
              String widthStr = item.endsWith('"') ? item.substring(0, item.length - 1) : item;
              double? widthValue = double.tryParse(widthStr);
              return {
                'product': 'General',
                'width': widthValue ?? 0.0,
              };
            }
            return <String, dynamic>{};
          }).toList();
        }
      }
      
      return widths;
    } catch (e) {
      print('Error getting widths: $e');
      return [];
    }
  }

  Future<void> addWidth(String product, double width) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing widths
      List<Map<String, dynamic>> widths = await getWidths();
      
      // Check if this width already exists for this product
      bool exists = widths.any((w) => 
        w['product'] == product && w['width'] == width);
      
      if (exists) {
        throw Exception('This width already exists for the selected product');
      }
      
      // Add new width
      widths.insert(0, {
        'product': product,
        'width': width,
      });
      
      // Save to Hive
      await box.put('widths', widths);
      await box.flush();
      
      print('Width added successfully');
    } catch (e) {
      print('Error adding width: $e');
      rethrow;
    }
  }

  Future<void> updateWidth(String oldProduct, double oldWidth, String newProduct, double newWidth) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing widths
      List<Map<String, dynamic>> widths = await getWidths();
      
      // Find the index of the width to update
      int index = widths.indexWhere((w) => 
        w['product'] == oldProduct && w['width'] == oldWidth);
      
      if (index == -1) {
        throw Exception('Width not found');
      }
      
      // Check if this width already exists for this product (excluding current entry)
      bool exists = widths.any((w) => 
        w['product'] == newProduct && w['width'] == newWidth && 
        (w['product'] != oldProduct || w['width'] != oldWidth));
      
      if (exists) {
        throw Exception('This width already exists for the selected product');
      }
      
      // Update width
      widths[index] = {
        'product': newProduct,
        'width': newWidth,
      };
      
      // Save to Hive
      await box.put('widths', widths);
      await box.flush();
      
      print('Width updated successfully');
    } catch (e) {
      print('Error updating width: $e');
      rethrow;
    }
  }

  Future<void> deleteWidth(String product, double width) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing widths
      List<Map<String, dynamic>> widths = await getWidths();
      
      // Remove the width
      widths.removeWhere((w) => w['product'] == product && w['width'] == width);
      
      // Save to Hive
      await box.put('widths', widths);
      await box.flush();
      
      print('Width deleted successfully');
    } catch (e) {
      print('Error deleting width: $e');
      rethrow;
    }
  }

}