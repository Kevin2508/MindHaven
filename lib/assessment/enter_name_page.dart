import 'package:flutter/material.dart';
import 'package:mindhaven/assessment/age.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({Key? key}) : super(key: key);

  @override
  _EnterNamePageState createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveDataAndNavigate() async {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your contact number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> profileData = {
        'id': user.id,
        'full_name': name,
        'phone_number': contact,
      };

      // Upload profile photo if selected
      if (_selectedImage != null) {
        final fileName = '${user.id}_profile.jpg';
        final bytes = await _selectedImage!.readAsBytes();
        await supabase.storage.from('profile_pictures').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        profileData['avatar_url'] = imageUrl;
      }

      await supabase.from('profiles').upsert(profileData, onConflict: 'id');
      print('Profile data stored successfully for user ${user.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data stored successfully!')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => AgePage()));
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: ${e.message}')),
      );
      print('Postgrest Exception: ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      print('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
      appBar: AppBar(
        backgroundColor: const Color(0xfff4eee0),
        elevation: 0,
        title: const Text(
          "Assessment",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF926247),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Text(
                  "Page 1 of 11",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Tell Us About Yourself",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF2E4A2E),
                        fontSize: orientation == Orientation.portrait ? 28 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    // Profile Photo
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          image: _selectedImage != null
                              ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                              : null,
                          border: Border.all(color: const Color(0xFF9BB068), width: 2),
                        ),
                        child: _selectedImage == null
                            ? const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF926247),
                          size: 40,
                        )
                            : null,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    const Text(
                      "Tap to choose profile photo",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    // Name Field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: Color(0xFF2E4A2E)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF9BB068)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF9BB068)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFF2E4A2E)),
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // Contact Number Field
                    TextField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        labelStyle: const TextStyle(color: Color(0xFF2E4A2E)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF9BB068)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF9BB068)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Color(0xFF2E4A2E)),
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    // Continue Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveDataAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF926247),
                        minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Continue ',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}