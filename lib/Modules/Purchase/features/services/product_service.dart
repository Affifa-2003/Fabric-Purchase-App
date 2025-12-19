import 'package:hive_flutter/hive_flutter.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  Map<String, bool> isProductMapped(String productName) {
    try {
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      print('Checking if product "$productName" is mapped');

      Map<String, bool> mappedAttributes = {
        'variety': false,
        'colorGroup': false,
        'sampleMeter': false,
        'width': false,
        'weaveType': false,
        'quality': false,
      };

      // Check if product is mapped in orders
      final ordersData = box.get('orders');
      print('Orders data: $ordersData');

      if (ordersData != null && ordersData is List) {
        for (var order in ordersData) {
          if (order is Map) {
            print('Checking order: $order');
            // Check if product matches
            if (order['product'] == productName) {
              print('Found matching product in order');
              if (order['variety'] != null &&
                  order['variety'].toString().isNotEmpty) {
                mappedAttributes['variety'] = true;
                print('Product is mapped with variety');
              }
              if (order['colorGroup'] != null &&
                  order['colorGroup'].toString().isNotEmpty) {
                mappedAttributes['colorGroup'] = true;
                print('Product is mapped with color group');
              }
              if (order['sampleMeter'] != null &&
                  order['sampleMeter'].toString().isNotEmpty) {
                mappedAttributes['sampleMeter'] = true;
                print('Product is mapped with sample meter');
              }
              if (order['width'] != null &&
                  order['width'].toString().isNotEmpty) {
                mappedAttributes['width'] = true;
                print('Product is mapped with width');
              }
              if (order['weaveType'] != null &&
                  order['weaveType'].toString().isNotEmpty) {
                mappedAttributes['weaveType'] = true;
                print('Product is mapped with weave type');
              }
              if (order['quality'] != null &&
                  order['quality'].toString().isNotEmpty) {
                mappedAttributes['quality'] = true;
                print('Product is mapped with quality');
              }
            }
          }
        }
      }

      // Check if product is mapped in varieties
      final varietiesData = box.get('varieties');
      print('Varieties data: $varietiesData');

      if (varietiesData != null && varietiesData is List) {
        for (var variety in varietiesData) {
          if (variety is Map) {
            // Check both 'product' and 'productName' fields
            String? varietyProduct =
                variety['product']?.toString() ??
                variety['productName']?.toString();
            print('Checking variety: $variety, product field: $varietyProduct');
            if (varietyProduct == productName) {
              mappedAttributes['variety'] = true;
              print('Product is mapped with variety in varieties data');
              break; // Found it, no need to continue
            }
          }
        }
      }

      // Check if product is mapped in color groups
      final colorGroupsData = box.get('colorGroups');
      print('Color groups data: $colorGroupsData');

      if (colorGroupsData != null && colorGroupsData is List) {
        for (var colorGroup in colorGroupsData) {
          if (colorGroup is Map) {
            // Check both 'product' and 'productName' fields
            String? colorGroupProduct =
                colorGroup['product']?.toString() ??
                colorGroup['productName']?.toString();
            print(
              'Checking color group: $colorGroup, product field: $colorGroupProduct',
            );
            if (colorGroupProduct == productName) {
              mappedAttributes['colorGroup'] = true;
              print('Product is mapped with color group in color groups data');
              break; // Found it, no need to continue
            }
          }
        }
      }

      // Check if product is mapped in sample meters
      final sampleMetersData = box.get('sampleMeters');
      print('Sample meters data: $sampleMetersData');

      if (sampleMetersData != null && sampleMetersData is List) {
        for (var sampleMeter in sampleMetersData) {
          if (sampleMeter is Map) {
            // Check both 'product' and 'productName' fields
            String? sampleMeterProduct =
                sampleMeter['product']?.toString() ??
                sampleMeter['productName']?.toString();
            print(
              'Checking sample meter: $sampleMeter, product field: $sampleMeterProduct',
            );
            if (sampleMeterProduct == productName) {
              mappedAttributes['sampleMeter'] = true;
              print(
                'Product is mapped with sample meter in sample meters data',
              );
              break; // Found it, no need to continue
            }
          }
        }
      }

      // Check if product is mapped in widths
      final widthsData = box.get('widths');
      print('Widths data: $widthsData');

      if (widthsData != null && widthsData is List) {
        for (var width in widthsData) {
          if (width is Map) {
            // Check both 'product' and 'productName' fields
            String? widthProduct =
                width['product']?.toString() ??
                width['productName']?.toString();
            print('Checking width: $width, product field: $widthProduct');
            if (widthProduct == productName) {
              mappedAttributes['width'] = true;
              print('Product is mapped with width in widths data');
              break; // Found it, no need to continue
            }
          }
        }
      }

      // Check if product is mapped in weave types
      final weaveTypesData = box.get('weaveTypes');
      print('Weave types data: $weaveTypesData');

      if (weaveTypesData != null && weaveTypesData is List) {
        for (var weaveType in weaveTypesData) {
          if (weaveType is Map) {
            // Check both 'product' and 'productName' fields
            String? weaveTypeProduct =
                weaveType['product']?.toString() ??
                weaveType['productName']?.toString();
            print(
              'Checking weave type: $weaveType, product field: $weaveTypeProduct',
            );
            if (weaveTypeProduct == productName) {
              mappedAttributes['weaveType'] = true;
              print('Product is mapped with weave type in weave types data');
              break; // Found it, no need to continue
            }
          }
        }
      }

      // Check if product is mapped in qualities
      final qualitiesData = box.get('qualities');
      print('Qualities data: $qualitiesData');

      if (qualitiesData != null && qualitiesData is List) {
        for (var quality in qualitiesData) {
          if (quality is Map) {
            // Check both 'product' and 'productName' fields
            String? qualityProduct =
                quality['product']?.toString() ??
                quality['productName']?.toString();
            print('Checking quality: $quality, product field: $qualityProduct');
            if (qualityProduct == productName) {
              mappedAttributes['quality'] = true;
              print('Product is mapped with quality in qualities data');
              break; // Found it, no need to continue
            }
          }
        }
      }

      print('Mapped attributes for $productName: $mappedAttributes');
      return mappedAttributes;
    } catch (e) {
      print('Error checking if product is mapped: $e');
      return {
        'variety': false,
        'colorGroup': false,
        'sampleMeter': false,
        'width': false,
        'weaveType': false,
        'quality': false,
      };
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

      return products;
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing products
      List<Map<String, dynamic>> products = await getProducts();

      // Check if product with same name already exists
      bool exists = products.any((p) => p['name'] == productData['name']);

      if (exists) {
        throw Exception('Product with this name already exists');
      }

      // Add new product
      products.insert(0, productData);

      // Save to Hive
      await box.put('products', products);
      await box.flush();

      print('Product added successfully');
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(
    String oldName,
    Map<String, dynamic> updatedProductData,
  ) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing products
      List<Map<String, dynamic>> products = await getProducts();

      // Find the index of the product to update
      int index = products.indexWhere((p) => p['name'] == oldName);

      if (index == -1) {
        throw Exception('Product not found');
      }

      // Check if product with same name already exists (excluding current entry)
      bool exists = products.any(
        (p) => p['name'] == updatedProductData['name'] && p['name'] != oldName,
      );

      if (exists) {
        throw Exception('Product with this name already exists');
      }

      // Update product
      products[index] = updatedProductData;

      // Save to Hive
      await box.put('products', products);
      await box.flush();

      // If name changed, update all related records
      if (oldName != updatedProductData['name']) {
        await _updateProductNameInAllRecords(
          oldName,
          updatedProductData['name'],
        );
      }

      print('Product updated successfully');
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productName) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Get existing products
      List<Map<String, dynamic>> products = await getProducts();

      // Remove product
      products.removeWhere((p) => p['name'] == productName);

      // Save to Hive
      await box.put('products', products);
      await box.flush();

      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> _updateProductNameInAllRecords(
    String oldName,
    String newName,
  ) async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final appDataBox = Hive.box('appData');

      // Update product name in orders box
      final ordersData = appDataBox.get('orders');
      if (ordersData != null && ordersData is List) {
        List<Map<String, dynamic>> updatedOrdersData = [];

        for (var order in ordersData) {
          Map<String, dynamic> orderMap = Map<String, dynamic>.from(order);
          if (orderMap['product'] == oldName) {
            orderMap['product'] = newName;
          }
          updatedOrdersData.add(orderMap);
        }

        await appDataBox.put('orders', updatedOrdersData);
        print('Updated product name in orders box');
      }

      // Update product name in varieties box
      final varietiesData = appDataBox.get('varieties');
      if (varietiesData != null && varietiesData is List) {
        List<Map<String, dynamic>> updatedVarietiesData = [];

        for (var variety in varietiesData) {
          Map<String, dynamic> varietyMap = Map<String, dynamic>.from(variety);
          if (varietyMap['product'] == oldName) {
            varietyMap['product'] = newName;
          }
          updatedVarietiesData.add(varietyMap);
        }

        await appDataBox.put('varieties', updatedVarietiesData);
        print('Updated product name in varieties box');
      }

      // Update product name in color groups box
      final colorGroupsData = appDataBox.get('colorGroups');
      if (colorGroupsData != null && colorGroupsData is List) {
        List<Map<String, dynamic>> updatedColorGroupsData = [];

        for (var colorGroup in colorGroupsData) {
          Map<String, dynamic> colorGroupMap = Map<String, dynamic>.from(
            colorGroup,
          );
          if (colorGroupMap['product'] == oldName) {
            colorGroupMap['product'] = newName;
          }
          updatedColorGroupsData.add(colorGroupMap);
        }

        await appDataBox.put('colorGroups', updatedColorGroupsData);
        print('Updated product name in color groups box');
      }

      // Update product name in sample meters box
      final sampleMetersData = appDataBox.get('sampleMeters');
      if (sampleMetersData != null && sampleMetersData is List) {
        List<Map<String, dynamic>> updatedSampleMetersData = [];

        for (var sampleMeter in sampleMetersData) {
          Map<String, dynamic> sampleMeterMap = Map<String, dynamic>.from(
            sampleMeter,
          );
          if (sampleMeterMap['product'] == oldName) {
            sampleMeterMap['product'] = newName;
          }
          updatedSampleMetersData.add(sampleMeterMap);
        }

        await appDataBox.put('sampleMeters', updatedSampleMetersData);
        print('Updated product name in sample meters box');
      }

      // Update product name in widths box
      final widthsData = appDataBox.get('widths');
      if (widthsData != null && widthsData is List) {
        List<Map<String, dynamic>> updatedWidthsData = [];

        for (var width in widthsData) {
          Map<String, dynamic> widthMap = Map<String, dynamic>.from(width);
          if (widthMap['product'] == oldName) {
            widthMap['product'] = newName;
          }
          updatedWidthsData.add(widthMap);
        }

        await appDataBox.put('widths', updatedWidthsData);
        print('Updated product name in widths box');
      }

      // Update product name in weave types box
      final weaveTypesData = appDataBox.get('weaveTypes');
      if (weaveTypesData != null && weaveTypesData is List) {
        List<Map<String, dynamic>> updatedWeaveTypesData = [];

        for (var weaveType in weaveTypesData) {
          Map<String, dynamic> weaveTypeMap = Map<String, dynamic>.from(
            weaveType,
          );
          if (weaveTypeMap['product'] == oldName) {
            weaveTypeMap['product'] = newName;
          }
          updatedWeaveTypesData.add(weaveTypeMap);
        }

        await appDataBox.put('weaveTypes', updatedWeaveTypesData);
        print('Updated product name in weave types box');
      }

      // Update product name in qualities box
      final qualitiesData = appDataBox.get('qualities');
      if (qualitiesData != null && qualitiesData is List) {
        List<Map<String, dynamic>> updatedQualitiesData = [];

        for (var quality in qualitiesData) {
          Map<String, dynamic> qualityMap = Map<String, dynamic>.from(quality);
          if (qualityMap['product'] == oldName) {
            qualityMap['product'] = newName;
          }
          updatedQualitiesData.add(qualityMap);
        }

        await appDataBox.put('qualities', updatedQualitiesData);
        print('Updated product name in qualities box');
      }

      // Flush all changes to disk
      await appDataBox.flush();
      print('All product name updates saved to disk');
    } catch (e) {
      print('Error updating product name in all records: $e');
    }
  }
}
