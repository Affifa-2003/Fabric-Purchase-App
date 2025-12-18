// lib/order_form_type_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/service/order_form_type_service.dart';
import 'package:purchase_app/widgets/add_order_form_type_dialog.dart';

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
      // Use the OrderFormTypeService to get order form types
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
        // Add the order form type using the service
        OrderFormTypeService()
            .addOrderFormType(
              result['name'],
              description: result['description'],
              isPlainMixed: result['isPlainMixed'],
              status: result['status'],
            )
            .then((_) {
              // Reload the order form types
              _loadOrderFormTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order form type added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding order form type: $error'),
                  backgroundColor: Colors.red,
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
    // Get the current name
    String currentName = orderFormType['name']?.toString() ?? '';
    String currentDescription = orderFormType['description']?.toString() ?? '';
    bool currentIsPlainMixed = orderFormType['isPlainMixed'] ?? false;
    String currentStatus = orderFormType['status']?.toString() ?? 'Active';

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
        // Update the order form type using the service
        OrderFormTypeService()
            .updateOrderFormType(
              currentName,
              result['name'],
              description: result['description'],
              isPlainMixed: result['isPlainMixed'],
              status: result['status'],
            )
            .then((_) {
              // Reload the order form types
              _loadOrderFormTypes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order form type updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating order form type: $error'),
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
        title: const Text('Order Form Type'),
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
              onPressed: _showAddNewOrderFormTypeDialog,
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
                        hintText: 'Search Order Form Types',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
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
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                orderFormTypes.isEmpty
                                    ? 'No order form types found'
                                    : 'No matching order form types',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                orderFormTypes.isEmpty
                                    ? 'Add order form types using the + button'
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
                                      Icons.description,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    orderFormType['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  // Removed subtitle that was showing "Plain Mixed"
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
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
          title: const Text('Confirm Delete'),
          content: isInUse
              ? const Text(
                  'This order form type is already used in orders and cannot be deleted.',
                )
              : Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            if (!isInUse)
              TextButton(
                onPressed: () async {
                  // Delete the order form type using the service
                  OrderFormTypeService()
                      .deleteOrderFormType(name)
                      .then((_) {
                        // Reload the order form types
                        _loadOrderFormTypes();

                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Order form type deleted successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error deleting order form type: $error',
                            ),
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
