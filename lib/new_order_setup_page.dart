import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:purchase_app/service/order_service.dart';
import 'package:purchase_app/service/width_service.dart';
import 'package:purchase_app/textile_details.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/widgets/add_width_dialog.dart';

class NewOrderSetupPage extends StatefulWidget {
  final bool isEditMode;
  final String? partyName;
  final String? ofType;
  final String? selectedWidth;
  final int? defaultChoices;
  final int? defaultMeters;
  final String? sampleRequired;
  final String? selectedSampleMtr;

  const NewOrderSetupPage({
    Key? key,
    this.isEditMode = false,
    this.partyName,
    this.ofType,
    this.selectedWidth,
    this.defaultChoices,
    this.defaultMeters,
    this.sampleRequired,
    this.selectedSampleMtr,
  }) : super(key: key);

  @override
  _NewOrderSetupPageState createState() => _NewOrderSetupPageState();
}

class _NewOrderSetupPageState extends State<NewOrderSetupPage> {
  String? selectedParty;
  String ofType = 'Regular';
  String selectedWidth = '58"';
  int defaultChoices = 2;
  TextEditingController defaultMetersController = TextEditingController(
    text: '100',
  );
  String sampleRequired = 'Yes';
  String selectedSampleMtr = '2.5';
  String? selectedAgent;
  final ImagePicker _imagePicker = ImagePicker();

  // Data that will be loaded from JSON and Hive
  List<String> parties = [];
  List<String> ofTypes = [];
  List<String> widths = [];
  List<String> sampleOptions = [];
  List<String> agents = [];
  List<String> sampleMtrOptions = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> activeProducts = [];

  bool _isLoading = true;
  late Box appDataBox;
  late Box ordersBox;

    @override
  void initState() {
    super.initState();
    // If in edit mode, set the values from parameters
    if (widget.isEditMode && widget.partyName != null) {
      selectedParty = widget.partyName;
      ofType = widget.ofType ?? 'Regular';
      selectedWidth = widget.selectedWidth ?? '58"';
      defaultChoices = widget.defaultChoices ?? 2;
      defaultMetersController.text =
          widget.defaultMeters?.toStringAsFixed(0) ?? '100';
      sampleRequired = widget.sampleRequired ?? 'Yes';
      selectedSampleMtr = widget.selectedSampleMtr ?? '2.5';
    }
    
    _initializeHiveAndLoadData().then((_) {
      // Load widths from the service after other data is loaded
      _loadWidths();
      // Load products after other data is loaded
      _loadProducts();
    });
    
    // Update party data from Hive to get latest changes
    _updatePartyDataFromHive();

    // Add a delay to verify data after loading
    Future.delayed(const Duration(seconds: 2), () {
      _verifyDataPersistence();
    });
  }
  Future<void> _initializeHiveAndLoadData() async {
    try {
      // Get the boxes (they should already be open from main.dart)
      appDataBox = Hive.box('appData');
      ordersBox = Hive.box('orders');
      print(
        'Hive boxes are open: ${Hive.isBoxOpen('appData')} and ${Hive.isBoxOpen('orders')}',
      );

      // Load data from JSON and Hive
      await _loadDataFromSources();
    } catch (e) {
      print('Error initializing Hive: $e');
      // Try to recover by reinitializing
      await _reinitializeHive();
    }
  }

    // Add this method to _NewOrderSetupPageState
  Future<void> _loadProducts() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveProducts = [];
      
      // Ensure the box is open
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
        activeProducts = products.where((product) => 
          product['status'] == 'Active').toList();
      });
      
      print('Loaded ${products.length} products (${activeProducts.length} active)');
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _reinitializeHive() async {
    try {
      // If the boxes are closed, reopen them
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }
      appDataBox = Hive.box('appData');
      ordersBox = Hive.box('orders');

      // Load data again
      await _loadDataFromSources();
    } catch (e) {
      print('Error reinitializing Hive: $e');
      // As a last resort, use defaults
      _useDefaultData();
    }
  }

  // Add this method to your NewOrderSetupPage
  Future<void> _verifyDataPersistence() async {
    try {
      final appDataBox = Hive.box('appData');
      final ordersBox = Hive.box('orders');
      final appDataKeys = appDataBox.keys.toList();
      final ordersKeys = ordersBox.keys.toList();

      print('Verifying data persistence. Keys in appData box: $appDataKeys');
      print('Verifying data persistence. Keys in orders box: $ordersKeys');

      for (var key in appDataKeys) {
        print('$key: ${appDataBox.get(key)}');
      }
      for (var key in ordersKeys) {
        print('$key: ${ordersBox.get(key)}');
      }
    } catch (e) {
      print('Error verifying data persistence: $e');
    }
  }

  Future<void> _loadDataFromSources() async {
    try {
      // Load data from JSON
      Map<String, dynamic> jsonData = {};
      try {
        final String response = await rootBundle.loadString('assets/order_data.json');
        jsonData = json.decode(response);
        print('Loaded data from JSON successfully');
      } catch (e) {
        print('Error loading JSON data: $e');
      }

      // Load data from Hive
      Map<String, dynamic> hiveData = {};
      try {
        final box = Hive.box('appData');

        // Initialize with defaults if box is empty
        if (box.isEmpty) {
          await _initializeBoxWithDefaults(box);
        }

        // Get all data from Hive
        final keys = box.keys.toList();
        for (var key in keys) {
          hiveData[key] = box.get(key);
        }
        print('Loaded data from Hive successfully');
      } catch (e) {
        print('Error loading Hive data: $e');
      }

      // Combine JSON and Hive data, with Hive taking precedence
      setState(() {
        // Combine parties
        final jsonParties = jsonData['parties'] != null
            ? List<String>.from(jsonData['parties'])
            : [];
        
        // Handle parties from Hive - could be in old format (List<String>) or new format (List<Map<String, dynamic>>)
        List<String> hiveParties = [];
        if (hiveData['parties'] != null) {
          if (hiveData['parties'] is List) {
            for (var party in hiveData['parties']) {
              if (party is String) {
                // Old format
                hiveParties.add(party);
              } else if (party is Map && party['name'] != null) {
                // New format
                hiveParties.add(party['name'] as String);
              }
            }
          }
        }
        
        parties = [...jsonParties, ...hiveParties];
        parties = parties.toSet().toList(); // Remove duplicates

        // Combine ofTypes
        final jsonOfTypes = jsonData['ofTypes'] != null
            ? List<String>.from(jsonData['ofTypes'])
            : [];
        final hiveOfTypes = hiveData['ofTypes'] != null
            ? List<String>.from(hiveData['ofTypes'])
            : [];
        final hiveTextileOfTypes = hiveData['textileOFTypes'] != null
            ? List<String>.from(hiveData['textileOFTypes'])
            : [];

        // Combine lists while preserving order
        List<String> combinedOfTypes = [];
        combinedOfTypes.addAll(jsonOfTypes as Iterable<String>);

        // Add items from hiveOfTypes if not already present
        for (var item in hiveOfTypes) {
          if (!combinedOfTypes.contains(item)) {
            combinedOfTypes.add(item);
          }
        }

        // Add items from hiveTextileOfTypes if not already present
        for (var item in hiveTextileOfTypes) {
          if (!combinedOfTypes.contains(item)) {
            combinedOfTypes.add(item);
          }
        }

        ofTypes = combinedOfTypes;
        // Remove the ofTypes.sort() line to maintain the original order

        // Combine widths
        final jsonWidths = jsonData['widths'] != null
            ? List<String>.from(jsonData['widths'])
            : [];
        final hiveWidths = hiveData['widths'] != null
            ? List<String>.from(hiveData['widths'])
            : [];
        final hiveTextileWidths = hiveData['textileWidths'] != null
            ? List<String>.from(hiveData['textileWidths'])
            : [];
        widths = [...jsonWidths, ...hiveWidths, ...hiveTextileWidths];
        widths = widths.toSet().toList(); // Remove duplicates
        widths.sort();

        // Combine sampleOptions
        final jsonSampleOptions = jsonData['sampleOptions'] != null
            ? List<String>.from(jsonData['sampleOptions'])
            : [];
        final hiveSampleOptions = hiveData['sampleOptions'] != null
            ? List<String>.from(hiveData['sampleOptions'])
            : [];
        sampleOptions = [...jsonSampleOptions, ...hiveSampleOptions];
        sampleOptions = sampleOptions.toSet().toList(); // Remove duplicates

        // Combine agents
        final jsonAgents = jsonData['agents'] != null
            ? List<String>.from(jsonData['agents'])
            : [];
        final hiveAgents = hiveData['agents'] != null
            ? List<String>.from(hiveData['agents'])
            : [];
        agents = [...jsonAgents, ...hiveAgents];
        agents = agents.toSet().toList(); // Remove duplicates

        // Combine sampleMtrOptions
        final jsonSampleMtrOptions = jsonData['sampleMtrOptions'] != null
            ? List<String>.from(jsonData['sampleMtrOptions'])
            : [];
        final hiveSampleMtrOptions = hiveData['sampleMtrOptions'] != null
            ? List<String>.from(hiveData['sampleMtrOptions'])
            : [];
        sampleMtrOptions = [...jsonSampleMtrOptions, ...hiveSampleMtrOptions];
        sampleMtrOptions = sampleMtrOptions.toSet().toList(); // Remove duplicates

        _isLoading = false;
      });

      // Debug: Print loaded data
      print('Combined parties: $parties');
      print('Combined ofTypes: $ofTypes');
    } catch (e) {
      print('Error loading data from sources: $e');
      // Fallback to defaults
      _useDefaultData();
    }
  }

  void _useDefaultData() {
    setState(() {
      parties = [
        'Manish Textiles',
        'Raj Fabrics',
        'Kumar Mills',
        'Shree Textiles',
      ];
      ofTypes = ['Regular', 'Mix', 'Plain'];
      widths = ['44"', '54"', '58"', '60"'];
      sampleOptions = ['Yes', 'No', 'Sample Only'];
      agents = ['Raju Sharma', 'Vijay Kumar', 'Anil Reddy', 'Sunil Patel'];
      sampleMtrOptions = ['2.5', '5.0', '7.5', '10.0'];
      _isLoading = false;
    });
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default values');

      // Set default values only if keys don't exist
      if (!box.containsKey('parties')) {
        await box.put('parties', [
          'Manish Textiles',
          'Raj Fabrics',
          'Kumar Mills',
          'Shree Textiles',
        ]);
      }
      if (!box.containsKey('ofTypes')) {
        await box.put('ofTypes', ['Regular', 'Mix', 'Plain']);
      }
      if (!box.containsKey('widths')) {
        await box.put('widths', ['44"', '54"', '58"', '60"']);
      }
      if (!box.containsKey('sampleOptions')) {
        await box.put('sampleOptions', ['Yes', 'No', 'Sample Only']);
      }
      if (!box.containsKey('agents')) {
        await box.put('agents', [
          'Raju Sharma',
          'Vijay Kumar',
          'Anil Reddy',
          'Sunil Patel',
        ]);
      }
      if (!box.containsKey('sampleMtrOptions')) {
        await box.put('sampleMtrOptions', ['2.5', '5.0', '7.5', '10.0']);
      }

      await box.flush();
      print('Hive box initialized successfully');
    } catch (e) {
      print('Error initializing box with defaults: $e');
    }
  }

  // In your NewOrderSetupPage, update the _saveDataToStorage method:

  Future<void> _saveDataToStorage() async {
    try {
      final box = Hive.box('appData');

      // Convert all lists to List<String> to ensure type safety
      final List<String> partiesToSave = parties
          .map((e) => e.toString())
          .toList();
      final List<String> ofTypesToSave = ofTypes
          .map((e) => e.toString())
          .toList();
      final List<String> widthsToSave = widths
          .map((e) => e.toString())
          .toList();
      final List<String> sampleOptionsToSave = sampleOptions
          .map((e) => e.toString())
          .toList();
      final List<String> agentsToSave = agents
          .map((e) => e.toString())
          .toList();
      final List<String> sampleMtrOptionsToSave = sampleMtrOptions
          .map((e) => e.toString())
          .toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('parties', partiesToSave);
      await box.put('ofTypes', ofTypesToSave);
      await box.put('widths', widthsToSave);
      await box.put('sampleOptions', sampleOptionsToSave);
      await box.put('agents', agentsToSave);
      await box.put('sampleMtrOptions', sampleMtrOptionsToSave);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved parties: ${box.get('parties')}');
      print('Data saved successfully');
    } catch (e) {
      print('Error saving data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // In _saveOrderToHive method in NewOrderSetupPage
  Future<void> _saveOrderToHive() async {
    try {
      // Ensure the orders box is open
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }

      final box = Hive.box('orders');

      // Create order data map
      final Map<String, dynamic> orderData = {
        'party': selectedParty,
        'type': ofType,
        'width': selectedWidth,
        'defaultChoices': defaultChoices,
        'defaultMeters': defaultMetersController.text,
        'sampleRequired': sampleRequired,
        'sampleMtr': _showSampleMtrField ? selectedSampleMtr : null,
        'agent': selectedAgent,
        'status': 'pending', // Default status
        'date': _formatDate(DateTime.now()), // Use simple date format
        'orders': 0, // Initial order count
      };

      // Generate a unique key for the order
      final String key = 'order_${DateTime.now().millisecondsSinceEpoch}';

      // Save the order
      await box.put(key, orderData);

      // Explicitly flush to disk
      await box.flush();

      print('Order saved successfully with key: $key');

      // Notify that orders have been updated
      OrderService().notifyOrderUpdated();
      
      // Mark the party as mapped
      await _markPartyAsMapped(selectedParty!);
    } catch (e) {
      print('Error saving order: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this new method to _NewOrderSetupPageState:
  Future<void> _markPartyAsMapped(String partyName) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      
      final box = Hive.box('appData');
      List<Map<String, dynamic>> partiesData = [];
      
      // Get existing parties
      final existingParties = box.get('parties');
      if (existingParties != null) {
        if (existingParties is List) {
          for (var party in existingParties) {
            if (party is Map) {
              partiesData.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
              // Handle legacy data format
              partiesData.add({
                'name': party,
                'agent': null,
                'visitingCardImage': null,
                'isMapped': false,
              });
            }
          }
        }
      }
      
      // Find and update the party
      for (int i = 0; i < partiesData.length; i++) {
        if (partiesData[i]['name'] == partyName) {
          partiesData[i]['isMapped'] = true;
          break;
        }
      }
      
      // Save to Hive
      await box.put('parties', partiesData);
      await box.flush();
      
      print('Party "$partyName" marked as mapped');
    } catch (e) {
      print('Error marking party as mapped: $e');
    }
  }

  Future<void> _updatePartyDataFromHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      
      final box = Hive.box('appData');
      final partiesData = box.get('parties');
      
      if (partiesData != null) {
        List<String> updatedParties = [];
        
        if (partiesData is List) {
          for (var party in partiesData) {
            if (party is Map && party['name'] != null) {
              updatedParties.add(party['name'] as String);
            } else if (party is String) {
              updatedParties.add(party);
            }
          }
        }
        
        setState(() {
          parties = updatedParties;
        });
      }
    } catch (e) {
      print('Error updating party data: $e');
    }
  }

  // Add this helper function to format the date
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  Future<void> _addNewParty(String partyName, String? agent, String? visitingCardImage) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }
      
      final box = Hive.box('appData');
      List<Map<String, dynamic>> partiesData = [];
      
      // Get existing parties
      final existingParties = box.get('parties');
      if (existingParties != null) {
        if (existingParties is List) {
          for (var party in existingParties) {
            if (party is Map) {
              partiesData.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
              // Handle legacy data format
              partiesData.add({
                'name': party,
                'agent': null,
                'visitingCardImage': null,
                'isMapped': false,
              });
            }
          }
        }
      }
      
      // Check if party already exists
      final existingIndex = partiesData.indexWhere((p) => p['name'] == partyName);
      if (existingIndex != -1) {
        // Update existing party
        partiesData[existingIndex] = {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': partiesData[existingIndex]['isMapped'] ?? false,
        };
      } else {
        // Add new party at the beginning of the list
        partiesData.insert(0, {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': false,
        });
      }
      
      // Save to Hive
      await box.put('parties', partiesData);
      await box.flush();
      
      // Update local state - add to the beginning of the list
      setState(() {
        if (!parties.contains(partyName)) {
          parties.insert(0, partyName);
        }
        selectedParty = partyName;

        // Add new agent if provided and not already in the list
        if (agent != null && !agents.contains(agent)) {
          agents.add(agent);
          selectedAgent = agent;
        }
      });
    } catch (e) {
      print('Error adding new party: $e');
    }
  }
  
  // Check if Sample Mtr field should be shown
  bool get _showSampleMtrField {
    return sampleRequired == 'Yes' || sampleRequired == 'Sample Only';
  }

  // Rest of your code remains the same...
  // (Keep all the existing UI code from _buildMobileView onwards)

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          toolbarHeight: 50,
          title: Text(
            widget.isEditMode ? 'Edit Order - Setup' : 'New Order - Setup',
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: Text(
          widget.isEditMode ? 'Edit Order - Setup' : 'New Order - Setup',
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: isTablet ? _buildTabletView() : _buildMobileView(),
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartyNameField(),
          const SizedBox(height: 16),
          _buildOfTypeField(),
          const SizedBox(height: 16),
          _buildWidthField(),
          const SizedBox(height: 16),
          _buildDefaultChoicesField(),
          const SizedBox(height: 16),
          _buildDefaultMetersField(),
          const SizedBox(height: 16),
          _buildSampleRequiredField(),
          // Only show Sample Mtr field if Sample Required is 'Yes' or 'Sample Only'
          if (_showSampleMtrField) ...[
            const SizedBox(height: 16),
            _buildSampleMtrField(),
          ],
          const SizedBox(height: 24),
          _buildInfoNote(),
          const SizedBox(height: 24),
          _buildStartCapturingButton(),
        ],
      ),
    );
  }

  Widget _buildTabletView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartyNameField(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOfTypeField()),
              const SizedBox(width: 24),
              Expanded(child: _buildWidthField()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDefaultChoicesField()),
              const SizedBox(width: 24),
              Expanded(child: _buildDefaultMetersField()),
            ],
          ),
          const SizedBox(height: 24),
          // Conditionally show Sample Required and Sample Mtr fields
          if (_showSampleMtrField)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSampleRequiredField()),
                const SizedBox(width: 24),
                Expanded(child: _buildSampleMtrField()),
              ],
            )
          else
            _buildSampleRequiredField(),
          const SizedBox(height: 32),
          _buildInfoNote(),
          const SizedBox(height: 32),
          _buildStartCapturingButton(),
        ],
      ),
    );
  }

  Widget _buildPartyNameField() {
  return Card(
    elevation: 0,
    color: const Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Party Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(' *', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: Color(0xFF767676)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedParty,
                    hint: const Text('Search or select party...'),
                    isDense: true,
                    style: const TextStyle(color: Colors.black),
                    items: parties.map((party) {
                      return DropdownMenuItem<String>(
                        value: party,
                        child: Text(party), // Just show the text without any icon
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedParty = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF529FF3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF767676),
                    ),
                    iconSize: 24,
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF529FF3)),
                onPressed: _showAddNewPartyDialog,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // Add this helper method to get party image path
  String? _getPartyImage(String partyName) {
    try {
      if (!Hive.isBoxOpen('appData')) {
        return null;
      }
      
      final box = Hive.box('appData');
      final partiesData = box.get('parties');
      
      if (partiesData != null) {
        for (var party in partiesData) {
          if (party is Map && party['name'] == partyName) {
            return party['visitingCardImage'];
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting party image: $e');
      return null;
    }
  }

  void _showAddNewPartyDialog() {
  TextEditingController newPartyController = TextEditingController();
  String? selectedAgent;
  File? visitingCardImage;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                          'Add New Party',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF767676),
                          ),
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
                          // Party Name Field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Party Name: *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: newPartyController,
                                  inputFormatters: [
                                    NoLeadingOrMultipleSpacesFormatter(),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: 'Enter party name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onEditingComplete: () {
                                    // Trim trailing spaces when editing is complete
                                    newPartyController.text = newPartyController.text.trim();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Agent Field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Agent: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedAgent,
                                  hint: const Text('Select agent...'),
                                  isDense: true,
                                  style: const TextStyle(color: Colors.black),
                                  items: agents.map((agent) {
                                    return DropdownMenuItem<String>(
                                      value: agent,
                                      child: Text(agent),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAgent = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF529FF3),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF767676),
                                  ),
                                  iconSize: 24,
                                  isExpanded: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Visiting Card Photo Field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Visiting Card Photo: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final XFile? pickedFile = await _imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      preferredCameraDevice: CameraDevice.rear,
                                    );
                                    if (pickedFile != null) {
                                      setState(() {
                                        visitingCardImage = File(pickedFile.path);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.add_a_photo,
                                          color: Color(0xFF529FF3),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            visitingCardImage != null
                                                ? 'Photo captured'
                                                : 'Tap to capture visiting card',
                                            style: TextStyle(
                                              color: visitingCardImage != null
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (visitingCardImage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        visitingCardImage!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
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
                                // Trim any trailing spaces before saving
                                String partyName = newPartyController.text.trim();
                                if (partyName.isNotEmpty) {
                                  // Save to Hive first
                                  await _saveNewPartyToHive(partyName, selectedAgent, visitingCardImage?.path);
                                  
                                  // Then refresh party data from Hive
                                  await _refreshPartyData();
                                  
                                  // Set the selected party to the newly added one
                                  setState(() {
                                    selectedParty = partyName;
                                  });
                                  
                                  Navigator.pop(context);
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Party added successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
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
    },
  );
}
  Future<void> _saveNewPartyToHive(String partyName, String? agent, String? visitingCardImage) async {
  try {
    if (!Hive.isBoxOpen('appData')) {
      await Hive.openBox('appData');
    }
    
    final box = Hive.box('appData');
    List<Map<String, dynamic>> partiesData = [];
    
    // Get existing parties
    final existingParties = box.get('parties');
    if (existingParties != null) {
      if (existingParties is List) {
        for (var party in existingParties) {
          if (party is Map) {
            partiesData.add(Map<String, dynamic>.from(party));
          } else if (party is String) {
            // Handle legacy data format
            partiesData.add({
              'name': party,
              'agent': null,
              'visitingCardImage': null,
              'isMapped': false,
            });
          }
        }
      }
    }
    
    // Check if party already exists
    final existingIndex = partiesData.indexWhere((p) => p['name'] == partyName);
    if (existingIndex != -1) {
      // Update existing party
      partiesData[existingIndex] = {
        'name': partyName,
        'agent': agent,
        'visitingCardImage': visitingCardImage,
        'isMapped': partiesData[existingIndex]['isMapped'] ?? false,
      };
    } else {
      // Add new party at the beginning of the list
      partiesData.insert(0, {
        'name': partyName,
        'agent': agent,
        'visitingCardImage': visitingCardImage,
        'isMapped': false,
      });
    }
    
    // Save to Hive
    await box.put('parties', partiesData);
    await box.flush();
    
    // Update local state immediately
    setState(() {
      if (!parties.contains(partyName)) {
        parties.insert(0, partyName);
      }
      
      // Add new agent if provided and not already in the list
      if (agent != null && !agents.contains(agent)) {
        agents.add(agent);
      }
    });
    
    print('Party "$partyName" saved to Hive with all details');
  } catch (e) {
    print('Error saving new party to Hive: $e');
  }
}
  Future<void> _refreshPartyData() async {
  try {
    if (!Hive.isBoxOpen('appData')) {
      await Hive.openBox('appData');
    }
    
    final box = Hive.box('appData');
    final partiesData = box.get('parties');
    
    if (partiesData != null) {
      List<String> updatedParties = [];
      
      if (partiesData is List) {
        for (var party in partiesData) {
          if (party is Map && party['name'] != null) {
            updatedParties.add(party['name'] as String);
          } else if (party is String) {
            updatedParties.add(party);
          }
        }
      }
      
      setState(() {
        parties = updatedParties;
      });
    }
  } catch (e) {
    print('Error updating party data: $e');
  }
}
  Widget _buildOfTypeField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('O/F Type', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(' *', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ofTypes.map((type) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            ofType = type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: ofType == type
                                ? const Color(0xFF2563EB)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ofType == type
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF529FF3)),
                  onPressed: _showAddNewTypeDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewTypeDialog() {
  TextEditingController newTypeController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Set only width constraint, keep original height
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                // Remove maxHeight to keep original dialog height
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // This keeps the dialog compact
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
                          'Add O/F Type',
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

                  // Content without Expanded to keep compact
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Type Name Field in a card
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
                                    'Type Name: *',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: newTypeController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Next Season, Special',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onEditingComplete: () {
                                  // Trim trailing spaces when editing is complete
                                  newTypeController.text = newTypeController.text.trim();
                                  setState(() {});
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
                                // Trim any trailing spaces before saving
                                String typeName = newTypeController.text.trim();
                                if (typeName.isNotEmpty) {
                                  setState(() {
                                    ofTypes.add(typeName);
                                    ofType = typeName;
                                  });

                                  // Save to Hive
                                  await _saveDataToStorage();

                                  Navigator.pop(context);

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Type added successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
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
    },
  );
}
  Widget _buildWidthField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('Width', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(' *', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widths.map((width) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedWidth = width;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selectedWidth == width
                                ? const Color(0xFF2563EB)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            width,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedWidth == width
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF529FF3)),
                  onPressed: _showAddNewWidthDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

    void _showAddNewWidthDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddWidthDialog(
          // Pass the loaded active products to the dialog
          activeProducts: activeProducts,
        );
      },
    ).then((result) {
      if (result != null) {
        // Add the width using the service
        WidthService().addWidth(result['product'], result['width']).then((_) {
          // Reload the widths
          _loadWidths();
          
          // Set the selected width to the newly added one
          setState(() {
            selectedWidth = result['width'].toString() + '"';
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Width added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }).catchError((error) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding width: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    });
  }

Future<void> _loadWidths() async {
  try {
    // Use the WidthService to get widths
    List<Map<String, dynamic>> widthsData = await WidthService().getWidths();
    
    // Convert WidthService widths to strings with " at the end
    List<String> serviceWidths = widthsData.map((width) => width['width'].toString() + '"').toList();
    
    // Combine existing widths with service widths
    setState(() {
      // Create a set to avoid duplicates
      Set<String> combinedWidths = Set.from(widths);
      
      // Add service widths to the set
      combinedWidths.addAll(serviceWidths);
      
      // Convert back to list and sort
      widths = combinedWidths.toList();
      widths.sort((a, b) {
        // Extract numeric value for comparison
        double aNum = double.tryParse(a.replaceAll('"', '')) ?? 0;
        double bNum = double.tryParse(b.replaceAll('"', '')) ?? 0;
        return aNum.compareTo(bNum);
      });
    });
    
    print('Loaded ${widths.length} widths from combined sources');
  } catch (e) {
    print('Error loading widths: $e');
    // Don't replace existing widths, just ensure we have defaults
    if (widths.isEmpty) {
      setState(() {
        widths = ['44"', '54"', '58"', '60"']; // Fallback to defaults
      });
    }
  }
}
  Widget _buildDefaultChoicesField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Choices',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (defaultChoices > 0) {
                        setState(() {
                          defaultChoices--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      defaultChoices.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        defaultChoices++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultMetersField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Meters',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: defaultMetersController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                NoLeadingOrMultipleSpacesFormatter(),
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF529FF3)),
                ),
                hintText: 'Enter meters',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onEditingComplete: () {
                // Trim trailing spaces when editing is complete
                defaultMetersController.text = defaultMetersController.text
                    .trim();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleRequiredField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Required?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: sampleOptions.map((option) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        sampleRequired = option;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sampleRequired == option
                            ? const Color(0xFF2563EB)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sampleRequired == option
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleMtrField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Mtr',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: selectedSampleMtr,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF767676),
                    ),
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSampleMtr = newValue!;
                      });
                    },
                    items: sampleMtrOptions.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF529FF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF529FF3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Quality and Weave Type will be selected during photo capture. These defaults will be used for other fields.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Modified _buildStartCapturingButton to save order and navigate to TextileDetailsPage
  Widget _buildStartCapturingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (selectedParty != null) {
            if (widget.isEditMode) {
              // In edit mode, just return the updated values back to textile_details
              Navigator.pop(context, {
                'ofType': ofType,
                'selectedWidth': selectedWidth,
                'defaultChoices': defaultChoices,
                'defaultMeters':
                    int.tryParse(defaultMetersController.text) ?? 100,
                'sampleRequired': sampleRequired,
                'selectedSampleMtr': selectedSampleMtr,
              });
            } else {
              // In new mode, save order and navigate to textile_details
              // Save order to Hive
              await _saveOrderToHive();

              // Notify that orders have been updated
              OrderService().notifyOrderUpdated();

              // Navigate to TextileDetailsPage with all selected values
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => TextileDetailsPage(
                    partyName: selectedParty!,
                    textileType: ofType,
                    selectedWidth: selectedWidth,
                    defaultChoices: defaultChoices,
                    defaultMeters:
                        int.tryParse(defaultMetersController.text) ?? 100,
                    sampleRequired: sampleRequired,
                    selectedSampleMtr: selectedSampleMtr,
                  ),
                ),
              );

              // If user clicked "Edit Defaults", update the values here
              if (result != null && result['isEditMode'] != true) {
                setState(() {
                  ofType = result['ofType'] ?? ofType;
                  selectedWidth = result['selectedWidth'] ?? selectedWidth;
                  defaultChoices = result['defaultChoices'] ?? defaultChoices;
                  int metersValue =
                      result['defaultMeters'] ??
                      int.tryParse(defaultMetersController.text) ??
                      100;
                  sampleRequired = result['sampleRequired'] ?? sampleRequired;
                  selectedSampleMtr =
                      result['selectedSampleMtr'] ?? selectedSampleMtr;
                  defaultMetersController.text = metersValue.toStringAsFixed(0);
                });
              }
            }
          } else {
            // Show error message if party is not selected
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a party name'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Text(
              widget.isEditMode ? 'Update' : 'Start Capturing',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Party {
  final String name;
  final String? agent;
  final String? visitingCardImage;
  final bool isMapped;

  Party({
    required this.name,
    this.agent,
    this.visitingCardImage,
    this.isMapped = false,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      name: map['name'] ?? '',
      agent: map['agent'],
      visitingCardImage: map['visitingCardImage'],
      isMapped: map['isMapped'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'agent': agent,
      'visitingCardImage': visitingCardImage,
      'isMapped': isMapped,
    };
  }
}