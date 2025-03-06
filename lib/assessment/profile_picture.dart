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
  String? profileImageUrl = 'https://via.placeholder.com/128';
  int? userAge;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url, age')
          .eq('id', user.id)
          .single()
          .catchError((e) {
        print('Error fetching profile: $e');
        return null;
      });

      setState(() {
        userName = response?['full_name'] ?? user.email?.split('@')[0] ?? 'User';
        profileImageUrl = response?['avatar_url'] ?? 'https://via.placeholder.com/128';
        userAge = response?['age'] as int?;
        _nameController.text = userName ?? ''; // Pre-fill name for editing
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _uploadNewProfilePicture(File(pickedFile.path));
      });
    }
  }

  Future<void> _uploadNewProfilePicture(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update your profile picture')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload new image to Supabase Storage
      final fileName = '${user.id}_profile.jpg';
      final bytes = await imageFile.readAsBytes();
      await supabase.storage.from('profile_pictures').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      // Get the public URL of the uploaded image
      final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);

      // Update the user's profile in the profiles table with the new image URL
      await supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      setState(() {
        profileImageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      print('Error uploading new profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
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

      // Update the user's profile in the profiles table with the new name
      await supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
      }).eq('id', user.id);

      setState(() {
        userName = _nameController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context); // Close the dialog
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
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
                    backgroundImage: _isLoading
                        ? const AssetImage('assets/images/loading.gif') as ImageProvider
                        : NetworkImage(profileImageUrl!),
                    child: _isLoading ? null : const Icon(Icons.edit, color: Colors.grey),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Save'),
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
                        fontSize: 16,
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