import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class QualityPage extends StatefulWidget {
  const QualityPage({Key? key}) : super(key: key);

  @override
  _QualityPageState createState() => _QualityPageState();
}

class _QualityPageState extends State<QualityPage> {
  List<Map<String, dynamic>> qualities = [];
  List<Map<String, dynamic>> filteredQualities = [];
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
    _searchController.addListener(_filterQualities);
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
      
      // Load qualities
      await _loadQualities();
      
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

  Future<void> _loadQualities() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveQualities = [];
      
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');
      
      final qualitiesData = appDataBox.get('qualities');
      if (qualitiesData != null) {
        // Handle different types of data
        if (qualitiesData is List) {
          hiveQualities = qualitiesData.map((item) {
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
        qualities = hiveQualities;
        filteredQualities = List.from(qualities);
      });
      
      print('Loaded ${qualities.length} qualities from Hive');
    } catch (e) {
      print('Error loading qualities: $e');
      setState(() {
        qualities = [];
        filteredQualities = [];
      });
    }
  }

  Future<void> _saveQualitiesToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> qualitiesToSave = qualities.map((quality) {
        return {
          'product': quality['product']?.toString() ?? '',
          'quality': quality['quality']?.toString() ?? '',
          // 'description': quality['description']?.toString() ?? '',
        };
      }).toList();
      
      // Save data with explicit await to ensure it's written to disk
      await box.put('qualities', qualitiesToSave);
      
      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved qualities: ${box.get('qualities')}');
      print('Qualities data saved successfully');
    } catch (e) {
      print('Error saving qualities data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving qualities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterQualities() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredQualities = qualities.where((quality) {
        return quality['product'].toString().toLowerCase().contains(query) || 
               quality['quality'].toString().toLowerCase().contains(query);
              //  quality['description'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // Check if a quality is mapped to any order
  bool _isQualityMapped(String productName, String qualityName) {
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
              // Check if quality is mapped with this product and quality name
              if (order['product'] == productName && 
                  order['quality'] != null && 
                  order['quality'] == qualityName) {
                return true;
              }
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if quality is mapped: $e');
      return false;
    }
  }

  void _showAddNewQualityDialog() {
    TextEditingController qualityController = TextEditingController();
    // TextEditingController descriptionController = TextEditingController();
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
                          'Add Quality',
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
                        
                        // Quality Name Field
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
                                    'Quality Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: qualityController,
                                inputFormatters: [
                              NoLeadingOrMultipleSpacesFormatter(),
                            ],
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Poly Cotton',
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
                                if (selectedProductValue == null || selectedProductValue!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (qualityController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Quality name is required'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                String qualityValue = qualityController.text.trim();
                                
                                // Check if this quality already exists for this product
                                bool exists = qualities.any((q) => 
                                  q['product'] == selectedProductValue && q['quality'] == qualityValue);
                                
                                if (exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This quality already exists for the selected product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Create new quality
                                Map<String, dynamic> newQuality = {
                                  'product': selectedProductValue,
                                  'quality': qualityValue,
                                  // 'description': descriptionController.text.trim(),
                                };
                                
                                // Update local state immediately
                                setState(() {
                                  // Add to the beginning of the list
                                  qualities.insert(0, newQuality);
                                  _filterQualities(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveQualitiesToStorage();

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quality added successfully'),
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

  void _showEditQualityDialog(Map<String, dynamic> quality, int index) {
    TextEditingController qualityController = TextEditingController(text: quality['quality']?.toString() ?? '');
    // TextEditingController descriptionController = TextEditingController(text: quality['description']?.toString() ?? '');
    String? selectedProductValue = quality['product'];

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
                          'Edit Quality',
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
                        
                        // Quality Name Field
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
                                    'Quality Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: qualityController,
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Poly Cotton',
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
                                  'This will update the quality in master and all associated records.',
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
                                if (selectedProductValue == null || selectedProductValue!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (qualityController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Quality name is required'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                String qualityValue = qualityController.text.trim();
                                
                                // Check if this quality already exists for this product (excluding current entry)
                                bool exists = qualities.any((q) => 
                                  q['product'] == selectedProductValue && 
                                  q['quality'] == qualityValue && 
                                  q != quality);
                                
                                if (exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This quality already exists for the selected product'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Check if product or quality is being changed
                                bool productChanged = selectedProductValue != quality['product'];
                                bool qualityNameChanged = qualityValue != quality['quality'];
                                
                                // Create updated quality
                                Map<String, dynamic> updatedQuality = {
                                  'product': selectedProductValue,
                                  'quality': qualityValue,
                                  // 'description': descriptionController.text.trim(),
                                };
                                
                                // Update local state immediately
                                setState(() {
                                  // Remove the old quality
                                  qualities.removeAt(index);
                                  // Add the updated quality at the beginning
                                  qualities.insert(0, updatedQuality);
                                  _filterQualities(); // Update filtered list
                                });

                                // Save to Hive
                                await _saveQualitiesToStorage();

                                // If product or quality changed, update all related records
                                if (productChanged || qualityNameChanged) {
                                  await _updateQualityInAllRecords(quality['product'], quality['quality'], updatedQuality);
                                }

                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quality updated successfully'),
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

  Future<void> _updateQualityInAllRecords(String oldProduct, String oldQuality, Map<String, dynamic> updatedQuality) async {
    try {
      // Update quality in orders box
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final ordersData = appDataBox.get('orders');
        
        if (ordersData != null && ordersData is List) {
          List<Map<String, dynamic>> updatedOrdersData = [];
          
          for (var order in ordersData) {
            Map<String, dynamic> orderMap = Map<String, dynamic>.from(order);
            if (orderMap['product'] == oldProduct && orderMap['quality'] == oldQuality) {
              orderMap['product'] = updatedQuality['product'];
              orderMap['quality'] = updatedQuality['quality'];
            }
            updatedOrdersData.add(orderMap);
          }
          
          await appDataBox.put('orders', updatedOrdersData);
          await appDataBox.flush();
          print('Updated quality in orders box');
        }
      }
      
    } catch (e) {
      print('Error updating quality in all records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Quality'),
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
              onPressed: _showAddNewQualityDialog,
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
                        hintText: 'Search Qualities',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                
                // Qualities list
                Expanded(
                  child: filteredQualities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.style,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                qualities.isEmpty
                                    ? 'No qualities found'
                                    : 'No matching qualities',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                qualities.isEmpty
                                    ? 'Add qualities using the + button'
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
                          onRefresh: _loadQualities,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredQualities.length,
                            itemBuilder: (context, index) {
                              final quality = filteredQualities[index];
                              final isMapped = _isQualityMapped(quality['product'], quality['quality']);
                              // Check if the product is still active
                              bool isProductActive = activeProducts.any((p) => p['name'] == quality['product']);
                              
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
                                      Icons.style,
                                      color: isProductActive 
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  title: Text(
                                    '${quality['product']} - ${quality['quality']}',
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
                                      _showDeleteConfirmationDialog(quality, isMapped);
                                    },
                                  ),
                                  onTap: () {
                                    // Only allow editing if product is still active
                                    if (isProductActive) {
                                      // Find the original index in the qualities list
                                      int originalIndex = qualities.indexWhere((q) => 
                                        q['product'] == quality['product'] && q['quality'] == quality['quality']);
                                      if (originalIndex != -1) {
                                        _showEditQualityDialog(quality, originalIndex);
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cannot edit quality for inactive product'),
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> quality, bool isMapped) {
    // Check if the product is still active
    bool isProductActive = activeProducts.any((p) => p['name'] == quality['product']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: !isProductActive
              ? Text('This quality belongs to an inactive product "${quality['product']}" and cannot be deleted.')
              : isMapped 
                  ? const Text('This quality is already mapped with orders and cannot be deleted.')
                  : Text('Are you sure you want to delete "${quality['product']} - ${quality['quality']}"?'),
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
                  // Find the original index in the qualities list
                  int originalIndex = qualities.indexWhere((q) => 
                    q['product'] == quality['product'] && q['quality'] == quality['quality']);
                  if (originalIndex != -1) {
                    // Update local state immediately
                    setState(() {
                      qualities.removeAt(originalIndex);
                      _filterQualities(); // Update filtered list
                    });
                    
                    // Save to Hive
                    await _saveQualitiesToStorage();
                    
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quality deleted successfully'),
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