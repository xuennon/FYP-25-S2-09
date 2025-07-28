import 'package:flutter/material.dart';
import 'widgets/user_avatar.dart';
import 'services/user_profile_service.dart';

class WritePostPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPostCreated;
  
  const WritePostPage({super.key, this.onPostCreated});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  final List<String> _selectedImages = [];
  bool _isPublishing = false;

  void _addImage() {
    // Simulate image picker - in a real app, you'd use image_picker package
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Image'),
          content: const Text('In a real app, this would open the image picker. For demo purposes, we\'ll add a placeholder image.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.add('placeholder_image_${_selectedImages.length + 1}');
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Add Placeholder'),
            ),
          ],
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _publishPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content or images to your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create post data
    final postData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'username': _profileService.username,
      'postTime': 'Just now',
      'content': _contentController.text.trim(),
      'userAvatar': 'current_user',
      'likes': 0,
      'comments': <Map<String, dynamic>>[],
      'images': List<String>.from(_selectedImages),
      'isLikedByMe': false,
    };

    setState(() {
      _isPublishing = false;
    });

    // Call the callback function to add the post
    if (widget.onPostCreated != null) {
      widget.onPostCreated!(postData);
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post published successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to home page
    Navigator.of(context).pop(postData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Add Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'PUBLISH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            Row(
              children: [
                const UserAvatar(radius: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileService.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Public',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Content input
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's going on?",
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Selected images section
            if (_selectedImages.isNotEmpty) ...[
              const Text(
                'Selected Images:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _selectedImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  String image = entry.value;
                  
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                image,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            
            // Add content options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to your post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAddOptionButton(
                        icon: Icons.image,
                        label: 'Photo',
                        color: Colors.green,
                        onTap: _addImage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100), // Extra space for better scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
