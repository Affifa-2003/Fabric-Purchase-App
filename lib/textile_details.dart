import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'order_form_finish_page.dart';

class TextileDetailsPage extends StatefulWidget {
  final String partyName;
  final String textileType;

  const TextileDetailsPage({
    Key? key,
    required this.partyName,
    required this.textileType,
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
  TextEditingController defaultMetersController = TextEditingController(
    text: '100',
  );
  // Form state
  File? capturedPhoto;
  String selectedMode = 'Design';
  String? selectedQuality;
  String? selectedWeave;
  String? partyDesignNo;
  String selectedWidth = '72"';
  int defaultChoices = 2;
  double defaultMeters = 100;
  List<String> qualities = ['PC', 'Cotton', 'CP', 'Linen'];
  List<String> weaves = ['Twill', 'Oxford', 'Dobby', 'Flannel', 'Satin'];
  List<String> widthOptions = ['44"', '54"', '58"', '60"', '72"'];
  List<Map<String, dynamic>> capturedDesigns = [];

  // For O/F Type override
  String selectedOFType = '';
  List<String> ofTypes = ['Regular', 'Mix', 'Plain'];

  // For Weave Type dialog
  final TextEditingController _weaveTypeController = TextEditingController();
  bool _showAddWeaveDialog = false;

  // For Quality dialog
  final TextEditingController _qualityController = TextEditingController();
  bool _showAddQualityDialog = false;

  @override
  void initState() {
    super.initState();
    // Initialize selectedOFType with the widget's textileType
    selectedOFType = widget.textileType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTextileData();
    });
  }

  Future<void> _loadTextileData() async {
    try {
      // Initialize with values to match image 1
      setState(() {
        textileData = {'d': 25, 'ch': 50, 'mtr': 2500};
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading textile data: $e');
      setState(() {
        textileData = {'d': 25, 'ch': 50, 'mtr': 2500};
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _weaveTypeController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 90,
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
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                (isTablet ? _buildTabletView() : _buildMobileView()),
                if (_showAddWeaveDialog) _buildAddWeaveDialog(),
                if (_showAddQualityDialog) _buildAddQualityDialog(),
              ],
            ),
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildTextileDetailsCard(),
          const SizedBox(height: 16),
          _buildModeSelectionSection(),
          const SizedBox(height: 16),
          _buildPartyDesignNoSection(),
          const SizedBox(height: 16),
          _buildOFTypeSection(), // New O/F Type section
          const SizedBox(height: 16),
          _buildWeaveTypeSection(), // New Weave Type section
          const SizedBox(height: 16),
          _buildQualitySection(),
          const SizedBox(height: 16),
          _buildWidthOverrideSection(),
          const SizedBox(height: 16),
          _buildChoicesOverrideSection(),
          const SizedBox(height: 16),
          _buildMetersOverrideSection(),
          const SizedBox(height: 16),
          _buildCapturePhotoSection(), // Moved to after meters section
          const SizedBox(height: 16),
          _buildCapturedDesignsSection(),
          const SizedBox(height: 20),
          _buildActionButtons(),
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
            // Summary at top
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildTextileDetailsCard(),
            const SizedBox(height: 16),

            // Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Photo capture
                Expanded(
                  flex: 1,
                  child: _buildCapturePhotoSection(), // Now includes Will Capture info
                ),
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
                      _buildOFTypeSection(), // New O/F Type section
                      const SizedBox(height: 16),
                      _buildWeaveTypeSection(), // New Weave Type section
                      const SizedBox(height: 16),
                      _buildQualitySection(),
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

            const SizedBox(height: 32),
            _buildCapturedDesignsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
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
                'Colors',
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

  // New textile details card - MODIFIED TO PUT ALL FIELDS IN A SINGLE ROW
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
                        widget.textileType,
                        style: TextStyle(
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
                      _buildDetailValue('Yes (2.5)'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notification with icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4), // Light yellow background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFBC02D),
                ), // Yellow border
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFF57F17), // Dark yellow
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weave & Quality will be selected during photo capture for each design',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5D4037), // Dark brown text
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Edit Defaults button with icon
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New O/F Type section
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
                const Text(
                  'O/F Type: (Override)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOFType = widget.textileType;
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
              children: ofTypes.map((type) {
                bool isSelected = selectedOFType == type;

                return GestureDetector(
                  onTap: () {
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
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF2563EB))
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      type,
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
              'Default: ${widget.textileType}',
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    
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
            InkWell(
              onTap: () async {
                final XFile? pickedFile = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.rear,
                );
                if (pickedFile != null) {
                  setState(() {
                    capturedPhoto = File(pickedFile.path);
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
                child: capturedPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(capturedPhoto!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Modern camera icon with gradient background
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5),
                                  const Color(0xFF2563EB),
                                ],
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Will Capture section - now included for both mobile and tablet views
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Will Capture:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWillCaptureItem('Type:', selectedOFType),
                  _buildWillCaptureItem('Weave:', selectedWeave ?? '-'),
                  _buildWillCaptureItem('Quality:', selectedQuality ?? '-'),
                  _buildWillCaptureItem('Width:', selectedWidth),
                  _buildWillCaptureItem('Choices:', defaultChoices.toString()),
                  _buildWillCaptureItem('Meters:', defaultMeters.toStringAsFixed(0)),
                ],
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
            const Text(
              'Party Design No: (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                        partyDesignNo = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
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
            const Text(
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
                      selectedWidth = '58"';
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
              'Default: 72"',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choices: (Override)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      defaultChoices = 2;
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
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (defaultChoices > 0) defaultChoices--;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    defaultChoices.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      defaultChoices++;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Default: 2',
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
                      defaultMeters = 100;
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
              'Default: 100',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedDesignsSection() {
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
            // First Row - Title only
            const Text(
              'All Captured Designs:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, //  Move filters to right side
              children: ['All', 'Design', 'Sample'].map((filter) {
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
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFEE2E2) // selected background
                          : const Color(0xFFF3F4F6), // unselected background
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEF4444) // selected border
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

            const SizedBox(height: 16),

            // Empty State Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Text(
                'No designs captured yet. Start capturing photos!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Design photos saved')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Save & Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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
                      totalDesigns: 47,
                      totalChoices: 100,
                      totalMeters: 4500,
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
}