import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_variety_dialog.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';
import 'package:purchase_app/Modules/Purchase/features/services/variety_service.dart';

class VarietyPage extends StatefulWidget {
  const VarietyPage({Key? key}) : super(key: key);

  @override
  _VarietyPageState createState() => _VarietyPageState();
}

class _VarietyPageState extends State<VarietyPage> {
  List<Map<String, dynamic>> varieties = [];
  List<Map<String, dynamic>> filteredVarieties = [];
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterVarieties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadVarieties(), _loadProducts()]);
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadVarieties() async {
    try {
      varieties = await VarietyService().getVarieties();
      setState(() {
        filteredVarieties = List.from(varieties);
      });
      print('Loaded ${varieties.length} varieties from service');
    } catch (e) {
      print('Error loading varieties: $e');
      setState(() {
        varieties = [];
        filteredVarieties = [];
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      products = await VarietyService().getProducts();
      print('Loaded ${products.length} active products from service');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
      });
    }
  }

  void _filterVarieties() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // If search query is empty, show all varieties
        filteredVarieties = List.from(varieties);
      } else {
        // Filter by both variety name and product name
        filteredVarieties = varieties.where((variety) {
          final varietyName = variety['name']?.toString().toLowerCase() ?? '';
          final productName =
              variety['productName']?.toString().toLowerCase() ?? '';
          return varietyName.contains(query) || productName.contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewVarietyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddVarietyDialog(products: products);
      },
    ).then((result) {
      if (result != null) {
        // Add the variety using the service
        VarietyService()
            .addVariety(result)
            .then((_) {
              // Reload the varieties
              _loadVarieties();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Variety added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding variety: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  void _showEditVarietyDialog(Map<String, dynamic> variety, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AddVarietyDialog(
          isEditMode: true,
          initialVariety: variety,
          products: products,
        );
      },
    ).then((result) {
      if (result != null) {
        // Update the variety using the service
        VarietyService()
            .updateVariety(variety['name'], result)
            .then((_) {
              // Reload the varieties
              _loadVarieties();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Variety updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating variety: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> variety) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${variety['name']}"?',
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
            TextButton(
              onPressed: () async {
                // Delete the variety using the service
                VarietyService()
                    .deleteVariety(variety['name'])
                    .then((_) {
                      // Reload the varieties
                      _loadVarieties();

                      Navigator.of(context).pop(); // Close dialog

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Variety deleted successfully'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    })
                    .catchError((error) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting variety: $error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Varieties'),
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
                color: Color(0xFF2563EB), // Blue color for + icon
                size: 24,
              ),
              onPressed: _showAddNewVarietyDialog,
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
                      hintText: 'Search Varieties',
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

                // Varieties list
                Expanded(
                  child: filteredVarieties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                varieties.isEmpty
                                    ? 'No varieties found'
                                    : 'No matching varieties',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                varieties.isEmpty
                                    ? 'Add varieties using the + button'
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
                          onRefresh: _loadVarieties,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredVarieties.length,
                            itemBuilder: (context, index) {
                              final variety = filteredVarieties[index];
                              final originalIndex = varieties.indexWhere(
                                (v) => v['name'] == variety['name'],
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
                                      Icons.category,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    variety['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Product: ${variety['productName']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(variety);
                                    },
                                  ),
                                  onTap: () {
                                    if (originalIndex != -1) {
                                      _showEditVarietyDialog(
                                        variety,
                                        originalIndex,
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
}
