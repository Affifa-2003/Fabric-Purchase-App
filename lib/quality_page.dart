import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/service/quality_service.dart';
import 'package:purchase_app/widgets/quality_dialog.dart';

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
    // Use the QualityService to get qualities
    qualities = await QualityService().getQualities();
    
    setState(() {
      filteredQualities = List.from(qualities);
    });
    
    print('Loaded ${qualities.length} qualities from service');
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
  showDialog(
    context: context,
    builder: (context) {
      return QualityDialog(
        activeProducts: activeProducts,
      );
    },
  ).then((result) {
    if (result != null) {
      // Add the quality using the service
      QualityService().addQuality(result['product'], result['quality']).then((_) {
        // Reload the qualities
        _loadQualities();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quality added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding quality: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  });
}

// Replace the _showEditQualityDialog method with:
void _showEditQualityDialog(Map<String, dynamic> quality, int index) {
  showDialog(
    context: context,
    builder: (context) {
      return QualityDialog(
        isEditMode: true,
        initialProduct: quality['product'],
        initialQuality: quality['quality'],
        activeProducts: activeProducts,
      );
    },
  ).then((result) {
    if (result != null) {
      // Update the quality using the service
      QualityService().updateQuality(
        quality['product'], 
        quality['quality'], 
        result['product'], 
        result['quality']
      ).then((_) {
        // Reload the qualities
        _loadQualities();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quality updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quality: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  });
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
              style: TextStyle(color: Colors.grey),
            ),
          ),
          if (isProductActive && !isMapped)
            TextButton(
              onPressed: () {
                // Delete the quality using the service
                QualityService().deleteQuality(quality['product'], quality['quality']).then((_) {
                  // Reload the qualities
                  _loadQualities();
                  
                  Navigator.of(context).pop(); // Close dialog
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quality deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((error) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting quality: $error'),
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