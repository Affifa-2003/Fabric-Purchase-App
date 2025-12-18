import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

      // Ensure the box is open
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
      // Ensure the box is open
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving seasons: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterSeasons() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredSeasons = seasons.where((season) {
        return season['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddNewSeasonDialog() {
    TextEditingController nameController = TextEditingController();

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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                        'Add Season',
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
                        // Season Name Field
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
                                    'Season Name: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Summer, Winter',
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
                                  'This will be added to master and available for future orders.',
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
                                    content: Text('Season name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Create new season
                              Map<String, dynamic> newSeason = {
                                'name': nameController.text.trim(),
                              };

                              // Update local state immediately
                              setState(() {
                                // Add to the beginning of the list
                                seasons.insert(0, newSeason);
                                _filterSeasons(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveSeasonsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Season added successfully'),
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

  void _showEditSeasonDialog(Map<String, dynamic> season, int index) {
    TextEditingController nameController = TextEditingController(
      text: season['name'],
    );

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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                        'Edit Season',
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
                        // Season Name Field
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
                                    'Season Name: *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Summer, Winter',
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
                                  'This will update the season in master and all associated records.',
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
                                    content: Text('Season name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Create updated season
                              Map<String, dynamic> updatedSeason = {
                                'name': nameController.text.trim(),
                              };

                              // Update local state immediately
                              setState(() {
                                // Remove the old season
                                seasons.removeAt(index);
                                // Add the updated season at the beginning
                                seasons.insert(0, updatedSeason);
                                _filterSeasons(); // Update filtered list
                              });

                              // Save to Hive
                              await _saveSeasonsToStorage();

                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Season updated successfully'),
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
        title: const Text('Seasons'),
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
              onPressed: _showAddNewSeasonDialog,
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
                        hintText: 'Search Seasons',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Seasons list
                Expanded(
                  child: filteredSeasons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .eco_outlined, // Changed from calendar_today_outlined
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                seasons.isEmpty
                                    ? 'No seasons found'
                                    : 'No matching seasons',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                seasons.isEmpty
                                    ? 'Add seasons using the + button'
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
                          onRefresh: _loadSeasons,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredSeasons.length,
                            itemBuilder: (context, index) {
                              final season = filteredSeasons[index];

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
                                      Icons.eco, // Changed from calendar_today
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  title: Text(
                                    season['name'],
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
                                      _showDeleteConfirmationDialog(season);
                                    },
                                  ),
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
              // Check if the season is in the seasons list of this group
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: isUsedInPurchaseOrderGroups
              ? const Text(
                  'This season is already mapped with purchase order groups and cannot be deleted.',
                )
              : Text('Are you sure you want to delete "${season['name']}"?'),
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

                    Navigator.of(context).pop(); // Close dialog

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Season deleted successfully'),
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
