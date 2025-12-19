import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/services/weave_type_service.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/weave_type_dialog.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                SnackBar(
                  content: Text(
                    '${AppStrings.weaveType} ${AppStrings.addedSuccessfully}',
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
                    '${AppStrings.errorAdding} ${AppStrings.weaveType.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
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
                SnackBar(
                  content: Text(
                    '${AppStrings.weaveType} ${AppStrings.updatedSuccessfully}',
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
                    '${AppStrings.errorUpdating} ${AppStrings.weaveType.toLowerCase()}: $error',
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
        title: Text(AppStrings.weaveType),
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
              onPressed: _showAddNewWeaveTypeDialog,
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
                      hintText: 'Search ${AppStrings.weaveType}s',
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

                // Weave types list
                Expanded(
                  child: filteredWeaveTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.texture,
                                size: AppSizes.iconXLarge,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                weaveTypes.isEmpty
                                    ? 'No ${AppStrings.weaveType}s found'
                                    : 'No matching ${AppStrings.weaveType}s',
                                style: AppTextStyles.emptyStateTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weaveTypes.isEmpty
                                    ? 'Add ${AppStrings.weaveType}s using the + button'
                                    : AppStrings.tryDifferentSearch,
                                style: AppTextStyles.emptyStateSubtitle,
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
                                      Icons.texture,
                                      color: isProductActive
                                          ? AppColors.primaryColor
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
                                        SnackBar(
                                          content: Text(
                                            'Cannot edit ${AppStrings.weaveType.toLowerCase()} for inactive product',
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
          title: Text(AppStrings.confirmDelete),
          content: !isProductActive
              ? Text(
                  'This ${AppStrings.weaveType.toLowerCase()} belongs to an inactive product "${weaveType['product']}" and cannot be deleted.',
                )
              : isMapped
              ? Text(
                  'This ${AppStrings.weaveType.toLowerCase()} is already mapped with orders and cannot be deleted.',
                )
              : Text(
                  '${AppStrings.areYouSureDelete} "${weaveType['product']} - ${weaveType['code']}"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: AppColors.pending),
              ),
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
                          SnackBar(
                            content: Text(
                              '${AppStrings.weaveType} ${AppStrings.deletedSuccessfully}',
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
                              '${AppStrings.errorDeleting} ${AppStrings.weaveType.toLowerCase()}: $error',
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
