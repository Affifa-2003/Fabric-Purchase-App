import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/Modules/Purchase/features/services/product_service.dart';
import 'package:purchase_app/Modules/Purchase/features/widgets/add_product_dialog.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      products = await ProductService().getProducts();
      setState(() {
        filteredProducts = List.from(products);
        _isLoading = false;
      });
      print('Loaded ${products.length} products from service');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
        filteredProducts = [];
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddNewProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const AddProductDialog();
      },
    ).then((result) {
      if (result != null) {
        // Add the product using the service
        ProductService()
            .addProduct(result)
            .then((_) {
              // Reload the products
              _loadProducts();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding product: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  void _showEditProductDialog(Map<String, dynamic> product, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AddProductDialog(isEditMode: true, initialProduct: product);
      },
    ).then((result) {
      if (result != null) {
        // Update the product using the service
        ProductService()
            .updateProduct(product['name'], result)
            .then((_) {
              // Reload the products
              _loadProducts();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating product: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> product) {
    // Get the mapped attributes
    Map<String, bool> mappedAttributes = ProductService().isProductMapped(
      product['name'],
    );

    // Collect names of pages where the product is mapped
    List<String> mappedPages = [];
    if (mappedAttributes['variety'] == true) mappedPages.add('Variety');
    if (mappedAttributes['colorGroup'] == true) mappedPages.add('Color Group');
    if (mappedAttributes['sampleMeter'] == true)
      mappedPages.add('Sample Meter');
    if (mappedAttributes['width'] == true) mappedPages.add('Width');
    if (mappedAttributes['weaveType'] == true) mappedPages.add('Weave Type');
    if (mappedAttributes['quality'] == true) mappedPages.add('Quality');

    // Check if the product is mapped to any page
    bool isMapped = mappedPages.isNotEmpty;

    // Show the delete confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isMapped
              ? Text(
                  'This product is already mapped with the following pages and cannot be deleted:\n\n${mappedPages.join(', ')}',
                )
              : Text('Are you sure you want to delete "${product['name']}"?'),
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
            if (!isMapped)
              TextButton(
                onPressed: () async {
                  // Delete the product using the service
                  ProductService()
                      .deleteProduct(product['name'])
                      .then((_) {
                        // Reload the products
                        _loadProducts();

                        Navigator.of(context).pop(); // Close dialog

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product deleted successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      })
                      .catchError((error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting product: $error'),
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
        title: const Text('Products'),
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
              onPressed: _showAddNewProductDialog,
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
                      hintText: 'Search Products',
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

                // Products list
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                products.isEmpty
                                    ? 'No products found'
                                    : 'No matching products',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                products.isEmpty
                                    ? 'Add products using the + button'
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
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final isMapped = ProductService().isProductMapped(
                                product['name'],
                              );
                              final originalIndex = products.indexWhere(
                                (p) => p['name'] == product['name'],
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
                                      Icons.inventory_2,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(product);
                                    },
                                  ),
                                  onTap: () {
                                    if (originalIndex != -1) {
                                      _showEditProductDialog(
                                        product,
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
