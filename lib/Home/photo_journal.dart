import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img; // For image processing
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
  final List<String> _moods = ['Sad', 'Angry', 'Neutral', 'Happy', 'Very Happy', 'Very Sad'];
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true, // Enable facial landmarks
      enableClassification: true, // Enable smile/eye detection
    ),
  );

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
              content: Text('Camera permission required'),
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

  Future<String> _detectFacialExpression(XFile photo) async {
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('No face detected');
        return 'Neutral'; // Default mood if no face is detected
      }

      for (Face face in faces) {
        // Classification data
        final smileProb = face.smilingProbability ?? 0.0;
        final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
        final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;

        // Contour data for advanced detection
        final upperLipTop = face.contours[FaceContourType.upperLipTop]?.points;
        final upperLipBottom = face.contours[FaceContourType.upperLipBottom]?.points;
        final lowerLipTop = face.contours[FaceContourType.lowerLipTop]?.points;
        final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom]?.points;
        final leftEyebrowTop = face.contours[FaceContourType.leftEyebrowTop]?.points;
        final rightEyebrowTop = face.contours[FaceContourType.rightEyebrowTop]?.points;

        print('Debug - Smile: $smileProb, LeftEye: $leftEyeOpen, RightEye: $rightEyeOpen');

        // Approximate mouth height and width
        // Approximate mouth height and width
        // Approximate mouth height and width
        int? mouthTopY, mouthBottomY, mouthLeftX, mouthRightX;
        double? mouthHeight, mouthWidth;
        if (upperLipTop != null && lowerLipBottom != null && upperLipTop.isNotEmpty && lowerLipBottom.isNotEmpty) {
          try {
            mouthTopY = upperLipTop.map((p) => p.y).reduce((a, b) => a < b ? a : b); // Min Y
            mouthBottomY = lowerLipBottom.map((p) => p.y).reduce((a, b) => a > b ? a : b); // Max Y
            mouthLeftX = upperLipTop.map((p) => p.x).reduce((a, b) => a < b ? a : b); // Min X
            mouthRightX = lowerLipBottom.map((p) => p.x).reduce((a, b) => a > b ? a : b); // Max X
            mouthHeight = (mouthBottomY?.toDouble() ?? 0.0) - (mouthTopY?.toDouble() ?? 0.0);
            mouthWidth = (mouthRightX?.toDouble() ?? 0.0) - (mouthLeftX?.toDouble() ?? 0.0);

            print('Debug - Mouth: TopY=$mouthTopY, BottomY=$mouthBottomY, Height=$mouthHeight, Width=$mouthWidth, Ratio=${mouthWidth! / mouthHeight!}');
          } catch (e) {
            print('Error calculating mouth metrics: $e');
            // Fallback values to avoid breaking the logic
            mouthTopY = null;
            mouthBottomY = null;
            mouthLeftX = null;
            mouthRightX = null;
            mouthHeight = null;
            mouthWidth = null;
          }
        } else {
          print('Debug - Mouth contours not detected');
        }

        // Very Happy: High smile probability and wide mouth
        if (smileProb > 0.9 && mouthWidth != null && mouthHeight != null && mouthWidth / mouthHeight > 2.5) {
          print('Detected Very Happy with smile: $smileProb, mouth ratio: ${mouthWidth / mouthHeight}');
          return 'Very Happy';
        }
        // Happy: Moderate smile probability
        else if (smileProb > 0.7) {
          print('Detected Happy with smile: $smileProb');
          return 'Happy';
        }
        // Very Sad: Closed eyes and extreme mouth downturn
        else if (leftEyeOpen < 0.2 && rightEyeOpen < 0.2 && mouthBottomY != null && mouthTopY != null && mouthBottomY > mouthTopY + 6) {
          print('Detected Very Sad with eyes: $leftEyeOpen/$rightEyeOpen, mouth downturn: ${mouthBottomY - mouthTopY}');
          return 'Very Sad';
        }
        // Sad: Low smile, downturned mouth, or slight brow furrow
        else if (smileProb < 0.3 && mouthBottomY != null && mouthTopY != null && mouthBottomY > mouthTopY + 1 &&
            mouthWidth != null && mouthHeight != null && mouthWidth / mouthHeight < 1.1) {
          print('Detected Sad with smile: $smileProb, mouth downturn: ${mouthBottomY - mouthTopY}, ratio: ${mouthWidth / mouthHeight}');
          return 'Sad';
        }
        // Angry: Low smile, narrowed eyes, and slight brow furrow
        else if (smileProb < 0.3 && leftEyeOpen < 0.6 && rightEyeOpen < 0.6 &&
            leftEyebrowTop != null && rightEyebrowTop != null &&
            leftEyebrowTop.last.y - leftEyebrowTop.first.y > 3 &&
            rightEyebrowTop.last.y - rightEyebrowTop.first.y > 3) {
          print('Detected Angry with smile: $smileProb, eyes: $leftEyeOpen/$rightEyeOpen, brow diff: ${leftEyebrowTop.last.y - leftEyebrowTop.first.y}');
          return 'Angry';
        }
      }
      print('Falling back to Neutral');
      return 'Neutral';
    } catch (e) {
      print('Error detecting facial expression: $e');
      return 'Neutral'; // Fallback if detection fails
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

        // Detect facial expression
        final detectedMood = await _detectFacialExpression(photo);
        setState(() {
          _selectedMood = detectedMood;
        });
        print('Detected mood: $_selectedMood');

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
            SnackBar(content: Text('Photo saved successfully with mood: $_selectedMood')),
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
    _faceDetector.close();
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
          fit: StackFit.expand,
          children: [
            // Camera preview with proper scaling and mirroring fix
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(_isRearCamera ? 1.0 : -1.0, 1.0, 1.0), // Flip horizontally for front camera
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
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
                        child: Text(
                          'Detected Mood: $_selectedMood',
                          style: const TextStyle(
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
                  const SizedBox(width: 48),
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