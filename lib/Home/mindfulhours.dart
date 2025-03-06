import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mindhaven/Home/exercise_page.dart';

class StressReliefPage extends StatefulWidget {
  final String audioTitle;
  final String audioFile;

  const StressReliefPage({super.key, required this.audioTitle, required this.audioFile});

  @override
  _StressReliefPageState createState() => _StressReliefPageState();
}

class _StressReliefPageState extends State<StressReliefPage> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _animationController;
  double _listenedMinutes = 0.0; // Total time listened in minutes

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _saveListenedTime(); // Save any remaining time when disposing
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
        if (_isPlaying) {
          _listenedMinutes = _position.inSeconds / 60.0; // Update listened time while playing
        }
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (!_isPlaying) {
          _saveListenedTime(); // Save time when paused or stopped
        }
      });
    });

    await _playPause(); // Start playing immediately
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(AssetSource(widget.audioFile));
      }
    } catch (e) {
      print('Error loading audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load audio file')),
      );
    }
  }

  Future<void> _saveListenedTime() async {
    if (_listenedMinutes > 0) {
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase.from('mindful_history').insert({
            'user_id': user.id,
            'activity_name': widget.audioTitle,
            'duration': _listenedMinutes,
            'activity_type': 'audio',
            'timestamp': DateTime.now().toIso8601String(),
          });
          print('Saved listened time to Supabase: $_listenedMinutes minutes');
          _listenedMinutes = 0.0; // Reset after saving
        } else {
          print('No user logged in');
        }
      } catch (e) {
        print('Error saving listened time: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _seekTo(double value) {
    final duration = _duration.inMilliseconds.toDouble();
    final position = value * duration;
    _audioPlayer.seek(Duration(milliseconds: position.toInt()));
  }

  void _rewind() {
    final newPosition = _position - const Duration(seconds: 10);
    _audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void _fastForward() {
    final newPosition = _position + const Duration(seconds: 10);
    _audioPlayer.seek(newPosition < _duration ? newPosition : _duration);
  }

  void _goToExercisePage() {
    _saveListenedTime(); // Save time before navigating
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExercisePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToExercisePage();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF9BB068),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 10 * _animationController.value),
                      child: child,
                    );
                  },
                  child: CircleAvatar(
                    radius: 120,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Image.asset(
                      'assets/images/Meditate.png',
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 200, color: Colors.red);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.audioTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎵 SOUND: ${widget.audioTitle.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _duration.inMilliseconds > 0
                      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0,
                  onChanged: _seekTo,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: _rewind,
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 60,
                      onPressed: _playPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: _fastForward,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}