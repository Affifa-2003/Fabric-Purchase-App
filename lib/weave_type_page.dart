// lib/weave_type_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/service/weave_type_service.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/widgets/weave_type_dialog.dart';

class WeaveTypePage extends StatefulWidget {
  const WeaveTypePage({Key? key}) : super(key: key);

  @override
  _WeaveTypePageState createState() => _WeaveTypePageState();
}

class _WeaveTypePageState extends State<WeaveTypePage> {
  List<Map<String, dynamic>> weaveTypes = [];
  List<Map<String, dynamic>> filteredWeaveTypes = [];
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
    _searchController.addListener(_filterWeaveTypes);
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

      // Load weave types
      await _loadWeaveTypes();

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

      // Ensure box is open
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
        activeProducts = products
            .where((product) => product['status'] == 'Active')
            .toList();
      });

      print(
        'Loaded ${products.length} products (${activeProducts.length} active)',
      );
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadWeaveTypes() async {
    try {
      // Use WeaveTypeService to get weave types
      weaveTypes = await WeaveTypeService().getWeaveTypes();

      setState(() {
        filteredWeaveTypes = List.from(weaveTypes);
      });

      print('Loaded ${weaveTypes.length} weave types from service');
    } catch (e) {
      print('Error loading weave types: $e');
      setState(() {
        weaveTypes = [];
        filteredWeaveTypes = [];
      });
    }
  }

  void _filterWeaveTypes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredWeaveTypes = weaveTypes.where((weaveType) {
        return weaveType['product'].toLowerCase().contains(query) ||
            weaveType['code'].toLowerCase().contains(query) ||
            (weaveType['name'] != null &&
                weaveType['name'].toLowerCase().contains(query));
      }).toList();
    });
  }

  // Check if a weave type is mapped to any order
  bool _isWeaveTypeMapped(String productName, String weaveTypeCode) {
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
              // Check if weave type is mapped with this product and weave type code
              if (order['product'] == productName &&
                  order['weaveTypeCode'] != null &&
                  order['weaveTypeCode'] == weaveTypeCode) {
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking if weave type is mapped: $e');
      return false;
    }
  }

  void _showAddNewWeaveTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return WeaveTypeDialog(activeProducts: activeProducts);
      },
    ).then((result) {
      if (result != null) {
        // Add weave type using service
        WeaveTypeService()
            .addWeaveType(
              result['product'],
              result['code'],
              name: result['name'],
              description: result['description'],
              status: result['status'],
            )
            .then((_) {
              // Reload weave types
              _loadWeaveTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weave type added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding weave type: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  void _showEditWeaveTypeDialog(Map<String, dynamic> weaveType, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return WeaveTypeDialog(
          isEditMode: true,
          initialProduct: weaveType['product'],
          initialCode: weaveType['code'],
          initialWeaveType: weaveType['name'],
          initialDescription: weaveType['description'],
          initialStatus: weaveType['status'],
          activeProducts: activeProducts,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update weave type using service
        WeaveTypeService()
            .updateWeaveType(
              weaveType['product'],
              weaveType['code'],
              result['product'],
              result['code'],
              name: result['name'],
              description: result['description'],
              status: result['status'],
            )
            .then((_) {
              // Reload weave types
              _loadWeaveTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weave type updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating weave type: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Weave Type'),
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
              icon: const Icon(
                Icons.add,
                color: Color(0xFF2563EB),
                size: 24,
              ), // Adjusted icon size
              onPressed: _showAddNewWeaveTypeDialog,
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
                        hintText: 'Search Weave Types',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Weave types list
                Expanded(
                  child: filteredWeaveTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.texture,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                weaveTypes.isEmpty
                                    ? 'No weave types found'
                                    : 'No matching weave types',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weaveTypes.isEmpty
                                    ? 'Add weave types using the + button'
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
                          onRefresh: _loadWeaveTypes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredWeaveTypes.length,
                            itemBuilder: (context, index) {
                              final weaveType = filteredWeaveTypes[index];
                              final isMapped = _isWeaveTypeMapped(
                                weaveType['product'],
                                weaveType['code'],
                              );
                              // Check if product is still active
                              bool isProductActive = activeProducts.any(
                                (p) => p['name'] == weaveType['product'],
                              );

                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isProductActive
                                        ? const Color(0xFFEBF5FF)
                                        : Colors.grey[200],
                                    child: Icon(
                                      Icons.texture,
                                      color: isProductActive
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  title: Text(
                                    // Display only product name and weave type name
                                    weaveType['name'] != null &&
                                            weaveType['name']
                                                .toString()
                                                .isNotEmpty
                                        ? '${weaveType['product']} - ${weaveType['name']}'
                                        : '${weaveType['product']} - ${weaveType['code']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: isProductActive
                                          ? Colors.black
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        weaveType,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // Only allow editing if product is still active
                                    if (isProductActive) {
                                      // Find original index in weave types list
                                      int originalIndex = weaveTypes.indexWhere(
                                        (w) =>
                                            w['product'] ==
                                                weaveType['product'] &&
                                            w['code'] == weaveType['code'],
                                      );
                                      if (originalIndex != -1) {
                                        _showEditWeaveTypeDialog(
                                          weaveType,
                                          originalIndex,
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cannot edit weave type for inactive product',
                                          ),
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

  void _showDeleteConfirmationDialog(
    Map<String, dynamic> weaveType,
    bool isMapped,
  ) {
    // Check if product is still active
    bool isProductActive = activeProducts.any(
      (p) => p['name'] == weaveType['product'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: !isProductActive
              ? Text(
                  'This weave type belongs to an inactive product "${weaveType['product']}" and cannot be deleted.',
                )
              : isMapped
              ? const Text(
                  'This weave type is already mapped with orders and cannot be deleted.',
                )
              : Text(
                  'Are you sure you want to delete "${weaveType['product']} - ${weaveType['code']}"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            if (isProductActive && !isMapped)
              TextButton(
                onPressed: () async {
                  // Delete weave type using the service
                  WeaveTypeService()
                      .deleteWeaveType(weaveType['product'], weaveType['code'])
                      .then((_) {
                        // Reload the weave types
                        _loadWeaveTypes();

                        Navigator.of(context).pop(); // Close dialog

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Weave type deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting weave type: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                },
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );
  }
}
