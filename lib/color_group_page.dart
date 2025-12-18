import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchase_app/utils/input_formatters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ColorGroupPage extends StatefulWidget {
  const ColorGroupPage({Key? key}) : super(key: key);

  @override
  _ColorGroupPageState createState() => _ColorGroupPageState();
}

class _ColorGroupPageState extends State<ColorGroupPage> {
  List<Map<String, dynamic>> colorGroups = [];
  List<Map<String, dynamic>> filteredColorGroups = [];
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  late Box appDataBox;
  TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadColorGroups();
    _loadProducts();
    _searchController.addListener(_filterColorGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColorGroups() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      appDataBox = Hive.box('appData');

      final colorGroupsData = appDataBox.get('colorGroups');
      List<Map<String, dynamic>> hiveColorGroups = [];
      if (colorGroupsData != null && colorGroupsData is List) {
        hiveColorGroups = colorGroupsData.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }

      setState(() {
        colorGroups = hiveColorGroups;
        filteredColorGroups = List.from(colorGroups);
        _isLoading = false;
      });
      print('Loaded ${colorGroups.length} color groups from Hive');
    } catch (e) {
      print('Error loading color groups: $e');
      setState(() {
        colorGroups = [];
        filteredColorGroups = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      appDataBox = Hive.box('appData');

      final productsData = appDataBox.get('products');
      List<Map<String, dynamic>> hiveProducts = [];
      if (productsData != null && productsData is List) {
        hiveProducts = productsData.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }

      setState(() {
        products = hiveProducts
            .where((product) => product['status'] == 'Active')
            .toList();
      });
      print('Loaded ${products.length} active products from Hive');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
      });
    }
  }

  Future<void> _saveColorGroupsToStorage() async {
    try {
      if (!Hive.isBoxOpen('appData')) {
        await Hive.openBox('appData');
      }
      final box = Hive.box('appData');

      List<Map<String, dynamic>> colorGroupsToSave = colorGroups.map((group) {
        return {
          'name': group['name']?.toString() ?? '',
          'photos': group['photos'] is List
              ? List<String>.from(group['photos'])
              : [],
          'productName': group['productName']?.toString() ?? '',
          'description': group['description']?.toString() ?? '',
          'status': group['status']?.toString() ?? 'Active',
        };
      }).toList();

      await box.put('colorGroups', colorGroupsToSave);
      await box.flush();
      print('Color groups data saved successfully');
    } catch (e) {
      print('Error saving color groups data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving color groups: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterColorGroups() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredColorGroups = List.from(colorGroups);
      } else {
        filteredColorGroups = colorGroups.where((group) {
          final groupName = group['name']?.toString().toLowerCase() ?? '';
          final productName =
              group['productName']?.toString().toLowerCase() ?? '';
          return groupName.contains(query) || productName.contains(query);
        }).toList();
      }
    });
  }

  void _showAddNewColorGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ColorGroupDialog(
          title: 'Add Color Group',
          onSave: (newGroup) {
            setState(() {
              colorGroups.insert(0, newGroup);
              _filterColorGroups();
            });
            _saveColorGroupsToStorage();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Color Group added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          products: products,
        );
      },
    );
  }

  void _showEditColorGroupDialog(Map<String, dynamic> group, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return ColorGroupDialog(
          title: 'Edit Color Group',
          initialGroup: group,
          onSave: (updatedGroup) {
            setState(() {
              colorGroups.removeAt(index);
              colorGroups.insert(0, updatedGroup);
              _filterColorGroups();
            });
            _saveColorGroupsToStorage();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Color Group updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          products: products,
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
        title: const Text('Color Groups'),
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
              onPressed: _showAddNewColorGroupDialog,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Search Color Groups',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredColorGroups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.color_lens_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                colorGroups.isEmpty
                                    ? 'No color groups found'
                                    : 'No matching color groups',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                colorGroups.isEmpty
                                    ? 'Add color groups using the + button'
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
                          onRefresh: _loadColorGroups,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: filteredColorGroups.length,
                            itemBuilder: (context, index) {
                              final group = filteredColorGroups[index];
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
                                      Icons.color_lens,
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
                                    'Product: ${group['productName']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
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
                                  onTap: () {
                                    int originalIndex = colorGroups.indexWhere(
                                      (g) => g['name'] == group['name'],
                                    );
                                    if (originalIndex != -1) {
                                      _showEditColorGroupDialog(
                                        group,
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${group['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                int originalIndex = colorGroups.indexWhere(
                  (g) => g['name'] == group['name'],
                );
                if (originalIndex != -1) {
                  setState(() {
                    colorGroups.removeAt(originalIndex);
                    _filterColorGroups();
                  });
                  await _saveColorGroupsToStorage();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Color Group deleted successfully'),
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

// Separate StatefulWidget for the dialog
class ColorGroupDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialGroup;
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onSave;

  const ColorGroupDialog({
    Key? key,
    required this.title,
    this.initialGroup,
    required this.products,
    required this.onSave,
  }) : super(key: key);

  @override
  _ColorGroupDialogState createState() => _ColorGroupDialogState();
}

class _ColorGroupDialogState extends State<ColorGroupDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<XFile> _selectedPhotos = [];
  String? _selectedProduct;
  String _statusValue = 'Active';

  // Photo capture state variables (from textile_details.dart)
  bool _isCapturingMultiple = false;
  List<XFile> _pendingPhotos = [];
  bool _isProcessingPhotos = false;

  // Full screen photo preview state
  int? _previewPhotoIndex;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialGroup?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialGroup?['description'] ?? '',
    );

    // Load existing photos from file paths if editing
    if (widget.initialGroup?['photos'] != null) {
      _loadPhotosFromPaths(
        List<String>.from(widget.initialGroup?['photos'] ?? []),
      );
    }

    _selectedProduct = widget.initialGroup?['productName'];
    _statusValue = widget.initialGroup?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Method to load photos from permanent file paths when editing
  Future<void> _loadPhotosFromPaths(List<String> photoPaths) async {
    List<XFile> photos = [];
    for (String filePath in photoPaths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          photos.add(XFile(filePath));
        } else {
          print('File not found: $filePath');
        }
      } catch (e) {
        print('Error loading photo from path: $e');
      }
    }
    setState(() {
      _selectedPhotos = photos;
    });
  }

  // UPDATED: Method to save an image to device storage and return its permanent path
  // This is now exactly the same as in textile_details.dart
  Future<String> _saveImageToDevice(XFile image) async {
    try {
      Directory? directory;
      String location = "";

      // --- Platform-specific logic to determine the save directory ---
      if (Platform.isIOS) {
        // For iOS, use the app's private documents directory.
        // This is the standard and recommended location for app-specific files.
        final appDirectory = await getApplicationDocumentsDirectory();
        directory = Directory(
          '${appDirectory.path}/ColorGroups',
        ); // Changed to ColorGroups
        location = "App Documents";
        print("iOS detected. Saving to app's documents directory.");
      } else if (Platform.isAndroid) {
        // For Android, use the existing logic to save to the Downloads directory.
        try {
          // For Android 10 and above
          directory = Directory('/storage/emulated/0/Download');

          if (await directory.exists()) {
            location = "Download Directory";
          }
        } catch (e) {
          print("Error accessing primary Download directory on Android: $e");
        }

        // If the primary directory doesn't exist or is not accessible, try an alternative path.
        if (directory == null || !await directory.exists()) {
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              directory = Directory('${externalDir.path}/Download');
              if (await directory.exists()) {
                location = "Download Directory";
              }
            }
          } catch (e) {
            print(
              "Error accessing alternative Download directory on Android: $e",
            );
          }
        }
      }

      // --- Fallback for all platforms if the above fails ---
      if (directory == null || !await directory.exists()) {
        print("Using fallback directory: App Documents");
        final appDirectory = await getApplicationDocumentsDirectory();
        directory = Directory(
          '${appDirectory.path}/ColorGroups',
        ); // Changed to ColorGroups
        location = "App Documents";
      }

      // Create the directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // --- The rest of the logic remains UNCHANGED ---
      // Check if the image is already saved to avoid duplicates
      final List<FileSystemEntity> files = await directory.list().toList();
      for (var file in files) {
        if (file is File &&
            path.basename(file.path).startsWith('ColorGroup_')) {
          // Changed prefix
          // Compare file sizes to check if it's the same image
          final int savedFileSize = await file.length();
          final int newFileSize = await image.length();

          if (savedFileSize == newFileSize) {
            // It's likely the same image, return the existing path
            print("Image already exists in $location: ${file.path}");
            return file.path;
          }
        }
      }

      // Generate a unique filename using timestamp and app identifier
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'ColorGroup_$timestamp.jpg'; // Changed prefix
      final String filePath = path.join(directory.path, fileName);

      // Save the image file
      await image.saveTo(filePath);

      print("Image saved to $location: $filePath");
      return filePath;
    } catch (e) {
      print('Error saving image to device: $e');
      rethrow;
    }
  }

  // Converts XFile list to a list of permanent file paths for saving
  Future<List<String>> _convertPhotosToPaths() async {
    List<String> photoPaths = [];

    for (XFile photo in _selectedPhotos) {
      if (photo.path.contains('ColorGroup_')) {
        photoPaths.add(photo.path);
      } else {
        String filePath = await _saveImageToDevice(photo);
        photoPaths.add(filePath);
      }
    }

    return photoPaths;
  }

  // --- START: Photo Capture Logic from textile_details.dart ---

  // Add this new method to handle multiple photo capture
  Future<void> _captureMultiplePhotos() async {
    try {
      while (_isCapturingMultiple) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );

        if (pickedFile != null) {
          setState(() {
            _pendingPhotos.add(pickedFile);
            _isProcessingPhotos = true;
          });

          // Process photo in background
          await _processPendingPhoto(pickedFile);
        } else {
          // User cancelled or closed camera
          setState(() {
            _isCapturingMultiple = false;
          });
          break;
        }
      }
    } catch (e) {
      print('Error capturing photos: $e');
      setState(() {
        _isCapturingMultiple = false;
        _isProcessingPhotos = false;
      });
    }
  }

  // Add this method to process pending photos
  Future<void> _processPendingPhoto(XFile photo) async {
    try {
      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _selectedPhotos.add(photo);
        _pendingPhotos.remove(photo);

        if (_pendingPhotos.isEmpty) {
          _isProcessingPhotos = false;
        }
      });
    } catch (e) {
      print('Error processing photo: $e');
      setState(() {
        _pendingPhotos.remove(photo);
        if (_pendingPhotos.isEmpty) {
          _isProcessingPhotos = false;
        }
      });
    }
  }

  Widget _buildEmptyCaptureArea() {
    return InkWell(
      onTap: () async {
        setState(() {
          _isCapturingMultiple = true;
          _pendingPhotos.clear();
        });
        await _captureMultiplePhotos();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF9FAFB),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4F46E5), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to Capture Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to capture photos',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // --- END: Photo Capture Logic from textile_details.dart ---

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
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(),
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildPhotoField(),
                        const SizedBox(height: 16),
                        _buildProductDropdown(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildStatusDropdown(),
                        const SizedBox(height: 16),
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                _buildDialogButtons(),
              ],
            ),
            // Full screen preview overlay
            if (_previewPhotoIndex != null) _buildFullScreenPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
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
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Color(0xFF767676)),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return _buildFieldContainer(
      'Color Group Name: *',
      TextField(
        controller: _nameController,
        inputFormatters: [NoLeadingOrMultipleSpacesFormatter()],
        decoration: const InputDecoration(
          hintText: 'e.g. Warm Colors',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPhotoField() {
    return _buildFieldContainer(
      'Photos:',
      Column(
        children: [
          const SizedBox(height: 12),

          // Photo capture area
          if (_selectedPhotos.isEmpty && _pendingPhotos.isEmpty)
            _buildEmptyCaptureArea()
          else
            _buildPhotoGrid(),

          const SizedBox(height: 12),

          // Capture button
          InkWell(
            onTap: () async {
              setState(() {
                _isCapturingMultiple = true;
                _pendingPhotos.clear();
              });
              await _captureMultiplePhotos();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4F46E5), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Capture Photos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final allPhotos = [..._selectedPhotos, ..._pendingPhotos];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allPhotos.length,
        itemBuilder: (context, index) {
          final isPending = index >= _selectedPhotos.length;
          return GestureDetector(
            onTap: isPending
                ? null
                : () {
                    setState(() {
                      _previewPhotoIndex = index;
                    });
                  },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 2),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      color: Colors.grey[200],
                      child: isPending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            )
                          : Image.file(
                              File(allPhotos[index].path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  if (isPending)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  // REMOVED THE RED DELETE ICON HERE
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullScreenPreview() {
    if (_previewPhotoIndex == null || _selectedPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _previewPhotoIndex = null;
        });
        return false;
      },
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black)),
          Positioned.fill(
            top: 0,
            bottom: 100,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3,
              child: Center(
                child: Image.file(
                  File(_selectedPhotos[_previewPhotoIndex!].path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _previewPhotoIndex = null),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_previewPhotoIndex! + 1} / ${_selectedPhotos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _showDeleteConfirmationDialog(_previewPhotoIndex!),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                itemCount: _selectedPhotos.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _previewPhotoIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _previewPhotoIndex = index),
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(_selectedPhotos[index].path),
                          fit: BoxFit.cover,
                        ),
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

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Photo'),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPhotos.removeAt(index);
                  if (_previewPhotoIndex! >= _selectedPhotos.length) {
                    _previewPhotoIndex = _selectedPhotos.length - 1;
                  }
                  if (_selectedPhotos.isEmpty) {
                    _previewPhotoIndex = null;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductDropdown() {
    return _buildFieldContainer(
      'Product: *',
      DropdownButtonFormField<String>(
        value: _selectedProduct,
        hint: const Text('Select a product'),
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: widget.products.isEmpty
            ? []
            : widget.products
                  .map(
                    (product) => DropdownMenuItem<String>(
                      value: product['name'],
                      child: Text(product['name']),
                    ),
                  )
                  .toList(),
        onChanged: widget.products.isEmpty
            ? null
            : (value) {
                setState(() {
                  _selectedProduct = value;
                });
              },
        disabledHint: const Text('No products available'),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _buildFieldContainer(
      'Description:',
      TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Optional description',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildFieldContainer(
      'Status: *',
      DropdownButtonFormField<String>(
        value: _statusValue,
        decoration: const InputDecoration(border: OutlineInputBorder()),
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
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3182CE)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF3182CE)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.initialGroup == null
                  ? 'This will be added to master and available for future orders.'
                  : 'This will update color group in master and all associated records.',
              style: const TextStyle(color: Color(0xFF3182CE)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              'Cancel',
              const Color(0xFF2563EB),
              () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildButton(
              widget.initialGroup == null
                  ? 'Save to Master'
                  : 'Update to Master',
              const Color(0xFF10B981),
              () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Color Group name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_selectedProduct == null || _selectedProduct!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                List<String> photoPaths = await _convertPhotosToPaths();

                Map<String, dynamic> newGroup = {
                  'name': _nameController.text.trim(),
                  'photos': photoPaths,
                  'productName': _selectedProduct,
                  'description': _descriptionController.text.trim(),
                  'status': _statusValue,
                };

                widget.onSave(newGroup);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return Container(
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
  }

  Widget _buildFieldContainer(String label, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
