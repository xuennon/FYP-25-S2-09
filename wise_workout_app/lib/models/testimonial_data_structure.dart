// Updated Testimonial/Feedback Data Structure Documentation
// After removing the status field

import 'package:cloud_firestore/cloud_firestore.dart';

/*
TESTIMONIAL/FEEDBACK DATA STRUCTURE (Updated - No Status Field)

Your Firebase testimonial documents now have this clean structure:

{
  "userId": "5bP0kcGL6cSqNPQfpDH5uJUMSqH2",
  "rating": 5,
  "feedback": "cm is a handsome boy",
  "name": null,                    // Optional - user's name
  "email": null,                   // Optional - user's email
  "timestamp": "2025-08-04T01:57:44Z",
  "isCompleted": true,             // Boolean - indicates if testimonial is complete
  "userType": "normal"             // String - user's subscription type
}

FIELD DESCRIPTIONS:

1. userId (String, Required)
   - Firebase Auth user ID of the person who submitted the feedback

2. rating (Number, Required) 
   - Star rating from 1-5

3. feedback (String, Required)
   - The actual feedback text content

4. name (String, Optional)
   - User's name if they chose to provide it
   - null if not provided

5. email (String, Optional)  
   - User's email if they chose to provide it
   - null if not provided

6. timestamp (Timestamp, Required)
   - When the feedback was submitted
   - Automatically set by Firebase server

7. isCompleted (Boolean, Required)
   - true: Testimonial is complete with feedback
   - false: Testimonial is incomplete/draft (rarely used since we only save completed ones)

8. userType (String, Required)
   - "normal": Free plan users
   - "premium": Premium subscription users
   - Automatically determined from user's current subscription

REMOVED FIELDS:
- status: This field has been removed and is no longer used

MIGRATION NOTES:
- Use StatusRemovalMigrationService.removeStatusFromTestimonials() to clean existing data
- All new testimonials will automatically exclude the status field
- Existing testimonials with status field should be migrated
*/

class TestimonialDataStructure {
  // This class serves as documentation and type reference
  
  static const String COLLECTION_NAME = 'testimonial';
  
  // Field names (use these constants to avoid typos)
  static const String FIELD_USER_ID = 'userId';
  static const String FIELD_RATING = 'rating';
  static const String FIELD_FEEDBACK = 'feedback';
  static const String FIELD_NAME = 'name';
  static const String FIELD_EMAIL = 'email';
  static const String FIELD_TIMESTAMP = 'timestamp';
  static const String FIELD_IS_COMPLETED = 'isCompleted';
  static const String FIELD_USER_TYPE = 'userType';
  
  // User type values
  static const String USER_TYPE_NORMAL = 'normal';
  static const String USER_TYPE_PREMIUM = 'premium';
  
  // Example of creating a testimonial data map
  static Map<String, dynamic> createTestimonialData({
    required String userId,
    required int rating,
    required String feedback,
    String? name,
    String? email,
    required bool isCompleted,
    required String userType,
  }) {
    return {
      FIELD_USER_ID: userId,
      FIELD_RATING: rating,
      FIELD_FEEDBACK: feedback,
      FIELD_NAME: name,
      FIELD_EMAIL: email,
      FIELD_TIMESTAMP: FieldValue.serverTimestamp(),
      FIELD_IS_COMPLETED: isCompleted,
      FIELD_USER_TYPE: userType,
    };
  }
  
  // Validate user type
  static bool isValidUserType(String userType) {
    return userType == USER_TYPE_NORMAL || userType == USER_TYPE_PREMIUM;
  }
  
  // Validate rating
  static bool isValidRating(int rating) {
    return rating >= 1 && rating <= 5;
  }
}
