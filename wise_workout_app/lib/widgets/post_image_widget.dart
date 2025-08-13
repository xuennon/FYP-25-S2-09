import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class PostImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PostImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Log the image path to see what we're getting
    print('🖼️ PostImageWidget: Attempting to load image: $imagePath');
    
    // Check if it's a local file path
    if (imagePath.startsWith('/') || 
        imagePath.contains('cache') || 
        imagePath.contains('Documents') ||
        imagePath.contains('storage/emulated') ||
        imagePath.contains('data/user')) {
      
      File imageFile = File(imagePath);
      print('🖼️ PostImageWidget: Loading as local file: $imagePath');
      return Image.file(
        imageFile,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ PostImageWidget: Error loading local file: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: (height != null && height! < 100) ? 30 : 50,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  'Image not found',
                  style: TextStyle(
                    fontSize: (height != null && height! < 100) ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else if (imagePath.startsWith('http')) {
      // It's a network URL
      print('🖼️ PostImageWidget: Loading as network image: $imagePath');
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ PostImageWidget: Error loading network image: $error');
          print('❌ PostImageWidget: Stack trace: $stackTrace');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: (height != null && height! < 100) ? 30 : 50,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    fontSize: (height != null && height! < 100) ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else if (imagePath.startsWith('data:image/') || imagePath.contains('base64')) {
      // It's a base64 encoded image
      print('🖼️ PostImageWidget: Loading as base64 image: ${imagePath.substring(0, 50)}...');
      try {
        String base64String = imagePath;
        if (imagePath.startsWith('data:image/')) {
          // Extract base64 part from data URL
          base64String = imagePath.split(',')[1];
        }
        
        final bytes = base64Decode(base64String);
        print('✅ PostImageWidget: Successfully decoded base64 image');
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('❌ PostImageWidget: Error loading base64 image: $error');
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: (height != null && height! < 100) ? 30 : 50,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invalid base64 image',
                    style: TextStyle(
                      fontSize: (height != null && height! < 100) ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        print('❌ PostImageWidget: Base64 decode error: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: (height != null && height! < 100) ? 30 : 50,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                'Base64 decode error',
                style: TextStyle(
                  fontSize: (height != null && height! < 100) ? 10 : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else {
      // Fallback placeholder for unknown format
      print('❌ PostImageWidget: Unknown image format: $imagePath');
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: (height != null && height! < 100) ? 30 : 50,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'Invalid image path',
              style: TextStyle(
                fontSize: (height != null && height! < 100) ? 10 : 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

class PostImageGrid extends StatelessWidget {
  final List<String> images;

  const PostImageGrid({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: PostImageWidget(
            imagePath: images[0],
            height: 200,
          ),
        ),
      );
    }

    // For multiple images, show in a grid
    return SizedBox(
      height: 120,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length == 2 ? 2 : 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: images.length > 6 ? 6 : images.length,
        itemBuilder: (context, index) {
          if (index == 5 && images.length > 6) {
            // Show "+X more" for additional images
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Center(
                child: Text(
                  '+${images.length - 5}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PostImageWidget(
                imagePath: images[index],
                height: 120,
              ),
            ),
          );
        },
      ),
    );
  }
}
