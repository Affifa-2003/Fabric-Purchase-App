import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/services/width_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_width_dialog.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        activeProducts = products
            .where((product) => product['status'] == AppStrings.active)
            .toList();
      });

      print(
        'Loaded ${products.length} products (${activeProducts.length} active)',
      );
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadWidths() async {
    try {
      // Use the WidthService to get widths
      widths = await WidthService().getWidths();
      print('width : $widths');
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
              if (order['product'] == productName && order['width'] != null) {
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
        return AddWidthDialog(activeProducts: activeProducts);
      },
    ).then((result) {
      if (result != null) {
        // Add the width using the service
        WidthService()
            .addWidth(result['product'], result['width'])
            .then((_) {
              // Reload the widths
              _loadWidths();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.width} ${AppStrings.addedSuccessfully}',
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
                    '${AppStrings.errorAdding} ${AppStrings.width.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  void _showEditWidthDialog(Map<String, dynamic> width, int index) {
    // Get the current product name and width as integer
    String currentProduct = width['product']?.toString() ?? '';
    int currentWidth = width['width'] is int
        ? width['width']
        : int.tryParse(width['width']?.toString() ?? '') ?? 0;
    String currentDescription = width['description']?.toString() ?? '';
    String currentStatus = width['status']?.toString() ?? AppStrings.active;

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
        WidthService()
            .updateWidth(
              currentProduct,
              currentWidth,
              result['product'],
              result['width'],
              description: result['description'],
              status: result['status'],
            )
            .then((_) {
              // Reload the widths
              _loadWidths();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.width} ${AppStrings.updatedSuccessfully}',
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
                    '${AppStrings.errorUpdating} ${AppStrings.width.toLowerCase()}: $error',
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
        backgroundColor: AppColors.primaryColor,
        toolbarHeight: AppSizes.appBarHeight,
        title: Text(AppStrings.width),
        titleTextStyle: AppTextStyles.appBarTitle,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        iconTheme: const IconThemeData(color: AppColors.cardBackground),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: AppSizes.buttonWidth,
            height: AppSizes.buttonHeight,
            decoration: AppDecorations.buttonDecoration(
              color: AppColors.cardBackground,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add,
                color: AppColors.primaryColor,
                size: AppSizes.buttonIconSize,
              ),
              onPressed: _showAddNewWidthDialog,
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        primaryColor: AppColors.primaryColor,
        appTitle: AppStrings.appTitle,
      ),
      backgroundColor: AppColors.scaffoldBackground,
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
                      hintText: 'Search ${AppStrings.width}s',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: AppColors.cardBackground,
                      filled: true,
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
                                size: AppSizes.iconXLarge,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widths.isEmpty
                                    ? 'No ${AppStrings.width}s found'
                                    : 'No matching ${AppStrings.width}s',
                                style: AppTextStyles.emptyStateTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widths.isEmpty
                                    ? 'Add ${AppStrings.width}s using the + button'
                                    : AppStrings.tryDifferentSearch,
                                style: AppTextStyles.emptyStateSubtitle,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadWidths,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredWidths.length,
                            itemBuilder: (context, index) {
                              final width = filteredWidths[index];
                              // Ensure width value is an integer
                              int widthValue = width['width'] is int
                                  ? width['width']
                                  : int.tryParse(
                                          width['width']?.toString() ?? '',
                                        ) ??
                                        0;

                              final isMapped = _isWidthMapped(
                                width['product']?.toString() ?? '',
                                widthValue,
                              );
                              // Check if the product is still active
                              bool isProductActive = activeProducts.any(
                                (p) => p['name'] == width['product'],
                              );

                              return Card(
                                elevation: AppSizes.cardElevation,
                                color: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.cardRadius,
                                  ),
                                  side: BorderSide(color: AppColors.border),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isProductActive
                                        ? AppColors.primaryLight
                                        : Colors.grey[200],
                                    child: Icon(
                                      Icons.straighten,
                                      color: isProductActive
                                          ? AppColors.primaryColor
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  title: Text(
                                    '${width['product']} - $widthValue inches',
                                    style: AppTextStyles.listItemTitle.copyWith(
                                      color: isProductActive
                                          ? AppColors.textPrimary
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.pending,
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        width,
                                        isMapped,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // Only allow editing if product is still active
                                    if (isProductActive) {
                                      _showEditWidthDialog(width, index);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cannot edit ${AppStrings.width.toLowerCase()} for inactive product',
                                          ),
                                          backgroundColor: AppColors.mixed,
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
    Map<String, dynamic> width,
    bool isMapped,
  ) {
    // Check if the product is still active
    bool isProductActive = activeProducts.any(
      (p) => p['name'] == width['product'],
    );

    // Ensure width value is an integer
    int widthValue = width['width'] is int
        ? width['width']
        : int.tryParse(width['width']?.toString() ?? '') ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.confirmDelete),
          content: !isProductActive
              ? Text(
                  'This ${AppStrings.width.toLowerCase()} belongs to an inactive product "${width['product']}" and cannot be deleted.',
                )
              : isMapped
              ? Text(
                  'This ${AppStrings.width.toLowerCase()} is already mapped with orders and cannot be deleted.',
                )
              : Text(
                  '${AppStrings.areYouSureDelete} "${width['product']} - $widthValue inches"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: AppColors.pending),
              ),
            ),
            if (isProductActive && !isMapped)
              TextButton(
                onPressed: () async {
                  // Delete the width using the service
                  WidthService()
                      .deleteWidth(
                        width['product']?.toString() ?? '',
                        widthValue,
                      )
                      .then((_) {
                        // Reload the widths
                        _loadWidths();

                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppStrings.width} ${AppStrings.deletedSuccessfully}',
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
                              '${AppStrings.errorDeleting} ${AppStrings.width.toLowerCase()}: $error',
                            ),
                            backgroundColor: AppColors.pending,
                          ),
                        );
                      });
                },
                child: Text(AppStrings.delete),
              ),
          ],
        );
      },
    );
  }
}
