// Create a new file: quality_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class QualityService {
  static final QualityService _instance = QualityService._internal();
  factory QualityService() => _instance;
  QualityService._internal();

  Future<List<Map<String, dynamic>>> getQualities() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      final qualitiesData = box.get('qualities');
      List<Map<String, dynamic>> qualities = [];
      
      if (qualitiesData != null) {
        if (qualitiesData is List) {
          qualities = qualitiesData.map((item) {
            if (item is Map) {
              // Ensure all values have the correct types
              Map<String, dynamic> qualityMap = Map<String, dynamic>.from(item);
              
              // Ensure product is a string and not empty
              if (qualityMap['product'] is! String || qualityMap['product'].toString().trim().isEmpty) {
                // Skip items without a valid product name
                return null;
              }
              
              // Ensure quality is a string
              if (qualityMap['quality'] is! String) {
                qualityMap['quality'] = qualityMap['quality']?.toString() ?? '';
              }
              
              return qualityMap;
            }
            // Skip invalid items
            return null;
          }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
        }
      }
      
      return qualities;
    } catch (e) {
      print('Error getting qualities: $e');
      return [];
    }
  }

  Future<void> addQuality(String product, String quality) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing qualities
      List<Map<String, dynamic>> qualities = await getQualities();
      
      // Check if this quality already exists for this product
      bool exists = qualities.any((q) => 
        q['product'] == product && q['quality'] == quality);
      
      if (exists) {
        throw Exception('This quality already exists for the selected product');
      }
      
      // Add new quality
      qualities.insert(0, {
        'product': product,
        'quality': quality,
      });
      
      // Save to Hive
      await box.put('qualities', qualities);
      await box.flush();
      
      print('Quality added successfully');
    } catch (e) {
      print('Error adding quality: $e');
      rethrow;
    }
  }

  Future<void> updateQuality(String oldProduct, String oldQuality, String newProduct, String newQuality) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing qualities
      List<Map<String, dynamic>> qualities = await getQualities();
      
      // Find the index of the quality to update
      int index = qualities.indexWhere((q) => 
        q['product'] == oldProduct && q['quality'] == oldQuality);
      
      if (index == -1) {
        throw Exception('Quality not found');
      }
      
      // Check if this quality already exists for this product (excluding current entry)
      bool exists = qualities.any((q) => 
        q['product'] == newProduct && q['quality'] == newQuality && 
        (q['product'] != oldProduct || q['quality'] != oldQuality));
      
      if (exists) {
        throw Exception('This quality already exists for the selected product');
      }
      
      // Update quality
      qualities[index] = {
        'product': newProduct,
        'quality': newQuality,
      };
      
      // Save to Hive
      await box.put('qualities', qualities);
      await box.flush();
      
      print('Quality updated successfully');
    } catch (e) {
      print('Error updating quality: $e');
      rethrow;
    }
  }

  Future<void> deleteQuality(String product, String quality) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Get existing qualities
      List<Map<String, dynamic>> qualities = await getQualities();
      
      // Remove the quality
      qualities.removeWhere((q) => q['product'] == product && q['quality'] == quality);
      
      // Save to Hive
      await box.put('qualities', qualities);
      await box.flush();
      
      print('Quality deleted successfully');
    } catch (e) {
      print('Error deleting quality: $e');
      rethrow;
    }
  }
}