import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/core/utils/input_formatters.dart';
import 'package:purchase_app/core/utils/validators.dart' hide NoLeadingOrMultipleSpacesFormatter;
import 'package:purchase_app/core/utils/helpers.dart';
import 'package:purchase_app/Modules/Purchase/features/layout/custom_drawer.dart';
import 'package:purchase_app/core/constants/app_constants.dart';

class SeasonPage extends StatefulWidget {
  const SeasonPage({Key? key}) : super(key: key);

  @override
  _SeasonPageState createState() => _SeasonPageState();
}

class _SeasonPageState extends State<SeasonPage> {
  List<Map<String, dynamic>> seasons = [];
  List<Map<String, dynamic>> filteredSeasons = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadSeasons();
    _searchController.addListener(_filterSeasons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    try {
      // Load data from Hive
      List<Map<String, dynamic>> hiveSeasons = [];

      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      appDataBox = Hive.box('appData');

      final seasonsData = appDataBox.get('seasons');
      if (seasonsData != null) {
        // Handle different types of data
        if (seasonsData is List) {
          hiveSeasons = seasonsData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      setState(() {
        seasons = hiveSeasons;
        filteredSeasons = List.from(seasons);
        _isLoading = false;
      });

      print('Loaded ${seasons.length} seasons from Hive');
    } catch (e) {
      print('Error loading seasons: $e');
      setState(() {
        seasons = [];
        filteredSeasons = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSeasonsToStorage() async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }

      final box = Hive.box('appData');

      // Ensure we're saving a list of maps with proper types
      List<Map<String, dynamic>> seasonsToSave = seasons.map((season) {
        return {'name': season['name']?.toString() ?? ''};
      }).toList();

      // Save data with explicit await to ensure it's written to disk
      await box.put('seasons', seasonsToSave);

      // Explicitly flush to disk
      await box.flush();

      // Verify data was saved
      print('Saved seasons: ${box.get('seasons')}');
      print('Seasons data saved successfully');
    } catch (e) {
      print('Error saving seasons data: $e');
      // Show error to user
      Helpers.showErrorSnackBar(context, 'Error saving seasons: $e');
    }
  }

  void _filterSeasons() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSeasons = List.from(seasons);
      } else {
        filteredSeasons = seasons.where((season) {
          return season['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewSeasonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SeasonDialog(
          title: 'Add Season',
          onSave: (newSeason) {
            setState(() {
              seasons.insert(0, newSeason);
              _filterSeasons();
            });
            _saveSeasonsToStorage();
            Helpers.showSuccessSnackBar(context, 'Season added successfully');
          },
        );
      },
    );
  }

  void _showEditSeasonDialog(Map<String, dynamic> season, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SeasonDialog(
          title: 'Edit Season',
          initialSeason: season,
          onSave: (updatedSeason) {
            setState(() {
              seasons.removeAt(index);
              seasons.insert(0, updatedSeason);
              _filterSeasons();
            });
            _saveSeasonsToStorage();
            Helpers.showSuccessSnackBar(context, 'Season updated successfully');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Helpers.buildScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Seasons',
      body: _isLoading
          ? Helpers.buildLoadingWidget()
          : Column(
              children: [
                Helpers.buildSearchField(
                  controller: _searchController,
                  hintText: 'Search Seasons',
                ),
                Expanded(
                  child: filteredSeasons.isEmpty
                      ? Helpers.buildEmptyState(
                          icon: Icons.eco_outlined,
                          title: seasons.isEmpty
                              ? 'No seasons found'
                              : 'No matching seasons',
                          subtitle: seasons.isEmpty
                              ? 'Add seasons using the + button'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSeasons,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredSeasons.length,
                            itemBuilder: (context, index) {
                              final season = filteredSeasons[index];
                              return Helpers.buildListItem(
                                title: season['name'],
                                icon: Icons.eco,
                                onTap: () {
                                  // Find the original index in the seasons list
                                  int originalIndex = seasons.indexWhere(
                                    (s) => s['name'] == season['name'],
                                  );
                                  if (originalIndex != -1) {
                                    _showEditSeasonDialog(
                                      season,
                                      originalIndex,
                                    );
                                  }
                                },
                                onDelete: () => _showDeleteConfirmationDialog(season),
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
            onPressed: _showAddNewSeasonDialog,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> season) {
    // Check if season is used in any purchase order groups
    bool isUsedInPurchaseOrderGroups = false;

    try {
      if (Hive.isBoxOpen('appData')) {
        final appDataBox = Hive.box('appData');
        final purchaseOrderGroupsData = appDataBox.get('purchaseOrderGroups');

        if (purchaseOrderGroupsData != null &&
            purchaseOrderGroupsData is List) {
          for (var group in purchaseOrderGroupsData) {
            if (group is Map) {
              // Check if season is in seasons list of this group
              if (group['seasons'] != null && group['seasons'] is List) {
                List<dynamic> seasonsList = group['seasons'];
                if (seasonsList.contains(season['name'])) {
                  isUsedInPurchaseOrderGroups = true;
                  break;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking if season is used: $e');
    }

    if (isUsedInPurchaseOrderGroups) {
      Helpers.showErrorSnackBar(
        context,
        'This season is already mapped with purchase order groups and cannot be deleted.',
      );
      return;
    }

    Helpers.showConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to delete "${season['name']}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        // Find the original index in the seasons list
        int originalIndex = seasons.indexWhere(
          (s) => s['name'] == season['name'],
        );
        if (originalIndex != -1) {
          // Update local state immediately
          setState(() {
            seasons.removeAt(originalIndex);
            _filterSeasons(); // Update filtered list
          });

          // Save to Hive
          await _saveSeasonsToStorage();

          // Show success message
          Helpers.showSuccessSnackBar(context, 'Season deleted successfully');
        }
      },
    );
  }
}

// Separate StatefulWidget for the dialog
class SeasonDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialSeason;
  final Function(Map<String, dynamic>) onSave;

  const SeasonDialog({
    Key? key,
    required this.title,
    this.initialSeason,
    required this.onSave,
  }) : super(key: key);

  @override
  _SeasonDialogState createState() => _SeasonDialogState();
}

class _SeasonDialogState extends State<SeasonDialog> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  
  // Error states
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialSeason?['name'] ?? '',
    );
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
          maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                    Helpers.buildInfoBox(
                      widget.initialSeason == null
                          ? 'This will be added to master and available for future orders.'
                          : 'This will update season in master and all associated records.',
                      isEditing: widget.initialSeason != null,
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
      title: 'Season Name: *',
      child: TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: InputDecoration(
          hintText: 'e.g. Summer, Winter',
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _nameError ? Colors.red : Colors.grey,
            ),
          ),
          errorText: _nameError ? 'Season name is required' : null,
        ),
        onChanged: (value) {
          setState(() {
            _nameError = Validators.validateRequired(value, 'Season Name') != null;
          });
        },
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Helpers.buildDialogActions(
      context,
      widget.initialSeason != null,
      () async {
        // Validate form
        setState(() {
          _nameError = Validators.validateRequired(_nameController.text, 'Season Name') != null;
        });

        if (_nameError) {
          return;
        }

        setState(() {
          _isSaving = true;
        });

        Map<String, dynamic> newSeason = {
          'name': _nameController.text.trim(),
        };

        await widget.onSave(newSeason);

        setState(() {
          _isSaving = false;
        });

        Navigator.pop(context);
      },
      saveText: widget.initialSeason == null ? 'Save to Master' : 'Update to Master',
    );
  }
}