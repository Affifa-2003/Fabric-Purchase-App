// lib/quality_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/Modules/Purchase/features/services/quality_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/quality_dialog.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      final productsData = box.get('products');
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
        return QualityDialog(activeProducts: activeProducts);
      },
    ).then((result) {
      if (result != null) {
        // Add's quality using the service
        QualityService()
            .addQuality(
              result['product'],
              result['quality'],
              code: result['code'],
              description: result['description'],
              status: result['status'],
            )
            .then((_) {
              // Reload the qualities
              _loadQualities();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.quality} ${AppStrings.addedSuccessfully}',
                  ),
                  backgroundColor: AppColors.complete,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.errorAdding} ${AppStrings.quality.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  void _showEditQualityDialog(Map<String, dynamic> quality, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return QualityDialog(
          isEditMode: true,
          initialProduct: quality['product'],
          initialQuality: quality['quality'],
          initialCode: quality['code'],
          initialDescription: quality['description'],
          initialStatus: quality['status'],
          activeProducts: activeProducts,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update quality using the service
        QualityService()
            .updateQuality(
              quality['product'],
              quality['quality'],
              result['product'],
              result['quality'],
              code: result['code'],
              description: result['description'],
              status: result['status'],
            )
            .then((_) {
              // Reload the qualities
              _loadQualities();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.quality} ${AppStrings.updatedSuccessfully}',
                  ),
                  backgroundColor: AppColors.complete,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.errorUpdating} ${AppStrings.quality.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
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
                color: Color(0xFF2563EB), // Blue color for the + icon
                size: 24,
              ),
              onPressed: _showAddNewQualityDialog,
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        primaryColor: const Color(0xFF2563EB),
        appTitle: 'Hyatt Purchase',
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Qualities',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: Colors.white,
                      filled: true,
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
                                    ? 'Add qualities using + button'
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredQualities.length,
                            itemBuilder: (context, index) {
                              final quality = filteredQualities[index];
                              final isMapped = _isQualityMapped(
                                quality['product'],
                                quality['quality'],
                              );
                              // Check if product is still active
                              bool isProductActive = activeProducts.any(
                                (p) => p['name'] == quality['product'],
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
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(
                                      Icons.style,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    // Display product name - quality name
                                    '${quality['product']} - ${quality['quality']}',
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
                                      _showDeleteConfirmationDialog(
                                        quality,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // Only allow editing if product is still active
                                    if (isProductActive) {
                                      _showEditQualityDialog(quality, index);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Cannot edit quality for inactive product',
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
    Map<String, dynamic> quality,
    bool isMapped,
  ) {
    // Check if product is still active
    bool isProductActive = activeProducts.any(
      (p) => p['name'] == quality['product'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: !isProductActive
              ? Text(
                  'This quality belongs to an inactive product "${quality['product']}" and cannot be deleted.',
                )
              : isMapped
              ? const Text(
                  'This quality is already mapped with orders and cannot be deleted.',
                )
              : Text(
                  'Are you sure you want to delete "${quality['product']} - ${quality['quality']}"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
            if (isProductActive && !isMapped)
              TextButton(
                onPressed: () async {
                  // Delete's quality using the service
                  QualityService()
                      .deleteQuality(quality['product'], quality['quality'])
                      .then((_) {
                        // Reload the qualities
                        _loadQualities();

                        Navigator.of(context).pop(); // Close dialog

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Quality deleted successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting quality: $error'),
                            backgroundColor: Color(0xFFEF4444),
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
