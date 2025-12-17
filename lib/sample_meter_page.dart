import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

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
        products = hiveProducts.where((product) => product['status'] == 'Active').toList();
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
        'isMapped': meter['isMapped'] ?? false, // Add this line to track if meter is mapped
      };
    }).toList();

    await box.put('sampleMeters', sampleMetersToSave);
    await box.flush();
    print('Sample meters data saved successfully');
  } catch (e) {
    print('Error saving sample meters data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving sample meters: $e'),
        backgroundColor: Colors.red,
      ),
    );
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
          final productName = meter['productName']?.toString().toLowerCase() ?? '';
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sample Meter added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Don't call Navigator.pop here, let the dialog handle it
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sample Meter updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Don't call Navigator.pop here, let the dialog handle it
          },
          products: products,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Sample Meters'),
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
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24),
              onPressed: _showAddNewSampleMeterDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: 'Search Sample Meters',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredSampleMeters.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speed_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                sampleMeters.isEmpty ? 'No sample meters found' : 'No matching sample meters',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                sampleMeters.isEmpty ? 'Add sample meters using the + button' : 'Try a different search term',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSampleMeters,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredSampleMeters.length,
                            itemBuilder: (context, index) {
                              final meter = filteredSampleMeters[index];
                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(Icons.speed, color: const Color(0xFF2563EB)),
                                  ),
                                  title: Text(
                                    '${meter['productName'] ?? 'No Product'} - ${meter['name'] ?? 'No Name'}',
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                                    onPressed: () => _showDeleteConfirmationDialog(meter),
                                  ),
                                  onTap: () {
                                    int originalIndex = sampleMeters.indexWhere((m) => m['name'] == meter['name']);
                                    if (originalIndex != -1) {
                                      _showEditSampleMeterDialog(meter, originalIndex);
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

  // Update the _showDeleteConfirmationDialog method to check if the meter is mapped:

void _showDeleteConfirmationDialog(Map<String, dynamic> meter) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${meter['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              // Check if meter is mapped
              bool isMapped = _isMeterMapped(meter['name']);
              
              if (isMapped) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Already mapped. Cannot delete this Sample Meter.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              int originalIndex = sampleMeters.indexWhere((m) => m['name'] == meter['name']);
              if (originalIndex != -1) {
                setState(() {
                  sampleMeters.removeAt(originalIndex);
                  _filterSampleMeters();
                });
                await _saveSampleMetersToStorage();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample Meter deleted successfully'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      );
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
        if (meter is Map && meter['name'] == meterName && meter['isMapped'] == true) {
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialMeter?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialMeter?['description'] ?? '');
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
            _buildDialogHeader(),
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
                    _buildInfoBox(),
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

  Widget _buildDialogHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Color(0xFF767676)),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return _buildFieldContainer(
      'Name: *',
      TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'e.g. 1.5',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return _buildFieldContainer(
      'Product: *',
      DropdownButtonFormField<String>(
        value: _selectedProduct,
        hint: const Text('Select a product'),
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: widget.products.isEmpty
            ? []
            : widget.products.map((product) => DropdownMenuItem<String>(
                  value: product['name'],
                  child: Text(product['name']),
                )).toList(),
        onChanged: widget.products.isEmpty ? null : (value) {
          setState(() {
            _selectedProduct = value;
          });
        },
        disabledHint: const Text('No products available'),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _buildFieldContainer(
      'Description:',
      TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Optional description',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildFieldContainer(
      'Status: *',
      DropdownButtonFormField<String>(
        value: _statusValue,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: ['Active', 'Inactive'].map((status) => DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        )).toList(),
        onChanged: (value) {
          setState(() {
            _statusValue = value!;
          });
        },
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3182CE)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF3182CE)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.initialMeter == null
                  ? 'This will be added to master and available for future orders.'
                  : 'This will update the sample meter in master and all associated records.',
              style: const TextStyle(color: Color(0xFF3182CE)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              'Cancel',
              const Color(0xFF2563EB),
              () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildButton(
              widget.initialMeter == null ? 'Save to Master' : 'Update to Master',
              const Color(0xFF10B981),
              () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (_selectedProduct == null || _selectedProduct!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildFieldContainer(String label, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}