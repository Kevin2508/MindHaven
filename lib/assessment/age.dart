import 'package:flutter/material.dart';
import 'package:mindhaven/assessment/gender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:mindhaven/assessment/gender.dart';

class AgePage extends StatefulWidget {
  const AgePage({Key? key}) : super(key: key);

  @override
  _AgePageState createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> {
  int _selectedAge = 18; // Default age
  final List<int> _ages = List.generate(100, (index) => index + 1); // Ages from 1 to 100
  late FixedExtentScrollController _scrollController; // Scroll controller

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _ages.indexOf(_selectedAge));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> navigateToNextScreen() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save your age.')),
        );
        return;
      }

      print('Attempting to store age $_selectedAge for user ${user.id}');
      await supabase.from('profiles').upsert({
        'id': user.id,
        'age': _selectedAge,
      }, onConflict: 'id');

      print('Age stored successfully for user ${user.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age stored successfully!')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => GenderPage())); // Changed to navigate to ProfilePicturePage
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
                    "What is your age?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: orientation == Orientation.portrait ? 24 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF9BB068), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListWheelScrollView.useDelegate(
                        controller: _scrollController,
                        itemExtent: orientation == Orientation.portrait
                            ? MediaQuery.of(context).size.height * 0.2
                            : MediaQuery.of(context).size.width * 0.2,
                        diameterRatio: 1.5,
                        perspective: 0.001,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedAge = _ages[index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final age = _ages[index];
                            final distance = (age - _selectedAge).abs();
                            final opacity = 1.0 - (distance * 0.1).clamp(0.0, 0.8);
                            final scale = 1.0 - (distance * 0.05).clamp(0.0, 0.5);
                            final isSelected = age == _selectedAge;

                            return Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: orientation == Orientation.portrait
                                    ? MediaQuery.of(context).size.height * 0.5
                                    : MediaQuery.of(context).size.width * 0.5,
                                transform: Matrix4.identity()..scale(scale),
                                decoration: isSelected
                                    ? BoxDecoration(
                                  color: const Color(0xFF9BB068).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(102),
                                )
                                    : null,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      "$age",
                                      style: TextStyle(
                                        fontSize: isSelected ? 100 : 40,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: const Color(0xFF2E4A2E),
                                        shadows: isSelected
                                            ? [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ]
                                            : [],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _ages.length,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: navigateToNextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF926247),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Continue ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}