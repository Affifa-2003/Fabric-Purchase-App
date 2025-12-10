import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchase_app/purchase_details_page.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/service/order_service.dart';
import 'new_order_setup_page.dart';
import 'package:intl/intl.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({Key? key}) : super(key: key);

  @override
  _PurchaseListPageState createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  List<dynamic> purchaseList = [];
  List<dynamic> filteredList = [];
  String selectedFilter = 'Pending'; // Default to Pending
  TextEditingController searchController = TextEditingController();
  late Box ordersBox;
  late StreamSubscription<void> _orderUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeHive();
    loadPurchaseList();
    searchController.addListener(() {
      filterList();
    });

    // Listen for order updates
    _orderUpdateSubscription = OrderService().orderUpdateStream.listen((_) {
      loadPurchaseList();
    });
  }

  @override
  void dispose() {
    _orderUpdateSubscription.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeHive() async {
    try {
      // Ensure the orders box is open
      if (!Hive.isBoxOpen('orders')) {
        await Hive.openBox('orders');
      }
      ordersBox = Hive.box('orders');
      print('Hive orders box is open: ${Hive.isBoxOpen('orders')}');
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  // Helper function to format date to "dd MMM yyyy" format
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  Future<void> loadPurchaseList() async {
  try {
    // Load initial data from JSON
    final String response = await rootBundle.loadString(
      'assets/purchase_list.json',
    );
    final List<dynamic> jsonData = json.decode(response);

    // Load data from Hive
    List<dynamic> hiveData = [];
    if (Hive.isBoxOpen('orders')) {
      hiveData = ordersBox.values.toList();

      // Convert ISO date strings to simple format for Hive data
      for (var item in hiveData) {
        if (item['date'] is String && item['date'].contains('T')) {
          try {
            final DateTime parsedDate = DateTime.parse(item['date']);
            item['date'] = _formatDate(parsedDate);
          } catch (e) {
            print('Error parsing date: ${item['date']} - $e');
          }
        }
        
        // Calculate the number of orders based on designs/textiles for this party
        String partyName = item['party'];
        int orderCount = 0;
        
        // Check if designs box is open
        if (Hive.isBoxOpen('designs')) {
          final designsBox = Hive.box('designs');
          
          // Count designs for this party
          for (var key in designsBox.keys) {
            if (key is String && key.startsWith('designs_${partyName}_')) {
              final designs = designsBox.get(key);
              if (designs is List) {
                orderCount += designs.length;
              }
            }
          }
        }
        
        // Update the orders count
        item['orders'] = orderCount;
        
        // Update status based on orders count
        if (orderCount > 0) {
          // For simplicity, setting status to 'mixed' if there are orders
          // You can implement more complex logic here based on your requirements
          item['status'] = 'mixed';
        } else {
          item['status'] = 'pending';
        }
      }
    }

    // Combine JSON data and Hive data (Hive data overrides JSON if same party exists)
    Map<String, dynamic> mergedMap = {};

    // Add all JSON data first
    for (var item in jsonData) {
      mergedMap[item['party']] = item;
    }

    // Override with Hive data if same party exists
    for (var item in hiveData) {
      mergedMap[item['party']] = item;
    }

    setState(() {
      purchaseList = mergedMap.values.toList();
      filteredList = List.from(purchaseList);
    });

    print(
      'Loaded ${jsonData.length} items from JSON and ${hiveData.length} items from Hive, merged into ${purchaseList.length} unique parties',
    );
  } catch (e) {
    print('Error loading purchase list: $e');
  }
}
  void filterList() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredList = purchaseList.where((item) {
        bool matchesSearch = item['party'].toLowerCase().contains(query);
        bool matchesFilter =
            selectedFilter == 'All' ||
            (selectedFilter == 'Pending' && item['status'] == 'pending') ||
            (selectedFilter == 'Mixed' && item['status'] == 'mixed') ||
            (selectedFilter == 'Complete' && item['status'] == 'complete');
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      filterList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Background color from image
      body: Column(
        children: [
          // Search field with card styling
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              color: const Color(0xFFFFFFFF), // White card background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search party name...', // Updated hint text
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ), // Grey search icon
                  border: InputBorder.none, // Remove default border
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
          // Container with white background and horizontal lines
          Container(
            color: const Color(0xFFFFFFFF), // White background
            child: Column(
              children: [
                // Top horizontal line
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E7EB), // Light grey divider color
                  ),
                ),
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 50,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Pending',
                          Colors.red,
                          const Color(0xFFFEF2F2),
                        ), // Red for pending with light red background
                        _buildFilterChip(
                          'Mixed',
                          Colors.orange,
                          const Color(0xFFFFF7ED),
                        ), // Orange for mixed with light orange background
                        _buildFilterChip(
                          'Complete',
                          Colors.green,
                          const Color(0xFFF0FDF4),
                        ), // Green for complete with light green background
                      ],
                    ),
                  ),
                ),
                // Bottom horizontal line
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E7EB), // Light grey divider color
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadPurchaseList,
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 0,
                    color: const Color(0xFFFFFFFF), // White card background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),

                    // In the PurchaseListPage, update the ListTile in the ListView.builder to navigate to PartyDetailsPage
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: _getStatusDot(
                        item['status'],
                      ), // Status dot instead of icon
                      title: Text(
                        item['party'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${item['orders']} orders • ${item['date']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ), // Arrow icon
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PartyDetailsPage(partyName: item['party']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color dotColor, Color selectedBgColor) {
    bool isSelected = selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          applyFilter(label);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedBgColor
                : Colors.transparent, // Light background color when selected
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? dotColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(
                      0.3,
                    ), // Border color matches dot color when selected
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: dotColor, // Always use the status color for the dot
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? dotColor
                      : Colors
                            .black, // Text color matches dot color when selected
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusDot(String status) {
    Color dotColor;
    switch (status) {
      case 'pending':
        dotColor = Colors.red; // Red dot for pending
        break;
      case 'mixed':
        dotColor = Colors.orange; // Orange dot for mixed
        break;
      case 'complete':
        dotColor = Colors.green; // Green dot for complete
        break;
      default:
        dotColor = Colors.grey;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }

  Widget _buildSummary() {
  // Use the full purchaseList for overall totals so the bottom summary
  // always shows totals across all parties, independent of current filter.
  final listForSummary = purchaseList;

  // Count the total number of parties
  int total = listForSummary.length;
  
  // Count the number of parties with 'pending' status
  int pending = listForSummary
      .where(
        (item) =>
            (item['status'] ?? '').toString().toLowerCase() == 'pending',
      )
      .length;
      
  // Count the number of parties with 'complete' status
  int complete = listForSummary
      .where(
        (item) =>
            (item['status'] ?? '').toString().toLowerCase() == 'complete',
      )
      .length;

  return Card(
    margin: EdgeInsets.zero, // Remove all margins
    elevation: 0,
    color: const Color(0xFFFFFFFF), // White card background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0), // Remove border radius
      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', total, Colors.black), // Black for Total
          _buildSummaryItem(
            'Pending',
            pending,
            Colors.red,
          ), // Red for Pending
          _buildSummaryItem(
            'Complete',
            complete,
            Colors.green,
          ), // Green for Complete
        ],
      ),
    ),
  );
}
  Widget _buildSummaryItem(String label, int count, Color numberColor) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: numberColor, // Use the specified color for the number
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black, // Keep label text black
          ),
        ),
      ],
    );
  }
}
