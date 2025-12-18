import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:purchase_app/utils/input_formatters.dart';

class PurchaseOrderGroupPage extends StatefulWidget {
  const PurchaseOrderGroupPage({Key? key}) : super(key: key);

  @override
  _PurchaseOrderGroupPageState createState() => _PurchaseOrderGroupPageState();
}

class _PurchaseOrderGroupPageState extends State<PurchaseOrderGroupPage> {
  List<Map<String, dynamic>> purchaseOrderGroups = [];
  List<Map<String, dynamic>> filteredPurchaseOrderGroups = [];
  List<Map<String, dynamic>> seasons = [];
  List<Map<String, dynamic>> financialYears = [];

  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterPurchaseOrderGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadPurchaseOrderGroups(),
      _loadSeasons(),
      _loadFinancialYears(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPurchaseOrderGroups() async {
    try {
      if (!Hive.isBoxOpen('appData')) await Hive.openBox('appData');
      final box = Hive.box('appData');
      final data = box.get('purchaseOrderGroups');
      if (data is List) {
        purchaseOrderGroups = data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
      filteredPurchaseOrderGroups = List.from(purchaseOrderGroups);
    } catch (e) {
      print('Error loading purchase order groups: $e');
    }
  }

  Future<void> _loadSeasons() async {
    try {
      if (!Hive.isBoxOpen('appData')) await Hive.openBox('appData');
      final box = Hive.box('appData');
      final data = box.get('seasons');

      print('Loading seasons from Hive: $data'); // Debug print

      if (data is List) {
        seasons = data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
        print(
          'Seasons loaded successfully: ${seasons.length} seasons',
        ); // Debug print
      } else {
        print('No seasons data found or invalid format'); // Debug print
        seasons = [];
      }
    } catch (e) {
      print('Error loading seasons: $e');
      seasons = [];
    }
  }

  Future<void> _loadFinancialYears() async {
    try {
      if (!Hive.isBoxOpen('appData')) await Hive.openBox('appData');
      final box = Hive.box('appData');
      final data = box.get('financialYears');
      if (data is List) {
        financialYears = data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (e) {
      print('Error loading financial years: $e');
    }
  }

  Future<void> _savePurchaseOrderGroupsToStorage() async {
    try {
      if (!Hive.isBoxOpen('appData')) await Hive.openBox('appData');
      final box = Hive.box('appData');
      await box.put('purchaseOrderGroups', purchaseOrderGroups);
      await box.flush();
    } catch (e) {
      print('Error saving purchase order groups: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterPurchaseOrderGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPurchaseOrderGroups = purchaseOrderGroups.where((group) {
        return group['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getFinancialYearNameById(String? id) {
    if (id == null) return 'N/A';
    final year = financialYears.firstWhere(
      (fy) => fy['name'] == id,
      orElse: () => {'name': 'N/A'},
    );
    return year['name'];
  }

  void _showAddEditDialog({Map<String, dynamic>? group, int? index}) async {
    // Load seasons and financial years before showing the dialog
    await _loadSeasons();
    await _loadFinancialYears();

    final isEditing = group != null;
    final nameController = TextEditingController(
      text: isEditing ? group['name'] : '',
    );

    // Use a list for selected seasons
    List<String> selectedSeasonIds = isEditing
        ? List<String>.from(group['seasons'] ?? [])
        : [];

    String? selectedFinancialYearId = isEditing ? group['financialYear'] : null;
    DateTime? startDate = isEditing
        ? DateTime.tryParse(group['startDate'] ?? '')
        : null;
    DateTime? endDate = isEditing
        ? DateTime.tryParse(group['endDate'] ?? '')
        : null;
    String statusValue = isEditing ? group['status'] ?? 'Active' : 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildDialogHeader(
                    isEditing
                        ? 'Edit Purchase Order Group'
                        : 'Add Purchase Order Group',
                  ),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildNameField(nameController),
                          const SizedBox(height: 16),
                          // Use the multi-select dropdown for seasons
                          _buildSeasonMultiSelectDropdown(
                            selectedSeasonIds,
                            setDialogState,
                          ),
                          const SizedBox(height: 16),
                          _buildFinancialYearDropdown(
                            selectedFinancialYearId,
                            setDialogState,
                            (value) {
                              setDialogState(() {
                                selectedFinancialYearId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(
                            title: 'Start Date: *',
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  startDate = picked;
                                  // If end date is before the new start date, clear it
                                  if (endDate != null &&
                                      endDate!.isBefore(picked)) {
                                    endDate = null;
                                  }
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),
                          _buildDateField(
                            title: 'End Date:',
                            date: endDate,
                            onTap: () async {
                              // Ensure startDate is selected before allowing end date selection
                              if (startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a start date first',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    endDate ??
                                    startDate!.add(const Duration(days: 1)),
                                firstDate:
                                    startDate!, // Set minimum date to the start date
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() => endDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildStatusDropdown(statusValue, setDialogState),
                          const SizedBox(height: 16),
                          _buildInfoBox(isEditing),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  _buildDialogActions(isEditing, () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (selectedSeasonIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('At least one season is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (selectedFinancialYearId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Financial Year is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (startDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Start Date is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newGroup = {
                      'name': nameController.text.trim(),
                      'seasons': selectedSeasonIds,
                      'financialYear': selectedFinancialYearId,
                      'startDate': startDate!.toIso8601String(),
                      'endDate': endDate?.toIso8601String(),
                      'status': statusValue,
                    };

                    setState(() {
                      if (isEditing && index != null) {
                        purchaseOrderGroups[index] = newGroup;
                      } else {
                        purchaseOrderGroups.insert(0, newGroup);
                      }
                      _filterPurchaseOrderGroups();
                    });

                    _savePurchaseOrderGroupsToStorage();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Group updated successfully'
                              : 'Group added successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogHeader(String title) => Container(
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
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: Color(0xFF767676)),
        ),
      ],
    ),
  );

  Widget _buildDialogActions(bool isEditing, VoidCallback onSave) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Expanded(
          child: _buildDialogButton(
            'Cancel',
            const Color(0xFF2563EB),
            () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDialogButton(
            isEditing ? 'Update' : 'Save to Master',
            const Color(0xFF10B981),
            onSave,
          ),
        ),
      ],
    ),
  );

  Widget _buildDialogButton(String text, Color color, VoidCallback onPressed) =>
      Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildNameField(TextEditingController controller) => _buildFormField(
    title: 'Name: *',
    child: TextField(
      controller: controller,
      inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
      decoration: const InputDecoration(
        hintText: 'e.g., Summer Collection 2024',
        border: OutlineInputBorder(),
      ),
    ),
  );

  Widget _buildSeasonMultiSelectDropdown(
    List<String> selectedIds,
    StateSetter setDialogState,
  ) {
    return _buildFormField(
      title: 'Seasons: *',
      child: InkWell(
        onTap: () async {
          // Reload seasons to ensure we have the latest data
          await _loadSeasons();

          // Create a temporary copy of selected IDs for the dialog
          final List<String> tempSelection = List.from(selectedIds);

          await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                return AlertDialog(
                  title: const Text('Select Seasons'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: seasons.isEmpty
                        ? const Center(
                            child: Text(
                              'No seasons found. Please add seasons first.',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: seasons.length,
                            itemBuilder: (context, index) {
                              final season = seasons[index];
                              final id = season['name'].toString();
                              final isSelected = tempSelection.contains(id);

                              return Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFF2563EB),
                                    onChanged: (bool? value) {
                                      if (value == true) {
                                        tempSelection.add(id);
                                      } else {
                                        tempSelection.remove(id);
                                      }
                                      setDialogState(() {});
                                    },
                                  ),
                                  Expanded(child: Text(id)),
                                ],
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Update the original list
                        selectedIds.clear();
                        selectedIds.addAll(tempSelection);
                        // Force update the parent dialog state
                        setDialogState(() {});
                        // Close the dialog
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            ),
          ).then((_) {
            // Ensure the parent dialog rebuilds after the selection dialog is closed
            setDialogState(() {});
          });
        },
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'Select seasons',
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: selectedIds.isEmpty
              ? const Text(
                  'Select seasons',
                  style: TextStyle(color: Colors.grey),
                )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: selectedIds
                      .map(
                        (id) => Chip(
                          label: Text(id),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setDialogState(() => selectedIds.remove(id));
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildFinancialYearDropdown(
    String? selectedId,
    StateSetter setDialogState,
    Function(String?) onChanged, // Added callback parameter
  ) => _buildFormField(
    title: 'Financial Year: *',
    child: DropdownButtonFormField<String>(
      value: selectedId,
      hint: const Text('Select Financial Year'),
      items: financialYears
          .map(
            (fy) => DropdownMenuItem(
              value: fy['name'].toString(),
              child: Text(fy['name'].toString()),
            ),
          )
          .toList(),
      onChanged: onChanged, // Use the callback
      decoration: const InputDecoration(border: OutlineInputBorder()),
    ),
  );

  Widget _buildDateField({
    required String title,
    DateTime? date,
    required VoidCallback onTap,
    DateTime? minDate, // Add this parameter
  }) {
    return _buildFormField(
      title: title,
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'Select Date',
            hintStyle: TextStyle(
              color: date == null ? Colors.grey : Colors.black,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
          child: Text(
            date == null
                ? 'Select Date'
                : DateFormat('dd-MM-yyyy').format(date),
            style: TextStyle(color: date == null ? Colors.grey : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(String status, StateSetter setDialogState) =>
      _buildFormField(
        title: 'Status: *',
        child: DropdownButtonFormField<String>(
          value: status,
          items: [
            'Active',
            'Inactive',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => setDialogState(() => status = value!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      );

  Widget _buildInfoBox(bool isEditing) => Container(
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: const Color(0xFFEBF8FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF3182CE)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Color(0xFF3182CE)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEditing
                ? 'This will update the group in master and all associated records.'
                : 'This will be added to master and available for future orders.',
            style: const TextStyle(color: Color(0xFF3182CE)),
          ),
        ),
      ],
    ),
  );

  Widget _buildFormField({required String title, required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  void _showDeleteConfirmationDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              final originalIndex = purchaseOrderGroups.indexWhere(
                (g) => g['name'] == group['name'],
              );
              if (originalIndex != -1) {
                setState(() {
                  purchaseOrderGroups.removeAt(originalIndex);
                  _filterPurchaseOrderGroups();
                });
                _savePurchaseOrderGroupsToStorage();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 55,
        title: const Text('Purchase Order Group'),
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
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 24),
              onPressed: () => _showAddEditDialog(),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Purchase Order Group',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredPurchaseOrderGroups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                purchaseOrderGroups.isEmpty
                                    ? 'No groups found'
                                    : 'No matching groups',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                purchaseOrderGroups.isEmpty
                                    ? 'Add groups using the + button'
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
                          onRefresh: _loadAllData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredPurchaseOrderGroups.length,
                            itemBuilder: (context, index) {
                              final group = filteredPurchaseOrderGroups[index];
                              final originalIndex = purchaseOrderGroups
                                  .indexWhere(
                                    (g) => g['name'] == group['name'],
                                  );
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
                                      Icons.group,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    group['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _getFinancialYearNameById(
                                      group['financialYear'],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmationDialog(group),
                                  ),
                                  onTap: () => _showAddEditDialog(
                                    group: group,
                                    index: originalIndex,
                                  ),
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
}
