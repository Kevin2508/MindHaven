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
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    print('Loading user data for user: ${user?.id}');

    if (user != null) {
      try {
        final response = await supabase
            .from('profiles')
            .select('full_name, avatar_url, age')
            .eq('id', user.id)
            .single();

        print('Loaded profile data: $response');

        if (mounted) {
          setState(() {
            userName = response['full_name'] ?? user.email?.split('@')[0] ?? 'User';
            profileImageUrl = response['avatar_url'] ?? 'https://via.placeholder.com/128';
            userAge = response['age'] as int?;
            _nameController.text = userName ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading profile data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e')),
          );
          setState(() {
            _isLoading = false;
            profileImageUrl = 'https://via.placeholder.com/128';
          });
        }
      }
    } else {
      print('No authenticated user found');
      if (mounted) {
        setState(() {
          _isLoading = false;
          profileImageUrl = 'https://via.placeholder.com/128';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
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

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update your profile')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Ensure profile exists
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      print('Existing profile check: $existingProfile');

      if (existingProfile == null) {
        // Create new profile if it doesn’t exist
        print('Creating new profile for id: ${user.id}');
        await supabase.from('profiles').insert({
          'id': user.id, // Explicitly set id
          'full_name': _nameController.text.trim(),
        });
      }

      Map<String, dynamic> updates = {
        'full_name': _nameController.text.trim(),
      };

      String? newImageUrl;
      if (_newProfileImage != null) {
        final fileName = '${user.id}_profile.jpg';
        final bytes = await _newProfileImage!.readAsBytes();
        print('Uploading image: $fileName');

        try {
          await supabase.storage.from('profile_pictures').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true, // Overwrite if exists
            ),
          );

          newImageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
          updates['avatar_url'] = newImageUrl;
          print('Image uploaded, new URL: $newImageUrl');
        } on StorageException catch (e) {
          print('Storage exception: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Storage error: ${e.message}')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update the profile
      print('Updating profile with: $updates');
      await supabase.from('profiles').update(updates).eq('id', user.id);

      if (mounted) {
        setState(() {
          userName = _nameController.text.trim();
          if (_newProfileImage != null) {
            profileImageUrl = newImageUrl ?? profileImageUrl;
          }
          _newProfileImage = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.auth.signOut();
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
                  onTap: _isLoading ? null : _pickImage,
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
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                  maxLines: 1,
                  enabled: !_isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                setState(() => _newProfileImage = null);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
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
                    onPressed: _showEditProfileDialog,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
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