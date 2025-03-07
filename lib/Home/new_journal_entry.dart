import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/Home/daily_journal.dart'; // Replace with your actual import

class NewJournalEntryPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? journalData;

  const NewJournalEntryPage({
    super.key,
    this.isEditing = false,
    this.journalData,
  });

  @override
  _NewJournalEntryPageState createState() => _NewJournalEntryPageState();
}

class _NewJournalEntryPageState extends State<NewJournalEntryPage> {
  final _titleController = TextEditingController();
  final _entryController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _entryFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String _selectedEmotion = 'Neutral';
  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Sad', 'emoji': '😢', 'color': Colors.blueAccent},
    {'name': 'Angry', 'emoji': '😡', 'color': Colors.orangeAccent},
    {'name': 'Neutral', 'emoji': '😐', 'color': Colors.grey},
    {'name': 'Happy', 'emoji': '🙂', 'color': Colors.yellowAccent},
    {'name': 'Very Happy', 'emoji': '😄', 'color': Colors.greenAccent},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.journalData != null) {
      _titleController.text = widget.journalData!['title']?.toString() ?? '';
      _entryController.text = widget.journalData!['entry']?.toString() ?? '';
      _selectedEmotion = widget.journalData!['mood']?.toString() ?? 'Neutral';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _entryController.dispose();
    _titleFocusNode.dispose();
    _entryFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null && _titleController.text.isNotEmpty && _entryController.text.isNotEmpty) {
        if (widget.isEditing && widget.journalData != null) {
          await supabase
              .from('journal_entries')
              .update({
            'mood': _selectedEmotion,
            'title': _titleController.text,
            'entry': _entryController.text,
            'timestamp': DateTime.now().toIso8601String(),
          })
              .eq('id', widget.journalData!['id']);
        } else {
          await supabase.from('journal_entries').insert({
            'user_id': user.id,
            'mood': _selectedEmotion,
            'title': _titleController.text,
            'entry': _entryController.text,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const JournalPage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving journal: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xfff4eee0),
              Color(0xffe0d8c8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded, color: Color(0xff5e3e2b), size: 20),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const JournalPage()),
                        ),
                        splashRadius: 24,
                        tooltip: 'Back to Journal',
                      ),
                      Text(
                        widget.isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff5e3e2b),
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Title Input
                  Text(
                    'Journal Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff5e3e2b),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter title here',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onTap: () {
                        _titleFocusNode.requestFocus();
                        _scrollController.animateTo(
                          0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  // Emotion Selection
                  Text(
                    'How Are You Feeling?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff5e3e2b),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _emotions.map((emotion) {
                      final isSelected = _selectedEmotion == emotion['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmotion = emotion['name'] as String;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(isSelected ? 8 : 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (emotion['color'] as Color).withOpacity(0.2)
                                : Colors.transparent,
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: (emotion['color'] as Color).withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                                : [],
                          ),
                          child: Text(
                            emotion['emoji'] as String,
                            style: TextStyle(fontSize: isSelected ? 36 : 30),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  // Entry Input
                  Text(
                    'Your Thoughts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff5e3e2b),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _entryController,
                      focusNode: _entryFocusNode,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onTap: () {
                        _entryFocusNode.requestFocus();
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveJournal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff5e3e2b),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black38,
                      ),
                      child: Text(
                        widget.isEditing ? 'Update Journal' : 'Save Journal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}