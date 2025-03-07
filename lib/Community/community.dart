import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class CommunityPage extends StatefulWidget {
  final String? theme; // Add parameter to filter posts by hashtag/theme

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
  bool _isLoading = true; // Add loading state
  List<String> _uniqueHashtags = []; // Store unique hashtags

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPosts(); // Fetch posts on initialization
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Create Post'),
            content: SingleChildScrollView( // Make the content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.file(
                    File(image.path),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: 'Write a caption...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _caption = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  _uploadPost();
                },
                child: const Text('Post'),
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
        userName = response?['full_name']?.split(' ')?.first ??
            user.email?.split('@')[0] ??
            'User';
        profileImageUrl = response?['avatar_url'] ??
            'https://via.placeholder.com/64'; // Default image
      });
    }
  }

  Future _fetchPosts() async {
    debugPrint('Attempting to fetch posts...');
    setState(() {
      _isLoading = true;
    });
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
      });
      debugPrint('Fetched posts: $_posts');
      debugPrint('Detected hashtags: $_uniqueHashtags');
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _extractHashtags(String caption) {
    List<String> hashtags = [];
    RegExp regExp = RegExp(r'#\w+');
    Iterable<Match> matches = regExp.allMatches(caption);
    for (Match match in matches) {
      hashtags.add(match.group(0)!); // Add the full hashtag (e.g., "#job")
    }
    return hashtags;
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      return response['full_name'] ?? 'Anonymous';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Anonymous';
    }
  }

  Future<String?> _getUserProfileImage(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      return response['avatar_url'] ?? 'https://via.placeholder.com/64';
    } catch (e) {
      print('Error fetching user profile image: $e');
      return 'https://via.placeholder.com/64';
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to post')),
        );
        return;
      }

      // Upload image to storage
      final fileName = '${DateTime.now().toIso8601String()}_${user.id}.jpg';
      final bytes = await _selectedImage!.readAsBytes();
      await supabase.storage.from('community_images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
        ),
      );

      // Get the public URL of the uploaded image
      final imageUrl = supabase.storage
          .from('community_images')
          .getPublicUrl(fileName);

      // Create post in the database
      await supabase.from('community_posts').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'caption': _caption,
        'upvotes': 0,
        'downvotes': 0,
      });

      // Clear the form and refresh posts
      setState(() {
        _selectedImage = null;
        _caption = '';
        _captionController.clear();
      });

      // Close the dialog
      Navigator.pop(context);

      // Refresh posts
      await _fetchPosts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully!')),
      );
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading post: $e')),
      );
    }
  }

  Future<void> _votePost(String postId, bool isUpvote) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote.')),
        );
        return;
      }

      final postIdNum = int.tryParse(postId) ?? 0; // Safely convert postId to int
      if (postIdNum == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid post ID.')),
        );
        return;
      }

      final existingVote = await supabase
          .from('user_votes')
          .select('vote_type')
          .eq('user_id', user.id)
          .eq('post_id', postIdNum)
          .single()
          .then((value) => value as Map<String, dynamic>?)
          .catchError((e) {
        print('Error checking existing vote: $e');
        return null;
      });

      final postResponse = await supabase
          .from('community_posts')
          .select('upvotes, downvotes')
          .eq('id', postIdNum)
          .single()
          .catchError((e) {
        print('Error fetching post data: $e');
        return null;
      }) as Map<String, dynamic>?;

      if (postResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found.')),
        );
        return;
      }

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
          await supabase.from('user_votes').insert({
            'user_id': user.id,
            'post_id': postIdNum,
            'vote_type': 'upvote',
          });
          await supabase.from('community_posts').update({'upvotes': currentUpvotes}).eq('id', postIdNum);
        } else {
          currentDownvotes += 1;
          await supabase.from('user_votes').insert({
            'user_id': user.id,
            'post_id': postIdNum,
            'vote_type': 'downvote',
          });
          await supabase.from('community_posts').update({'downvotes': currentDownvotes}).eq('id', postIdNum);
        }
      }

      await _fetchPosts();
    } catch (e) {
      print('Error voting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    print('Showing options for post: ${post['id']}');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update'),
              onTap: () {
                print('Update tapped for post: ${post['id']}');
                Navigator.pop(sheetContext); // Close bottom sheet
                _showUpdateCaptionDialog(context, post); // Use original context
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                print('Delete tapped for post: ${post['id']}');
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
    print('Attempting to show update dialog for post: ${post['id']}');
    final TextEditingController captionController = TextEditingController(text: post['caption'] ?? '');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        print('Dialog builder called');
        return AlertDialog(
          title: const Text('Update Caption'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  post['image_url'],
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Image load error: $error');
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Text('Image not available')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter new caption...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Cancel pressed');
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print('Update pressed with caption: ${captionController.text}');
                if (captionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption cannot be empty')),
                  );
                  return;
                }
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('community_posts').update({
                    'caption': captionController.text.trim(),
                  }).eq('id', post['id']);
                  Navigator.pop(dialogContext); // Close dialog
                  await _fetchPosts(); // Refresh posts
                  setState(() {}); // Ensure UI updates
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption updated successfully!')),
                  );
                } catch (e) {
                  print('Error updating caption: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating caption: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    ).catchError((e) {
      print('Error showing dialog: $e');
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedPosts = widget.theme != null
        ? _posts.where((post) {
      final hashtags = post['hashtags'] as List<String>? ?? [];
      return hashtags.any((hashtag) => hashtag.toLowerCase() == '#${widget.theme!.toLowerCase()}');
    }).toList()
        : _posts;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xff9bb068),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(profileImageUrl!),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        userName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.add, color: Color(0xff9bb068)),
                    ),
                    onPressed: _pickImage,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Themed Discussion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_uniqueHashtags.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _uniqueHashtags.asMap().entries.map((entry) {
                        int index = entry.key;
                        String hashtag = entry.value;
                        String buttonText = hashtag.replaceAll('#', '').toUpperCase();

                        Color buttonColor;
                        switch (index % 3) {
                          case 0:
                            buttonColor = Color(0xff9bb068);
                            break;
                          case 1:
                            buttonColor = Color(0xff6b9b68);
                            break;
                          case 2:
                            buttonColor = Color(0xff689b9b);
                            break;
                          default:
                            buttonColor = Colors.grey;
                        }

                        return ElevatedButton(
                          onPressed: () {
                            final currentTheme = widget.theme;
                            if (currentTheme == buttonText) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommunityPage(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityPage(theme: buttonText),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    if (displayedPosts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No posts yet for this theme. Be the first to share!'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedPosts.length,
                        itemBuilder: (context, index) {
                          final post = displayedPosts[index];
                          bool isUpvoted = post['userVote'] == 'upvote';
                          bool isDownvoted = post['userVote'] == 'downvote';
                          final currentUser = Supabase.instance.client.auth.currentUser;
                          final isCurrentUserPost = currentUser != null && post['user_id'] == currentUser.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: FutureBuilder<String?>(
                                      future: _getUserProfileImage(post['user_id']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey[300],
                                            child: const CircularProgressIndicator(),
                                          );
                                        }
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return const CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage('https://via.placeholder.com/64'),
                                          );
                                        }
                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(snapshot.data!),
                                        );
                                      },
                                    ),
                                    title: FutureBuilder<String?>(
                                      future: _getUserName(post['user_id']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold));
                                        }
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return const Text('Anonymous', style: TextStyle(fontWeight: FontWeight.bold));
                                        }
                                        return Text(
                                          snapshot.data!,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM d, hh:mm a').format(DateTime.parse(post['created_at'])),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: isCurrentUserPost
                                        ? IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        print('Three-dot clicked for post: ${post['id']}');
                                        _showPostOptions(context, post);
                                      },
                                      iconSize: 24,
                                    )
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      post['image_url'],
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          height: 300,
                                          color: Colors.grey[300],
                                          child: const Center(child: Text('Image not available')),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      post['caption'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_upward,
                                                color: isUpvoted ? Colors.green : Colors.grey,
                                              ),
                                              onPressed: () => _votePost(post['id'].toString(), true),
                                              iconSize: 24,
                                            ),
                                            Text('${post['upvotes']} Upvotes'),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_downward,
                                                color: isDownvoted ? Colors.red : Colors.grey,
                                              ),
                                              onPressed: () => _votePost(post['id'].toString(), false),
                                              iconSize: 24,
                                            ),
                                            Text('${post['downvotes']} Downvotes'),
                                          ],
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
                  ],
                ),
              ),
            ),
          ],
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityPage(theme: theme),
        ),
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}