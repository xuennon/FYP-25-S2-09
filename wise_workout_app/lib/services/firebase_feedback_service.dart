import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_user_profile_service.dart';

class FirebaseFeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseUserProfileService _userProfileService = FirebaseUserProfileService();

  /// Submit feedback to Firebase
  Future<void> submitFeedback({
    required int rating,
    required String feedback,
    String? name,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's current subscription type
      String userType = await _userProfileService.getUserType();

      // Prepare feedback data
      final feedbackData = {
        'userId': user.uid,
        'rating': rating,
        'feedback': feedback,
        'name': name?.trim().isNotEmpty == true ? name!.trim() : null,
        'email': email?.trim().isNotEmpty == true ? email!.trim() : null,
        'timestamp': FieldValue.serverTimestamp(),
        'isCompleted': true, // Mark as completed when submitted
        'userType': userType, // User's subscription type (normal or premium)
      };

      // Debug: Print the exact data being sent to Firebase
      print('=== FEEDBACK DATA BEING SENT TO FIREBASE ===');
      feedbackData.forEach((key, value) {
        print('$key: $value');
      });
      print('===============================================');

      // Add feedback to Firestore (testimonial collection)
      await _firestore.collection('testimonial').add(feedbackData);
      
      print('Feedback submitted successfully to Firebase');
      print('User ID: ${user.uid}');
      print('Rating: $rating stars');
      print('Feedback: $feedback');
      print('User Type: $userType');
      print('Is Completed: true');
      if (name?.isNotEmpty == true) print('Name: $name');
      if (email?.isNotEmpty == true) print('Email: $email');
      
    } catch (e) {
      print('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Get all feedback (for admin purposes)
  Stream<QuerySnapshot> getAllFeedback() {
    return _firestore
        .collection('testimonial')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get feedback by user
  Stream<QuerySnapshot> getUserFeedback(String userId) {
    return _firestore
        .collection('testimonial')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Update feedback completion status
  Future<void> updateFeedbackCompletion(String feedbackId, bool isCompleted) async {
    try {
      await _firestore.collection('testimonial').doc(feedbackId).update({
        'isCompleted': isCompleted,
        'completionUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('Feedback completion status updated to: $isCompleted');
    } catch (e) {
      print('Error updating feedback completion: $e');
      throw Exception('Failed to update feedback completion: $e');
    }
  }

  /// Get feedback by completion status
  Stream<QuerySnapshot> getFeedbackByCompletion(bool isCompleted) {
    return _firestore
        .collection('testimonial')
        .where('isCompleted', isEqualTo: isCompleted)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get feedback by user type
  Stream<QuerySnapshot> getFeedbackByUserType(String userType) {
    return _firestore
        .collection('testimonial')
        .where('userType', isEqualTo: userType)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get completed feedback from premium users
  Stream<QuerySnapshot> getCompletedPremiumFeedback() {
    return _firestore
        .collection('testimonial')
        .where('isCompleted', isEqualTo: true)
        .where('userType', isEqualTo: 'premium')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get completed feedback from normal users
  Stream<QuerySnapshot> getCompletedNormalFeedback() {
    return _firestore
        .collection('testimonial')
        .where('isCompleted', isEqualTo: true)
        .where('userType', isEqualTo: 'normal')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      // Get all feedback
      QuerySnapshot allFeedback = await _firestore.collection('testimonial').get();
      
      int total = allFeedback.docs.length;
      int completed = 0;
      int premiumUsers = 0;
      int normalUsers = 0;
      double averageRating = 0.0;
      int totalRating = 0;
      
      for (var doc in allFeedback.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Count completion status
        if (data['isCompleted'] == true) completed++;
        
        // Count user types
        if (data['userType'] == 'premium') {
          premiumUsers++;
        } else {
          normalUsers++;
        }
        
        // Calculate average rating
        if (data['rating'] != null) {
          totalRating += (data['rating'] as int);
        }
      }
      
      if (total > 0) {
        averageRating = totalRating / total;
      }
      
      return {
        'total': total,
        'completed': completed,
        'incomplete': total - completed,
        'premiumUsers': premiumUsers,
        'normalUsers': normalUsers,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'incomplete': 0,
        'premiumUsers': 0,
        'normalUsers': 0,
        'averageRating': 0.0,
      };
    }
  }
}
