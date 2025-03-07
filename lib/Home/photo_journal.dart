import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'gallery_page.dart';

class PhotoJournalPage extends StatefulWidget {
  const PhotoJournalPage({super.key});

  @override
  _PhotoJournalPageState createState() => _PhotoJournalPageState();
}

class _PhotoJournalPageState extends State<PhotoJournalPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isRearCamera = true;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedMood = 'Neutral';
  final List<String> _moods = ['Sad', 'Angry', 'Neutral', 'Happy', 'Very Happy'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions().then((_) {
        _initializeCamera();
      });
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    print('Checking camera permissions...');
    var status = await Permission.camera.status;
    print('Initial camera permission status: $status');
    if (!status.isGranted && !status.isPermanentlyDenied) {
      status = await Permission.camera.request();
      print('Requested camera permission result: $status');
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Camera permission permanently denied. Please enable it in app settings.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Camera permission denied. Please allow access.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied. Please allow access.')),
          );
        }
        return;
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Camera permission permanently denied. Please enable it in app settings.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission permanently denied'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }
  }

  Future<void> _initializeCamera() async {
    if (_errorMessage != null) return;
    setState(() => _isLoading = true);
    print('Initializing camera...');

    try {
      _cameras = await availableCameras();
      print('Number of cameras detected: ${_cameras.length}');
      if (_cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No cameras available on this device. Please use a device with a camera.';
        });
        return;
      }

      _controller = CameraController(
        _cameras[_isRearCamera ? 0 : 1],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      print('Camera initialized successfully: ${_controller!.value.isInitialized}');
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Camera initialization failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (_controller != null && _controller!.value.isInitialized) {
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      try {
        final XFile photo = await _controller!.takePicture();
        final file = File(filePath);
        await file.writeAsBytes(await photo.readAsBytes());

        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          final photoName = 'photo_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          print('Uploading photo: $photoName');

          final bucketList = await supabase.storage.listBuckets();
          final bucketExists = bucketList.any((bucket) => bucket.name == 'photos');
          if (!bucketExists) {
            throw Exception('Bucket "photos" not found in Supabase Storage');
          }

          await supabase.storage.from('photos').uploadBinary(
            photoName,
            await file.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

          final photoUrl = supabase.storage.from('photos').getPublicUrl(photoName);
          print('Generated photo URL: $photoUrl');

          final photoEntry = {
            'user_id': user.id,
            'photo_url': photoUrl,
            'mood': _selectedMood,
            'timestamp': DateTime.now().toIso8601String(),
          };
          print('Inserting into photo_entries: $photoEntry');

          await supabase.from('photo_entries').insert(photoEntry).timeout(const Duration(seconds: 10));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo saved successfully')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GalleryPage()),
          );
        }
      } catch (e) {
        print('Error taking photo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      setState(() {
        _isRearCamera = !_isRearCamera;
      });
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _goToGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GalleryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHomePage();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _checkAndRequestPermissions().then((_) => _initializeCamera());
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        )
            : _isCameraReady && _controller != null
            ? Stack(
          fit: StackFit.expand, // Ensure Stack fills the screen
          children: [
            // Camera preview with proper scaling
            Center(
              child: FittedBox(
                fit: BoxFit.cover, // Cover the screen while maintaining aspect ratio
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
            // Top bar with mood and gallery button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withOpacity(0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Today MOOD: HAPPY',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _goToGallery,
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        tooltip: 'View Gallery',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom bar with camera controls
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(Icons.flip_camera_android, color: Colors.black),
                    tooltip: 'Switch Camera',
                  ),
                  FloatingActionButton(
                    onPressed: _takePhoto,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(Icons.camera, color: Colors.black),
                    tooltip: 'Take Photo',
                  ),
                  const SizedBox(width: 48), // Placeholder for symmetry
                ],
              ),
            ),
          ],
        )
            : const Center(
          child: Text(
            'Camera initialization failed. Please check permissions or device.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}