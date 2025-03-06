import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/assessment/mood_page.dart';

class GenderPage extends StatefulWidget {
  const GenderPage({Key? key}) : super(key: key);

  @override
  _GenderPageState createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  String? selectedGender;

  @override
  void initState() {
    super.initState();
  }

  Future<void> navigateToNextScreen() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save your gender.')),
        );
        return;
      }

      if (selectedGender != null) {
        print('Attempting to store gender $selectedGender for user ${user.id}');
        await supabase.from('profiles').upsert({
          'id': user.id,
          'gender': selectedGender,
        }, onConflict: 'id');

        print('Gender $selectedGender stored successfully for user ${user.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gender stored successfully!')),
        );
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MoodPage()));
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Postgrest Error: ${e.message} (Code: ${e.code}, Details: ${e.details})')),
      );
      print('Postgrest Exception: ${e.message}, Details: ${e.details}, Code: ${e.code}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      print('Unexpected error: $e');
    }
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
                  "Page 2 of 11",
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
                    "What is your gender?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: orientation == Orientation.portrait ? 24 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Column(
                    children: [
                      _buildGenderButton("I am Male", "assets/images/male.png"),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildGenderButton("I am Female", "assets/images/female.png"),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      ElevatedButton(
                        onPressed: navigateToNextScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9BB068),
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.9, MediaQuery.of(context).size.height * 0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text(
                          "Prefer to skip, thanks",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      ElevatedButton(
                        onPressed: selectedGender != null ? navigateToNextScreen : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF926247),
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.9, MediaQuery.of(context).size.height * 0.07),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
          color: selectedGender == gender
              ? const Color(0xFFC1D396)
              : const Color(0xFF9BB068),
          border: Border.all(
            color: selectedGender == gender ? const Color(0xFF9BB068) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.03,
              left: MediaQuery.of(context).size.width * 0.03,
              child: Text(
                gender,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 25,
              bottom: 12,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.17,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}