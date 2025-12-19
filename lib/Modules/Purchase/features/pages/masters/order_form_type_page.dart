import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/services/order_form_type_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_order_form_type_dialog.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class OrderFormTypePage extends StatefulWidget {
  const OrderFormTypePage({Key? key}) : super(key: key);

  @override
  _OrderFormTypePageState createState() => _OrderFormTypePageState();
}

class _OrderFormTypePageState extends State<OrderFormTypePage> {
  List<Map<String, dynamic>> orderFormTypes = [];
  List<Map<String, dynamic>> filteredOrderFormTypes = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterOrderFormTypes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load order form types
      await _loadOrderFormTypes();

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

  Future<void> _loadOrderFormTypes() async {
    try {
      // Use OrderFormTypeService to get order form types
      orderFormTypes = await OrderFormTypeService().getOrderFormTypes();

      setState(() {
        filteredOrderFormTypes = List.from(orderFormTypes);
      });

      print('Loaded ${orderFormTypes.length} order form types from service');
    } catch (e) {
      print('Error loading order form types: $e');
      setState(() {
        orderFormTypes = [];
        filteredOrderFormTypes = [];
      });
    }
  }

  void _filterOrderFormTypes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredOrderFormTypes = orderFormTypes.where((type) {
        // Ensure name is a string before calling toLowerCase
        String name = type['name'] is String
            ? type['name']
            : type['name']?.toString() ?? '';

        // Ensure description is a string before calling contains
        String description = type['description']?.toString() ?? '';

        return name.toLowerCase().contains(query) ||
            description.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Check if an order form type is used in any order
  bool _isOrderFormTypeInUse(String name) {
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
              // Check if order form type is used in this order
              if (order['orderFormType'] == name) {
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking if order form type is in use: $e');
      return false;
    }
  }

  void _showAddNewOrderFormTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const AddOrderFormTypeDialog();
      },
    ).then((result) {
      if (result != null) {
        // Add order form type using service
        OrderFormTypeService()
            .addOrderFormType(
              result['name'],
              description: result['description'],
              isPlainMixed: result['isPlainMixed'],
              status: result['status'],
            )
            .then((_) {
              // Reload order form types
              _loadOrderFormTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.orderFormType} ${AppStrings.addedSuccessfully}',
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
                    '${AppStrings.errorAdding} ${AppStrings.orderFormType.toLowerCase()}: $error',
                  ),
                  backgroundColor: AppColors.pending,
                ),
              );
            });
      }
    });
  }

  void _showEditOrderFormTypeDialog(
    Map<String, dynamic> orderFormType,
    int index,
  ) {
    // Get current name
    String currentName = orderFormType['name']?.toString() ?? '';
    String currentDescription = orderFormType['description']?.toString() ?? '';
    bool currentIsPlainMixed = orderFormType['isPlainMixed'] ?? false;
    String currentStatus =
        orderFormType['status']?.toString() ?? AppStrings.active;

    showDialog(
      context: context,
      builder: (context) {
        return AddOrderFormTypeDialog(
          isEditMode: true,
          initialName: currentName,
          initialDescription: currentDescription,
          initialIsPlainMixed: currentIsPlainMixed,
          initialStatus: currentStatus,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update order form type using service
        OrderFormTypeService()
            .updateOrderFormType(
              currentName,
              result['name'],
              description: result['description'],
              isPlainMixed: result['isPlainMixed'],
              status: result['status'],
            )
            .then((_) {
              // Reload order form types
              _loadOrderFormTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.orderFormType} ${AppStrings.updatedSuccessfully}',
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
                    '${AppStrings.errorUpdating} ${AppStrings.orderFormType.toLowerCase()}: $error',
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
        title: Text(AppStrings.orderFormType),
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
              onPressed: _showAddNewOrderFormTypeDialog,
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
                      hintText: 'Search ${AppStrings.orderFormType}s',
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

                // Order form types list
                Expanded(
                  child: filteredOrderFormTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: AppSizes.iconXLarge,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                orderFormTypes.isEmpty
                                    ? 'No ${AppStrings.orderFormType}s found'
                                    : 'No matching ${AppStrings.orderFormType}s',
                                style: AppTextStyles.emptyStateTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                orderFormTypes.isEmpty
                                    ? 'Add ${AppStrings.orderFormType}s using the + button'
                                    : AppStrings.tryDifferentSearch,
                                style: AppTextStyles.emptyStateSubtitle,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrderFormTypes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredOrderFormTypes.length,
                            itemBuilder: (context, index) {
                              final orderFormType =
                                  filteredOrderFormTypes[index];
                              final isInUse = _isOrderFormTypeInUse(
                                orderFormType['name']?.toString() ?? '',
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
                                    backgroundColor: AppColors.primaryLight,
                                    child: Icon(
                                      Icons.description,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  title: Text(
                                    orderFormType['name']?.toString() ?? '',
                                    style: AppTextStyles.listItemTitle,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.pending,
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        orderFormType,
                                        isInUse,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    _showEditOrderFormTypeDialog(
                                      orderFormType,
                                      index,
                                    );
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
    Map<String, dynamic> orderFormType,
    bool isInUse,
  ) {
    String name = orderFormType['name']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.confirmDelete),
          content: isInUse
              ? Text(
                  'This ${AppStrings.orderFormType.toLowerCase()} is already used in orders and cannot be deleted.',
                )
              : Text('${AppStrings.areYouSureDelete} "$name"?'),
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
            if (!isInUse)
              TextButton(
                onPressed: () async {
                  // Delete order form type using the service
                  OrderFormTypeService()
                      .deleteOrderFormType(name)
                      .then((_) {
                        // Reload the order form types
                        _loadOrderFormTypes();

                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppStrings.orderFormType} ${AppStrings.deletedSuccessfully}',
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
                              '${AppStrings.errorDeleting} ${AppStrings.orderFormType.toLowerCase()}: $error',
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
