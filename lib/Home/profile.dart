import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName = 'User';
  String? profileImageUrl = 'https://via.placeholder.com/128'; // Default value set here
  int? userAge;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  File? _newProfileImage; // To hold the new profile picture temporarily

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    debugPrint('Loading user data for user: ${user?.id}'); // Debug log

    if (user != null) {
      try {
        final response = await supabase
            .from('profiles')
            .select('full_name, avatar_url, age')
            .eq('id', user.id)
            .single();

        debugPrint('Supabase response: $response'); // Debug log for response

        setState(() {
          userName = response['full_name'] ?? user.email?.split('@')[0] ?? 'User';
          profileImageUrl = response['avatar_url'] ?? 'https://via.placeholder.com/128'; // Fallback to default
          userAge = response['age'] as int?;
          _nameController.text = userName ?? ''; // Pre-fill name for editing
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error fetching profile data: $e'); // Debug log for errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        setState(() {
          _isLoading = false;
          profileImageUrl = 'https://via.placeholder.com/128'; // Ensure fallback
        });
      }
    } else {
      debugPrint('No authenticated user found'); // Debug log
      setState(() {
        _isLoading = false;
        profileImageUrl = 'https://via.placeholder.com/128'; // Ensure fallback
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path); // Store the new image temporarily
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update your profile')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare updates
      Map<String, dynamic> updates = {
        'full_name': _nameController.text.trim(),
      };

      // Handle profile picture update if a new image was selected
      if (_newProfileImage != null) {
        // Check if the bucket exists before uploading
        try {
          final bucketList = await supabase.storage.listBuckets();
          final bucketExists = bucketList.any((bucket) => bucket.name.toLowerCase() == 'profile_pictures'.toLowerCase());
          if (!bucketExists) {
            throw Exception('Bucket "profile_pictures" not found in Supabase Storage');
          }

          // Upload new image to Supabase Storage
          final fileName = '${user.id}_profile.jpg';
          final bytes = await _newProfileImage!.readAsBytes();
          await supabase.storage.from('profile_pictures').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

          // Get the public URL of the uploaded image
          final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
          updates['avatar_url'] = imageUrl;
        } catch (e) {
          debugPrint('Error with bucket or upload: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading profile picture: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update the user's profile in the profiles table
      await supabase.from('profiles').update(updates).eq('id', user.id);

      // Update local state
      setState(() {
        userName = _nameController.text.trim();
        if (_newProfileImage != null) {
          profileImageUrl = updates['avatar_url'];
        }
        _newProfileImage = null; // Clear the temporary image after updating
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context); // Close the dialog
    } catch (e) {
      debugPrint('Error updating profile: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    debugPrint('Showing Edit Profile Dialog - isLoading: $_isLoading, userName: $userName, profileImageUrl: $profileImageUrl'); // Debug log
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _newProfileImage != null
                        ? FileImage(_newProfileImage!) as ImageProvider
                        : NetworkImage(profileImageUrl!),
                    child: _newProfileImage == null && !_isLoading
                        ? const Icon(Icons.edit, color: Colors.grey)
                        : null,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _newProfileImage = null; // Reset new image if canceled
                });
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ProfilePage - isLoading: $_isLoading, userName: $userName, profileImageUrl: $profileImageUrl'); // Debug print
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0), // Match HomePage background
      appBar: AppBar(
        backgroundColor: const Color(0xfff4eee0),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : OrientationBuilder(
          builder: (context, orientation) {
            debugPrint('Orientation: $orientation'); // Debug print
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: orientation == Orientation.portrait
                        ? MediaQuery.of(context).size.width * 0.15
                        : MediaQuery.of(context).size.height * 0.15,
                    backgroundImage: NetworkImage(profileImageUrl!),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    userName!,
                    style: TextStyle(
                      fontSize: orientation == Orientation.portrait ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E4A2E),
                    ),
                  ),
                  if (userAge != null)
                    Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                      child: Text(
                        'Age: $userAge',
                        style: TextStyle(
                          fontSize: orientation == Orientation.portrait ? 16 : 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Edit Profile button pressed'); // Debug print
                      _showEditProfileDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF926247),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}