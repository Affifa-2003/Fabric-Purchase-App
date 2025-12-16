import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class WidthPage extends StatefulWidget {
  const WidthPage({Key? key}) : super(key: key);

  @override
  _WidthPageState createState() => _WidthPageState();
}

class _WidthPageState extends State<WidthPage> {
  List<Map<String, dynamic>> widths = [];
  List<Map<String, dynamic>> filteredWidths = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> activeProducts = []; // Only active products
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  String? selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterWidths);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load products first
      await _loadProducts();
      
      // Load widths
      await _loadWidths();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
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
      
      // Initialize with defaults if box is empty
      if (appDataBox.isEmpty) {
        await _initializeBoxWithDefaults(appDataBox);
      }
      
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
        // Filter only active products
        activeProducts = products.where((product) => 
          product['status'] == 'Active').toList();
      });
      
      print('Loaded ${products.length} products (${activeProducts.length} active)');
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadWidths() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveWidths = [];
      
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');
      
      // Initialize with defaults if box is empty
      if (appDataBox.isEmpty) {
        await _initializeBoxWithDefaults(appDataBox);
      }
      
      final widthsData = appDataBox.get('widths');
      if (widthsData != null) {
        // Handle different types of data
        if (widthsData is List) {
          hiveWidths = widthsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            // If it's a LinkedMap or other map type
            if (item is Map<dynamic, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }
      
      setState(() {
        widths = hiveWidths;
        filteredWidths = List.from(widths);
      });
      
      print('Loaded ${widths.length} widths from Hive');
    } catch (e) {
      print('Error loading widths: $e');
      setState(() {
        widths = [];
        filteredWidths = [];
      });
    }
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default widths');
      
      // Fallback to hardcoded defaults
      List<Map<String, dynamic>> defaultWidths = [
        {'product': 'Cotton Shirt', 'width': 72},
        {'product': 'Denim Jeans', 'width': 60},
        {'product': 'Silk Scarf', 'width': 45},
      ];
      
      // Set default widths
      await box.put('widths', defaultWidths);
      await box.flush();
      print('Hive box initialized with default widths');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }

  Future<void> _saveWidthsToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> widthsToSave = widths.map((width) {
        return {
          'product': width['product']?.toString() ?? '',
          'width': width['width'] is int ? width['width'].toDouble() : width['width'] ?? 0.0,
        };
      }).toList();
      
      // Save data with explicit await to ensure it's written to disk
      await box.put('widths', widthsToSave);
      
      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved widths: ${box.get('widths')}');
      print('Widths data saved successfully');
    } catch (e) {
      print('Error saving widths data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving widths: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterWidths() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredWidths = widths.where((width) {
        return width['product'].toLowerCase().contains(query) || 
               width['width'].toString().contains(query);
      }).toList();
    });
  }

  // Check if a width is mapped to any order
  bool _isWidthMapped(String productName, double widthValue) {
    try {
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }
      
      final box = Hive.box('appData');
      final ordersData = box.get('orders');
      
      if (ordersData != null) {
        if (ordersData is List) {
          for (var order in ordersData) {
            if (order is Map) {
              // Check if width is mapped with this product and width value
              if (order['product'] == productName && 
                  order['width'] != null && 
                  order['width'] == widthValue) {
                return true;
              }
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if width is mapped: $e');
      return false;
    }
  }

  void _showAddNewWidthDialog() {
    TextEditingController widthController = TextEditingController();
    String? selectedProductValue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          'Add Width',
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

                  // Content
                  Padding(
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
                              DropdownButtonFormField<String>(
                                value: selectedProductValue,
                                decoration: const InputDecoration(
                                  hintText: 'Select a product',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: activeProducts.map((product) {
                                  return DropdownMenuItem<String>(
                                    value: product['name'],
                                    child: Text(product['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedProductValue = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Width Field
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
                                    'Width (in inches): *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: widthController,
                                inputFormatters: [
                              NoLeadingOrMultipleSpacesFormatter(),
                            ],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 72',
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

                  // Horizontal divider
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  
                  // Buttons
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
                                if (selectedProductValue == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (widthController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Width is required'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Parse width value
                                double? widthValue = double.tryParse(widthController.text.trim());
                                if (widthValue == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid width value'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Check if this width already exists for this product
                                bool exists = widths.any((w) => 
                                  w['product'] == selectedProductValue && w['width'] == widthValue);
                                
                                if (exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This width already exists for the selected product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Create new width
                                Map<String, dynamic> newWidth = {
                                  'product': selectedProductValue,
                                  'width': widthValue,
                                };
                                
                                // Update local state immediately
                                setState(() {
                                  // Add to the beginning of the list
                                  widths.insert(0, newWidth);
                                  _filterWidths(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveWidthsToStorage();

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Width added successfully'),
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
            );
          },
        );
      },
    );
  }

  void _showEditWidthDialog(Map<String, dynamic> width, int index) {
    TextEditingController widthController = TextEditingController(text: width['width'].toString());
    String? selectedProductValue = width['product'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          'Edit Width',
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

                  // Content
                  Padding(
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
                              DropdownButtonFormField<String>(
                                value: selectedProductValue,
                                decoration: const InputDecoration(
                                  hintText: 'Select a product',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: activeProducts.map((product) {
                                  return DropdownMenuItem<String>(
                                    value: product['name'],
                                    child: Text(product['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedProductValue = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Width Field
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
                                    'Width (in inches): *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: widthController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 72',
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
                                  'This will update the width in master and all associated records.',
                                  style: TextStyle(color: Color(0xFF3182CE)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal divider
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  
                  // Buttons
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
                                if (selectedProductValue == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (widthController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Width is required'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Parse width value
                                double? widthValue = double.tryParse(widthController.text.trim());
                                if (widthValue == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid width value'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Check if this width already exists for this product (excluding current entry)
                                bool exists = widths.any((w) => 
                                  w['product'] == selectedProductValue && 
                                  w['width'] == widthValue && 
                                  w != width);
                                
                                if (exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This width already exists for the selected product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Check if product or width is being changed
                                bool productChanged = selectedProductValue != width['product'];
                                bool widthChanged = widthValue != width['width'];
                                
                                // Create updated width
                                Map<String, dynamic> updatedWidth = {
                                  'product': selectedProductValue,
                                  'width': widthValue,
                                };
                                
                                // Update local state immediately
                                setState(() {
                                  // Remove the old width
                                  widths.removeAt(index);
                                  // Add the updated width at the beginning
                                  widths.insert(0, updatedWidth);
                                  _filterWidths(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveWidthsToStorage();

                                // If product or width changed, update all related records
                                if (productChanged || widthChanged) {
                                  await _updateWidthInAllRecords(width['product'], width['width'], updatedWidth);
                                }

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Width updated successfully'),
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
            );
          },
        );
      },
    );
  }

  Future<void> _updateWidthInAllRecords(String oldProduct, double oldWidth, Map<String, dynamic> updatedWidth) async {
    try {
      // Update width in orders box
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final ordersData = appDataBox.get('orders');
        
        if (ordersData != null && ordersData is List) {
          List<Map<String, dynamic>> updatedOrdersData = [];
          
          for (var order in ordersData) {
            Map<String, dynamic> orderMap = Map<String, dynamic>.from(order);
            if (orderMap['product'] == oldProduct && orderMap['width'] == oldWidth) {
              orderMap['product'] = updatedWidth['product'];
              orderMap['width'] = updatedWidth['width'];
            }
            updatedOrdersData.add(orderMap);
          }
          
          await appDataBox.put('orders', updatedOrdersData);
          await appDataBox.flush();
          print('Updated width in orders box');
        }
      }
      
    } catch (e) {
      print('Error updating width in all records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Width'),
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
              onPressed: _showAddNewWidthDialog,
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
                        hintText: 'Search Widths',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                
                // Widths list
                Expanded(
                  child: filteredWidths.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widths.isEmpty
                                    ? 'No widths found'
                                    : 'No matching widths',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widths.isEmpty
                                    ? 'Add widths using the + button'
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
                          onRefresh: _loadWidths,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredWidths.length,
                            itemBuilder: (context, index) {
                              final width = filteredWidths[index];
                              final isMapped = _isWidthMapped(width['product'], width['width']);
                              // Check if the product is still active
                              bool isProductActive = activeProducts.any((p) => p['name'] == width['product']);
                              
                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isProductActive 
                                        ? const Color(0xFFEBF5FF)
                                        : Colors.grey[200],
                                    child: Icon(
                                      Icons.straighten,
                                      color: isProductActive 
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  title: Text(
                                    '${width['product']} - ${width['width']} inches',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: isProductActive ? Colors.black : Colors.grey[500],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(width, isMapped);
                                    },
                                  ),
                                  onTap: () {
                                    // Only allow editing if product is still active
                                    if (isProductActive) {
                                      // Find the original index in the widths list
                                      int originalIndex = widths.indexWhere((w) => 
                                        w['product'] == width['product'] && w['width'] == width['width']);
                                      if (originalIndex != -1) {
                                        _showEditWidthDialog(width, originalIndex);
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cannot edit width for inactive product'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> width, bool isMapped) {
    // Check if the product is still active
    bool isProductActive = activeProducts.any((p) => p['name'] == width['product']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: !isProductActive
              ? Text('This width belongs to an inactive product "${width['product']}" and cannot be deleted.')
              : isMapped 
                  ? const Text('This width is already mapped with orders and cannot be deleted.')
                  : Text('Are you sure you want to delete "${width['product']} - ${width['width']} inches"?'),
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
            if (isProductActive && !isMapped)
              TextButton(
                onPressed: () async {
                  // Find the original index in the widths list
                  int originalIndex = widths.indexWhere((w) => 
                    w['product'] == width['product'] && w['width'] == width['width']);
                  if (originalIndex != -1) {
                    // Update local state immediately
                    setState(() {
                      widths.removeAt(originalIndex);
                      _filterWidths(); // Update filtered list
                    });
                    
                    // Save to Hive
                    await _saveWidthsToStorage();
                    
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Width deleted successfully'),
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