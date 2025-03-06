import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindhaven/Home/new_journal_entry.dart'; // Ensure this points to the correct file

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> _journalHistory = [];
  int _totalEntries = 0;
  String _predominantEmotion = 'Neutral';

  @override
  void initState() {
    super.initState();
    _loadJournalHistory();
  }

  Future<void> _loadJournalHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final history = await supabase
            .from('journal_entries')
            .select('mood, entry, timestamp, title')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false); // Changed to descending for newest first

        setState(() {
          _journalHistory = List<Map<String, dynamic>>.from(history);

          // Count unique days with journal entries
          final uniqueDays = <String>{};
          for (var entry in _journalHistory) {
            final timestamp = DateTime.parse(entry['timestamp'] as String);
            final dateString = DateFormat('yyyy-MM-dd').format(timestamp);
            uniqueDays.add(dateString);
          }
          _totalEntries = uniqueDays.length;

          // Calculate predominant emotion
          if (_journalHistory.isNotEmpty) {
            final moodCounts = <String, int>{
              'Happy': 0,
              'Angry': 0,
              'Neutral': 0,
              'Sad': 0,
              'Very Happy': 0, // Added to match emotions list
            };

            for (var entry in _journalHistory) {
              final mood = entry['mood'] as String? ?? 'Neutral';
              moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
            }

            var maxCount = 0;
            var predominantMood = 'Neutral';

            moodCounts.forEach((mood, count) {
              if (count > maxCount) {
                maxCount = count;
                predominantMood = mood;
              }
            });

            _predominantEmotion = predominantMood;
          }
        });
      }
    } catch (e) {
      setState(() {
        _journalHistory = [];
        _totalEntries = 0;
        _predominantEmotion = 'Neutral';
      });
    }
  }

  void _addNewJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewJournalEntryPage()), // Removed const
    ).then((_) => _loadJournalHistory());
  }

  void _editJournal(Map<String, dynamic> journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewJournalEntryPage(
          isEditing: true,
          journalData: journal,
        ),
      ),
    ).then((_) => _loadJournalHistory());
  }

  String _getEmojiFromMood(String mood) {
    switch (mood) {
      case 'Happy':
        return '🙂';
      case 'Angry':
        return '😡';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😢';
      case 'Very Happy':
        return '😄';
      default:
        return '😐';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.green;
      case 'Angry':
        return Colors.orange;
      case 'Neutral':
        return Colors.grey;
      case 'Sad':
        return Colors.blue;
      case 'Very Happy':
        return Colors.green[300]!; // Lighter green for Very Happy
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Entries',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Document your Mental Journal.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Journals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _journalHistory.length,
                  itemBuilder: (context, index) {
                    final journal = _journalHistory[index];
                    final mood = journal['mood'] as String? ?? 'Neutral';
                    final entry = journal['entry'] as String? ?? '';
                    final entrySnippet = entry.isNotEmpty ? '${entry.split('\n')[0]}...' : ''; // Show only first line
                    final title = journal['title'] as String? ?? '';
                    final timestamp = DateTime.parse(journal['timestamp'] as String);
                    final date = DateFormat('dd MMM').format(timestamp).toUpperCase();

                    return GestureDetector(
                      onTap: () => _editJournal(journal),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Text(
                                _getEmojiFromMood(mood),
                                style: const TextStyle(color: Colors.white, fontSize: 34),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const SizedBox(height: 4),
                                  Text(
                                    entrySnippet,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Journal Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description, color: Colors.green, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              '$_totalEntries/365',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Completed',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingActionButton(
                  onPressed: _addNewJournal,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}