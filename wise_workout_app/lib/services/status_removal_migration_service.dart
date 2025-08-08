import 'package:cloud_firestore/cloud_firestore.dart';

// This utility script removes the status field from existing testimonials
class StatusRemovalMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Remove status field from all existing testimonials
  static Future<void> removeStatusFromTestimonials() async {
    try {
      print('Starting status field removal migration...');
      
      // Get all testimonials that have the status field
      QuerySnapshot testimonialsWithStatus = await _firestore
          .collection('testimonial')
          .get();
      
      int totalTestimonials = testimonialsWithStatus.docs.length;
      int updatedTestimonials = 0;
      int skippedTestimonials = 0;
      int errorTestimonials = 0;
      
      print('Found $totalTestimonials testimonials to check');
      
      for (QueryDocumentSnapshot testimonialDoc in testimonialsWithStatus.docs) {
        try {
          Map<String, dynamic> testimonialData = testimonialDoc.data() as Map<String, dynamic>;
          
          // Check if testimonial has the status field
          if (!testimonialData.containsKey('status')) {
            print('Testimonial ${testimonialDoc.id} does not have status field');
            skippedTestimonials++;
            continue;
          }
          
          // Remove the status field
          await _firestore.collection('testimonial').doc(testimonialDoc.id).update({
            'status': FieldValue.delete(),
            'statusRemovedAt': FieldValue.serverTimestamp(),
          });
          
          updatedTestimonials++;
          print('Removed status field from testimonial ${testimonialDoc.id}');
          
        } catch (e) {
          print('Error updating testimonial ${testimonialDoc.id}: $e');
          errorTestimonials++;
        }
      }
      
      print('Status field removal migration completed!');
      print('Total testimonials checked: $totalTestimonials');
      print('Updated testimonials: $updatedTestimonials');
      print('Skipped testimonials: $skippedTestimonials');
      print('Error testimonials: $errorTestimonials');
      
    } catch (e) {
      print('Error during status removal migration: $e');
    }
  }

  // Check how many testimonials still have the status field
  static Future<Map<String, int>> checkStatusRemovalStatus() async {
    try {
      QuerySnapshot testimonialsSnapshot = await _firestore.collection('testimonial').get();
      
      int totalTestimonials = testimonialsSnapshot.docs.length;
      int testimonialsWithStatus = 0;
      int testimonialsWithoutStatus = 0;
      
      for (QueryDocumentSnapshot testimonialDoc in testimonialsSnapshot.docs) {
        Map<String, dynamic> testimonialData = testimonialDoc.data() as Map<String, dynamic>;
        
        if (testimonialData.containsKey('status')) {
          testimonialsWithStatus++;
        } else {
          testimonialsWithoutStatus++;
        }
      }
      
      return {
        'total': totalTestimonials,
        'withStatus': testimonialsWithStatus,
        'withoutStatus': testimonialsWithoutStatus,
      };
      
    } catch (e) {
      print('Error checking status removal status: $e');
      return {
        'total': 0,
        'withStatus': 0,
        'withoutStatus': 0,
      };
    }
  }

  // Print current status removal progress
  static Future<void> printStatusRemovalProgress() async {
    Map<String, int> status = await checkStatusRemovalStatus();
    
    print('=== Status Field Removal Progress ===');
    print('Total testimonials: ${status['total']}');
    print('Testimonials with status field: ${status['withStatus']}');
    print('Testimonials without status field: ${status['withoutStatus']}');
    
    if (status['withStatus']! > 0) {
      print('Migration needed for ${status['withStatus']} testimonials');
    } else {
      print('All testimonials have been migrated - no status fields found');
    }
    print('=====================================');
  }
}
