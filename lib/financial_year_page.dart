import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';

class FinancialYearPage extends StatefulWidget {
  const FinancialYearPage({Key? key}) : super(key: key);

  @override
  _FinancialYearPageState createState() => _FinancialYearPageState();
}

class _FinancialYearPageState extends State<FinancialYearPage> {
  List<Map<String, dynamic>> financialYears = [];
  List<Map<String, dynamic>> filteredFinancialYears = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFinancialYears();
    _searchController.addListener(_filterFinancialYears);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialYears() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveFinancialYears = [];

      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');

      final financialYearsData = appDataBox.get('financialYears');
      if (financialYearsData != null) {
        // Handle different types of data
        if (financialYearsData is List) {
          hiveFinancialYears = financialYearsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      setState(() {
        financialYears = hiveFinancialYears;
        filteredFinancialYears = List.from(financialYears);
        _isLoading = false;
      });

      print('Loaded ${financialYears.length} financial years from Hive');
    } catch (e) {
      print('Error loading financial years: $e');
      setState(() {
        financialYears = [];
        filteredFinancialYears = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFinancialYearsToStorage() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> financialYearsToSave = financialYears.map((
        financialYear,
      ) {
        return {
          'name': financialYear['name']?.toString() ?? '',
          'description': financialYear['description']?.toString() ?? '',
          'status': financialYear['status']?.toString() ?? 'Active',
        };
      }).toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('financialYears', financialYearsToSave);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved financial years: ${box.get('financialYears')}');
      print('Financial years data saved successfully');
    } catch (e) {
      print('Error saving financial years data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving financial years: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterFinancialYears() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredFinancialYears = financialYears.where((financialYear) {
        return financialYear['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddNewFinancialYearDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
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
                        'Add Financial Year',
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
                        // Financial Year Name Field
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
                                    'Financial Year Name: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                  hintText: 'e.g. 2024-25',
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

                        // Description Field
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
                                    'Description:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                inputFormatters: [
                                  NoLeadingOrMultipleSpacesFormatter(),
                                ],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Optional description',
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
                                    'Status: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    .map(
                                      (status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
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
                                  'This will be added to master and available for future use.',
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
                                    content: Text(
                                      'Financial year name is required',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Create new financial year
                              Map<String, dynamic> newFinancialYear = {
                                'name': nameController.text.trim(),
                                'description': descriptionController.text
                                    .trim(),
                                'status': statusValue,
                              };

                              // Update local state immediately
                              setState(() {
                                // Add to the beginning of the list
                                financialYears.insert(0, newFinancialYear);
                                _filterFinancialYears(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveFinancialYearsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Financial year added successfully',
                                  ),
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

  void _showEditFinancialYearDialog(
    Map<String, dynamic> financialYear,
    int index,
  ) {
    TextEditingController nameController = TextEditingController(
      text: financialYear['name'],
    );
    TextEditingController descriptionController = TextEditingController(
      text: financialYear['description'] ?? '',
    );
    String statusValue = financialYear['status'];

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
                        'Edit Financial Year',
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
                        // Financial Year Name Field
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
                                    'Financial Year Name: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                  hintText: 'e.g. 2024-25',
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

                        // Description Field
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
                                    'Description:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Optional description',
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
                                    'Status: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    .map(
                                      (status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
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
                                  'This will update the financial year in master and all associated records.',
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
                                    content: Text(
                                      'Financial year name is required',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Create updated financial year
                              Map<String, dynamic> updatedFinancialYear = {
                                'name': nameController.text.trim(),
                                'description': descriptionController.text
                                    .trim(),
                                'status': statusValue,
                              };

                              // Update local state immediately
                              setState(() {
                                // Remove the old financial year
                                financialYears.removeAt(index);
                                // Add the updated financial year at the beginning
                                financialYears.insert(0, updatedFinancialYear);
                                _filterFinancialYears(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveFinancialYearsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Financial year updated successfully',
                                  ),
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
        title: const Text('Financial Year'),
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
              icon: const Icon(
                Icons.add,
                color: Color(0xFF2563EB),
                size: 24,
              ), // Adjusted icon size
              onPressed: _showAddNewFinancialYearDialog,
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
                        hintText: 'Search Financial Year',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Financial years list
                Expanded(
                  child: filteredFinancialYears.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                financialYears.isEmpty
                                    ? 'No financial years found'
                                    : 'No matching financial years',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                financialYears.isEmpty
                                    ? 'Add financial years using the + button'
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
                          onRefresh: _loadFinancialYears,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredFinancialYears.length,
                            itemBuilder: (context, index) {
                              final financialYear =
                                  filteredFinancialYears[index];

                              return Card(
                                elevation: 0,
                                color: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEBF5FF),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    financialYear['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        financialYear,
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // Find the original index in the financialYears list
                                    int originalIndex = financialYears
                                        .indexWhere(
                                          (fy) =>
                                              fy['name'] ==
                                              financialYear['name'],
                                        );
                                    if (originalIndex != -1) {
                                      _showEditFinancialYearDialog(
                                        financialYear,
                                        originalIndex,
                                      );
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> financialYear) {
    // Check if financial year is used in any purchase order groups
    bool isUsedInPurchaseOrderGroups = false;

    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final purchaseOrderGroupsData = appDataBox.get('purchaseOrderGroups');

        if (purchaseOrderGroupsData != null &&
            purchaseOrderGroupsData is List) {
          for (var group in purchaseOrderGroupsData) {
            if (group is Map &&
                group['financialYear'] == financialYear['name']) {
              isUsedInPurchaseOrderGroups = true;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if financial year is used: $e');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isUsedInPurchaseOrderGroups
              ? const Text(
                  'This financial year is already mapped with purchase order groups and cannot be deleted.',
                )
              : Text(
                  'Are you sure you want to delete "${financialYear['name']}"?',
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            if (!isUsedInPurchaseOrderGroups)
              TextButton(
                onPressed: () async {
                  // Find the original index in the financialYears list
                  int originalIndex = financialYears.indexWhere(
                    (fy) => fy['name'] == financialYear['name'],
                  );
                  if (originalIndex != -1) {
                    // Update local state immediately
                    setState(() {
                      financialYears.removeAt(originalIndex);
                      _filterFinancialYears(); // Update filtered list
                    });

                    // Save to Hive
                    await _saveFinancialYearsToStorage();

                    Navigator.of(context).pop(); // Close dialog

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Financial year deleted successfully'),
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
