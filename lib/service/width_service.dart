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
              // Ensure all values have the correct types
              Map<String, dynamic> widthMap = Map<String, dynamic>.from(item);
              
              // Ensure product is a string and not empty
              if (widthMap['product'] is! String || widthMap['product'].toString().trim().isEmpty) {
                // Skip items without a valid product name
                return null;
              }
              
              // Ensure width is a double
              if (widthMap['width'] is int) {
                widthMap['width'] = (widthMap['width'] as int).toDouble();
              } else if (widthMap['width'] is String) {
                widthMap['width'] = double.tryParse(widthMap['width']) ?? 0.0;
              } else if (widthMap['width'] is! double) {
                widthMap['width'] = 0.0;
              }
              
              return widthMap;
            }
            // If it's a string (old format), skip it since it doesn't have a product name
            if (item is String) {
              // Skip string items without product names
              return null;
            }
            // Skip invalid items
            return null;
          }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
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