import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/Home/daily_journal.dart';

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
  String _selectedEmotion = 'Neutral';
  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Sad', 'emoji': '😢', 'color': Colors.blue},
    {'name': 'Angry', 'emoji': '😡', 'color': Colors.orange},
    {'name': 'Neutral', 'emoji': '😐', 'color': Colors.grey},
    {'name': 'Happy', 'emoji': '🙂', 'color': Colors.yellow},
    {'name': 'Very Happy', 'emoji': '😄', 'color': Colors.green},
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
    super.dispose();
  }

  Future<void> _saveJournal() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null && _titleController.text.isNotEmpty && _entryController.text.isNotEmpty) {
        if (widget.isEditing && widget.journalData != null) {
          // Update existing entry
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
          // Create new entry
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
          const SnackBar(content: Text('Please fill all fields')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving journal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const JournalPage()),
                      ),
                    ),
                    Text(
                      widget.isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Journal Title',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter title here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Your Emotion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _emotions.map((emotion) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmotion = emotion['name'] as String;
                        });
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: _selectedEmotion == emotion['name']
                            ? emotion['color'].withOpacity(0.2)
                            : Colors.transparent,
                        child: Text(
                          emotion['emoji'] as String,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Write Your Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: TextField(
                    controller: _entryController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveJournal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.isEditing ? 'Update Journal' : 'Create Journal',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}