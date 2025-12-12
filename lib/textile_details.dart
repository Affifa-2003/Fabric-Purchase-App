import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'order_form_finish_page.dart';
import 'new_order_setup_page.dart';
import 'package:purchase_app/service/order_service.dart';
enum FilterType { mode, ofType }
class TextileDetailsPage extends StatefulWidget {
  final String partyName;
  final String textileType;
  final String selectedWidth;
  final int defaultChoices;
  final double defaultMeters;
  final String sampleRequired;
  final String? selectedSampleMtr;
  final Map<String, dynamic>? initialDesign;
  final bool lockOFType;

  const TextileDetailsPage({
    Key? key,
    required this.partyName,
    required this.textileType,
    required this.selectedWidth,
    required this.defaultChoices,
    required this.defaultMeters,
    required this.sampleRequired,
    this.selectedSampleMtr,
    this.initialDesign,
    this.lockOFType = false,
  }) : super(key: key);

  @override
  _TextileDetailsPageState createState() => _TextileDetailsPageState();
}

class _TextileDetailsPageState extends State<TextileDetailsPage> {
  Map<String, dynamic> textileData = {};
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = const Color(0xFF2563EB);
  final ImagePicker _imagePicker = ImagePicker();
  String selectedFilter = 'All';
  
  FilterType currentFilterType = FilterType.mode;
  TextEditingController defaultMetersController = TextEditingController(
    text: '100',
  );
  // Form state
  List<XFile> capturedPhotos = []; // Changed to list for multiple photos
  String selectedMode = 'Design';
  String? selectedQuality;
  String? selectedWeave;
  String? partyDesignNo;
  late String selectedWidth;
  late int defaultChoices;
  late double defaultMeters;
  late String sampleRequired;
  late String? selectedSampleMtr;
  late String selectedOFType;
  // Add these variables to track current default values
  late String currentDefaultOFType;
  late String currentDefaultWidth;
  late int currentDefaultChoices;
  late double currentDefaultMeters;

  List<String> qualities = ['PC', 'Cotton', 'CP', 'Linen'];
  List<String> weaves = ['Twill', 'Oxford', 'Dobby', 'Flannel', 'Satin'];
  List<String> widthOptions = ['44"', '54"', '58"', '60"', '72"'];
  List<Map<String, dynamic>> capturedDesigns = [];

  // For O/F Type override
  List<String> ofTypes = ['Regular', 'Mix', 'Plain'];

  // For Weave Type dialog
  final TextEditingController _weaveTypeController = TextEditingController();
  bool _showAddWeaveDialog = false;

  // For Quality dialog
  final TextEditingController _qualityController = TextEditingController();
  bool _showAddQualityDialog = false;

  // For O/F Type dialog
  final TextEditingController _ofTypeController = TextEditingController();
  bool _showAddOFTypeDialog = false;

  // For Width dialog
  final TextEditingController _widthController = TextEditingController();
  bool _showAddWidthDialog = false;

  TextEditingController _partyDesignController = TextEditingController();

  // APC (Auto Party Code) state
  bool _isGeneratingAPC = false;
  // APC counters removed; APC is generated from existing saved designs

  // Hive boxes
  late Box appDataBox;
  late Box designsBox;

  // Design editing state
  int? _editingDesignIndex;
  TextEditingController _choicesController = TextEditingController();
  // _metersController removed (not used). Use defaultMetersController instead.
  // TextEditingController _partyDesignController = TextEditingController();

  // Full screen photo preview state
  int? _previewPhotoIndex;

  @override
  void initState() {
    super.initState();
    // Initialize with values from new_order_setup_page
    selectedOFType = widget.textileType;
    selectedWidth = widget.selectedWidth;
    defaultChoices = widget.defaultChoices;
    defaultMeters = widget.defaultMeters;
    sampleRequired = widget.sampleRequired;
    selectedSampleMtr = widget.selectedSampleMtr;
    defaultMetersController = TextEditingController(
      text: defaultMeters.toString(),
    );

    // Initialize choices, meters and party design controllers
    _choicesController = TextEditingController(text: defaultChoices.toString());
    defaultMetersController = TextEditingController(
      text: defaultMeters.toString(),
    );
    _partyDesignController = TextEditingController(text: partyDesignNo ?? '');
    // Initialize current default values
    currentDefaultOFType = widget.textileType;
    currentDefaultWidth = widget.selectedWidth;
    currentDefaultChoices = widget.defaultChoices;
    currentDefaultMeters = widget.defaultMeters;

    _initializeHiveAndLoadData();
  }

  // Update the _initializeHiveAndLoadData method to initialize with empty designs
  Future<void> _initializeHiveAndLoadData() async {
    try {
      // Get the boxes (they should already be open from main.dart)
      appDataBox = Hive.box('appData');

      // Check if designs box is open, if not open it
      if (!Hive.isBoxOpen('designs')) {
        designsBox = await Hive.openBox('designs');
      } else {
        designsBox = Hive.box('designs');
      }

      print(
        'Hive boxes are open: ${Hive.isBoxOpen('appData')} and ${Hive.isBoxOpen('designs')}',
      );

      // Load data from JSON and Hive
      await _loadDataFromSources();

      // Initialize textileData with empty values
      textileData = {'d': 0, 'ch': 0, 'mtr': 0};

      // Load captured designs from Hive
      await _loadCapturedDesigns();
    } catch (e) {
      print('Error initializing Hive: $e');
      // Try to recover by reinitializing
      await _reinitializeHive();
    }
  }

  Future<void> _reinitializeHive() async {
    try {
      // If the boxes are closed, reopen them
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      if (!Hive.isBoxOpen('designs')) {
        await Hive.openBox('designs');
      }
      appDataBox = Hive.box('appData');
      designsBox = Hive.box('designs');

      // Load data again
      await _loadDataFromSources();
    } catch (e) {
      print('Error reinitializing Hive: $e');
      // As a last resort, use defaults
      _useDefaultData();
    }
  }

  // Updated method to load data from both JSON and Hive
  Future<void> _loadDataFromSources() async {
    try {
      // Load data from order_data.json
      Map<String, dynamic> jsonOrderData = {};
      try {
        final String response = await rootBundle.loadString(
          'assets/order_data.json',
        );
        jsonOrderData = json.decode(response);
        print('Loaded order data from JSON successfully');
      } catch (e) {
        print('Error loading order JSON data: $e');
      }

      // Load data from textile_designs.json
      Map<String, dynamic> jsonTextileData = {};
      try {
        final String response = await rootBundle.loadString(
          'assets/textile_designs.json',
        );
        jsonTextileData = json.decode(response);
        print('Loaded textile data from JSON successfully');
      } catch (e) {
        print('Error loading textile JSON data: $e');
      }

      // Load data from Hive
      Map<String, dynamic> hiveData = {};
      try {
        final box = Hive.box('appData');

        // Get all data from Hive
        final keys = box.keys.toList();
        for (var key in keys) {
          hiveData[key] = box.get(key);
        }
        print('Loaded master data from Hive successfully');
      } catch (e) {
        print('Error loading Hive data: $e');
      }

      // Combine JSON and Hive data
      setState(() {
        // Combine O/F Types from order_data.json + Hive (both app-level and textile-specific keys)
        final jsonOFTypes = jsonOrderData['ofTypes'] != null
            ? List<String>.from(jsonOrderData['ofTypes'])
            : [];
        final hiveAppOFTypes = hiveData['ofTypes'] != null
            ? List<String>.from(hiveData['ofTypes'])
            : [];
        final hiveTextileOFTypes = hiveData['textileOFTypes'] != null
            ? List<String>.from(hiveData['textileOFTypes'])
            : [];

        // Combine lists while preserving order
        List<String> combinedOFTypes = [];
        combinedOFTypes.addAll(jsonOFTypes as Iterable<String>);

        // Add items from hiveAppOFTypes if not already present
        for (var item in hiveAppOFTypes) {
          if (!combinedOFTypes.contains(item)) {
            combinedOFTypes.add(item);
          }
        }

        // Add items from hiveTextileOFTypes if not already present
        for (var item in hiveTextileOFTypes) {
          if (!combinedOFTypes.contains(item)) {
            combinedOFTypes.add(item);
          }
        }

        ofTypes = combinedOFTypes;
        // Remove the ofTypes.sort() line to maintain the original order

        // Combine Widths from order_data.json + Hive (both app-level and textile-specific keys)
        final jsonWidths = jsonOrderData['widths'] != null
            ? List<String>.from(jsonOrderData['widths'])
            : [];
        final hiveAppWidths = hiveData['widths'] != null
            ? List<String>.from(hiveData['widths'])
            : [];
        final hiveTextileWidths = hiveData['textileWidths'] != null
            ? List<String>.from(hiveData['textileWidths'])
            : [];
        widthOptions = [...jsonWidths, ...hiveAppWidths, ...hiveTextileWidths];
        widthOptions = widthOptions.toSet().toList(); // Remove duplicates
        widthOptions.sort();

        // Combine Qualities from order_data.json + textile_designs.json + Hive
        final jsonQualities = jsonOrderData['qualities'] != null
            ? List<String>.from(jsonOrderData['qualities'])
            : [];

        final textileJsonQualities = <String>{};
        if (jsonTextileData['Manish Textiles'] != null) {
          final partyData = jsonTextileData['Manish Textiles'];
          if (partyData is Map) {
            partyData.values.forEach((typeData) {
              if (typeData is Map && typeData['designs'] is List) {
                for (var design in typeData['designs']) {
                  if (design is Map && design['quality'] != null) {
                    textileJsonQualities.add(design['quality'].toString());
                  }
                }
              }
            });
          }
        }

        final hiveQualities = hiveData['textileQualities'] != null
            ? List<String>.from(hiveData['textileQualities'])
            : [];
        qualities = [
          ...jsonQualities,
          ...textileJsonQualities,
          ...hiveQualities,
        ];
        qualities = qualities.toSet().toList(); // Remove duplicates
        qualities.sort();

        // Combine Weaves from order_data.json + textile_designs.json + Hive
        final jsonWeaves = jsonOrderData['weaveTypes'] != null
            ? List<String>.from(jsonOrderData['weaveTypes'])
            : [];

        final textileJsonWeaves = <String>{};
        if (jsonTextileData['Manish Textiles'] != null) {
          final partyData = jsonTextileData['Manish Textiles'];
          if (partyData is Map) {
            partyData.values.forEach((typeData) {
              if (typeData is Map && typeData['designs'] is List) {
                for (var design in typeData['designs']) {
                  if (design is Map && design['weave'] != null) {
                    textileJsonWeaves.add(design['weave'].toString());
                  }
                }
              }
            });
          }
        }

        final hiveWeaves = hiveData['textileWeaves'] != null
            ? List<String>.from(hiveData['textileWeaves'])
            : [];
        weaves = [...jsonWeaves, ...textileJsonWeaves, ...hiveWeaves];
        weaves = weaves.toSet().toList(); // Remove duplicates
        weaves.sort();

        textileData = {'d': 25, 'ch': 50, 'mtr': 2500};
        _isLoading = false;
      });

      // Load captured designs from Hive
      await _loadCapturedDesigns();

      // Debug: Print loaded data
      print('Combined O/F Types: $ofTypes');
      print('Combined Widths: $widthOptions');
      print('Combined Qualities: $qualities');
      print('Combined Weaves: $weaves');
    } catch (e) {
      print('Error loading data from sources: $e');
      // Fallback to defaults
      _useDefaultData();
    }
  }

  // Update the _useDefaultData method to initialize with empty designs
  void _useDefaultData() {
    setState(() {
      qualities = ['PC', 'Cotton', 'CP', 'Linen'];
      weaves = ['Twill', 'Oxford', 'Dobby', 'Flannel', 'Satin'];
      textileData = {'d': 0, 'ch': 0, 'mtr': 0}; // Start with zeros
      _isLoading = false;
    });
  }

  // Save qualities to Hive
  Future<void> _saveQualitiesToHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      await box.put('textileQualities', qualities);
      await box.flush();

      print('Qualities saved to Hive: $qualities');
    } catch (e) {
      print('Error saving qualities: $e');
    }
  }

  // Save weaves to Hive
  Future<void> _saveWeavesToHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      await box.put('textileWeaves', weaves);
      await box.flush();

      print('Weaves saved to Hive: $weaves');
    } catch (e) {
      print('Error saving weaves: $e');
    }
  }

  // Save O/F Types to Hive
  Future<void> _saveOFTypesToHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      // Save under both textile-specific and app-level keys so other pages can read them
      await box.put('textileOFTypes', ofTypes);
      await box.put('ofTypes', ofTypes);
      await box.flush();

      print('O/F Types saved to Hive (textileOFTypes & ofTypes): $ofTypes');
    } catch (e) {
      print('Error saving O/F Types: $e');
    }
  }

  // Save Widths to Hive
  Future<void> _saveWidthsToHive() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');
      // Save under both textile-specific and app-level keys so other pages can read them
      await box.put('textileWidths', widthOptions);
      await box.put('widths', widthOptions);
      await box.flush();

      print('Widths saved to Hive (textileWidths & widths): $widthOptions');
    } catch (e) {
      print('Error saving widths: $e');
    }
  }

  String _generateAPC() {
    // Generate APC using existing saved designs for the specific party and selected O/F type
    int maxExisting = 0;

    // Check Hive for all previously saved designs for the party and selected O/F type
    try {
      if (Hive.isBoxOpen('designs')) {
        final box = Hive.box('designs');

        // Check all designs for the current party
        for (var key in box.keys) {
          if (key is String && key.startsWith('designs_${widget.partyName}_')) {
            final list = box.get(key);
            if (list is List) {
              for (var d in list) {
                try {
                  if (d['ofType'] == selectedOFType) {
                    final designNo = d['designNo']?.toString() ?? '';
                    if (designNo.startsWith('APC-')) {
                      final parts = designNo.split('-');
                      if (parts.length >= 2) {
                        final numPart = int.tryParse(parts.last) ?? 0;
                        if (numPart > maxExisting) maxExisting = numPart;
                      }
                    }
                  }
                } catch (e) {
                  // ignore parse errors
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning existing APCs: $e');
    }

    // Also check current session's capturedDesigns for the selected O/F type
    for (var design in capturedDesigns) {
      try {
        if (design['ofType'] == selectedOFType) {
          final designNo = design['designNo']?.toString() ?? '';
          if (designNo.startsWith('APC-')) {
            final parts = designNo.split('-');
            if (parts.length >= 2) {
              final numPart = int.tryParse(parts.last) ?? 0;
              if (numPart > maxExisting) maxExisting = numPart;
            }
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    }

    final newCount = maxExisting + 1;
    return 'APC-$newCount';
  }

  Future<void> _handleStartAPC() async {
    setState(() {
      _isGeneratingAPC = true;
    });

    // Simulate a delay for loading
    await Future.delayed(const Duration(seconds: 1));

    // Generate the APC
    final apc = _generateAPC();

    setState(() {
      partyDesignNo = apc;
      _isGeneratingAPC = false;
    });

    // Patch into controller so the TextField updates
    _partyDesignController.text = apc;

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generated $apc for ${widget.partyName} ($selectedOFType)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadCapturedDesigns() async {
    try {
      if (!Hive.isBoxOpen('designs')) {
        await Hive.openBox('designs');
      }

      final box = Hive.box('designs');
      List<Map<String, dynamic>> allDesigns = [];

      // Load all designs for all textile types of this party
      for (var key in box.keys) {
        if (key is String && key.startsWith('designs_${widget.partyName}_')) {
          final designs = box.get(key);
          if (designs is List) {
            allDesigns.addAll(
              designs.map((d) => Map<String, dynamic>.from(d as Map)),
            );
          }
        }
      }

      // Filter designs by the current textileType (O/F Type)
      List<Map<String, dynamic>> filteredDesigns = allDesigns
          .where((design) => design['ofType'] == widget.textileType)
          .toList();

      // Reset S.No to start from 1 for each textile type
      for (int i = 0; i < filteredDesigns.length; i++) {
        filteredDesigns[i]['sNo'] = i + 1;
      }

      setState(() {
        capturedDesigns = filteredDesigns;
      });

      // Update summary values based on filtered designs
      _updateSummaryValues();

      // If an initial design was provided, select it for editing
      if (widget.initialDesign != null) {
        try {
          final init = widget.initialDesign!;
          // Find matching design by ref or designNo
          int foundIndex = -1;
          for (int i = 0; i < capturedDesigns.length; i++) {
            final d = capturedDesigns[i];
            if ((init['ref'] != null && d['ref'] == init['ref']) ||
                (init['designNo'] != null &&
                    d['designNo'] == init['designNo'])) {
              foundIndex = i;
              break;
            }
          }
          if (foundIndex != -1) {
            _selectDesignForEditing(capturedDesigns[foundIndex], foundIndex);
          }
        } catch (e) {
          print('Error applying initial design: $e');
        }
      }
    } catch (e) {
      print('Error loading designs: $e');
    }
  }

  void _addOrUpdateDesign({
    required int? choices,
    required double? meters,
    required String? designNo,
    required String mode,
  }) async {
    // Get the meters value from the defaultMetersController if not provided
    final metersValue =
        meters ?? double.tryParse(defaultMetersController.text) ?? 100;
    if (choices == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Choices'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate the next reference number for the selected O/F type
    int typeCount = capturedDesigns.length + 1; // Use current length + 1
    String refPrefix = selectedOFType.toUpperCase().substring(0, 3);
    String ref = '$refPrefix-${typeCount.toString().padLeft(3, '0')}';

    // Convert captured photos to base64 strings for storage
    List<String> photoBase64List = [];
    for (XFile photo in capturedPhotos) {
      String base64 = await _xFileToBase64(photo);
      photoBase64List.add(base64);
    }

    setState(() {
      if (_editingDesignIndex != null) {
        // Update existing design with all fields, but keep the original S.No
        capturedDesigns[_editingDesignIndex!] = {
          'sNo':
              capturedDesigns[_editingDesignIndex!]['sNo'], // Keep original S.No
          'designNo': designNo ?? '-',
          'choices': choices,
          'meters': metersValue,
          'mode': mode,
          'timestamp': DateTime.now().toIso8601String(),
          'ofType': selectedOFType,
          'weave': selectedWeave,
          'quality': selectedQuality,
          'width': selectedWidth,
          'ref': ref,
          'photos': photoBase64List,
        };
        _editingDesignIndex = null;
      } else {
        // Add new design with all fields and set S.No to current length + 1
        capturedDesigns.add({
          'sNo': capturedDesigns.length + 1, // Set S.No to current length + 1
          'designNo': designNo ?? '-',
          'choices': choices,
          'meters': metersValue,
          'mode': mode,
          'timestamp': DateTime.now().toIso8601String(),
          'ofType': selectedOFType,
          'weave': selectedWeave,
          'quality': selectedQuality,
          'width': selectedWidth,
          'ref': ref,
          'photos': photoBase64List,
        });
      }
    });

    _updateSummaryValues();
    // Only clear party design number, quality, and weave
    _clearSelectedFields();

    // Clear captured photos after saving
    setState(() {
      capturedPhotos = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingDesignIndex != null
              ? 'Design updated successfully'
              : 'Design added successfully',
        ),
      ),
    );
  }

  // Update the _clearSelectedFields method to clear only party design number, quality, and weave
  void _clearSelectedFields() {
    setState(() {
      partyDesignNo = null;
      _partyDesignController.clear();
      selectedQuality = null;
      selectedWeave = null;
      // Keep Mode, O/F Type, Width, Choices, and Meters unchanged
    });
  }

  void _selectDesignForEditing(Map<String, dynamic> design, int index) async {
    setState(() {
      _editingDesignIndex = index;

      // Populate all form fields with the selected design's data
      partyDesignNo = design['designNo'].toString() != '-'
          ? design['designNo'].toString()
          : null;
      _partyDesignController.text = design['designNo'].toString() != '-'
          ? design['designNo'].toString()
          : '';
      selectedMode = design['mode'].toString();

      // Update controllers with proper values
      _choicesController.text = design['choices'].toString();
      defaultMetersController.text = design['meters'].toStringAsFixed(0);

      // Update defaultMeters to match the design
      defaultMeters = design['meters'] as double;

      // Now populate all the additional fields from the design data
      selectedOFType = design['ofType']?.toString() ?? currentDefaultOFType;
      selectedWeave = design['weave']?.toString();
      selectedQuality = design['quality']?.toString();
      selectedWidth = design['width']?.toString() ?? currentDefaultWidth;

      // Update default values if needed
      defaultChoices = design['choices'] as int;
    });

    // Load photos if available
    if (design['photos'] != null && design['photos'] is List) {
      List<String> photoBase64List = List<String>.from(design['photos']);
      List<XFile> photos = [];
      for (String base64 in photoBase64List) {
        XFile photo = await _base64ToXFile(base64);
        photos.add(photo);
      }
      setState(() {
        capturedPhotos = photos;
      });
    }
  }

  void _clearEditingState() {
    setState(() {
      _editingDesignIndex = null;

      // Clear only the party design controller, quality, and weave
      _partyDesignController.clear();
      partyDesignNo = null;
      selectedQuality = null;
      selectedWeave = null;

      // Keep Mode, O/F Type, Width, Choices, and Meters unchanged
      // Only clear the captured photos
      capturedPhotos = [];
    });
  }

  @override
  void dispose() {
    _weaveTypeController.dispose();
    _qualityController.dispose();
    _partyDesignController.dispose();
    defaultMetersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 55,
        backgroundColor: primaryColor,
        title: Text(
          widget.partyName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        actions: [
          // Hamburger menu button
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(child: _buildCapturedDesignsSection()),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sticky summary card at the top
                Container(
                  color: const Color(0xFFF9FAFB), // Same as background color
                  child: _buildSummaryCard(),
                ),

                // Scrollable content below
                Expanded(
                  child: Stack(
                    children: [
                      (isTablet ? _buildTabletView() : _buildMobileView()),
                      if (_showAddWeaveDialog) _buildAddWeaveDialog(),
                      if (_showAddQualityDialog) _buildAddQualityDialog(),
                      if (_showAddOFTypeDialog) _buildAddOFTypeDialog(),
                      if (_showAddWidthDialog) _buildAddWidthDialog(),
                      if (_previewPhotoIndex != null) _buildFullScreenPreview(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<String> _xFileToBase64(XFile file) async {
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  // Convert base64 string back to XFile
  Future<XFile> _base64ToXFile(String base64String) async {
    List<int> bytes = base64Decode(base64String);
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(bytes);
    return XFile(tempFile.path);
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Removed _buildSummaryCard() from here
          const SizedBox(height: 16),
          _buildTextileDetailsCard(),
          const SizedBox(height: 16),
          _buildCapturePhotoSection(),
          const SizedBox(height: 16),
          _buildModeSelectionSection(),
          const SizedBox(height: 16),
          _buildPartyDesignNoSection(),
          const SizedBox(height: 16),
          _buildWeaveTypeSection(),
          const SizedBox(height: 16),
          _buildQualitySection(),
          const SizedBox(height: 16),
          _buildOFTypeSection(),
          const SizedBox(height: 16),
          _buildWidthOverrideSection(),
          const SizedBox(height: 16),
          _buildChoicesOverrideSection(),
          const SizedBox(height: 16),
          _buildMetersOverrideSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 20),
          // Removed _buildCapturedDesignsSection() from here
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabletView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Removed _buildSummaryCard() from here
            const SizedBox(height: 16),
            _buildTextileDetailsCard(),
            const SizedBox(height: 16),

            // Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Photo capture
                Expanded(flex: 1, child: _buildCapturePhotoSection()),
                const SizedBox(width: 24),

                // Right column - Form fields
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildModeSelectionSection(),
                      const SizedBox(height: 16),
                      _buildPartyDesignNoSection(),
                      const SizedBox(height: 16),
                      _buildWeaveTypeSection(),
                      const SizedBox(height: 16),
                      _buildQualitySection(),
                      const SizedBox(height: 16),
                      _buildOFTypeSection(),
                      const SizedBox(height: 16),
                      _buildWidthOverrideSection(),
                      const SizedBox(height: 16),
                      _buildChoicesOverrideSection(),
                      const SizedBox(height: 16),
                      _buildMetersOverrideSection(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            // Removed _buildCapturedDesignsSection() from here
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // New summary card with vertical lines
  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Designs column
            Expanded(
              child: _buildSummaryItem(
                'Designs',
                textileData['d']?.toString() ?? '0',
              ),
            ),

            // Vertical line 1
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),

            // Colors column
            Expanded(
              child: _buildSummaryItem(
                'Choices',
                textileData['ch']?.toString() ?? '0',
              ),
            ),

            // Vertical line 2
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),

            // Meters column
            Expanded(
              child: _buildSummaryItem(
                'Meters',
                textileData['mtr']?.toString() ?? '0',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextileDetailsCard() {
  return Card(
    elevation: 0,
    color: const Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit icon button
              IconButton(
                onPressed: () async {
                  // Navigate back to NewOrderSetupPage in edit mode with current values
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewOrderSetupPage(
                        isEditMode: true,
                        partyName: widget.partyName,
                        ofType: selectedOFType,
                        selectedWidth: selectedWidth,
                        defaultChoices: defaultChoices,
                        defaultMeters: defaultMeters,
                        sampleRequired: sampleRequired,
                        selectedSampleMtr: selectedSampleMtr,
                      ),
                    ),
                  );

                  // Update values if returned
                  if (result != null) {
                    setState(() {
                      selectedOFType = result['ofType'] ?? selectedOFType;
                      selectedWidth = result['selectedWidth'] ?? selectedWidth;
                      defaultChoices = result['defaultChoices'] ?? defaultChoices;
                      defaultMeters = result['defaultMeters'] ?? defaultMeters;
                      sampleRequired = result['sampleRequired'] ?? sampleRequired;
                      selectedSampleMtr = result['selectedSampleMtr'];

                      // Update the controller text to match the new defaultMeters value
                      defaultMetersController.text = defaultMeters.toStringAsFixed(0);

                      // Update current default values
                      currentDefaultOFType = selectedOFType;
                      currentDefaultWidth = selectedWidth;
                      currentDefaultChoices = defaultChoices;
                      currentDefaultMeters = defaultMeters;
                    });
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Single row with all fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // O/F TYPE column
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'O/F TYPE',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedOFType,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical line 1
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),

              // WIDTH column
              Expanded(
                child: Column(
                  children: [
                    _buildDetailHeading('WIDTH'),
                    const SizedBox(height: 4),
                    _buildDetailValue(selectedWidth),
                  ],
                ),
              ),

              // Vertical line 2
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),

              // CHOICES column
              Expanded(
                child: Column(
                  children: [
                    _buildDetailHeading('CHOICES'),
                    const SizedBox(height: 4),
                    _buildDetailValue(defaultChoices.toString()),
                  ],
                ),
              ),

              // Vertical line 3
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),

              // METERS column
              Expanded(
                child: Column(
                  children: [
                    _buildDetailHeading('METERS'),
                    const SizedBox(height: 4),
                    _buildDetailValue(defaultMeters.toStringAsFixed(0)),
                  ],
                ),
              ),

              // Vertical line 4
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),

              // SAMPLE column
              Expanded(
                child: Column(
                  children: [
                    _buildDetailHeading('SAMPLE'),
                    const SizedBox(height: 4),
                    _buildDetailValue(_formatSampleDisplay()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildOFTypeSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.lockOFType ? 'O/F Type:' : 'O/F Type: (Override)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (!widget.lockOFType)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedOFType = currentDefaultOFType;
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Show all options but make them non-interactive when locked
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ofTypes.map((type) {
                bool isSelected = selectedOFType == type;

                return GestureDetector(
                  onTap: widget.lockOFType
                      ? null
                      : () {
                          // Disable tap when locked
                          setState(() {
                            selectedOFType = type;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.lockOFType
                          ? (isSelected
                                ? const Color(0xFF2563EB).withOpacity(0.8)
                                : Colors.grey[300])
                          : (isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.lockOFType
                            ? (isSelected
                                  ? const Color(0xFF2563EB).withOpacity(0.8)
                                  : Colors.grey.withOpacity(0.3))
                            : (isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: widget.lockOFType
                            ? (isSelected ? Colors.white : Colors.grey[600])
                            : (isSelected ? Colors.white : Colors.black),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
            Text(
              'Default: $currentDefaultOFType',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // New Weave Type section
  Widget _buildWeaveTypeSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weave Type: *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAddWeaveDialog = true;
                      _weaveTypeController.clear();
                    });
                  },
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 20, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weaves.map((weave) {
                bool isSelected = selectedWeave == weave;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedWeave = weave;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF2563EB))
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      weave,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
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

  // Updated Quality section with + button functionality
  Widget _buildQualitySection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quality: *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAddQualityDialog = true;
                      _qualityController.clear();
                    });
                  },
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 20, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: qualities.map((quality) {
                bool isSelected = selectedQuality == quality;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedQuality = quality;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF2563EB))
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      quality,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
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

  // Add Weave Type Dialog
  Widget _buildAddWeaveDialog() {
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _showAddWeaveDialog = false;
            });
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Dialog content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 500
                : double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Weave Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAddWeaveDialog = false;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // Dialog body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weave Type Name field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weave Type Name: *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _weaveTypeController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Jacquard, Canvas',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This will be added to master and available immediately.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialog footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cancel button - LEFT SIDE WITH EQUAL WIDTH
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showAddWeaveDialog = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF2563EB,
                            ), // Blue background
                            foregroundColor: Colors.white, // White text
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save to Master button - RIGHT SIDE WITH EQUAL WIDTH
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_weaveTypeController.text.isNotEmpty) {
                              setState(() {
                                weaves.add(_weaveTypeController.text);
                                selectedWeave = _weaveTypeController.text;
                                _showAddWeaveDialog = false;
                              });
                              // Save weaves to Hive
                              _saveWeavesToHive();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF10B981,
                            ), // Green background
                            foregroundColor: Colors.white, // White text
                          ),
                          child: const Text(
                            'Save to Master',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  // Add Quality Dialog
  Widget _buildAddQualityDialog() {
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _showAddQualityDialog = false;
            });
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Dialog content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 500
                : double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Quality',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAddQualityDialog = false;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // Dialog body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quality Name field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quality Name: *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _qualityController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Poly Cotton, Viscose',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This will be added to master and available immediately.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialog footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cancel button - LEFT SIDE WITH EQUAL WIDTH
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showAddQualityDialog = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF2563EB,
                            ), // Blue background
                            foregroundColor: Colors.white, // White text
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save to Master button - RIGHT SIDE WITH EQUAL WIDTH
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_qualityController.text.isNotEmpty) {
                              setState(() {
                                qualities.add(_qualityController.text);
                                selectedQuality = _qualityController.text;
                                _showAddQualityDialog = false;
                              });
                              // Save qualities to Hive
                              _saveQualitiesToHive();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF10B981,
                            ), // Green background
                            foregroundColor: Colors.white, // White text
                          ),
                          child: const Text(
                            'Save to Master',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  // Add O/F Type Dialog
  Widget _buildAddOFTypeDialog() {
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _showAddOFTypeDialog = false;
            });
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Dialog content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 500
                : double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add O/F Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAddOFTypeDialog = false;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // Dialog body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // O/F Type Name field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'O/F Type Name: *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ofTypeController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Regular, Mix, Plain',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This will be added to master and available immediately.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialog footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showAddOFTypeDialog = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save to Master button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_ofTypeController.text.isNotEmpty) {
                              setState(() {
                                ofTypes.add(_ofTypeController.text);
                                selectedOFType = _ofTypeController.text;
                                _showAddOFTypeDialog = false;
                              });
                              // Save O/F Types to Hive
                              _saveOFTypesToHive();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Save to Master',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  // Add Width Dialog
  Widget _buildAddWidthDialog() {
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _showAddWidthDialog = false;
            });
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Dialog content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 500
                : double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Width',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAddWidthDialog = false;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // Dialog body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Width Name field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Width: *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _widthController,
                              decoration: InputDecoration(
                                hintText: 'e.g., 44", 58", 60"',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This will be added to master and available immediately.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialog footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showAddWidthDialog = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save to Master button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_widthController.text.isNotEmpty) {
                              setState(() {
                                widthOptions.add(_widthController.text);
                                selectedWidth = _widthController.text;
                                _showAddWidthDialog = false;
                              });
                              // Save widths to Hive
                              _saveWidthsToHive();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Save to Master',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  Widget _buildDetailHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDetailValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2563EB),
      ),
    );
  }

  String _formatSampleDisplay() {
    if (sampleRequired == 'No') {
      return '-';
    } else if (sampleRequired == 'Sample Only') {
      return 'Sample Only (${selectedSampleMtr ?? '2.5'})';
    } else {
      // sampleRequired == 'Yes'
      return 'Yes (${selectedSampleMtr ?? '2.5'})';
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturePhotoSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Capture Photo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            // Photo capture area
            if (capturedPhotos.isEmpty)
              _buildEmptyCaptureArea()
            else
              _buildPhotoGrid(),

            const SizedBox(height: 16),

            // Capture button
            InkWell(
              onTap: () async {
                final XFile? pickedFile = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.rear,
                );
                if (pickedFile != null) {
                  setState(() {
                    capturedPhotos.add(pickedFile);
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4F46E5), const Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Capture New Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWillCaptureItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectionSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['Design', 'Sample'].map((mode) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMode = mode;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedMode == mode
                            ? const Color(0xFF2563EB)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedMode == mode
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
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

  Widget _buildPartyDesignNoSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Party Design No: (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_editingDesignIndex != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Editing',
                      style: TextStyle(fontSize: 10, color: Color(0xFF92400E)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _partyDesignController, // Use the controller instead of creating a new one
                    decoration: InputDecoration(
                      hintText: 'Leave empty for AI',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        partyDesignNo = value.isEmpty ? null : value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _isGeneratingAPC
                    ? ElevatedButton.icon(
                        onPressed: null, // Disabled while loading
                        icon: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        label: const Text('Loading APC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B5563), // Dark gray
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _handleStartAPC,
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text('Start APC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF3C7),
                          foregroundColor: const Color(0xFF9C4915),
                          elevation: 0,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Start APC" to begin auto-numbering (APC-1, APC-2...)',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthOverrideSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Width: (Override)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedWidth = currentDefaultWidth;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widthOptions.map((width) {
                bool isSelected = selectedWidth == width;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedWidth = width;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF2563EB))
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      width,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Default: $currentDefaultWidth',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Modified _buildChoicesOverrideSection to reduce spacing between icons
  Widget _buildChoicesOverrideSection() {
  return Card(
    elevation: 0,
    color: const Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choices: (Override)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    defaultChoices = currentDefaultChoices;
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          const SizedBox(height: 8),
          Text(
            'Default: $currentDefaultChoices',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildMetersOverrideSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meters: (Override)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      defaultMeters = currentDefaultMeters;
                      defaultMetersController.text = currentDefaultMeters
                          .toStringAsFixed(0);
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: defaultMetersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter meters',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  defaultMeters = double.tryParse(value) ?? 100;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Default: $currentDefaultMeters',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCaptureArea() {
    return InkWell(
      onTap: () async {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
        if (pickedFile != null) {
          setState(() {
            capturedPhotos.add(pickedFile);
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF9FAFB),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern camera icon with gradient background
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4F46E5), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to Capture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to capture',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isTablet) {
      // Tablet view - Grid layout
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: capturedPhotos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _previewPhotoIndex = index;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(capturedPhotos[index].path),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Mobile view - Horizontal list
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: capturedPhotos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _previewPhotoIndex = index;
                });
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(capturedPhotos[index].path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildFullScreenPreview() {
    if (_previewPhotoIndex == null || capturedPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Full screen black background
        GestureDetector(
          onTap: () {
            setState(() {
              _previewPhotoIndex = null;
            });
          },
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Photo preview
        Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3,
            child: Image.file(
              File(capturedPhotos[_previewPhotoIndex!].path),
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Top bar with close button
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _previewPhotoIndex = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),

              // Photo counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_previewPhotoIndex! + 1} / ${capturedPhotos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

              // Delete button
              GestureDetector(
                onTap: () {
                  setState(() {
                    capturedPhotos.removeAt(_previewPhotoIndex!);
                    if (_previewPhotoIndex! >= capturedPhotos.length) {
                      _previewPhotoIndex = capturedPhotos.length - 1;
                    }
                    if (capturedPhotos.isEmpty) {
                      _previewPhotoIndex = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom navigation buttons
        if (capturedPhotos.length > 1)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                if (_previewPhotoIndex! > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _previewPhotoIndex = _previewPhotoIndex! - 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),

                // Next button
                if (_previewPhotoIndex! < capturedPhotos.length - 1)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _previewPhotoIndex = _previewPhotoIndex! + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
  final isEditing = _editingDesignIndex != null;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              // Capture current form values
              int choices =
                  int.tryParse(_choicesController.text) ?? defaultChoices;
              double meters =
                  double.tryParse(defaultMetersController.text) ??
                  defaultMeters;

              // Add or update design
              _addOrUpdateDesign(
                choices: choices,
                meters: meters,
                designNo: _partyDesignController.text.isNotEmpty
                    ? _partyDesignController.text
                    : null,
                mode: selectedMode,
              );

              // Save to Hive
              await _saveCapturedDesignToHive();
              // Also save summary values
              await _saveSummaryValuesToHive();

              // Only clear specific fields
              _clearSelectedFields();
            },
            icon: const Icon(Icons.check),
            label: Text(isEditing ? 'Update & Continue' : 'Save & Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing
                  ? const Color(0xFF10B981)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderFormFinishPage(
                    partyName: widget.partyName,
                    totalDesigns: textileData['d'] ?? 0,
                    totalChoices: textileData['ch'] ?? 0,
                    totalMeters: textileData['mtr'] ?? 0,
                  ),
                ),
              );
            },
            child: const Text('Finish Order →'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildCapturedDesignsSection() {
  // Determine which filter options to show based on currentFilterType
  List<String> filterOptions = [];
  if (currentFilterType == FilterType.mode) {
    filterOptions = ['All', 'Design', 'Sample'];
  } else {
    filterOptions = ['All', ...ofTypes];
  }

  // Filter designs based on selected tab and filter type
  List<Map<String, dynamic>> filteredDesigns = capturedDesigns.where((design) {
    if (currentFilterType == FilterType.mode) {
      if (selectedFilter == 'All') return true;
      if (selectedFilter == 'Design') return design['mode'] == 'Design';
      if (selectedFilter == 'Sample') return design['mode'] == 'Sample';
    } else { // FilterType.ofType
      if (selectedFilter == 'All') return true;
      return design['ofType'] == selectedFilter;
    }
    return true;
  }).toList();

  return Container(
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Captured Designs:', // Show the current O/F Type
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the drawer
                },
              ),
            ],
          ),
        ),

        // Filter type selector (Mode or O/F Type)
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Filter by:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              // Mode filter button
              GestureDetector(
                onTap: () {
                  setState(() {
                    currentFilterType = FilterType.mode;
                    selectedFilter = 'All'; // Reset to All when switching filter types
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: currentFilterType == FilterType.mode
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentFilterType == FilterType.mode
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'Mode',
                    style: TextStyle(
                      fontSize: 13,
                      color: currentFilterType == FilterType.mode
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // O/F Type filter button
              GestureDetector(
                onTap: () {
                  setState(() {
                    currentFilterType = FilterType.ofType;
                    selectedFilter = 'All'; // Reset to All when switching filter types
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: currentFilterType == FilterType.ofType
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentFilterType == FilterType.ofType
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'O/F Type',
                    style: TextStyle(
                      fontSize: 13,
                      color: currentFilterType == FilterType.ofType
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter tabs
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: filterOptions.map((filter) {
              bool isSelected = selectedFilter == filter;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(left: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEF4444)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Design list or empty state
        if (filteredDesigns.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Text(
              currentFilterType == FilterType.mode
                  ? 'No ${selectedFilter.toLowerCase()} designs captured yet. Start capturing photos!'
                  : 'No ${selectedFilter} designs captured yet. Start capturing photos!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          )
        else
          // MODIFIED PART: Use LayoutBuilder to make table full width
          Container(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth, // Take full available width
                    ),
                    child: DataTable(
                      columnSpacing: 24, // Increase spacing between columns
                      horizontalMargin: 12, // Add horizontal margin
                      columns: [
                        const DataColumn(
                          label: Text(
                            'S.No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Design No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Choices',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Meters',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (currentFilterType == FilterType.mode) // Only show O/F Type column when filtering by mode
                          const DataColumn(
                            label: Text(
                              'O/F Type',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                      rows: filteredDesigns.asMap().entries.map((entry) {
                        final display = entry.value;
                        final originalIndex = capturedDesigns.indexOf(display);
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              // Highlight the row that is being edited
                              if (_editingDesignIndex != null &&
                                  originalIndex == _editingDesignIndex) {
                                return const Color(0xFFE3F2FD);
                              }
                              return null;
                            },
                          ),
                          onSelectChanged: (selected) {
                            if (selected ?? false) {
                              Navigator.of(context).pop(); // Close the drawer first
                              _selectDesignForEditing(display, originalIndex);
                            }
                          },
                          cells: [
                            DataCell(
                              Text(
                                (display['sNo'] ?? (originalIndex + 1))
                                    .toString(),
                              ),
                            ),
                            DataCell(
                              Text(
                                display['designNo']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                display['choices']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (display['meters'] is num)
                                    ? (display['meters'] as num)
                                          .toDouble()
                                          .toStringAsFixed(0)
                                    : display['meters']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (currentFilterType == FilterType.mode) // Only show O/F Type cell when filtering by mode
                              DataCell(
                                Text(
                                  display['ofType']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
  Future<void> _saveCapturedDesignToHive() async {
  try {
    if (!Hive.isBoxOpen('designs')) {
      await Hive.openBox('designs');
    }

    final box = Hive.box('designs');
    final designsKey = 'designs_${widget.partyName}_${widget.textileType}';

    // Get existing designs for this textile type
    List<Map<String, dynamic>> existingDesigns = [];
    if (box.containsKey(designsKey)) {
      final savedDesigns = box.get(designsKey);
      if (savedDesigns is List) {
        existingDesigns = List<Map<String, dynamic>>.from(
          savedDesigns.map((d) => Map<String, dynamic>.from(d as Map))
        );
      }
    }

    // Merge new designs with existing ones
    List<Map<String, dynamic>> mergedDesigns = [...existingDesigns];
    
    // Add new designs or update existing ones
    for (var newDesign in capturedDesigns) {
      final designNo = newDesign['designNo']?.toString();
      final ref = newDesign['ref']?.toString();
      
      // Check if design already exists
      final existingIndex = mergedDesigns.indexWhere((d) => 
        (designNo != null && designNo != '-' && d['designNo'] == designNo) ||
        (ref != null && ref != '-' && d['ref'] == ref)
      );
      
      if (existingIndex >= 0) {
        // Update existing design
        mergedDesigns[existingIndex] = newDesign;
      } else {
        // Add new design
        mergedDesigns.add(newDesign);
      }
    }

    // Save merged designs
    await box.put(designsKey, mergedDesigns);
    await box.flush();

    print('Captured designs saved to Hive with key: $designsKey');
    print('Designs: $mergedDesigns');

    // Update orders count in the orders box for this party
    try {
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }
      final ordersBox = Hive.box('orders');

      // Calculate total designs across all textile types for this party
      int totalDesignsForParty = 0;
      for (var key in box.keys) {
        if (key is String && key.startsWith('designs_${widget.partyName}_')) {
          final list = box.get(key);
          if (list is List) totalDesignsForParty += list.length;
        }
      }

      final orderEntry = {
        'party': widget.partyName,
        'orders': totalDesignsForParty,
        'date': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      await ordersBox.put(widget.partyName, orderEntry);
      await ordersBox.flush();

      // notify listeners so purchase_list_page reloads
      try {
        OrderService().notifyOrderUpdated();
      } catch (e) {
        print('OrderService notify error: $e');
      }
    } catch (e) {
      print('Error updating orders box: $e');
    }
  } catch (e) {
    print('Error saving captured designs: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving designs: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  // Method to calculate summary values from captured designs
  Map<String, dynamic> _calculateSummaryValues() {
    // Count each saved row as one design so the summary shows raw saved items
    int totalDesigns = capturedDesigns.length;
    int totalChoices = 0;
    double totalMeters = 0.0;

    for (var design in capturedDesigns) {
      final choicesVal = (design['choices'] is int)
          ? design['choices'] as int
          : int.tryParse(design['choices']?.toString() ?? '0') ?? 0;
      totalChoices += choicesVal;

      final metersVal = (design['meters'] is int)
          ? (design['meters'] as int).toDouble()
          : (design['meters'] is double
                ? design['meters'] as double
                : double.tryParse(design['meters']?.toString() ?? '0') ?? 0.0);
      totalMeters += metersVal;
    }

    return {'d': totalDesigns, 'ch': totalChoices, 'mtr': totalMeters.round()};
  }

  // Method to update the textileData with calculated values
  void _updateSummaryValues() {
    setState(() {
      textileData = _calculateSummaryValues();
    });
  }

  // Method to save summary values to Hive
  Future<void> _saveSummaryValuesToHive() async {
    try {
      if (!Hive.isBoxOpen('designs')) {
        await Hive.openBox('designs');
      }

      final box = Hive.box('designs');
      final summaryKey = 'summary_${widget.partyName}_${widget.textileType}';

      await box.put(summaryKey, textileData);
      await box.flush();

      print('Summary values saved to Hive with key: $summaryKey');
    } catch (e) {
      print('Error saving summary values: $e');
    }
  }

  // Method to load summary values from Hive
  Future<void> _loadSummaryValuesFromHive() async {
    try {
      if (!Hive.isBoxOpen('designs')) {
        await Hive.openBox('designs');
      }

      final box = Hive.box('designs');
      final summaryKey = 'summary_${widget.partyName}_${widget.textileType}';

      if (box.containsKey(summaryKey)) {
        final savedSummary = box.get(summaryKey);
        if (savedSummary is Map) {
          setState(() {
            textileData = Map<String, dynamic>.from(savedSummary);
          });
          print('Loaded summary values from Hive');
        }
      }
    } catch (e) {
      print('Error loading summary values: $e');
    }
  }
}
