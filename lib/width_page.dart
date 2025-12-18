// lib/width_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/service/width_service.dart';
import 'package:purchase_app/widgets/add_width_dialog.dart';
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
      // Use the WidthService to get widths
      widths = await WidthService().getWidths();
      
      setState(() {
        filteredWidths = List.from(widths);
      });
      
      print('Loaded ${widths.length} widths from service');
    } catch (e) {
      print('Error loading widths: $e');
      setState(() {
        widths = [];
        filteredWidths = [];
      });
    }
  }

  void _filterWidths() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredWidths = widths.where((width) {
        // Ensure product is a string before calling toLowerCase
        String product = width['product'] is String 
            ? width['product'] 
            : width['product']?.toString() ?? '';
        
        // Ensure width is a string before calling contains
        String widthStr = width['width']?.toString() ?? '';
        
        return product.toLowerCase().contains(query) || 
               widthStr.contains(query);
      }).toList();
    });
  }

  // Check if a width is mapped to any order
  bool _isWidthMapped(String productName, int widthValue) {
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
                  order['width'] != null) {
                
                // Convert order width to int for comparison
                int orderWidth = 0;
                if (order['width'] is int) {
                  orderWidth = order['width'];
                } else if (order['width'] is double) {
                  orderWidth = (order['width'] as double).toInt();
                } else if (order['width'] is String) {
                  orderWidth = int.tryParse(order['width']) ?? 0;
                }
                
                if (orderWidth == widthValue) {
                  return true;
                }
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
    showDialog(
      context: context,
      builder: (context) {
        return AddWidthDialog(
          activeProducts: activeProducts,
        );
      },
    ).then((result) {
      if (result != null) {
        // Add the width using the service
        WidthService().addWidth(result['product'], result['width']).then((_) {
          // Reload the widths
          _loadWidths();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Width added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }).catchError((error) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding width: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    });
  }

  // In WidthPage.dart, update the _showEditWidthDialog method:

void _showEditWidthDialog(Map<String, dynamic> width, int index) {
  // Get the current product name and width as integer
  String currentProduct = width['product']?.toString() ?? '';
  int currentWidth = width['width'] is int 
      ? width['width'] 
      : int.tryParse(width['width']?.toString() ?? '') ?? 0;
  String currentDescription = width['description']?.toString() ?? '';
  String currentStatus = width['status']?.toString() ?? 'Active';
  
  showDialog(
    context: context,
    builder: (context) {
      return AddWidthDialog(
        isEditMode: true,
        initialWidth: currentWidth.toString(), // Pass as string for display
        initialProduct: currentProduct,
        initialDescription: currentDescription,
        initialStatus: currentStatus,
        activeProducts: activeProducts,
      );
    },
  ).then((result) {
    if (result != null) {
      // Update the width using the service
      WidthService().updateWidth(
        currentProduct, 
        currentWidth, 
        result['product'], 
        result['width'],
        description: result['description'],
        status: result['status']
      ).then((_) {
        // Reload the widths
        _loadWidths();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Width updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating width: $error'),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24),
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
                              // Ensure width value is an integer
                              int widthValue = width['width'] is int 
                                  ? width['width'] 
                                  : int.tryParse(width['width']?.toString() ?? '') ?? 0;
                              
                              final isMapped = _isWidthMapped(width['product']?.toString() ?? '', widthValue);
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
                                    '${width['product']} - $widthValue inches',
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
                                      _showEditWidthDialog(width, index);
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
    
    // Ensure width value is an integer
    int widthValue = width['width'] is int 
        ? width['width'] 
        : int.tryParse(width['width']?.toString() ?? '') ?? 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: !isProductActive
              ? Text('This width belongs to an inactive product "${width['product']}" and cannot be deleted.')
              : isMapped 
                  ? const Text('This width is already mapped with orders and cannot be deleted.')
                  : Text('Are you sure you want to delete "${width['product']} - $widthValue inches"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            if (isProductActive && !isMapped)
              TextButton(
                onPressed: () async {
                  // Delete the width using the service
                  WidthService().deleteWidth(width['product']?.toString() ?? '', widthValue).then((_) {
                    // Reload the widths
                    _loadWidths();
                    
                    Navigator.of(context).pop();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Width deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }).catchError((error) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting width: $error'),
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