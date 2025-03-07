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
  String _currentSort = 'upvotes';
  bool _isSortAscending = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPosts();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        userName = response['full_name']?.split(' ')?.first ?? user.email?.split('@')[0] ?? 'User';
        profileImageUrl = response['avatar_url'] ?? 'https://via.placeholder.com/64';
      });
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('community_posts')
          .select('id, user_id, image_url, caption, upvotes, downvotes, created_at');

      Set<String> uniqueHashtags = {};
      final user = supabase.auth.currentUser;

      final posts = await Future.wait(response.map((post) async => await _processPost(post, user, uniqueHashtags)));

      setState(() {
        _posts = _sortPosts(posts.toList());
        _uniqueHashtags = uniqueHashtags.toList();
        _isLoading = false;
      });
    } catch (e) {
      _handleError('Error fetching posts: $e');
    }
  }

  Future<Map<String, dynamic>> _processPost(dynamic post, User? user, Set<String> uniqueHashtags) async {
    String? userVote;
    if (user != null) {
      userVote = await supabase
          .from('user_votes')
          .select('vote_type')
          .eq('user_id', user.id)
          .eq('post_id', post['id'])
          .maybeSingle()
          .then((vote) => vote?['vote_type'] as String?);
    }

    final hashtags = _extractHashtags(post['caption'] ?? '');
    hashtags.forEach((hashtag) => uniqueHashtags.add(hashtag.toLowerCase()));

    return {
      'id': post['id'],
      'user_id': post['user_id'],
      'image_url': post['image_url'],
      'caption': post['caption'] ?? '',
      'upvotes': post['upvotes'] ?? 0,
      'downvotes': post['downvotes'] ?? 0,
      'created_at': post['created_at'] ?? DateTime.now().toIso8601String(),
      'userVote': userVote,
      'hashtags': hashtags,
    };
  }

  List<String> _extractHashtags(String caption) => RegExp(r'#\w+')
      .allMatches(caption)
      .map((match) => match.group(0)!)
      .toList();

  List<Map<String, dynamic>> _sortPosts(List<Map<String, dynamic>> posts) {
    posts.sort((a, b) {
      int comparison;
      switch (_currentSort) {
        case 'upvotes':
          comparison = a['upvotes'].compareTo(b['upvotes']);
          break;
        case 'downvotes':
          comparison = a['downvotes'].compareTo(b['downvotes']);
          break;
        case 'latest':
        case 'oldest':
          comparison = DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']));
          comparison = _currentSort == 'oldest' ? -comparison : comparison;
          break;
        default:
          comparison = 0;
      }
      return _isSortAscending ? comparison : -comparison;
    });
    return posts;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    _showPostDialog(image: File(image.path), isUpdate: false);
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image');
      return;
    }

    final user = _authenticatedUserCheck();
    if (user == null) return;

    try {
      final fileName = '${DateTime.now().toIso8601String()}_${user.id}.jpg';
      final imageUrl = await _uploadImage(fileName);

      await supabase.from('community_posts').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'caption': _caption,
        'upvotes': 0,
        'downvotes': 0,
      });

      _resetPostForm();
      if (!mounted) return;
      Navigator.pop(context);
      _fetchPosts();
      _showSnackBar('Post uploaded successfully!');
    } catch (e) {
      _handleError('Error uploading post: $e');
    }
  }

  Future<String> _uploadImage(String fileName) async {
    final bytes = await _selectedImage!.readAsBytes();
    await supabase.storage.from('community_images').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return supabase.storage.from('community_images').getPublicUrl(fileName);
  }

  Future<void> _votePost(String postId, bool isUpvote) async {
    final user = _authenticatedUserCheck();
    if (user == null) return;

    final postIdNum = int.tryParse(postId) ?? 0;
    if (postIdNum == 0) return;

    try {
      final postIndex = _posts.indexWhere((p) => p['id'].toString() == postId);
      if (postIndex == -1) return;

      final voteData = await _getVoteData(user.id, postIdNum);
      final updatedPost = await _updateVote(postIdNum, isUpvote, voteData, Map.from(_posts[postIndex]));

      setState(() {
        _posts[postIndex] = updatedPost;
        _posts = _sortPosts(_posts);
      });
    } catch (e) {
      _handleError('Error voting: $e');
    }
  }

  Future<Map<String, dynamic>?> _getVoteData(String userId, int postId) async {
    return await supabase
        .from('user_votes')
        .select('vote_type')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .single()
        .then((value) => value as Map<String, dynamic>?)
        .catchError((e) => null);
  }

  Future<Map<String, dynamic>> _updateVote(int postId, bool isUpvote, Map<String, dynamic>? existingVote, Map<String, dynamic> post) async {
    int upvotes = post['upvotes'];
    int downvotes = post['downvotes'];
    String? newVoteType;

    if (existingVote != null) {
      final currentVote = existingVote['vote_type'] as String?;
      if (currentVote == 'upvote' && !isUpvote) {
        upvotes--;
        downvotes++;
        newVoteType = 'downvote';
      } else if (currentVote == 'downvote' && isUpvote) {
        upvotes++;
        downvotes--;
        newVoteType = 'upvote';
      }
      if (newVoteType != null) {
        await supabase.from('user_votes').update({'vote_type': newVoteType}).eq('user_id', supabase.auth.currentUser!.id).eq('post_id', postId);
      }
    } else {
      if (isUpvote) {
        upvotes++;
        newVoteType = 'upvote';
      } else {
        downvotes++;
        newVoteType = 'downvote';
      }
      await supabase.from('user_votes').insert({'user_id': supabase.auth.currentUser!.id, 'post_id': postId, 'vote_type': newVoteType});
    }

    await supabase.from('community_posts').update({'upvotes': upvotes, 'downvotes': downvotes}).eq('id', postId);
    return {...post, 'upvotes': upvotes, 'downvotes': downvotes, 'userVote': newVoteType};
  }

  Future<String?> _getUserInfo(String userId, String column) async {
    try {
      final response = await supabase.from('profiles').select(column).eq('id', userId).single();
      return response[column] ?? (column == 'full_name' ? 'Anonymous' : 'https://via.placeholder.com/64');
    } catch (e) {
      return column == 'full_name' ? 'Anonymous' : 'https://via.placeholder.com/64';
    }
  }

  void _showPostDialog({required File image, required bool isUpdate, Map<String, dynamic>? post}) {
    if (isUpdate && post != null) _captionController.text = post['caption'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xfff4eee0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isUpdate ? 'Update Caption' : 'Create Post',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isUpdate
                    ? Image.network(post!['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              _buildTextField(_captionController, 'Write a caption...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xff5e3e2b))),
          ),
          ElevatedButton(
            onPressed: () => isUpdate ? _updateCaption(post!) : _handleNewPost(image),
            style: _buttonStyle(),
            child: Text(isUpdate ? 'Update' : 'Post', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
          fillColor: Colors.white,
          filled: true,
        ),
        maxLines: 3,
        onChanged: (value) => _caption = value,
      ),
    );
  }

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xff5e3e2b),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _handleNewPost(File image) {
    setState(() => _selectedImage = image);
    _uploadPost();
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xfff4eee0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xff5e3e2b)),
            title: const Text('Update', style: TextStyle(color: Color(0xff5e3e2b))),
            onTap: () {
              Navigator.pop(context);
              _showPostDialog(image: File(''), isUpdate: true, post: post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete', style: TextStyle(color: Color(0xff5e3e2b))),
            onTap: () {
              Navigator.pop(context);
              _deletePost(post);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateCaption(Map<String, dynamic> post) async {
    if (_captionController.text.trim().isEmpty) {
      _showSnackBar('Caption cannot be empty');
      return;
    }
    try {
      await supabase.from('community_posts').update({'caption': _captionController.text.trim()}).eq('id', post['id']);
      if (!mounted) return;
      Navigator.pop(context);
      _fetchPosts();
      _showSnackBar('Caption updated successfully!');
    } catch (e) {
      _handleError('Error updating caption: $e');
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    try {
      final imageUrl = post['image_url'];
      if (imageUrl != null) {
        await supabase.storage.from('community_images').remove([imageUrl.split('/').last]);
      }
      await supabase.from('community_posts').delete().eq('id', post['id']);
      await supabase.from('user_votes').delete().eq('post_id', post['id']);
      _fetchPosts();
      _showSnackBar('Post deleted successfully!');
    } catch (e) {
      _handleError('Error deleting post: $e');
    }
  }

  User? _authenticatedUserCheck() {
    final user = supabase.auth.currentUser;
    if (user == null) _showSnackBar('Please log in to perform this action');
    return user;
  }

  void _resetPostForm() {
    setState(() {
      _selectedImage = null;
      _caption = '';
      _captionController.clear();
    });
  }

  void _handleError(String message) {
    print(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = widget.theme != null
        ? _posts.where((post) => (post['hashtags'] as List<String>).any((hashtag) => hashtag.toLowerCase() == '#${widget.theme!.toLowerCase()}')).toList()
        : _posts;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xfff4eee0), Color(0xffe0d8c8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildHashtagsSection(),
              Expanded(child: _buildPostsList(displayedPosts)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xff926247),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              const Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.white),
                onSelected: (value) {
                  setState(() {
                    if (value == 'reverse') {
                      _isSortAscending = !_isSortAscending;
                    } else {
                      _currentSort = value;
                    }
                    _posts = _sortPosts(_posts);
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'upvotes', child: Text('Sort by Upvotes')),
                  const PopupMenuItem(value: 'downvotes', child: Text('Sort by Downvotes')),
                  const PopupMenuItem(value: 'latest', child: Text('Sort by Latest')),
                  const PopupMenuItem(value: 'oldest', child: Text('Sort by Oldest')),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'reverse', child: Text(_isSortAscending ? 'Ascending' : 'Descending')),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Color(0xff5e3e2b), size: 24),
            ),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Themed Discussion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff5e3e2b))),
          const SizedBox(height: 12),
          if (_uniqueHashtags.isNotEmpty)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _uniqueHashtags.map((hashtag) {
                final buttonText = hashtag.replaceAll('#', '').toUpperCase();
                final buttonColor = const [Color(0xff9bb068), Color(0xff6b9b68), Color(0xff689b9b)][_uniqueHashtags.indexOf(hashtag) % 3];
                return ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityPage(theme: widget.theme == buttonText ? null : buttonText))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ).animate().fadeIn(duration: 300.ms);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<Map<String, dynamic>> posts) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -4))],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff5e3e2b)))
          : posts.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No posts yet for this theme. Be the first to share!', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) => _buildPostCard(posts[index]),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isUpvoted = post['userVote'] == 'upvote';
    final isDownvoted = post['userVote'] == 'downvote';
    final currentUser = supabase.auth.currentUser;
    final isCurrentUserPost = currentUser != null && post['user_id'] == currentUser.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: FutureBuilder<String?>(
                future: _getUserInfo(post['user_id'], 'avatar_url'),
                builder: (context, snapshot) => CircleAvatar(
                  radius: 20,
                  backgroundImage: snapshot.data != null ? NetworkImage(snapshot.data!) : null,
                  backgroundColor: snapshot.connectionState == ConnectionState.waiting ? Colors.grey[300] : null,
                ),
              ),
              title: FutureBuilder<String?>(
                future: _getUserInfo(post['user_id'], 'full_name'),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff5e3e2b)),
                ),
              ),
              subtitle: Text(DateFormat('MMM d, hh:mm a').format(DateTime.parse(post['created_at']))),
              trailing: isCurrentUserPost
                  ? IconButton(icon: const Icon(Icons.more_vert, color: Color(0xff5e3e2b)), onPressed: () => _showPostOptions(post))
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
                  child: const Center(child: Text('Image not available')),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(post['caption'], style: const TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildVoteButton(Icons.arrow_upward, post['upvotes'], () => _votePost(post['id'].toString(), true), isUpvoted ? Colors.green : Colors.grey),
                  _buildVoteButton(Icons.arrow_downward, post['downvotes'], () => _votePost(post['id'].toString(), false), isDownvoted ? Colors.red : Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildVoteButton(IconData icon, int count, VoidCallback onPressed, Color color) {
    return Row(
      children: [
        IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onPressed),
        Text('$count', style: const TextStyle(color: Colors.grey)),
      ],
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}