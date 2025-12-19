import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class SampleMeterPage extends StatefulWidget {
  const SampleMeterPage({Key? key}) : super(key: key);

  @override
  _SampleMeterPageState createState() => _SampleMeterPageState();
}

class _SampleMeterPageState extends State<SampleMeterPage> {
  List<Map<String, dynamic>> sampleMeters = [];
  List<Map<String, dynamic>> filteredSampleMeters = [];
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadSampleMeters();
    _loadProducts();
    _searchController.addListener(_filterSampleMeters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Update the _loadSampleMeters method to handle the isMapped field:
  Future<void> _loadSampleMeters() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      appDataBox = Hive.box('appData');

      final sampleMetersData = appDataBox.get('sampleMeters');
      List<Map<String, dynamic>> hiveSampleMeters = [];
      if (sampleMetersData != null && sampleMetersData is List) {
        hiveSampleMeters = sampleMetersData.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }

      setState(() {
        sampleMeters = hiveSampleMeters;
        filteredSampleMeters = List.from(sampleMeters);
        _isLoading = false;
      });
      print('Loaded ${sampleMeters.length} sample meters from Hive');
    } catch (e) {
      print('Error loading sample meters: $e');
      setState(() {
        sampleMeters = [];
        filteredSampleMeters = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      appDataBox = Hive.box('appData');

      final productsData = appDataBox.get('products');
      List<Map<String, dynamic>> hiveProducts = [];
      if (productsData != null && productsData is List) {
        hiveProducts = productsData.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }

      setState(() {
        products = hiveProducts
            .where((product) => product['status'] == 'Active')
            .toList();
      });
      print('Loaded ${products.length} active products from Hive');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
      });
    }
  }

  // Update the _saveSampleMetersToStorage method in SampleMeterPage
  Future<void> _saveSampleMetersToStorage() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      final box = Hive.box('appData');

      List<Map<String, dynamic>> sampleMetersToSave = sampleMeters.map((meter) {
        return {
          'name': meter['name']?.toString() ?? '',
          'productName': meter['productName']?.toString() ?? '',
          'description': meter['description']?.toString() ?? '',
          'status': meter['status']?.toString() ?? 'Active',
          'isMapped':
              meter['isMapped'] ??
              false, // Add this line to track if meter is mapped
        };
      }).toList();

      await box.put('sampleMeters', sampleMetersToSave);
      await box.flush();
      print('Sample meters data saved successfully');
    } catch (e) {
      print('Error saving sample meters data: $e');
      Helpers.showErrorSnackBar(context, 'Error saving sample meters: $e');
    }
  }

  void _filterSampleMeters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSampleMeters = List.from(sampleMeters);
      } else {
        filteredSampleMeters = sampleMeters.where((meter) {
          final meterName = meter['name']?.toString().toLowerCase() ?? '';
          final productName =
              meter['productName']?.toString().toLowerCase() ?? '';
          return meterName.contains(query) || productName.contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewSampleMeterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SampleMeterDialog(
          title: 'Add Sample Meter',
          onSave: (newMeter) {
            setState(() {
              sampleMeters.insert(0, newMeter);
              _filterSampleMeters();
            });
            _saveSampleMetersToStorage();
            Helpers.showSuccessSnackBar(context, 'Sample Meter added successfully');
          },
          products: products,
        );
      },
    );
  }

  void _showEditSampleMeterDialog(Map<String, dynamic> meter, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SampleMeterDialog(
          title: 'Edit Sample Meter',
          initialMeter: meter,
          onSave: (updatedMeter) {
            setState(() {
              sampleMeters.removeAt(index);
              sampleMeters.insert(0, updatedMeter);
              _filterSampleMeters();
            });
            _saveSampleMetersToStorage();
            Helpers.showSuccessSnackBar(context, 'Sample Meter updated successfully');
          },
          products: products,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Sample Meters',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Sample Meters',
                ),
                Expanded(
                  child: filteredSampleMeters.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.speed_outlined,
                          title: sampleMeters.isEmpty
                              ? 'No sample meters found'
                              : 'No matching sample meters',
                          subtitle: sampleMeters.isEmpty
                              ? 'Add sample meters using the + button'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSampleMeters,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredSampleMeters.length,
                            itemBuilder: (context, index) {
                              final meter = filteredSampleMeters[index];
                              return Helpers.buildListItem(
                                title: '${meter['productName'] ?? 'No Product'} - ${meter['name'] ?? 'No Name'}',
                                icon: Icons.speed,
                                onTap: () {
                                  int originalIndex = sampleMeters.indexWhere(
                                    (m) => m['name'] == meter['name'],
                                  );
                                  if (originalIndex != -1) {
                                    _showEditSampleMeterDialog(
                                      meter,
                                      originalIndex,
                                    );
                                  }
                                },
                                onDelete: () =>
                                    _showDeleteConfirmationDialog(meter),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24),
            onPressed: _showAddNewSampleMeterDialog,
          ),
        ),
      ],
    );
  }

  // Update the _showDeleteConfirmationDialog method to check if the meter is mapped:
  void _showDeleteConfirmationDialog(Map<String, dynamic> meter) {
    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${meter['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        // Check if meter is mapped
        bool isMapped = _isMeterMapped(meter['name']);

        if (isMapped) {
          Helpers.showErrorSnackBar(
            context,
            'Already mapped. Cannot delete this Sample Meter.',
          );
          return;
        }

        int originalIndex = sampleMeters.indexWhere(
          (m) => m['name'] == meter['name'],
        );
        if (originalIndex != -1) {
          setState(() {
            sampleMeters.removeAt(originalIndex);
            _filterSampleMeters();
          });
          await _saveSampleMetersToStorage();
          Helpers.showSuccessSnackBar(context, 'Sample Meter deleted successfully');
        }
      },
    );
  }

  bool _isMeterMapped(String meterName) {
    try {
      // First check if the meter has the 'isMapped' flag set to true
      final meterIndex = sampleMeters.indexWhere((m) => m['name'] == meterName);
      if (meterIndex != -1 && sampleMeters[meterIndex]['isMapped'] == true) {
        return true;
      }

      // If not found in the local data, check in Hive
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final sampleMetersData = box.get('sampleMeters');

      if (sampleMetersData != null && sampleMetersData is List) {
        for (var meter in sampleMetersData) {
          if (meter is Map &&
              meter['name'] == meterName &&
              meter['isMapped'] == true) {
            return true;
          }
        }
      }

      // Also check if it's used in any orders
      final ordersData = box.get('orders');

      if (ordersData != null && ordersData is List) {
        for (var order in ordersData) {
          if (order is Map && order['sampleMtr'] == meterName) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking if meter is mapped: $e');
      return false;
    }
  }
}

// Separate StatefulWidget for the dialog
class SampleMeterDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialMeter;
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onSave;

  const SampleMeterDialog({
    Key? key,
    required this.title,
    this.initialMeter,
    required this.products,
    required this.onSave,
  }) : super(key: key);

  @override
  _SampleMeterDialogState createState() => _SampleMeterDialogState();
}

class _SampleMeterDialogState extends State<SampleMeterDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedProduct;
  String _statusValue = 'Active';
  bool _isSaving = false;
  
  // Error states
  bool _nameError = false;
  bool _productError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMeter?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialMeter?['description'] ?? '',
    );
    _selectedProduct = widget.initialMeter?['productName'];
    _statusValue = widget.initialMeter?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Helpers.buildDialogHeader(widget.title, context),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildProductDropdown(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    Helpers.buildInfoBox(
                      widget.initialMeter == null
                          ? 'This will be added to master and available for future orders.'
                          : 'This will update sample meter in master and all associated records.',
                      isEditing: widget.initialMeter != null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            _buildDialogButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Helpers.buildFormField(
      title: 'Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'e.g. 1.5',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError = Validators.validateRequired(value, 'Name') != null;
          });
        },
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Helpers.buildFormField(
      title: 'Product: *',
      child: DropdownButtonFormField<String>(
        value: _selectedProduct,
        hint: const Text('Select a product'),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _productError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _productError ? 'Product is required' : null,
        ),
        items: widget.products.isEmpty
            ? []
            : widget.products
                  .map(
                    (product) => DropdownMenuItem<String>(
                      value: product['name'],
                      child: Text(product['name']),
                    ),
                  )
                  .toList(),
        onChanged: widget.products.isEmpty
            ? null
            : (value) {
                setState(() {
                  _selectedProduct = value;
                  _productError = false;
                });
              },
        disabledHint: const Text('No products available'),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Helpers.buildFormField(
      title: 'Description:',
      child: TextField(
        controller: _descriptionController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Optional description',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Helpers.buildFormField(
      title: 'Status: *',
      child: DropdownButtonFormField<String>(
        value: _statusValue,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: ['Active', 'Inactive']
            .map(
              (status) =>
                  DropdownMenuItem<String>(value: status, child: Text(status)),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _statusValue = value!;
          });
        },
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Helpers.buildDialogActions(
      context,
      widget.initialMeter != null,
      () async {
        // Validate form
        setState(() {
          _nameError = Validators.validateRequired(_nameController.text, 'Name') != null;
          _productError = Validators.validateRequired(_selectedProduct, 'Product') != null;
        });

        if (_nameError || _productError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newMeter = {
          'name': _nameController.text.trim(),
          'productName': _selectedProduct,
          'description': _descriptionController.text.trim(),
          'status': _statusValue,
        };

        await widget.onSave(newMeter);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialMeter == null ? 'Save to Master' : 'Update to Master',
    );
  }
}