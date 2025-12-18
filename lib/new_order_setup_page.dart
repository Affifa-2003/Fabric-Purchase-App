// lib/new_order_setup_page.dart

// --- START: ADD THESE NEW IMPORTS ---
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:purchase_app/service/data_service.dart';
import 'package:purchase_app/service/order_service.dart';
import 'package:purchase_app/service/party_service.dart';
import 'package:purchase_app/service/width_service.dart';
// --- ADD THIS IMPORT FOR ORDER FORM TYPE ---
import 'package:purchase_app/service/order_form_type_service.dart';
import 'package:purchase_app/textile_details.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:purchase_app/widgets/add_party_dialog.dart';
import 'package:purchase_app/widgets/add_width_dialog.dart';
// --- ADD THIS IMPORT FOR THE DIALOG ---
import 'package:purchase_app/widgets/add_order_form_type_dialog.dart';

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
  // --- CHANGE: We will now load ofTypes from a service, but keep defaults ---
  // List<String> ofTypes = []; // Old way
  List<String> ofTypes = ['Regular', 'Mix', 'Plain']; // Start with defaults
  List<String> widths = [];
  List<String> sampleOptions = [];
  List<String> agents = [];
  List<String> transports = [];
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

    // Initialize Hive and load all data in the correct order
    _initializeHiveAndLoadData().then((_) {
      // Load widths from the service after other data is loaded
      _loadWidths();
      // Load products after other data is loaded
      _loadProducts();
      _refreshSampleMetersData();
      // --- ADD THIS: Load O/F Types from the service ---
      _loadOrderFormTypes();

      // Load agents and transports using the new service
      _loadAgentsAndTransports().then((_) {
        // Update party data from Hive to get latest changes AFTER agents are loaded
        _updatePartyDataFromHive();
      });
    });

    // Add a delay to verify data after loading
    Future.delayed(const Duration(seconds: 2), () {
      _verifyDataPersistence();
    });
  }

  // --- ADD THIS NEW METHOD TO LOAD ORDER FORM TYPES ---
  Future<void> _loadOrderFormTypes() async {
    try {
      // Use the OrderFormTypeService to get order form types
      List<Map<String, dynamic>> orderFormTypesData =
          await OrderFormTypeService().getOrderFormTypes();

      // Extract just the names from the order form types
      List<String> serviceOfTypes = orderFormTypesData
          .map((type) => type['name'] as String)
          .toList();

      // Combine with default types, using a Set to avoid duplicates
      Set<String> combinedOfTypes = Set.from(ofTypes);
      combinedOfTypes.addAll(serviceOfTypes);

      setState(() {
        ofTypes = combinedOfTypes.toList();
      });

      print(
        'Loaded ${ofTypes.length} order form types from service and defaults',
      );
    } catch (e) {
      print('Error loading order form types: $e');
    }
  }

  // --- ADD THIS NEW METHOD TO SHOW THE ADD DIALOG ---
  void _showAddNewTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // This is the same dialog used in order_form_type_page.dart
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
              // Reload the order form types to get the latest list
              _loadOrderFormTypes();

              // Set the selected type to the newly added one for good UX
              setState(() {
                ofType = result['name'];
              });

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

  // --- REST OF YOUR EXISTING CODE REMAINS THE SAME ---
  // I am keeping all your existing methods below this point.

  Future<void> _loadAgentsAndTransports() async {
    try {
      final dataService = DataService();

      final results = await Future.wait([
        dataService.getAgents(),
        dataService.getTransports(),
      ]);

      setState(() {
        agents = results[0] as List<String>;
        transports = results[1] as List<String>;
      });

      print(
        'Loaded ${agents.length} agents and ${transports.length} transports from service',
      );
    } catch (e) {
      print('Error loading agents and transports: $e');
    }
  }

  Future<void> _initializeHiveAndLoadData() async {
    try {
      appDataBox = Hive.box('appData');
      ordersBox = Hive.box('orders');
      print(
        'Hive boxes are open: ${Hive.isBoxOpen('appData')} and ${Hive.isBoxOpen('orders')}',
      );

      await _loadDataFromSources();
    } catch (e) {
      print('Error initializing Hive: $e');
      await _reinitializeHive();
    }
  }

  Future<void> _loadProducts() async {
    try {
      List<Map<String, dynamic>> hiveProducts = [];

      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final productsData = box.get('products');
      if (productsData != null) {
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
        activeProducts = products
            .where((product) => product['status'] == 'Active')
            .toList();
      });

      print(
        'Loaded ${products.length} products (${activeProducts.length} active)',
      );
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _reinitializeHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }
      appDataBox = Hive.box('appData');
      ordersBox = Hive.box('orders');

      await _loadDataFromSources();
    } catch (e) {
      print('Error reinitializing Hive: $e');
      _useDefaultData();
    }
  }

  Future<void> _refreshAgentsData() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final agentsData = box.get('agents');

      if (agentsData != null) {
        List<String> updatedAgents = [];

        if (agentsData is List) {
          for (var agent in agentsData) {
            if (agent is String) {
              updatedAgents.add(agent);
            }
          }
        }

        setState(() {
          agents = updatedAgents;
        });
      }
    } catch (e) {
      print('Error refreshing agents data: $e');
    }
  }

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

  Future<void> _refreshSampleMetersData() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final sampleMetersData = box.get('sampleMeters');

      if (sampleMetersData != null) {
        List<String> updatedSampleMeters = [];

        if (sampleMetersData is List) {
          for (var meter in sampleMetersData) {
            if (meter is Map &&
                meter['name'] != null &&
                meter['status'] == 'Active') {
              updatedSampleMeters.add(meter['name'] as String);
            }
          }
        }

        setState(() {
          final combinedOptions = [...sampleMtrOptions, ...updatedSampleMeters];
          sampleMtrOptions = combinedOptions.toSet().toList();
        });

        print('Refreshed sample meters: $sampleMtrOptions');
      }
    } catch (e) {
      print('Error refreshing sample meters data: $e');
    }
  }

  Future<void> _loadDataFromSources() async {
    try {
      Map<String, dynamic> jsonData = {};
      try {
        final String response = await rootBundle.loadString(
          'assets/order_data.json',
        );
        jsonData = json.decode(response);
        print('Loaded data from JSON successfully');
      } catch (e) {
        print('Error loading JSON data: $e');
      }

      Map<String, dynamic> hiveData = {};
      try {
        final box = Hive.box('appData');

        if (box.isEmpty) {
          await _initializeBoxWithDefaults(box);
        }

        final keys = box.keys.toList();
        for (var key in keys) {
          hiveData[key] = box.get(key);
        }
        print('Loaded data from Hive successfully');
      } catch (e) {
        print('Error loading Hive data: $e');
      }

      setState(() {
        final jsonParties = jsonData['parties'] != null
            ? List<String>.from(jsonData['parties'])
            : [];
        List<String> hiveParties = [];
        if (hiveData['parties'] != null) {
          if (hiveData['parties'] is List) {
            for (var party in hiveData['parties']) {
              if (party is String) {
                hiveParties.add(party);
              } else if (party is Map && party['name'] != null) {
                hiveParties.add(party['name'] as String);
              }
            }
          }
        }

        parties = [...jsonParties, ...hiveParties];
        parties = parties.toSet().toList();

        print('Combined parties: $parties');

        // --- NOTE: We are no longer loading ofTypes from here ---
        // The _loadOrderFormTypes method handles it now.

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
        widths = widths.toSet().toList();
        widths.sort();

        final jsonSampleOptions = jsonData['sampleOptions'] != null
            ? List<String>.from(jsonData['sampleOptions'])
            : [];
        final hiveSampleOptions = hiveData['sampleOptions'] != null
            ? List<String>.from(hiveData['sampleOptions'])
            : [];
        sampleOptions = [...jsonSampleOptions, ...hiveSampleOptions];
        sampleOptions = sampleOptions.toSet().toList();

        final jsonAgents = jsonData['agents'] != null
            ? List<String>.from(jsonData['agents'])
            : [];
        final hiveAgents = hiveData['agents'] != null
            ? List<String>.from(hiveData['agents'])
            : [];

        List<String> processedHiveAgents = [];
        if (hiveData['agents'] != null && hiveData['agents'] is List) {
          for (var agent in hiveData['agents']) {
            if (agent is String) {
              processedHiveAgents.add(agent);
            } else if (agent is Map && agent['name'] != null) {
              processedHiveAgents.add(agent['name'] as String);
            }
          }
        }

        Set<String> uniqueAgents = Set.from(jsonAgents);
        uniqueAgents.addAll(processedHiveAgents);

        agents = uniqueAgents.toList();

        final jsonTransports = jsonData['transports'] != null
            ? List<String>.from(jsonData['transports'])
            : [];
        final hiveTransports = hiveData['transports'] != null
            ? List<String>.from(hiveData['transports'])
            : [];

        List<String> processedHiveTransports = [];
        if (hiveData['transports'] != null && hiveData['transports'] is List) {
          for (var transport in hiveData['transports']) {
            if (transport is String) {
              processedHiveTransports.add(transport);
            } else if (transport is Map && transport['name'] != null) {
              processedHiveTransports.add(transport['name'] as String);
            }
          }
        }

        Set<String> uniqueTransports = Set.from(jsonTransports);
        uniqueTransports.addAll(processedHiveTransports);

        transports = uniqueTransports.toList();

        List<String> hiveSampleMeters = [];
        if (hiveData['sampleMeters'] != null &&
            hiveData['sampleMeters'] is List) {
          for (var meter in hiveData['sampleMeters']) {
            if (meter is Map && meter['name'] != null) {
              if (meter['status'] == 'Active') {
                hiveSampleMeters.add(meter['name'] as String);
              }
            }
          }
        }

        final jsonSampleMtrOptions = jsonData['sampleMtrOptions'] != null
            ? List<String>.from(jsonData['sampleMtrOptions'])
            : [];
        final hiveSampleMtrOptions = hiveData['sampleMtrOptions'] != null
            ? List<String>.from(hiveData['sampleMtrOptions'])
            : [];

        sampleMtrOptions = [
          ...jsonSampleMtrOptions,
          ...hiveSampleMeters,
          ...hiveSampleMtrOptions,
        ];
        sampleMtrOptions = sampleMtrOptions.toSet().toList();

        print('Final sampleMtrOptions: $sampleMtrOptions');
        print('Final agents: $agents');
        print('Final transports: $transports');

        _isLoading = false;
      });

      print('Combined parties: $parties');
    } catch (e) {
      print('Error loading data from sources: $e');
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
      // --- ofTypes is already set with defaults in the state variable ---
      ofTypes = ['Regular', 'Mix', 'Plain'];
      widths = ['44"', '54"', '58"', '60"'];
      sampleOptions = ['Yes', 'No', 'Sample Only'];
      agents = ['Raju Sharma', 'Vijay Kumar', 'Anil Reddy', 'Sunil Patel'];
      transports = ['DTDC', 'FedEx', 'Delhivery', 'Blue Dart'];
      sampleMtrOptions = ['2.5', '5.0', '7.5', '10.0'];
      _isLoading = false;
    });
  }

  Future<void> _initializeBoxWithDefaults(Box box) async {
    try {
      print('Initializing Hive box with default values');

      if (!box.containsKey('parties')) {
        await box.put('parties', [
          'Manish Textiles',
          'Raj Fabrics',
          'Kumar Mills',
          'Shree Textiles',
        ]);
      }
      // --- We don't need to initialize 'ofTypes' here anymore ---
      // if (!box.containsKey('ofTypes')) {
      //   await box.put('ofTypes', ['Regular', 'Mix', 'Plain']);
      // }
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
      if (!box.containsKey('transports')) {
        await box.put('transports', [
          'DTDC',
          'FedEx',
          'Delhivery',
          'Blue Dart',
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

  Future<void> _saveDataToStorage() async {
    try {
      final box = Hive.box('appData');

      final List<String> partiesToSave = parties
          .map((e) => e.toString())
          .toList();
      // --- We no longer save ofTypes directly to Hive here ---
      // final List<String> ofTypesToSave =
      //     ofTypes.map((e) => e.toString()).toList();
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

      await box.put('parties', partiesToSave);
      // await box.put('ofTypes', ofTypesToSave); // Not needed
      await box.put('widths', widthsToSave);
      await box.put('sampleOptions', sampleOptionsToSave);
      await box.put('agents', agentsToSave);
      await box.put('sampleMtrOptions', sampleMtrOptionsToSave);

      await box.flush();

      print('Saved parties: ${box.get('parties')}');
      print('Data saved successfully');
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveOrderToHive() async {
    try {
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }

      final box = Hive.box('orders');

      final Map<String, dynamic> orderData = {
        'party': selectedParty,
        'type': ofType,
        'width': selectedWidth,
        'defaultChoices': defaultChoices,
        'defaultMeters': defaultMetersController.text,
        'sampleRequired': sampleRequired,
        'sampleMtr': _showSampleMtrField ? selectedSampleMtr : null,
        'agent': selectedAgent,
        'status': 'pending',
        'date': _formatDate(DateTime.now()),
        'orders': 0,
      };

      final String key = 'order_${DateTime.now().millisecondsSinceEpoch}';

      await box.put(key, orderData);
      await box.flush();

      print('Order saved successfully with key: $key');

      OrderService().notifyOrderUpdated();

      await _markPartyAsMapped(selectedParty!);

      if (_showSampleMtrField && selectedSampleMtr != null) {
        await _markSampleMeterAsMapped(selectedSampleMtr);
      }
    } catch (e) {
      print('Error saving order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markSampleMeterAsMapped(String meterName) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<Map<String, dynamic>> sampleMeters = [];

      final existingSampleMeters = box.get('sampleMeters');
      if (existingSampleMeters != null) {
        if (existingSampleMeters is List) {
          for (var meter in existingSampleMeters) {
            if (meter is Map) {
              sampleMeters.add(Map<String, dynamic>.from(meter));
            }
          }
        }
      }

      for (int i = 0; i < sampleMeters.length; i++) {
        if (sampleMeters[i]['name'] == meterName) {
          sampleMeters[i]['isMapped'] = true;
          break;
        }
      }

      await box.put('sampleMeters', sampleMeters);
      await box.flush();

      print('Sample meter "$meterName" marked as mapped');
    } catch (e) {
      print('Error marking sample meter as mapped: $e');
    }
  }

  Future<void> _markPartyAsMapped(String partyName) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<Map<String, dynamic>> partiesData = [];

      final existingParties = box.get('parties');
      if (existingParties != null) {
        if (existingParties is List) {
          for (var party in existingParties) {
            if (party is Map) {
              partiesData.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
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

      for (int i = 0; i < partiesData.length; i++) {
        if (partiesData[i]['name'] == partyName) {
          partiesData[i]['isMapped'] = true;
          break;
        }
      }

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

        print('Updated parties from Hive: $updatedParties');
      }

      await _loadAgentsAndTransports();
    } catch (e) {
      print('Error updating party data: $e');
    }
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  Future<void> _addNewParty(
    String partyName,
    String? agent,
    String? visitingCardImage,
  ) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<Map<String, dynamic>> partiesData = [];

      final existingParties = box.get('parties');
      if (existingParties != null) {
        if (existingParties is List) {
          for (var party in existingParties) {
            if (party is Map) {
              partiesData.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
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

      final existingIndex = partiesData.indexWhere(
        (p) => p['name'] == partyName,
      );
      if (existingIndex != -1) {
        partiesData[existingIndex] = {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': partiesData[existingIndex]['isMapped'] ?? false,
        };
      } else {
        partiesData.insert(0, {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': false,
        });
      }

      await box.put('parties', partiesData);
      await box.flush();

      setState(() {
        if (!parties.contains(partyName)) {
          parties.insert(0, partyName);
        }
        selectedParty = partyName;

        if (agent != null && !agents.contains(agent)) {
          agents.add(agent);
          selectedAgent = agent;
        }
      });
    } catch (e) {
      print('Error adding new party: $e');
    }
  }

  bool get _showSampleMtrField {
    return sampleRequired == 'Yes' || sampleRequired == 'Sample Only';
  }

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
                      hint: Text(
                        parties.isEmpty
                            ? 'Loading parties...'
                            : 'Search or select party...',
                      ),
                      isDense: true,
                      style: const TextStyle(color: Colors.black),
                      items: parties.map((party) {
                        return DropdownMenuItem<String>(
                          value: party,
                          child: Text(party),
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
                  onPressed: () {
                    if (agents.isEmpty || transports.isEmpty) {
                      _loadAgentsAndTransports().then((_) {
                        _showAddNewPartyDialog();
                      });
                    } else {
                      _showAddNewPartyDialog();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
    showDialog(
      context: context,
      builder: (context) {
        return AddPartyDialog(
          isEditMode: false,
          agents: agents,
          transports: transports,
        );
      },
    ).then((result) {
      if (result != null) {
        PartyService()
            .addParty(
              result['name'],
              result['code'],
              partyType: result['partyType'],
              agent: result['agent'],
              mobileNumbers: result['mobileNumbers'],
              email: result['email'],
              address: result['address'],
              state: result['state'],
              district: result['district'],
              gstNo: result['gstNo'],
              bankName: result['bankName'],
              accountNo: result['accountNo'],
              ifscCode: result['ifscCode'],
              branchName: result['branchName'],
              accountHolderName: result['accountHolderName'],
              transport: result['transport'],
              status: result['status'],
            )
            .then((_) {
              _updatePartyDataFromHive();

              setState(() {
                selectedParty = result['name'];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Party added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding party: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
      }
    });
  }

  Future<void> _refreshTransportsData() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      final transportsData = box.get('transports');

      if (transportsData != null) {
        List<String> updatedTransports = [];

        if (transportsData is List) {
          for (var transport in transportsData) {
            if (transport is String) {
              updatedTransports.add(transport);
            } else if (transport is Map && transport['name'] != null) {
              updatedTransports.add(transport['name'] as String);
            }
          }
        }

        setState(() {
          transports = updatedTransports;
        });
      }
    } catch (e) {
      print('Error refreshing transports data: $e');
    }
  }

  Future<void> _saveNewPartyToHive(
    String partyName,
    String? agent,
    String? visitingCardImage,
  ) async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      List<Map<String, dynamic>> partiesData = [];

      final existingParties = box.get('parties');
      if (existingParties != null) {
        if (existingParties is List) {
          for (var party in existingParties) {
            if (party is Map) {
              partiesData.add(Map<String, dynamic>.from(party));
            } else if (party is String) {
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

      final existingIndex = partiesData.indexWhere(
        (p) => p['name'] == partyName,
      );
      if (existingIndex != -1) {
        partiesData[existingIndex] = {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': partiesData[existingIndex]['isMapped'] ?? false,
        };
      } else {
        partiesData.insert(0, {
          'name': partyName,
          'agent': agent,
          'visitingCardImage': visitingCardImage,
          'isMapped': false,
        });
      }

      await box.put('parties', partiesData);
      await box.flush();

      setState(() {
        if (!parties.contains(partyName)) {
          parties.insert(0, partyName);
        }

        if (agent != null && !agents.contains(agent)) {
          agents.add(agent);
          _saveAgentsToStorage();
        }
      });

      print('Party "$partyName" saved to Hive with all details');
    } catch (e) {
      print('Error saving new party to Hive: $e');
    }
  }

  Future<void> _saveAgentsToStorage() async {
    try {
      final box = Hive.box('appData');

      final List<String> agentsToSave = agents
          .map((e) => e.toString())
          .toList();

      await box.put('agents', agentsToSave);
      await box.flush();

      print('Agents data saved successfully');
    } catch (e) {
      print('Error saving agents data: $e');
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
                  // --- THIS IS THE KEY CHANGE ---
                  onPressed: _showAddNewTypeDialog, // Call the new method
                ),
              ],
            ),
          ],
        ),
      ),
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
        return AddWidthDialog(activeProducts: activeProducts);
      },
    ).then((result) {
      if (result != null) {
        WidthService()
            .addWidth(result['product'], result['width'])
            .then((_) {
              _loadWidths();

              setState(() {
                selectedWidth = result['width'].toString() + '"';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Width added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
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
      List<Map<String, dynamic>> widthsData = await WidthService().getWidths();

      List<String> serviceWidths = widthsData
          .map((width) => width['width'].toString() + '"')
          .toList();

      setState(() {
        Set<String> combinedWidths = Set.from(widths);
        combinedWidths.addAll(serviceWidths);

        widths = combinedWidths.toList();
        widths.sort((a, b) {
          double aNum = double.tryParse(a.replaceAll('"', '')) ?? 0;
          double bNum = double.tryParse(b.replaceAll('"', '')) ?? 0;
          return aNum.compareTo(bNum);
        });
      });

      print('Loaded ${widths.length} widths from combined sources');
    } catch (e) {
      print('Error loading widths: $e');
      if (widths.isEmpty) {
        setState(() {
          widths = ['44"', '54"', '58"', '60"'];
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

  Widget _buildStartCapturingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (selectedParty != null) {
            if (widget.isEditMode) {
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
              await _saveOrderToHive();

              OrderService().notifyOrderUpdated();

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
