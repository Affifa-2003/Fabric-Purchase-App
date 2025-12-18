import 'package:flutter/material.dart';
import 'dart:async';
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
      // Only load from Hive, no JSON loading
      await _ensureAllTextileTypes(); // Add this line
      await _loadCapturedDesigns();

      // Create a default structure for all parties
      setState(() {
        partyData = {
          'summary': {'d': 0, 'ch': 0, 'mtr': 0},
          'textiles': [],
        };
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

  Future<void> _ensureAllTextileTypes() async {
    try {
      if (!Hive.isBoxOpen('designs')) {
        await Hive.openBox('designs');
      }

      final box = Hive.box('designs');

      // Get all textile types for this party
      Set<String> textileTypes = {};
      for (var key in box.keys) {
        if (key is String && key.startsWith('designs_${widget.partyName}_')) {
          // Extract textile type from key (format: designs_partyName_textileType)
          final parts = key.split('_');
          if (parts.length >= 3) {
            textileTypes.add(
              parts.sublist(2).join('_'),
            ); // Join remaining parts in case textile type has underscores
          }
        }
      }

      // Ensure all textile types have at least one design entry
      for (var type in textileTypes) {
        final key = 'designs_${widget.partyName}_$type';
        final designs = box.get(key);

        if (designs == null || (designs is List && designs.isEmpty)) {
          // Create a placeholder design if none exists
          await box.put(key, [
            {
              'sNo': 1,
              'designNo': '-',
              'choices': 0,
              'meters': 0,
              'mode': 'Design',
              'timestamp': DateTime.now().toIso8601String(),
              'ofType': type,
              'weave': '',
              'quality': '',
              'width': '58"',
              'ref': '-',
              'photos': [],
            },
          ]);
        }
      }

      await box.flush();
    } catch (e) {
      print('Error ensuring all textile types: $e');
    }
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

      // print('Loaded ${capturedDesigns.length} captured designs from Hive');
    } catch (e) {
      print('Error loading captured designs: $e');
    }
  }

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
        // Create a set to track unique textile types
        Set<String> uniqueTextileTypes = {};

        // Find all unique textile types for this party
        for (var design in capturedDesigns) {
          // Check if the design has meaningful data
          if (design['ofType'] != null &&
              design['ofType'].toString().isNotEmpty &&
              design['width'] != null &&
              design['width'].toString().isNotEmpty) {
            // Add the textile type to our set
            uniqueTextileTypes.add(design['ofType']);
          }
        }

        // The order count is the number of unique textile types
        existingOrder['orders'] = uniqueTextileTypes.length;

        // Update status based on orders count
        if (uniqueTextileTypes.length > 0) {
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
        toolbarHeight: 55,
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
                      // Only show textile cards from Hive data for all parties
                      ...groupedDesigns.entries.map((entry) {
                        final type = entry.key;
                        final designs = entry.value;

                        // Show the card for each textile type
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
                                    builder: (context) => TextileDetailsPage(
                                      partyName: widget.partyName,
                                      textileType: d['ofType'] ?? '',
                                      selectedWidth: d['width'] ?? '58"',
                                      defaultChoices: (d['choices'] is num)
                                          ? (d['choices'] as num).toInt()
                                          : 2, // Safe cast
                                      defaultMeters: (d['meters'] is num)
                                          ? (d['meters'] as num).toInt()
                                          : 100, // Safe cast
                                      sampleRequired: 'Yes',
                                      selectedSampleMtr: null,
                                      lockOFType: true,
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
                                              Row(
                                                children: [
                                                  Text(
                                                    type,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Ref: -',
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
                                    int totalMeters = 0;

                                    for (var d in designs) {
                                      totalDesigns += 1;
                                      // Safe cast for choices
                                      totalChoices += (d['choices'] is num)
                                          ? (d['choices'] as num).toInt()
                                          : 0;
                                      // Safe cast for meters
                                      totalMeters += (d['meters'] is num)
                                          ? (d['meters'] as num).toInt()
                                          : 0;
                                    }

                                    return [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'D: $totalDesigns',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Ch: $totalChoices',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Mtr: ${totalMeters.toStringAsFixed(0)}',
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

                      // Show a message if no designs are found
                      if (groupedDesigns.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No designs found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add a new design',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummarySection() {
    // Only use Hive data for summary
    int totalDesigns = 0;
    int totalChoices = 0;
    int totalMeters = 0;

    // Add totals from captured designs
    for (var d in capturedDesigns) {
      totalDesigns += 1;
      // Safe cast for choices
      totalChoices += (d['choices'] is num) ? (d['choices'] as num).toInt() : 0;
      // Safe cast for meters
      final m = d['meters'];
      if (m is int) {
        totalMeters += m;
      } else if (m is double) {
        // Corrected condition
        totalMeters += m.toInt();
      } else {
        totalMeters += int.tryParse(m?.toString() ?? '0') ?? 0;
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
            totalMeters.toString(), // Use .toString() for an integer
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
