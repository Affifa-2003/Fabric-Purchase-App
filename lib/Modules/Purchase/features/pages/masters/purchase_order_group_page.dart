import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      Helpers.showErrorSnackBar(context, 'Error saving: $e');
    }
  }

  void _filterPurchaseOrderGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPurchaseOrderGroups = List.from(purchaseOrderGroups);
      } else {
        filteredPurchaseOrderGroups = purchaseOrderGroups.where((group) {
          return group['name'].toString().toLowerCase().contains(query);
        }).toList();
      }
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
    // Load seasons and financial years before showing dialog
    await _loadSeasons();
    await _loadFinancialYears();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PurchaseOrderGroupDialog(
          title: group != null ? 'Edit Purchase Order Group' : 'Add Purchase Order Group',
          initialGroup: group,
          seasons: seasons,
          financialYears: financialYears,
          onSave: (newGroup) {
            setState(() {
              if (group != null && index != null) {
                purchaseOrderGroups[index] = newGroup;
              } else {
                purchaseOrderGroups.insert(0, newGroup);
              }
              _filterPurchaseOrderGroups();
            });
            _savePurchaseOrderGroupsToStorage();
            Helpers.showSuccessSnackBar(
              context,
              group != null ? 'Group updated successfully' : 'Group added successfully',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Purchase Order Group',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Purchase Order Group',
                ),
                Expanded(
                  child: filteredPurchaseOrderGroups.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.group_outlined,
                          title: purchaseOrderGroups.isEmpty
                              ? 'No groups found'
                              : 'No matching groups',
                          subtitle: purchaseOrderGroups.isEmpty
                              ? 'Add groups using the + button'
                              : 'Try a different search term',
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
                              final originalIndex = purchaseOrderGroups.indexWhere(
                                (g) => g['name'] == group['name'],
                              );
                              return Helpers.buildListItem(
                                title: group['name'],
                                subtitle: _getFinancialYearNameById(group['financialYear']),
                                icon: Icons.group,
                                onTap: () => _showAddEditDialog(
                                  group: group,
                                  index: originalIndex,
                                ),
                                onDelete: () => _showDeleteConfirmationDialog(group),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
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
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> group) {
    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${group['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        final originalIndex = purchaseOrderGroups.indexWhere(
          (g) => g['name'] == group['name'],
        );
        if (originalIndex != -1) {
          setState(() {
            purchaseOrderGroups.removeAt(originalIndex);
            _filterPurchaseOrderGroups();
          });
          await _savePurchaseOrderGroupsToStorage();
          Helpers.showSuccessSnackBar(context, 'Group deleted successfully');
        }
      },
    );
  }
}

// Separate StatefulWidget for the dialog
class PurchaseOrderGroupDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialGroup;
  final List<Map<String, dynamic>> seasons;
  final List<Map<String, dynamic>> financialYears;
  final Function(Map<String, dynamic>) onSave;

  const PurchaseOrderGroupDialog({
    Key? key,
    required this.title,
    this.initialGroup,
    required this.seasons,
    required this.financialYears,
    required this.onSave,
  }) : super(key: key);

  @override
  _PurchaseOrderGroupDialogState createState() => _PurchaseOrderGroupDialogState();
}

class _PurchaseOrderGroupDialogState extends State<PurchaseOrderGroupDialog> {
  late TextEditingController _nameController;
  List<String> selectedSeasonIds = [];
  String? selectedFinancialYearId;
  DateTime? startDate;
  DateTime? endDate;
  String _statusValue = 'Active';
  bool _isSaving = false;
  
  // Error states
  bool _nameError = false;
  bool _seasonsError = false;
  bool _financialYearError = false;
  bool _startDateError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialGroup?['name'] ?? '',
    );
    
    // Initialize selected seasons
    if (widget.initialGroup?['seasons'] != null) {
      selectedSeasonIds = List<String>.from(widget.initialGroup!['seasons']);
    }
    
    selectedFinancialYearId = widget.initialGroup?['financialYear'];
    startDate = widget.initialGroup?['startDate'] != null
        ? DateTime.tryParse(widget.initialGroup!['startDate'])
        : null;
    endDate = widget.initialGroup?['endDate'] != null
        ? DateTime.tryParse(widget.initialGroup!['endDate'])
        : null;
    _statusValue = widget.initialGroup?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Helpers.buildDialogHeader(widget.title, context),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildSeasonMultiSelectDropdown(),
                    const SizedBox(height: 16),
                    _buildFinancialYearDropdown(),
                    const SizedBox(height: 16),
                    _buildStartDateField(),
                    const SizedBox(height: 16),
                    _buildEndDateField(),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    Helpers.buildInfoBox(
                      widget.initialGroup == null
                          ? 'This will be added to master and available for future orders.'
                          : 'This will update group in master and all associated records.',
                      isEditing: widget.initialGroup != null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            _buildDialogButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Helpers.buildFormField(
      title: 'Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: InputDecoration(
          hintText: 'e.g., Summer Collection 2024',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError = Validators.validateRequired(value, 'Name') != null;
          });
        },
      ),
    );
  }

  Widget _buildSeasonMultiSelectDropdown() {
    return Helpers.buildFormField(
      title: 'Seasons: *',
      child: InkWell(
        onTap: () async {
          // Create a temporary copy of selected IDs for dialog
          final List<String> tempSelection = List.from(selectedSeasonIds);

          await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                return AlertDialog(
                  title: const Text('Select Seasons'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: widget.seasons.isEmpty
                        ? const Center(
                            child: Text(
                              'No seasons found. Please add seasons first.',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.seasons.length,
                            itemBuilder: (context, index) {
                              final season = widget.seasons[index];
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
                        // Update original list
                        setState(() {
                          selectedSeasonIds.clear();
                          selectedSeasonIds.addAll(tempSelection);
                        });
                        // Close dialog
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            ),
          );
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
          child: selectedSeasonIds.isEmpty
              ? const Text(
                  'Select seasons',
                  style: TextStyle(color: Colors.grey),
                )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: selectedSeasonIds
                      .map(
                        (id) => Chip(
                          label: Text(id),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() => selectedSeasonIds.remove(id));
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildFinancialYearDropdown() {
    return Helpers.buildFormField(
      title: 'Financial Year: *',
      child: DropdownButtonFormField<String>(
        value: selectedFinancialYearId,
        hint: const Text('Select Financial Year'),
        items: widget.financialYears
            .map(
              (fy) => DropdownMenuItem(
                value: fy['name'].toString(),
                child: Text(fy['name'].toString()),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedFinancialYearId = value;
            _financialYearError = false;
          });
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _financialYearError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _financialYearError ? 'Financial Year is required' : null,
        ),
      ),
    );
  }

  Widget _buildStartDateField() {
    return Helpers.buildDateField(
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
          setState(() {
            startDate = picked;
            _startDateError = false;
            // If end date is before new start date, clear it
            if (endDate != null && endDate!.isBefore(picked)) {
              endDate = null;
            }
          });
        }
      },
    );
  }

  Widget _buildEndDateField() {
    return Helpers.buildDateField(
      title: 'End Date:',
      date: endDate,
      onTap: () async {
        // Ensure startDate is selected before allowing end date selection
        if (startDate == null) {
          Helpers.showErrorSnackBar(
            context,
            'Please select a start date first',
          );
          return;
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: endDate ?? startDate!.add(const Duration(days: 1)),
          firstDate: startDate!, // Set minimum date to start date
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => endDate = picked);
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return Helpers.buildFormField(
      title: 'Status: *',
      child: DropdownButtonFormField<String>(
        value: _statusValue,
        items: ['Active', 'Inactive']
            .map(
              (status) =>
                  DropdownMenuItem<String>(value: status, child: Text(status)),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _statusValue = value!;
          });
        },
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Helpers.buildDialogActions(
      context,
      widget.initialGroup != null,
      () async {
        // Validate form
        setState(() {
          _nameError = Validators.validateRequired(_nameController.text, 'Name') != null;
          _seasonsError = Validators.validateSeasons(selectedSeasonIds) != null;
          _financialYearError = Validators.validateRequired(selectedFinancialYearId, 'Financial Year') != null;
          _startDateError = Validators.validateStartDate(startDate) != null;
        });

        if (_nameError || _seasonsError || _financialYearError || _startDateError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newGroup = {
          'name': _nameController.text.trim(),
          'seasons': selectedSeasonIds,
          'financialYear': selectedFinancialYearId,
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'status': _statusValue,
        };

        await widget.onSave(newGroup);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialGroup == null ? 'Save to Master' : 'Update to Master',
    );
  }
}