import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({Key? key}) : super(key: key);

  @override
  _EnterNamePageState createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveNameAndNavigate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
        }, onConflict: 'id');
        print('Name $name stored successfully for user ${user.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name stored successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/question1');
      }
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving name: ${e.message}')),
      );
      print('Postgrest Exception: ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      print('Unexpected error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Enter Your Name",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF2E4A2E),
                      fontSize: orientation == Orientation.portrait ? 28 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: _saveNameAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF926247),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Row(
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
            );
          },
        ),
      ),
    );
  }
}