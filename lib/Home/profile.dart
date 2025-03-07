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
  File? _newProfileImage;
  List<Map<String, dynamic>> _userPosts = [];

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserPosts();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await supabase
            .from('profiles')
            .select('full_name, avatar_url, age')
            .eq('id', user.id)
            .single();

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
      if (mounted) {
        setState(() {
          _isLoading = false;
          profileImageUrl = 'https://via.placeholder.com/128';
        });
      }
    }
  }

  Future<void> _fetchUserPosts() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await supabase
            .from('community_posts')
            .select('id, image_url, caption, created_at')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _userPosts = List<Map<String, dynamic>>.from(response);
          });
        }
      } catch (e) {
        print('Error fetching user posts: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching posts: $e')),
          );
        }
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

      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic> updates = {
        'full_name': _nameController.text.trim(),
      };

      String? newImageUrl;
      if (_newProfileImage != null) {
        final fileName = '${user.id}_profile.jpg';
        final bytes = await _newProfileImage!.readAsBytes();
        await supabase.storage.from('profile_pictures').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

        newImageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        updates['avatar_url'] = newImageUrl;
      }

      if (existingProfile == null) {
        updates['id'] = user.id;
        await supabase.from('profiles').insert(updates);
      } else {
        await supabase.from('profiles').update(updates).eq('id', user.id);
      }

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
                    Navigator.pop(context);
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
            : SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large adjustable profile picture
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      profileImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.person, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  userName!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4A2E),
                  ),
                ),
                if (userAge != null)
                  Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                    child: Text(
                      'Age: $userAge',
                      style: const TextStyle(
                        fontSize: 16,
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
                // User's Community Posts
                Text(
                  "My Community Posts",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4A2E),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                _userPosts.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No posts yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userPosts.length,
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              post['image_url'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Text('Image not available')),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              post['caption'] ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                // Logout Button
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
          ),
        ),
      ),
    );
  }
}