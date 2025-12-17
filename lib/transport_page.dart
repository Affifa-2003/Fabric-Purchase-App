import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({Key? key}) : super(key: key);

  @override
  _TransportPageState createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  List<Map<String, dynamic>> transports = [];
  List<Map<String, dynamic>> filteredTransports = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransports();
    _searchController.addListener(_filterTransports);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Validate mobile number (10 digits, starting with 6-9)
  bool _validateMobileNumber(String mobile) {
    // Remove any non-digit characters
    String digitsOnly = mobile.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's exactly 10 digits and starts with 6-9
    if (digitsOnly.length != 10) {
      return false;
    }
    
    // Check if first digit is between 6 and 9
    int firstDigit = int.parse(digitsOnly[0]);
    return firstDigit >= 6 && firstDigit <= 9;
  }

  Future<void> _loadTransports() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveTransports = [];
      
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');
      
      final transportsData = appDataBox.get('transports');
      if (transportsData != null) {
        // Handle different types of data
        if (transportsData is List) {
          hiveTransports = transportsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }
      
      setState(() {
        transports = hiveTransports;
        filteredTransports = List.from(transports);
        _isLoading = false;
      });
      
      print('Loaded ${transports.length} transports from Hive');
    } catch (e) {
      print('Error loading transports: $e');
      setState(() {
        transports = [];
        filteredTransports = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTransportsToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      
      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> transportsToSave = transports.map((transport) {
        return {
          'name': transport['name']?.toString() ?? '',
          'address': transport['address']?.toString() ?? '',
          'gstNo': transport['gstNo']?.toString() ?? '',
          'mobileNumber': transport['mobileNumber']?.toString() ?? '',
          'contactPerson': transport['contactPerson']?.toString() ?? '',
          'status': transport['status']?.toString() ?? 'Active',
        };
      }).toList();
      
      // Save data with explicit await to ensure it's written to disk
      await box.put('transports', transportsToSave);
      
      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved transports: ${box.get('transports')}');
      print('Transports data saved successfully');
    } catch (e) {
      print('Error saving transports data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterTransports() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredTransports = transports.where((transport) {
        return transport['name'].toLowerCase().contains(query) ||
               transport['mobileNumber'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddNewTransportDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController gstNoController = TextEditingController();
    TextEditingController mobileNumberController = TextEditingController();
    TextEditingController contactPersonController = TextEditingController();
    String statusValue = 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Set constraints to make dialog responsive
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Transport',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close, color: Color(0xFF767676)),
                      ),
                    ],
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),

                // Content with SingleChildScrollView to make it scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Transport Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Transport Company Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. ABC Transport Services',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Address Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Address:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: addressController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Company address',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // GST No Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'GST No:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: gstNoController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                  // GST format: 2 digits + 1 letter + PAN format (10 chars) + 1 letter + 1 digit + Z
                                  // Example: 27AAPFU0939F1ZV
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                  UpperCaseTextFormatter(),
                                ],
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 27AAPFU0939F1ZV',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Mobile Number Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Mobile Number: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: mobileNumberController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 9876543210',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact Person Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Contact Person Name:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: contactPersonController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Name of the contact person',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Status Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Status: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: statusValue,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['Active', 'Inactive']
                                    .map((status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    statusValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Information text with icon in a box
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3182CE)),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF3182CE),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This will be added to master and available for future orders.',
                                  style: TextStyle(color: Color(0xFF3182CE)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                
                // Buttons - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              // Validate required fields
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transport company name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (mobileNumberController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mobile number is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Validate mobile number format
                              if (!_validateMobileNumber(mobileNumberController.text.trim())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid 10-digit mobile number starting with 6-9'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Create new transport
                              Map<String, dynamic> newTransport = {
                                'name': nameController.text.trim(),
                                'address': addressController.text.trim(),
                                'gstNo': gstNoController.text.trim(),
                                'mobileNumber': mobileNumberController.text.trim(),
                                'contactPerson': contactPersonController.text.trim(),
                                'status': statusValue,
                              };
                              
                              // Update local state immediately
                              setState(() {
                                // Add to the beginning of the list
                                transports.insert(0, newTransport);
                                _filterTransports(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveTransportsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transport added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'Save to Master',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditTransportDialog(Map<String, dynamic> transport, int index) {
    TextEditingController nameController = TextEditingController(text: transport['name']);
    TextEditingController addressController = TextEditingController(text: transport['address'] ?? '');
    TextEditingController gstNoController = TextEditingController(text: transport['gstNo'] ?? '');
    TextEditingController mobileNumberController = TextEditingController(text: transport['mobileNumber']);
    TextEditingController contactPersonController = TextEditingController(text: transport['contactPerson'] ?? '');
    String statusValue = transport['status'] ?? 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Set constraints to make dialog responsive
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Transport',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close, color: Color(0xFF767676)),
                      ),
                    ],
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),

                // Content with SingleChildScrollView to make it scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Transport Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Transport Company Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. ABC Transport Services',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Address Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Address:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: addressController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Company address',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // GST No Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'GST No:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: gstNoController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                  UpperCaseTextFormatter(),
                                ],
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 27AAPFU0939F1ZV',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Mobile Number Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Mobile Number: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: mobileNumberController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 9876543210',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact Person Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Contact Person Name:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: contactPersonController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Name of the contact person',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Status Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Status: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: statusValue,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['Active', 'Inactive']
                                    .map((status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    statusValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Information text with icon in a box
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3182CE)),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF3182CE),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This will update the transport in master and all associated records.',
                                  style: TextStyle(color: Color(0xFF3182CE)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal divider
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                
                // Buttons - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              // Validate required fields
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transport company name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (mobileNumberController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mobile number is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Validate mobile number format
                              if (!_validateMobileNumber(mobileNumberController.text.trim())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid 10-digit mobile number starting with 6-9'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Create updated transport
                              Map<String, dynamic> updatedTransport = {
                                'name': nameController.text.trim(),
                                'address': addressController.text.trim(),
                                'gstNo': gstNoController.text.trim(),
                                'mobileNumber': mobileNumberController.text.trim(),
                                'contactPerson': contactPersonController.text.trim(),
                                'status': statusValue,
                              };
                              
                              // Update local state immediately
                              setState(() {
                                // Remove the old transport
                                transports.removeAt(index);
                                // Add the updated transport at the beginning
                                transports.insert(0, updatedTransport);
                                _filterTransports(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveTransportsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transport updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'Update to Master',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        title: const Text('Transport'),
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
              onPressed: _showAddNewTransportDialog,
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
                        hintText: 'Search Transport',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                
                // Transports list
                Expanded(
                  child: filteredTransports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                transports.isEmpty
                                    ? 'No transport companies found'
                                    : 'No matching transport companies',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                transports.isEmpty
                                    ? 'Add transport companies using the + button'
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
                          onRefresh: _loadTransports,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredTransports.length,
                            itemBuilder: (context, index) {
                              final transport = filteredTransports[index];
                              
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
                                    child: Icon(
                                      Icons.local_shipping,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    transport['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    transport['mobileNumber'],
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
                                      _showDeleteConfirmationDialog(transport);
                                    },
                                  ),
                                  onTap: () {
                                    // Find the original index in the transports list
                                    int originalIndex = transports.indexWhere((t) => t['name'] == transport['name']);
                                    if (originalIndex != -1) {
                                      _showEditTransportDialog(transport, originalIndex);
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> transport) {
    // Check if transport is used in any orders
    bool isUsed = false;
    
    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final ordersData = appDataBox.get('orders');
        
        if (ordersData != null && ordersData is List) {
          for (var order in ordersData) {
            if (order is Map && order['transport'] == transport['name']) {
              isUsed = true;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if transport is used: $e');
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isUsed 
              ? const Text('This transport is already used in orders and cannot be deleted.')
              : Text('Are you sure you want to delete "${transport['name']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            if (!isUsed)
              TextButton(
                onPressed: () async {
                  // Find the original index in the transports list
                  int originalIndex = transports.indexWhere((t) => t['name'] == transport['name']);
                  if (originalIndex != -1) {
                    // Update local state immediately
                    setState(() {
                      transports.removeAt(originalIndex);
                      _filterTransports(); // Update filtered list
                    });
                    
                    // Save to Hive
                    await _saveTransportsToStorage();
                    
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transport deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
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
}

// Additional formatter for uppercase text (if not already in input_formatters.dart)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}