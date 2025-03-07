import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add to pubspec.yaml
import 'home_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> _photoUrls = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      print('Current user: $user');
      if (user != null) {
        final response = await supabase
            .from('photo_entries')
            .select('photo_url')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .timeout(const Duration(seconds: 10));
        print('Photo query response: $response');
        setState(() {
          _photoUrls = (response as List)
              .map((item) => item['photo_url'] as String)
              .where((url) => url.isNotEmpty)
              .toList();
          print('Loaded photo URLs: $_photoUrls');
          _isLoading = false;
        });
      } else {
        print('No user logged in');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view your photo journal.';
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading photos: $e. Retrying...')),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _loadPhotos();
      setState(() => _isLoading = false);
    }
  }

  void _goToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goToHomePage,
        ),
        title: const Text(
          'Photo Journal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : _photoUrls.isEmpty
          ? const Center(
        child: Text(
          'No photos yet. Start capturing your moments!',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _photoUrls.length,
        itemBuilder: (context, index) {
          print('Loading image at index $index: ${_photoUrls[index]}');
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: _photoUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  print('Image load error at index $index: $error');
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}