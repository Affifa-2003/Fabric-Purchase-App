import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, bool> _isProductMapped(String productName) {
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
            if (order['variety'] != null && order['variety'].toString().isNotEmpty) {
              mappedAttributes['variety'] = true;
              print('Product is mapped with variety');
            }
            if (order['colorGroup'] != null && order['colorGroup'].toString().isNotEmpty) {
              mappedAttributes['colorGroup'] = true;
              print('Product is mapped with color group');
            }
            if (order['sampleMeter'] != null && order['sampleMeter'].toString().isNotEmpty) {
              mappedAttributes['sampleMeter'] = true;
              print('Product is mapped with sample meter');
            }
            if (order['width'] != null && order['width'].toString().isNotEmpty) {
              mappedAttributes['width'] = true;
              print('Product is mapped with width');
            }
            if (order['weaveType'] != null && order['weaveType'].toString().isNotEmpty) {
              mappedAttributes['weaveType'] = true;
              print('Product is mapped with weave type');
            }
            if (order['quality'] != null && order['quality'].toString().isNotEmpty) {
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
          String? varietyProduct = variety['product']?.toString() ?? variety['productName']?.toString();
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
          String? colorGroupProduct = colorGroup['product']?.toString() ?? colorGroup['productName']?.toString();
          print('Checking color group: $colorGroup, product field: $colorGroupProduct');
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
          String? sampleMeterProduct = sampleMeter['product']?.toString() ?? sampleMeter['productName']?.toString();
          print('Checking sample meter: $sampleMeter, product field: $sampleMeterProduct');
          if (sampleMeterProduct == productName) {
            mappedAttributes['sampleMeter'] = true;
            print('Product is mapped with sample meter in sample meters data');
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
          String? widthProduct = width['product']?.toString() ?? width['productName']?.toString();
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
          String? weaveTypeProduct = weaveType['product']?.toString() ?? weaveType['productName']?.toString();
          print('Checking weave type: $weaveType, product field: $weaveTypeProduct');
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
          String? qualityProduct = quality['product']?.toString() ?? quality['productName']?.toString();
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
  Future<void> _loadProducts() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveProducts = [];
     
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');
     
      final productsData = appDataBox.get('products');
      if (productsData != null) {
        // Handle different types of data
        if (productsData is List) {
          hiveProducts = productsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }
     
      setState(() {
        products = hiveProducts;
        filteredProducts = List.from(products);
        _isLoading = false;
      });
     
      print('Loaded ${products.length} products from Hive');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
        filteredProducts = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProductsToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
     
      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> productsToSave = products.map((product) {
        return {
          'name': product['name']?.toString() ?? '',
          'consumption': product['consumption'] is int
              ? product['consumption'].toDouble()
              : product['consumption'] ?? 0.0,
          'description': product['description']?.toString() ?? '',
          'status': product['status']?.toString() ?? 'Active',
        };
      }).toList();
     
      // Save data with explicit await to ensure it's written to disk
      await box.put('products', productsToSave);
     
      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved products: ${box.get('products')}');
      print('Products data saved successfully');
    } catch (e) {
      print('Error saving products data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddNewProductDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController consumptionController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String statusValue = 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Set constraints to make dialog responsive
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Product',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close, color: Color(0xFF767676)),
                      ),
                    ],
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),

                // Content with SingleChildScrollView to make it scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Product Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Cotton Shirt',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Consumption Meter Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Consumption Meter: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: consumptionController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 1.5',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Description Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Description:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Optional product description',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Status Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Status: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: statusValue,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['Active', 'Inactive']
                                    .map((status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    statusValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Information text with icon in a box
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3182CE)),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF3182CE),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This will be added to master and available for future orders.',
                                  style: TextStyle(color: Color(0xFF3182CE)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
               
                // Buttons - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              // Validate required fields
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              if (consumptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Consumption meter is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              // Parse consumption value
                              double? consumption = double.tryParse(consumptionController.text.trim());
                              if (consumption == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid consumption value'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              // Create new product
                              Map<String, dynamic> newProduct = {
                                'name': nameController.text.trim(),
                                'consumption': consumption,
                                'description': descriptionController.text.trim(),
                                'status': statusValue,
                              };
                             
                              // Update local state immediately
                              setState(() {
                                // Add to the beginning of the list
                                products.insert(0, newProduct);
                                _filterProducts(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveProductsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'Save to Master',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product, int index) {
    TextEditingController nameController = TextEditingController(text: product['name']);
    TextEditingController consumptionController = TextEditingController(text: product['consumption'].toString());
    TextEditingController descriptionController = TextEditingController(text: product['description'] ?? '');
    String statusValue = product['status'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Set constraints to make dialog responsive
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Product',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close, color: Color(0xFF767676)),
                      ),
                    ],
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),

                // Content with SingleChildScrollView to make it scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Product Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Cotton Shirt',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Consumption Meter Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Consumption Meter: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: consumptionController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 1.5',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Description Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Description:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Optional product description',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                       
                        // Status Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Status: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: statusValue,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['Active', 'Inactive']
                                    .map((status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    statusValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Information text with icon in a box
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3182CE)),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF3182CE),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This will update the product in master and all associated records.',
                                  style: TextStyle(color: Color(0xFF3182CE)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
               
                // Buttons - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              // Validate required fields
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              if (consumptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Consumption meter is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              // Parse consumption value
                              double? consumption = double.tryParse(consumptionController.text.trim());
                              if (consumption == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid consumption value'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                             
                              // Check if name is being changed
                              bool nameChanged = nameController.text.trim() != product['name'];
                             
                              // Create updated product
                              Map<String, dynamic> updatedProduct = {
                                'name': nameController.text.trim(),
                                'consumption': consumption,
                                'description': descriptionController.text.trim(),
                                'status': statusValue,
                              };
                             
                              // Update local state immediately
                              setState(() {
                                // Remove the old product
                                products.removeAt(index);
                                // Add the updated product at the beginning
                                products.insert(0, updatedProduct);
                                _filterProducts(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveProductsToStorage();

                              // If name changed, update all related records
                              if (nameChanged) {
                                await _updateProductNameInAllRecords(product['name'], updatedProduct['name']);
                              }

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'Update to Master',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProductNameInAllRecords(String oldName, String newName) async {
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
          Map<String, dynamic> colorGroupMap = Map<String, dynamic>.from(colorGroup);
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
          Map<String, dynamic> sampleMeterMap = Map<String, dynamic>.from(sampleMeter);
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
          Map<String, dynamic> weaveTypeMap = Map<String, dynamic>.from(weaveType);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Products'),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, // Set fixed width for smaller circle
            height: 36, // Set fixed height for smaller circle
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero, // Remove default padding
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24), // Adjusted icon size
              onPressed: _showAddNewProductDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Search Products',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
               
                // Products list
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                products.isEmpty
                                    ? 'No products found'
                                    : 'No matching products',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                products.isEmpty
                                    ? 'Add products using the + button'
                                    : 'Try a different search term',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final isMapped = _isProductMapped(product['name']);
                             
                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(product);
                                    },
                                  ),
                                  onTap: () {
                                    // Find the original index in the products list
                                    int originalIndex = products.indexWhere((p) => p['name'] == product['name']);
                                    if (originalIndex != -1) {
                                      _showEditProductDialog(product, originalIndex);
                                    }
                                  },
                                ),
                              );  // Added missing closing parenthesis here
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> product) {
    // Get the mapped attributes
    Map<String, bool> mappedAttributes = _isProductMapped(product['name']);

    // Collect the names of pages where the product is mapped
    List<String> mappedPages = [];
    if (mappedAttributes['variety'] == true) mappedPages.add('Variety');
    if (mappedAttributes['colorGroup'] == true) mappedPages.add('Color Group');
    if (mappedAttributes['sampleMeter'] == true) mappedPages.add('Sample Meter');
    if (mappedAttributes['width'] == true) mappedPages.add('Width');
    if (mappedAttributes['weaveType'] == true) mappedPages.add('Weave Type');
    if (mappedAttributes['quality'] == true) mappedPages.add('Quality');

    // Check if the product is mapped to any page
    bool isMapped = mappedPages.isNotEmpty;

    // Show the delete confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isMapped
              ? Text(
                  'This product is already mapped with the following pages and cannot be deleted:\n\n${mappedPages.join(', ')}',
                )
              : Text('Are you sure you want to delete "${product['name']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Find the original index in the products list
                  int originalIndex = products.indexWhere((p) => p['name'] == product['name']);
                  if (originalIndex != -1) {
                    // Update local state immediately
                    setState(() {
                      products.removeAt(originalIndex);
                      _filterProducts(); // Update filtered list
                    });
                   
                    // Save to Hive
                    await _saveProductsToStorage();
                   
                    Navigator.of(context).pop(); // Close dialog
                   
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );
  }
}