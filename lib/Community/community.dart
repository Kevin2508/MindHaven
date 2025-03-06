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
            content: Column(
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
      _isLoading = true; // Set loading to true before fetching
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('community_posts')
          .select('id, user_id, image_url, caption, upvotes, downvotes, created_at')
          .order('upvotes', ascending: false); // Sort by upvotes descending
      debugPrint('Supabase response: $response');

      Set<String> uniqueHashtags = {}; // Store unique hashtags

      setState(() {
        _posts = response.map((post) {
          // Ensure created_at is a valid ISO 8601 string
          String createdAt = post['created_at']?.toString() ?? DateTime.now().toIso8601String();
          String? userVote = null;
          if (user != null) {
            // Fetch the user's vote for this post if logged in
            supabase.from('user_votes')
                .select('vote_type')
                .eq('user_id', user.id)
                .eq('post_id', post['id'])
                .single()
                .then((vote) {
              userVote = vote['vote_type'] as String?;
            }).catchError((e) {
              print('Error fetching user vote: $e');
              userVote = null;
            });
          }

          // Parse hashtags from the caption (e.g., #job, #stress)
          List<String> hashtags = _extractHashtags(post['caption'] ?? '');
          hashtags.forEach((hashtag) {
            uniqueHashtags.add(hashtag.toLowerCase()); // Add to set, converting to lowercase for consistency
          });

          return {
            'id': post['id'],
            'user_id': post['user_id'],
            'image_url': post['image_url'],
            'caption': post['caption'] ?? '', // Default to empty string if null
            'upvotes': (post['upvotes'] ?? 0) as int,
            'downvotes': (post['downvotes'] ?? 0) as int,
            'created_at': createdAt,
            'userVote': userVote, // Store the user's current vote (upvote/downvote or null)
            'hashtags': hashtags, // Store hashtags for this post
          };
        }).toList();

        // Store unique hashtags in the state
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
        _isLoading = false; // Set loading to false after fetching (or on error)
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

      final postIdNum = int.tryParse(postId) ?? 0; // Safely convert postId to int, default to 0 if invalid
      if (postIdNum == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid post ID.')),
        );
        return;
      }

      // Check the user's current vote for this post
      final existingVote = await supabase
          .from('user_votes')
          .select('vote_type')
          .eq('user_id', user.id)
          .eq('post_id', postIdNum)
          .single()
          .then((value) => value as Map<String, dynamic>?) // Explicitly cast the result
          .catchError((e) {
        print('Error checking existing vote: $e');
        return null; // Return null, matching Map<String, dynamic>?
      });

      // Get the current post data from Supabase directly (in case _posts is outdated)
      final postResponse = await supabase
          .from('community_posts')
          .select('upvotes, downvotes')
          .eq('id', postIdNum)
          .single()
          .catchError((e) {
        print('Error fetching post data: $e');
        return null; // Return null if the post isn’t found
      }) as Map<String, dynamic>?;

      if (postResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found.')),
        );
        return;
      }

      // Use the post data from Supabase
      int currentUpvotes = postResponse['upvotes'] as int? ?? 0;
      int currentDownvotes = postResponse['downvotes'] as int? ?? 0;

      if (existingVote != null) {
        // User has already voted; check and update the vote
        String? currentVoteType = existingVote['vote_type'] as String?;
        if (currentVoteType == 'upvote' && !isUpvote) {
          // Change from upvote to downvote: decrease upvotes, increase downvotes
          currentUpvotes -= 1;
          currentDownvotes += 1;
          await supabase.from('user_votes').update({'vote_type': 'downvote'}).eq('user_id', user.id).eq('post_id', postIdNum);
          await supabase.from('community_posts').update({'upvotes': currentUpvotes, 'downvotes': currentDownvotes}).eq('id', postIdNum);
        } else if (currentVoteType == 'downvote' && isUpvote) {
          // Change from downvote to upvote: increase upvotes, decrease downvotes
          currentUpvotes += 1;
          currentDownvotes -= 1;
          await supabase.from('user_votes').update({'vote_type': 'upvote'}).eq('user_id', user.id).eq('post_id', postIdNum);
          await supabase.from('community_posts').update({'upvotes': currentUpvotes, 'downvotes': currentDownvotes}).eq('id', postIdNum);
        } else {
          // User clicked the same vote type again (e.g., upvote on upvote)—no change needed
          return;
        }
      } else {
        // User has not voted yet; add new vote
        if (isUpvote) {
          // Add upvote: increase upvotes
          currentUpvotes += 1;
          await supabase.from('user_votes').insert({
            'user_id': user.id,
            'post_id': postIdNum,
            'vote_type': 'upvote',
          });
          await supabase.from('community_posts').update({'upvotes': currentUpvotes}).eq('id', postIdNum);
        } else {
          // Add downvote: increase downvotes
          currentDownvotes += 1;
          await supabase.from('user_votes').insert({
            'user_id': user.id,
            'post_id': postIdNum,
            'vote_type': 'downvote',
          });
          await supabase.from('community_posts').update({'downvotes': currentDownvotes}).eq('id', postIdNum);
        }
      }

      // Refresh posts to reflect the new vote counts
      await _fetchPosts();
    } catch (e) {
      print('Error voting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update'),
              onTap: () {
                _showUpdateCaptionDialog(context, post);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                _deletePost(post);
                Navigator.pop(context);
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Caption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show the image to confirm it's the same post
              Image.network(
                post['image_url'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (captionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption cannot be empty')),
                  );
                  return;
                }
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('community_posts').update({
                    'caption': captionController.text.trim(), // Update with new caption
                  }).eq('id', post['id']);
                  await _fetchPosts(); // Refresh posts after update
                  Navigator.pop(context);
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
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    try {
      final supabase = Supabase.instance.client;
      // Delete the post image from storage
      final imageUrl = post['image_url'];
      if (imageUrl != null) {
        final fileName = imageUrl.split('/').last; // Extract file name from URL
        await supabase.storage.from('community_images').remove([fileName]);
      }
      // Delete the post from the database
      await supabase.from('community_posts').delete().eq('id', post['id']);
      // Also delete any associated votes
      await supabase.from('user_votes').delete().eq('post_id', post['id']);
      // Refresh posts after deletion
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
    // Filter posts based on the theme (hashtag) if provided
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
            // User profile section (background #9bb068)
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
            // Themed Discussion Section (now with dynamic hashtag buttons)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Themed Discussion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_uniqueHashtags.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _uniqueHashtags.map((hashtag) {
                        String buttonText = hashtag.replaceAll('#', '').toUpperCase(); // Remove # and capitalize
                        return ElevatedButton(
                          onPressed: () {
                            // Get the current route's theme (if any) from CommunityPage
                            final currentTheme = widget.theme; // Use widget.theme directly
                            if (currentTheme == buttonText) {
                              // If the button text matches the current theme, reset to show all posts
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommunityPage(), // No theme parameter to show all posts
                                ),
                              );
                            } else {
                              // Navigate to filter by this hashtag
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityPage(theme: buttonText),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            // Posts Section (now below Themed Discussion, with loading state and filtering)
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    if (displayedPosts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
                                          return CircleAvatar(
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
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    trailing: isCurrentUserPost
                                        ? IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showPostOptions(context, post),
                                      iconSize: 24,
                                    )
                                        : null, // No 3-dot button for non-owners
                                    // Removed the verified badge
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      post['image_url'],
                                      width: double.infinity,
                                      height: 300, // Larger image for Instagram-like feel
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

// Updated ThemedDiscussionPage (placeholder, now just a redirect to CommunityPage with theme)
class ThemedDiscussionPage extends StatelessWidget {
  final String theme;

  const ThemedDiscussionPage({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to CommunityPage with the theme filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityPage(theme: theme),
        ),
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // Show loading while redirecting
    );
  }
}