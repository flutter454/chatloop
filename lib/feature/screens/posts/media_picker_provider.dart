import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaPickerProvider extends ChangeNotifier {
  // Asset Management
  List<AssetEntity> _assets = [];
  List<AssetEntity> get assets => _assets;

  AssetPathEntity? _currentPath;
  AssetPathEntity? get currentPath => _currentPath;

  List<AssetPathEntity> _paths = [];
  List<AssetPathEntity> get paths => _paths;

  // Selection
  AssetEntity? _selectedAsset;
  AssetEntity? get selectedAsset => _selectedAsset;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 80;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Tabs
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  final List<String> _tabs = ['POST', 'STORY', 'REEL', 'LIVE'];
  List<String> get tabs => _tabs;

  MediaPickerProvider() {
    _requestPermissionAndFetch();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void selectAsset(AssetEntity asset) {
    _selectedAsset = asset;
    notifyListeners();
  }

  void setCurrentPath(AssetPathEntity path) {
    _currentPath = path;
    _fetchAssets(reset: true);
    notifyListeners();
  }

  Future<void> _requestPermissionAndFetch() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _fetchPaths();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _fetchPaths() async {
    _isLoading = true;
    notifyListeners();

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      hasAll: true,
    );

    // Filter async
    final List<AssetPathEntity> validPaths = [];
    for (final p in paths) {
      final int count = await p.assetCountAsync;
      if (count > 0) validPaths.add(p);
    }
    _paths = validPaths;

    if (_paths.isNotEmpty) {
      _currentPath = _paths.first;
      await _fetchAssets(reset: true);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchAssets({bool reset = false}) async {
    if (_currentPath == null) return;

    // If resetting, clear everything and notify immediately
    if (reset) {
      _currentPage = 0;
      _assets.clear();
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore) return;

    final List<AssetEntity> newAssets = await _currentPath!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (newAssets.isEmpty) {
      _hasMore = false;
    } else {
      _assets.addAll(newAssets);
      _currentPage++;
      // Auto-select first asset if none selected
      if (_selectedAsset == null && _assets.isNotEmpty) {
        _selectedAsset = _assets.first;
      }
    }
    notifyListeners();
  }

  Future<void> loadMoreAssets() async {
    if (!_isLoading && _hasMore) {
      _isLoading = true;
      notifyListeners();
      await _fetchAssets();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickFromCamera(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text(
              'Take Photo',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.white),
            title: const Text(
              'Record Video',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickVideo();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      debugPrint("Taken photo: ${photo.path}");
      // TODO: Handle photo
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      debugPrint("Taken video: ${video.path}");
      // TODO: Handle video
    }
  }
}
