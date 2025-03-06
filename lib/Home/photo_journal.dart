import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindhaven/Home/home_page.dart';

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
  List<String> _photoUrls = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedMood = 'Neutral'; // Add mood selection
  final List<String> _moods = ['Sad', 'Angry', 'Neutral', 'Happy', 'Very Happy'];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions().then((_) {
        _initializeCamera();
        _loadPhotos();
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
                onPressed: () {
                  openAppSettings();
                },
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
            onPressed: () {
              openAppSettings();
            },
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
        imageFormatGroup: ImageFormatGroup.jpeg, // Explicitly set image format
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

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      print('Current user: $user');
      if (user != null) {
        final response = await supabase
            .from('photo_journal')
            .select('photo_url')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false);
        print('Photo query response: $response');
        setState(() {
          _photoUrls = (response as List).map((item) => item['photo_url'] as String).toList();
          _isLoading = false;
        });
      } else {
        print('No user logged in');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading photos: $e')),
      );
      setState(() => _isLoading = false);
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
          await supabase.storage.from('photos').uploadBinary(
            photoName,
            await file.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          final photoUrl = supabase.storage.from('photos').getPublicUrl(photoName);
          await supabase.from('photo_entries').insert({
            'user_id': user.id,
            'photo_url': photoUrl,
            'mood': _selectedMood, // Store selected mood
            'timestamp': DateTime.now().toIso8601String(),
          });
          _loadPhotos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo saved successfully')),
          );
          // Update HomePage score
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
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
      _initializeCamera(); // Reinitialize with the new camera
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHomePage();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Journal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
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
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.black, fontSize: 16),
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
            : _isCameraReady
            ? Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  CameraPreview(_controller!),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: _switchCamera,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.flip_camera_android, color: Colors.black),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: _takePhoto,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.camera, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _photoUrls.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          _photoUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        )
            : const Center(
          child: Text(
            'Camera initialization failed. Please check permissions or device.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}