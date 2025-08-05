import 'package:cloud_firestore/cloud_firestore.dart';

// This is a utility script to migrate existing testimonials to have the new fields
// You can call this once to update all existing testimonials in your database
class TestimonialMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate all existing testimonials to have isCompleted and userType fields
  static Future<void> migrateExistingTestimonials() async {
    try {
      print('Starting testimonial migration...');
      
      // Get all testimonials from the testimonial collection
      QuerySnapshot testimonialsSnapshot = await _firestore.collection('testimonial').get();
      
      int totalTestimonials = testimonialsSnapshot.docs.length;
      int updatedTestimonials = 0;
      int skippedTestimonials = 0;
      int errorTestimonials = 0;
      
      print('Found $totalTestimonials testimonials to migrate');
      
      for (QueryDocumentSnapshot testimonialDoc in testimonialsSnapshot.docs) {
        try {
          Map<String, dynamic> testimonialData = testimonialDoc.data() as Map<String, dynamic>;
          
          // Check if testimonial already has the new fields
          bool hasIsCompleted = testimonialData.containsKey('isCompleted');
          bool hasUserType = testimonialData.containsKey('userType');
          
          if (hasIsCompleted && hasUserType) {
            print('Testimonial ${testimonialDoc.id} already has new fields');
            skippedTestimonials++;
            continue;
          }
          
          Map<String, dynamic> updateData = {};
          
          // Add isCompleted field if missing
          if (!hasIsCompleted) {
            // If testimonial exists and has feedback, mark as completed
            bool isCompleted = testimonialData['feedback'] != null && 
                              testimonialData['feedback'].toString().isNotEmpty;
            updateData['isCompleted'] = isCompleted;
          }
          
          // Add userType field if missing
          if (!hasUserType) {
            String userType = 'normal'; // Default to normal
            
            // Try to get user type from user document if userId exists
            if (testimonialData['userId'] != null) {
              try {
                DocumentSnapshot userDoc = await _firestore
                    .collection('users')
                    .doc(testimonialData['userId'])
                    .get();
                
                if (userDoc.exists) {
                  Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
                  if (userData != null && userData['userType'] != null) {
                    userType = userData['userType'];
                  }
                }
              } catch (e) {
                print('Error getting user data for testimonial ${testimonialDoc.id}: $e');
                // Keep default 'normal' value
              }
            }
            
            updateData['userType'] = userType;
          }
          
          // Add migration timestamp
          updateData['migrationUpdatedAt'] = FieldValue.serverTimestamp();
          
          // Update the testimonial document
          await _firestore.collection('testimonial').doc(testimonialDoc.id).update(updateData);
          
          updatedTestimonials++;
          print('Updated testimonial ${testimonialDoc.id} with: $updateData');
          
        } catch (e) {
          print('Error updating testimonial ${testimonialDoc.id}: $e');
          errorTestimonials++;
        }
      }
      
      print('Testimonial migration completed!');
      print('Total testimonials: $totalTestimonials');
      print('Updated testimonials: $updatedTestimonials');
      print('Skipped testimonials: $skippedTestimonials');
      print('Error testimonials: $errorTestimonials');
      
    } catch (e) {
      print('Error during testimonial migration: $e');
    }
  }

  // Check migration status for testimonials
  static Future<Map<String, int>> checkTestimonialMigrationStatus() async {
    try {
      QuerySnapshot testimonialsSnapshot = await _firestore.collection('testimonial').get();
      
      int totalTestimonials = testimonialsSnapshot.docs.length;
      int testimonialsWithIsCompleted = 0;
      int testimonialsWithUserType = 0;
      int completedTestimonials = 0;
      int premiumTestimonials = 0;
      int normalTestimonials = 0;
      
      for (QueryDocumentSnapshot testimonialDoc in testimonialsSnapshot.docs) {
        Map<String, dynamic> testimonialData = testimonialDoc.data() as Map<String, dynamic>;
        
        if (testimonialData.containsKey('isCompleted')) {
          testimonialsWithIsCompleted++;
          if (testimonialData['isCompleted'] == true) {
            completedTestimonials++;
          }
        }
        
        if (testimonialData.containsKey('userType')) {
          testimonialsWithUserType++;
          String userType = testimonialData['userType'] ?? 'normal';
          if (userType == 'premium') {
            premiumTestimonials++;
          } else {
            normalTestimonials++;
          }
        }
      }
      
      return {
        'total': totalTestimonials,
        'withIsCompleted': testimonialsWithIsCompleted,
        'withUserType': testimonialsWithUserType,
        'completed': completedTestimonials,
        'premium': premiumTestimonials,
        'normal': normalTestimonials,
        'needsIsCompletedMigration': totalTestimonials - testimonialsWithIsCompleted,
        'needsUserTypeMigration': totalTestimonials - testimonialsWithUserType,
      };
      
    } catch (e) {
      print('Error checking testimonial migration status: $e');
      return {
        'total': 0,
        'withIsCompleted': 0,
        'withUserType': 0,
        'completed': 0,
        'premium': 0,
        'normal': 0,
        'needsIsCompletedMigration': 0,
        'needsUserTypeMigration': 0,
      };
    }
  }

  // Print current testimonial database status
  static Future<void> printTestimonialDatabaseStatus() async {
    Map<String, int> status = await checkTestimonialMigrationStatus();
    
    print('=== Testimonial Database Status ===');
    print('Total testimonials: ${status['total']}');
    print('Testimonials with isCompleted: ${status['withIsCompleted']}');
    print('Testimonials with userType: ${status['withUserType']}');
    print('Completed testimonials: ${status['completed']}');
    print('Premium user testimonials: ${status['premium']}');
    print('Normal user testimonials: ${status['normal']}');
    print('Testimonials needing isCompleted migration: ${status['needsIsCompletedMigration']}');
    print('Testimonials needing userType migration: ${status['needsUserTypeMigration']}');
    print('===================================');
  }

  // Fix incomplete testimonials (mark them as completed if they have feedback)
  static Future<void> fixIncompleteTestimonials() async {
    try {
      print('Fixing incomplete testimonials...');
      
      QuerySnapshot incompleteTestimonials = await _firestore
          .collection('testimonial')
          .where('isCompleted', isEqualTo: false)
          .get();
      
      int fixedCount = 0;
      
      for (QueryDocumentSnapshot doc in incompleteTestimonials.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If testimonial has feedback and rating, mark as completed
        if (data['feedback'] != null && 
            data['feedback'].toString().isNotEmpty &&
            data['rating'] != null) {
          
          await _firestore.collection('testimonial').doc(doc.id).update({
            'isCompleted': true,
            'fixedAt': FieldValue.serverTimestamp(),
          });
          
          fixedCount++;
          print('Fixed testimonial ${doc.id}');
        }
      }
      
      print('Fixed $fixedCount incomplete testimonials');
    } catch (e) {
      print('Error fixing incomplete testimonials: $e');
    }
  }
}
