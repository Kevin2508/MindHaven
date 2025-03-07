import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Map<String, dynamic>> _photoEntries = []; // Store photo URL and mood
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
            .select('photo_url, mood, id') // Include id for deletion
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .timeout(const Duration(seconds: 10));
        print('Photo query response: $response');
        setState(() {
          _photoEntries = (response as List)
              .map((item) => {
            'id': item['id'] as String,
            'photo_url': item['photo_url'] as String,
            'mood': item['mood'] as String,
          })
              .where((entry) => (entry['photo_url'] as String?)?.isNotEmpty ?? false)
              .toList();
          print('Loaded photo entries: $_photoEntries');
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

  Future<void> _deletePhoto(String id, String photoUrl) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = photoUrl.split('/').last; // Extract file name from URL
      await supabase.storage.from('photos').remove([fileName]); // Delete from storage
      await supabase.from('photo_entries').delete().eq('id', id); // Delete from table
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully')),
      );
      await _loadPhotos(); // Refresh the gallery
    } catch (e) {
      print('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: $e')),
      );
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
          : _photoEntries.isEmpty
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
        itemCount: _photoEntries.length,
        itemBuilder: (context, index) {
          final entry = _photoEntries[index];
          print('Loading image at index $index: ${entry['photo_url']}');
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: CachedNetworkImage(
                          imageUrl: entry['photo_url'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            print('Image load error at index $index: $error');
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withOpacity(0.7),
                      child: Text(
                        'Mood: ${entry['mood']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePhoto(entry['id'], entry['photo_url']),
                    tooltip: 'Delete Photo',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}