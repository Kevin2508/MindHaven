import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';

class CommunityPage extends StatefulWidget {
  final String? theme;

  const CommunityPage({super.key, this.theme});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String? userName = 'User';
  String? profileImageUrl = 'https://via.placeholder.com/64';
  File? _selectedImage;
  String _caption = '';
  final _captionController = TextEditingController();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  List<String> _uniqueHashtags = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPosts();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xfff4eee0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Create Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff5e3e2b),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(image.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
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
                      controller: _captionController,
                      decoration: InputDecoration(
                        hintText: 'Write a caption...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      maxLines: 3,
                      onChanged: (value) => _caption = value,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Color(0xff5e3e2b))),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  _uploadPost();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff5e3e2b),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Post', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  Future _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single()
          .catchError((e) {
        print('Error fetching profile: $e');
        return null;
      });

      setState(() {
        userName = response?['full_name']?.split(' ')?.first ?? user.email?.split('@')[0] ?? 'User';
        profileImageUrl = response?['avatar_url'] ?? 'https://via.placeholder.com/64';
      });
    }
  }

  Future _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('community_posts')
          .select('id, user_id, image_url, caption, upvotes, downvotes, created_at')
          .order('upvotes', ascending: false);

      Set<String> uniqueHashtags = {};

      final postsWithVotes = await Future.wait(response.map((post) async {
        String createdAt = post['created_at']?.toString() ?? DateTime.now().toIso8601String();
        String? userVote;

        if (user != null) {
          final voteResponse = await supabase
              .from('user_votes')
              .select('vote_type')
              .eq('user_id', user.id)
              .eq('post_id', post['id'])
              .maybeSingle();
          userVote = voteResponse?['vote_type'] as String?;
        }

        List<String> hashtags = _extractHashtags(post['caption'] ?? '');
        hashtags.forEach((hashtag) => uniqueHashtags.add(hashtag.toLowerCase()));

        return {
          'id': post['id'],
          'user_id': post['user_id'],
          'image_url': post['image_url'],
          'caption': post['caption'] ?? '',
          'upvotes': (post['upvotes'] ?? 0) as int,
          'downvotes': (post['downvotes'] ?? 0) as int,
          'created_at': createdAt,
          'userVote': userVote,
          'hashtags': hashtags,
        };
      }));

      setState(() {
        _posts = postsWithVotes;
        _uniqueHashtags = uniqueHashtags.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
      setState(() => _isLoading = false);
    }
  }

  List<String> _extractHashtags(String caption) {
    List<String> hashtags = [];
    RegExp regExp = RegExp(r'#\w+');
    Iterable<Match> matches = regExp.allMatches(caption);
    for (Match match in matches) {
      hashtags.add(match.group(0)!);
    }
    return hashtags;
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('profiles').select('full_name').eq('id', userId).single();
      return response['full_name'] ?? 'Anonymous';
    } catch (e) {
      return 'Anonymous';
    }
  }

  Future<String?> _getUserProfileImage(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('profiles').select('avatar_url').eq('id', userId).single();
      return response['avatar_url'] ?? 'https://via.placeholder.com/64';
    } catch (e) {
      return 'https://via.placeholder.com/64';
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to post')));
        return;
      }

      final fileName = '${DateTime.now().toIso8601String()}_${user.id}.jpg';
      final bytes = await _selectedImage!.readAsBytes();
      await supabase.storage.from('community_images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = supabase.storage.from('community_images').getPublicUrl(fileName);

      await supabase.from('community_posts').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'caption': _caption,
        'upvotes': 0,
        'downvotes': 0,
      });

      setState(() {
        _selectedImage = null;
        _caption = '';
        _captionController.clear();
      });

      Navigator.pop(context);
      await _fetchPosts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post uploaded successfully!')));
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading post: $e')));
    }
  }

  Future<void> _votePost(String postId, bool isUpvote) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to vote.')));
        return;
      }

      final postIdNum = int.tryParse(postId) ?? 0;
      if (postIdNum == 0) return;

      final existingVote = await supabase
          .from('user_votes')
          .select('vote_type')
          .eq('user_id', user.id)
          .eq('post_id', postIdNum)
          .single()
          .then((value) => value as Map<String, dynamic>?)
          .catchError((e) => null);

      final postResponse = await supabase
          .from('community_posts')
          .select('upvotes, downvotes')
          .eq('id', postIdNum)
          .single()
          .catchError((e) => null) as Map<String, dynamic>?;

      if (postResponse == null) return;

      int currentUpvotes = postResponse['upvotes'] as int? ?? 0;
      int currentDownvotes = postResponse['downvotes'] as int? ?? 0;

      if (existingVote != null) {
        String? currentVoteType = existingVote['vote_type'] as String?;
        if (currentVoteType == 'upvote' && !isUpvote) {
          currentUpvotes -= 1;
          currentDownvotes += 1;
          await supabase.from('user_votes').update({'vote_type': 'downvote'}).eq('user_id', user.id).eq('post_id', postIdNum);
          await supabase.from('community_posts').update({'upvotes': currentUpvotes, 'downvotes': currentDownvotes}).eq('id', postIdNum);
        } else if (currentVoteType == 'downvote' && isUpvote) {
          currentUpvotes += 1;
          currentDownvotes -= 1;
          await supabase.from('user_votes').update({'vote_type': 'upvote'}).eq('user_id', user.id).eq('post_id', postIdNum);
          await supabase.from('community_posts').update({'upvotes': currentUpvotes, 'downvotes': currentDownvotes}).eq('id', postIdNum);
        } else {
          return;
        }
      } else {
        if (isUpvote) {
          currentUpvotes += 1;
          await supabase.from('user_votes').insert({'user_id': user.id, 'post_id': postIdNum, 'vote_type': 'upvote'});
          await supabase.from('community_posts').update({'upvotes': currentUpvotes}).eq('id', postIdNum);
        } else {
          currentDownvotes += 1;
          await supabase.from('user_votes').insert({'user_id': user.id, 'post_id': postIdNum, 'vote_type': 'downvote'});
          await supabase.from('community_posts').update({'downvotes': currentDownvotes}).eq('id', postIdNum);
        }
      }

      await _fetchPosts();
    } catch (e) {
      print('Error voting: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error voting: $e')));
    }
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xfff4eee0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xff5e3e2b)),
              title: Text('Update', style: TextStyle(color: Color(0xff5e3e2b))),
              onTap: () {
                Navigator.pop(sheetContext);
                _showUpdateCaptionDialog(context, post);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.redAccent),
              title: Text('Delete', style: TextStyle(color: Color(0xff5e3e2b))),
              onTap: () {
                Navigator.pop(sheetContext);
                _deletePost(post);
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateCaptionDialog(BuildContext context, Map<String, dynamic> post) {
    final TextEditingController captionController = TextEditingController(text: post['caption'] ?? '');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xfff4eee0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Update Caption',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post['image_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(child: Text('Image not available')),
                    ),
                  ),
                ),
                SizedBox(height: 16),
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
                    controller: captionController,
                    decoration: InputDecoration(
                      hintText: 'Enter new caption...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Color(0xff5e3e2b))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (captionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caption cannot be empty')));
                  return;
                }
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('community_posts').update({'caption': captionController.text.trim()}).eq('id', post['id']);
                  Navigator.pop(dialogContext);
                  await _fetchPosts();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caption updated successfully!')));
                } catch (e) {
                  print('Error updating caption: $e');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating caption: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff5e3e2b),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    try {
      final supabase = Supabase.instance.client;
      final imageUrl = post['image_url'];
      if (imageUrl != null) {
        final fileName = imageUrl.split('/').last;
        await supabase.storage.from('community_images').remove([fileName]);
      }
      await supabase.from('community_posts').delete().eq('id', post['id']);
      await supabase.from('user_votes').delete().eq('post_id', post['id']);
      await _fetchPosts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully!')));
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedPosts = widget.theme != null
        ? _posts.where((post) => (post['hashtags'] as List<String>? ?? []).any((hashtag) => hashtag.toLowerCase() == '#${widget.theme!.toLowerCase()}')).toList()
        : _posts;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xfff4eee0), Color(0xffe0d8c8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Back Button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff926247),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                      tooltip: 'Back',
                    ),
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(2, 2))],
                      ),
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.add, color: Color(0xff5e3e2b), size: 24),
                      ),
                      onPressed: _pickImage,
                      tooltip: 'New Post',
                    ),
                  ],
                ),
              ),
              // Hashtags
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Themed Discussion',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)),
                    ),
                    SizedBox(height: 12),
                    if (_uniqueHashtags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _uniqueHashtags.asMap().entries.map((entry) {
                          int index = entry.key;
                          String hashtag = entry.value;
                          String buttonText = hashtag.replaceAll('#', '').toUpperCase();
                          Color buttonColor = [Color(0xff9bb068), Color(0xff6b9b68), Color(0xff689b9b)][index % 3];

                          return ElevatedButton(
                            onPressed: () {
                              final currentTheme = widget.theme;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityPage(theme: currentTheme == buttonText ? null : buttonText),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 4,
                            ),
                            child: Text(buttonText, style: TextStyle(color: Colors.white, fontSize: 14)),
                          ).animate().fadeIn(duration: 300.ms);
                        }).toList(),
                      ),
                  ],
                ),
              ),
              // Posts
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -4))],
                  ),
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Color(0xff5e3e2b)).animate().scale(duration: 400.ms))
                      : displayedPosts.isEmpty
                      ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No posts yet for this theme. Be the first to share!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: displayedPosts.length,
                    itemBuilder: (context, index) {
                      final post = displayedPosts[index];
                      bool isUpvoted = post['userVote'] == 'upvote';
                      bool isDownvoted = post['userVote'] == 'downvote';
                      final currentUser = Supabase.instance.client.auth.currentUser;
                      final isCurrentUserPost = currentUser != null && post['user_id'] == currentUser.id;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: FutureBuilder<String?>(
                                  future: _getUserProfileImage(post['user_id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircleAvatar(radius: 20, backgroundColor: Colors.grey[300]);
                                    }
                                    return CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(snapshot.data ?? 'https://via.placeholder.com/64'),
                                    );
                                  },
                                ),
                                title: FutureBuilder<String?>(
                                  future: _getUserName(post['user_id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)));
                                    }
                                    return Text(
                                      snapshot.data ?? 'Anonymous',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)),
                                    );
                                  },
                                ),
                                subtitle: Text(
                                  DateFormat('MMM d, hh:mm a').format(DateTime.parse(post['created_at'])),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: isCurrentUserPost
                                    ? IconButton(
                                  icon: Icon(Icons.more_vert, color: Color(0xff5e3e2b)),
                                  onPressed: () => _showPostOptions(context, post),
                                )
                                    : null,
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  post['image_url'],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: double.infinity,
                                    height: 300,
                                    color: Colors.grey[300],
                                    child: Center(child: Text('Image not available')),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  post['caption'],
                                  style: TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.arrow_upward, color: isUpvoted ? Colors.green : Colors.grey, size: 28),
                                          onPressed: () => _votePost(post['id'].toString(), true),
                                        ),
                                        Text('${post['upvotes']}', style: TextStyle(color: Colors.grey[700])),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.arrow_downward, color: isDownvoted ? Colors.red : Colors.grey, size: 28),
                                          onPressed: () => _votePost(post['id'].toString(), false),
                                        ),
                                        Text('${post['downvotes']}', style: TextStyle(color: Colors.grey[700])),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemedDiscussionPage extends StatelessWidget {
  final String theme;

  const ThemedDiscussionPage({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityPage(theme: theme)));
    });
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}