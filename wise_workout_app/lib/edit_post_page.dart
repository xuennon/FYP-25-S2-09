import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'models/post.dart';
import 'widgets/user_avatar.dart';
import 'services/firebase_posts_service.dart';
import 'services/firebase_storage_service.dart';

class EditPostPage extends StatefulWidget {
  final Post post;
  
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _contentController;
  final FirebasePostsService _firebasePostsService = FirebasePostsService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final List<File> _newSelectedImages = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    // Initialize with existing images
    _existingImageUrls.addAll(widget.post.images);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _addImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to select your image from:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImageFromSource(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImageFromSource(ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      print('📷 Attempting to pick image from ${source == ImageSource.camera ? "camera" : "gallery"}');
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        print('✅ Image picked successfully: ${pickedFile.path}');
        print('📊 File size: ${await File(pickedFile.path).length()} bytes');
        
        setState(() {
          _newSelectedImages.add(File(pickedFile.path));
        });
        
        print('📊 Total new images: ${_newSelectedImages.length}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ No image was picked');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
    });
  }

  void _updatePost() async {
    if (_contentController.text.trim().isEmpty && 
        _existingImageUrls.isEmpty && 
        _newSelectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content or images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      print('📝 Starting post update...');
      print('📄 Content length: ${_contentController.text.trim().length}');
      print('🖼️ Existing images: ${_existingImageUrls.length}');
      print('🖼️ New images to upload: ${_newSelectedImages.length}');

      // Upload new images to Firebase Storage
      List<String> newImageUrls = [];
      for (int i = 0; i < _newSelectedImages.length; i++) {
        File image = _newSelectedImages[i];
        print('📤 Uploading image ${i + 1}/${_newSelectedImages.length}: ${image.path}');
        
        // Check if file still exists before uploading
        if (!await image.exists()) {
          print('❌ Image file no longer exists: ${image.path}');
          continue;
        }
        
        String? uploadUrl = await _storageService.uploadImage(image, customPath: 'posts');
        if (uploadUrl != null) {
          newImageUrls.add(uploadUrl);
          print('✅ Image ${i + 1} uploaded successfully: $uploadUrl');
        } else {
          print('❌ Failed to upload image ${i + 1}');
          // Show error but don't fail the entire update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image ${i + 1}. Continuing with other images.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      print('📊 Upload results: ${newImageUrls.length}/${_newSelectedImages.length} images uploaded');

      // Combine existing images with new uploaded images
      List<String> allImageUrls = [..._existingImageUrls, ...newImageUrls];
      print('🖼️ Final image count: ${allImageUrls.length} (${_existingImageUrls.length} existing + ${newImageUrls.length} new)');

      // Final validation: ensure we have content or images
      if (_contentController.text.trim().isEmpty && allImageUrls.isEmpty) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post must have either text content or images. Please add some content.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update the post
      print('🔥 Updating post in Firebase...');
      bool success = await _firebasePostsService.updatePost(
        postId: widget.post.id,
        content: _contentController.text.trim(),
        imageUrls: allImageUrls,
      );

      setState(() {
        _isUpdating = false;
      });

      if (success) {
        print('✅ Post updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate post was updated
      } else {
        print('❌ Post update failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      print('❌ Error updating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _updatePost,
            child: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : const Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const UserAvatar(radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Public',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content text field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Existing Images
            if (_existingImageUrls.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Images:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _existingImageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_existingImageUrls[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // New Selected Images
            if (_newSelectedImages.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Images:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _newSelectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_newSelectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _addImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
