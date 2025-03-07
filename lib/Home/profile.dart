import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName = 'User';
  String? profileImageUrl = 'https://via.placeholder.com/128';
  String? userEmail;
  String? phoneNumber;
  int? userAge;
  String? bio; // New bio variable
  String? joinedDate;
  int streakCount = 0;
  bool _isLoading = true;
  File? _newProfileImage;
  List<Map<String, dynamic>> _userPosts = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); // New bio controller

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserPosts();
    _calculateStreak();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await supabase
            .from('profiles')
            .select('full_name, avatar_url, age, phone_number, bio') // Added bio
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            userName = response['full_name'] ?? user.email?.split('@')[0] ?? 'User';
            profileImageUrl = response['avatar_url'] ?? 'https://via.placeholder.com/128';
            userEmail = user.email;
            phoneNumber = response['phone_number'] as String?;
            userAge = response['age'] as int?;
            bio = response['bio'] as String?; // Fetch bio
            joinedDate = user.createdAt != null
                ? DateFormat('MMM d, yyyy').format(DateTime.parse(user.createdAt!))
                : 'Unknown';
            _nameController.text = userName ?? '';
            _emailController.text = userEmail ?? '';
            _phoneController.text = phoneNumber ?? '';
            _ageController.text = userAge?.toString() ?? '';
            _bioController.text = bio ?? ''; // Initialize bio controller
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

  Future<void> _calculateStreak() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final history = await supabase
          .from('mental_score_history')
          .select('date')
          .eq('user_id', user.id);

      final uniqueDays = (history as List)
          .map((entry) => entry['date'] as String)
          .toSet()
          .length;

      if (mounted) {
        setState(() => streakCount = uniqueDays);
      }
    } catch (e) {
      if (mounted) {
        setState(() => streakCount = 0);
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final age = _ageController.text.trim();
    final bioText = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email cannot be empty')),
      );
      return;
    }
    // Check bio word count
    if (bioText.split(RegExp(r'\s+')).length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio must be 20 words or fewer')),
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

      if (email != user.email) {
        await supabase.auth.updateUser(UserAttributes(email: email));
      }

      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic> updates = {
        'full_name': name,
        'phone_number': phone.isEmpty ? null : phone,
        'age': age.isEmpty ? null : int.tryParse(age),
        'bio': bioText.isEmpty ? null : bioText, // Save bio
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
          userName = name;
          userEmail = email;
          phoneNumber = phone.isEmpty ? null : phone;
          userAge = age.isEmpty ? null : int.tryParse(age);
          bio = bioText.isEmpty ? null : bioText; // Update bio in state
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

  Future<void> _deletePost(String postId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('community_posts').delete().eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully!')),
        );
        _fetchUserPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  Future<void> _updatePost(String postId, String currentCaption) async {
    final TextEditingController captionController = TextEditingController(text: currentCaption);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Enter new caption',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final newCaption = captionController.text.trim();
                if (newCaption.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption cannot be empty')),
                  );
                  return;
                }

                try {
                  final supabase = Supabase.instance.client;
                  await supabase
                      .from('community_posts')
                      .update({'caption': newCaption})
                      .eq('id', postId);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post updated successfully!')),
                    );
                    _fetchUserPosts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating post: $e')),
                    );
                  }
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  maxLines: 1,
                  enabled: !_isLoading,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                    labelText: 'Phone Number',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLines: 1,
                  enabled: !_isLoading,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your age',
                    border: OutlineInputBorder(),
                    labelText: 'Age',
                  ),
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  enabled: !_isLoading,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your bio (max 20 words)',
                    border: OutlineInputBorder(),
                    labelText: 'Bio',
                  ),
                  maxLines: 2,
                  enabled: !_isLoading,
                  onChanged: (value) {
                    final wordCount = value.trim().split(RegExp(r'\s+')).length;
                    if (wordCount > 20) {
                      _bioController.text = value.split(' ').take(20).join(' ');
                      _bioController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _bioController.text.length),
                      );
                    }
                  },
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

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF926247), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2E4A2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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
                if (bio != null && bio!.isNotEmpty) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    bio!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userEmail != null)
                          _buildProfileDetail(Icons.email, 'Email', userEmail!),
                        if (phoneNumber != null)
                          _buildProfileDetail(Icons.phone, 'Phone', phoneNumber!),
                        if (userAge != null)
                          _buildProfileDetail(Icons.cake, 'Age', '$userAge'),
                        if (joinedDate != null)
                          _buildProfileDetail(Icons.calendar_today, 'Joined', joinedDate!),
                        _buildProfileDetail(
                          Icons.local_fire_department,
                          'Streak',
                          '$streakCount Days',
                        ),
                      ],
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
                Text(
                  "My Community Posts",
                  style: const TextStyle(
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
                      margin: const EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['caption'] ?? '',
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _updatePost(post['id'], post['caption'] ?? ''),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Post'),
                                            content: const Text('Are you sure you want to delete this post?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deletePost(post['id']);
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _bioController.dispose(); // Dispose bio controller
    super.dispose();
  }
}