import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/new_order_setup_page.dart';
import 'package:purchase_app/service/order_service.dart';
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
  Map<String, List<Map<String, dynamic>>> groupedDesigns = {};
  late StreamSubscription<void> _orderUpdateSubscription;

  // List of original parties that should load from JSON
  final List<String> originalParties = [
    'Manish Textiles',
    'Raj Fabrics',
    'Kumar Mills',
    'Shree Textiles',
  ];

  @override
  void initState() {
    super.initState();
    _loadPartyData();
    // Listen for OrderService updates so this page reloads when designs/orders change
    _orderUpdateSubscription = OrderService().orderUpdateStream.listen((_) {
      _loadCapturedDesigns();
    });
  }

  @override
  void dispose() {
    _orderUpdateSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadPartyData() async {
    try {
      // Check if this is one of the original parties
      bool isOriginalParty = originalParties.contains(widget.partyName);

      if (isOriginalParty) {
        // Load data from JSON for original parties
        String jsonString = await rootBundle.loadString('party_details.json');
        Map<String, dynamic> allData = json.decode(jsonString);

        setState(() {
          partyData = allData[widget.partyName] ?? {};
        });

        // Also load designs from Hive to show any additional designs added
        await _loadCapturedDesigns();
      } else {
        // For new parties, load only from Hive
        await _loadCapturedDesigns();

        // Create a default structure for new parties
        setState(() {
          partyData = {
            'summary': {'d': 0, 'ch': 0, 'mtr': 0},
            'textiles': [],
          };
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading party data: $e');
      // Fallback to default data if loading fails
      setState(() {
        partyData = {
          'summary': {'d': 0, 'ch': 0, 'mtr': 0},
          'textiles': [],
        };
        _isLoading = false;
      });
    }
  }

  // In PartyDetailsPage, modify the _loadCapturedDesigns method to also update the orders box

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
      // Group by O/F type
      groupedDesigns = {};
      for (var design in capturedDesigns) {
        final type = design['ofType'] ?? 'Unknown';
        if (!groupedDesigns.containsKey(type)) {
          groupedDesigns[type] = [];
        }
        groupedDesigns[type]!.add(design);
      }
    });
    
    // Update the orders box with the correct count
    await _updateOrdersCount();
    
    print('Loaded ${capturedDesigns.length} captured designs from Hive');
  } catch (e) {
    print('Error loading captured designs: $e');
  }
}

// Add this new method to update the orders count
Future<void> _updateOrdersCount() async {
  try {
    if (!Hive.isBoxOpen('orders')) {
      await Hive.openBox('orders');
    }
    
    final ordersBox = Hive.box('orders');
    
    // Find the order for this party
    final existingOrder = ordersBox.values.firstWhere(
      (order) => order['party'] == widget.partyName,
      orElse: () => null,
    );
    
    if (existingOrder != null) {
      // Update the orders count
      existingOrder['orders'] = capturedDesigns.length;
      
      // Update status based on orders count
      if (capturedDesigns.length > 0) {
        existingOrder['status'] = 'mixed';
      } else {
        existingOrder['status'] = 'pending';
      }
      
      // Save the updated order
      await ordersBox.put(existingOrder['party'], existingOrder);
      
      // Notify listeners that orders have been updated
     OrderService().notifyOrderUpdated();
    }
  } catch (e) {
    print('Error updating orders count: $e');
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
                _buildSummarySection(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    children: [
                      // For original parties, show both JSON data and Hive data
                      if (originalParties.contains(widget.partyName)) ...[
                        // Show textile cards from JSON data
                        if (partyData['textiles'] != null)
                          ...(partyData['textiles'] as List<dynamic>).map((
                            textile,
                          ) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                              color: const Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TextileDetailsPage(
                                        partyName: widget.partyName,
                                        textileType: textile['type'] ?? '',
                                        selectedWidth: '58"',
                                        defaultChoices: textile['ch'] ?? 2,
                                        defaultMeters: textile['mtr'] ?? 100,
                                        sampleRequired: 'Yes',
                                        selectedSampleMtr: null,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: _parseColor(
                                                    textile['color'] ??
                                                        '#000000',
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    textile['type'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                          // Changed icon for JSON-loaded cards
                                          Icon(
                                            Icons.list_alt,
                                            color: Colors.grey[600],
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            'Designs: ${textile['d'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Choices: ${textile['ch'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Meters: ${textile['mtr'] ?? 0}',
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
                          }).toList(),
                      ],

                      // Show textile cards from Hive data for all parties
                      ...groupedDesigns.entries.map((entry) {
                        final type = entry.key;
                        final designs = entry.value;

                        // Skip if this is an original party and we already have this type in JSON
                        if (originalParties.contains(widget.partyName) &&
                            partyData['textiles'] != null) {
                          bool existsInJson =
                              (partyData['textiles'] as List<dynamic>).any(
                                (textile) =>
                                    (textile['type'] ?? '')
                                        .toString()
                                        .toLowerCase() ==
                                    type.toLowerCase(),
                              );
                          if (existsInJson) {
                            // We'll add a badge to show there are additional designs
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                              color: const Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  // On tap, go to textile_details.dart with the first design of this type
                                  if (designs.isNotEmpty) {
                                    final d = designs.first;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TextileDetailsPage(
                                              partyName: widget.partyName,
                                              textileType: d['ofType'] ?? '',
                                              selectedWidth:
                                                  d['width'] ?? '58"',
                                              defaultChoices: d['choices'] ?? 2,
                                              defaultMeters: d['meters'] ?? 100,
                                              sampleRequired: 'Yes',
                                              selectedSampleMtr: null,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: _parseColor(
                                                    _getTypeColor(type),
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        type,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF1F2937,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '+${designs.length} designs',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    'Additional designs',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          // Camera icon for Hive-loaded cards
                                          const Icon(
                                            Icons.camera_alt,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Compute totals for Designs, Choices, and Meters
                                      ...(() {
                                        int totalDesigns = 0;
                                        int totalChoices = 0;
                                        double totalMeters = 0.0;

                                        for (var d in designs) {
                                          totalDesigns += 1;
                                          totalChoices += (d['choices'] as int);
                                          totalMeters += ((d['meters'] is int)
                                              ? (d['meters'] as int).toDouble()
                                              : (d['meters'] as double));
                                        }

                                        return [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Designs: $totalDesigns',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  'Choices: $totalChoices',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  'Meters: ${totalMeters.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ];
                                      })(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        }

                        // For new parties or types not in JSON, show the original card
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 0,
                          color: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              // On tap, go to textile_details.dart and patch form with first design of this type
                              if (designs.isNotEmpty) {
                                final d = designs.first;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TextileDetailsPage(
                                      partyName: widget.partyName,
                                      textileType: d['ofType'] ?? '',
                                      selectedWidth: d['width'] ?? '58"',
                                      defaultChoices: d['choices'] ?? 2,
                                      defaultMeters: d['meters'] ?? 100,
                                      sampleRequired: 'Yes',
                                      selectedSampleMtr: null,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _parseColor(
                                                _getTypeColor(type),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                type,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              Text(
                                                'Ref: ${type.toUpperCase().substring(0, (type.length >= 3 ? 3 : type.length))}-${designs.length.toString().padLeft(3, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Camera icon for Hive-loaded cards
                                      const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Compute totals for Designs, Choices, and Meters
                                  ...(() {
                                    int totalDesigns = 0;
                                    int totalChoices = 0;
                                    double totalMeters = 0.0;

                                    for (var d in designs) {
                                      totalDesigns += 1;
                                      totalChoices += (d['choices'] as int);
                                      totalMeters += ((d['meters'] is int)
                                          ? (d['meters'] as int).toDouble()
                                          : (d['meters'] as double));
                                    }

                                    return [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Designs: $totalDesigns',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Choices: $totalChoices',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Meters: ${totalMeters.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];
                                  })(),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummarySection() {
    // For original parties, start with JSON summary and add Hive data
    int totalDesigns = 0;
    int totalChoices = 0;
    double totalMeters = 0.0;

    if (originalParties.contains(widget.partyName) &&
        partyData['summary'] != null) {
      totalDesigns = partyData['summary']['d'] ?? 0;
      totalChoices = partyData['summary']['ch'] ?? 0;
      totalMeters = (partyData['summary']['mtr'] is int)
          ? (partyData['summary']['mtr'] as int).toDouble()
          : (partyData['summary']['mtr'] as double);
    }

    // Add totals from captured designs
    for (var d in capturedDesigns) {
      totalDesigns += 1;
      totalChoices += (d['choices'] is int)
          ? d['choices'] as int
          : int.tryParse(d['choices']?.toString() ?? '0') ?? 0;
      final m = d['meters'];
      if (m is int) {
        totalMeters += m.toDouble();
      } else if (m is double) {
        totalMeters += m;
      } else {
        totalMeters += double.tryParse(m?.toString() ?? '0') ?? 0.0;
      }
    }

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
            totalDesigns.toString(),
            showRightDivider: true,
          ),
          _buildSummaryItem(
            'Ch',
            totalChoices.toString(),
            showRightDivider: true,
          ),
          _buildSummaryItem(
            'Mtr',
            totalMeters.toStringAsFixed(0),
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

  // Helper to get color for O/F type
  String _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'regular':
        return '#FF5722';
      case 'mix':
        return '#4CAF50';
      case 'plain':
        return '#2196F3';
      default:
        return '#BDBDBD';
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
