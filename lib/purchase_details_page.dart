import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/new_order_setup_page.dart';
import 'package:purchase_app/textile_details.dart';

class PartyDetailsPage extends StatefulWidget {
  final String partyName;

  const PartyDetailsPage({Key? key, required this.partyName}) : super(key: key);

  @override
  _PartyDetailsPageState createState() => _PartyDetailsPageState();
}

class _PartyDetailsPageState extends State<PartyDetailsPage> {
  Map<String, dynamic> partyData = {};
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = const Color(0xFF2563EB);
  List<Map<String, dynamic>> capturedDesigns = [];

  @override
  void initState() {
    super.initState();
    _loadPartyData();
  }

  Future<void> _loadPartyData() async {
    try {
      // Load JSON from assets
      String jsonString = await rootBundle.loadString('party_details.json');
      Map<String, dynamic> allData = json.decode(jsonString);

      // Find the specific party data
      setState(() {
        partyData = allData[widget.partyName] ?? {};
      });

      // Load captured designs from Hive
      await _loadCapturedDesigns();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading party data: $e');
      // Fallback to default data if JSON loading fails
      setState(() {
        partyData = {
          'summary': {'d': 47, 'ch': 100, 'mtr': 4500},
          'textiles': [
            {
              'type': 'Regular',
              'ref': 'REG-001',
              'd': 25,
              'ch': 50,
              'mtr': 2500,
              'color': '#FF5722',
            },
            {
              'type': 'Mix',
              'ref': 'MIX-001',
              'd': 15,
              'ch': 35,
              'mtr': 1500,
              'color': '#4CAF50',
            },
            {
              'type': 'Plain',
              'ref': 'PLN-001',
              'd': 7,
              'ch': 15,
              'mtr': 500,
              'color': '#2196F3',
            },
          ],
        };
        _isLoading = false;
      });
    }
  }

  // Load all captured designs from Hive
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

      setState(() {
        capturedDesigns = allDesigns;
      });

      print('Loaded ${capturedDesigns.length} captured designs from Hive');
    } catch (e) {
      print('Error loading captured designs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: primaryColor,
        title: Text(
          widget.partyName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20, // Increased font size
            fontWeight: FontWeight.bold, // Added bold weight
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
              icon: Icon(
                Icons.add,
                color: primaryColor,
                size: 24,
              ), // Adjusted icon size
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewOrderSetupPage(),
                  ),
                );
              },
            ),
          ),
        ],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22, // Match the title font size
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary section
                _buildSummarySection(),
                const SizedBox(height: 16),
                // Textiles list and captured designs
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Display JSON textiles
                      ...List.generate(partyData['textiles']?.length ?? 0, (
                        index,
                      ) {
                        final textile = partyData['textiles'][index];
                        return _buildTextileCard(textile);
                      }),
                      // Display captured designs
                      if (capturedDesigns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Captured Designs:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(label: Text('S.No')),
                              DataColumn(label: Text('Design No')),
                              DataColumn(label: Text('Choices')),
                              DataColumn(label: Text('Meters')),
                              DataColumn(label: Text('Mode')),
                            ],
                            rows: capturedDesigns
                                .map(
                                  (design) => DataRow(
                                    cells: [
                                      DataCell(Text(design['sNo'].toString())),
                                      DataCell(
                                        Text(design['designNo'].toString()),
                                      ),
                                      DataCell(
                                        Text(design['choices'].toString()),
                                      ),
                                      DataCell(
                                        Text(
                                          design['meters'].toStringAsFixed(0),
                                        ),
                                      ),
                                      DataCell(Text(design['mode'].toString())),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'D',
            partyData['summary']?['d']?.toString() ?? '0',
            showRightDivider: true,
          ),
          _buildSummaryItem(
            'Ch',
            partyData['summary']?['ch']?.toString() ?? '0',
            showRightDivider: true,
          ),
          _buildSummaryItem(
            'Mtr',
            partyData['summary']?['mtr']?.toString() ?? '0',
            showRightDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool showRightDivider = true,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2863EB), // Changed to the requested color
              ),
            ),
          ],
        ),
        if (showRightDivider) ...[
          const SizedBox(width: 16),
          Container(height: 40, width: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildTextileCard(Map<String, dynamic> textile) {
    Color indicatorColor = _parseColor(textile['color'] ?? '#2196F3');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        // Replace GestureDetector with InkWell for better feedback
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TextileDetailsPage(
                  partyName: widget.partyName,
                  textileType: textile['type'] ?? '',
                  selectedWidth: textile['width'] ?? '58"',
                  defaultChoices: textile['choices'] ?? 2,
                  defaultMeters:
                      double.tryParse(textile['meters']?.toString() ?? '100') ??
                      100,
                  sampleRequired: textile['sampleRequired'] ?? 'Yes',
                  selectedSampleMtr: textile['sampleMtr'],
                ),
              ),
            );
          } catch (e) {
            print('Navigation error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error navigating to details: $e')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Type and reference with dot
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textile['type'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Ref: ${textile['ref'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Right side: Camera icon
                  const Icon(Icons.camera_alt, color: Colors.black, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              // Details row
              Row(
                children: [
                  Text(
                    'D: ${textile['d']?.toString() ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Ch: ${textile['ch']?.toString() ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Mtr: ${textile['mtr']?.toString() ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
