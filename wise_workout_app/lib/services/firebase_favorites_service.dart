import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_subscription_service.dart';

class FirebaseFavoritesService {
  static const String _favoritesCollection = 'user_favorites';
  static const int _normalUserLimit = 3; // Normal users can only save 3 favorites
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Get user's favorites collection reference
  static CollectionReference? get _userFavoritesRef {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection(_favoritesCollection);
  }

  /// Get all favorite program IDs for the current user
  static Future<Set<String>> getFavoritePrograms() async {
    try {
      if (_userFavoritesRef == null) {
        print('❌ No authenticated user found');
        return {};
      }

      final snapshot = await _userFavoritesRef!.get();
      final favorites = snapshot.docs.map((doc) => doc.id).toSet();
      
      print('✅ Loaded ${favorites.length} favorites from Firebase');
      return favorites;
    } catch (e) {
      print('❌ Error loading favorites from Firebase: $e');
      return {};
    }
  }

  /// Check if user can add more favorites based on subscription
  static Future<Map<String, dynamic>> canAddToFavorites() async {
    try {
      final subscriptionService = FirebaseSubscriptionService();
      final favorites = await getFavoritePrograms();
      final isPremium = await subscriptionService.hasPremiumSubscription();
      
      if (isPremium) {
        return {
          'canAdd': true,
          'reason': 'Premium user - unlimited favorites',
          'currentCount': favorites.length,
          'limit': null,
        };
      } else {
        final canAdd = favorites.length < _normalUserLimit;
        return {
          'canAdd': canAdd,
          'reason': canAdd 
            ? 'Normal user - ${favorites.length}/$_normalUserLimit favorites used'
            : 'Normal user limit reached ($_normalUserLimit favorites). Upgrade to Premium for unlimited favorites!',
          'currentCount': favorites.length,
          'limit': _normalUserLimit,
        };
      }
    } catch (e) {
      print('❌ Error checking favorites limit: $e');
      return {
        'canAdd': false,
        'reason': 'Error checking subscription status',
        'currentCount': 0,
        'limit': _normalUserLimit,
      };
    }
  }

  /// Add a program to favorites
  static Future<Map<String, dynamic>> addToFavorites(String programId) async {
    try {
      if (_userFavoritesRef == null) {
        return {
          'success': false,
          'message': 'Please log in to save favorites',
        };
      }

      // Check if already favorited
      final doc = await _userFavoritesRef!.doc(programId).get();
      if (doc.exists) {
        return {
          'success': true,
          'message': 'Already in favorites',
        };
      }

      // Check if user can add more favorites
      final canAddResult = await canAddToFavorites();
      if (!canAddResult['canAdd']) {
        return {
          'success': false,
          'message': canAddResult['reason'],
          'isLimitReached': true,
          'currentCount': canAddResult['currentCount'],
          'limit': canAddResult['limit'],
        };
      }

      // Add to Firebase favorites
      await _userFavoritesRef!.doc(programId).set({
        'programId': programId,
        'addedAt': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
      });

      final newCount = canAddResult['currentCount'] + 1;
      
      print('✅ Added program $programId to favorites (count: $newCount)');
      
      return {
        'success': true,
        'message': 'Added to favorites!',
        'currentCount': newCount,
        'limit': canAddResult['limit'],
      };
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return {
        'success': false,
        'message': 'Error adding to favorites: $e',
      };
    }
  }

  /// Remove a program from favorites
  static Future<bool> removeFromFavorites(String programId) async {
    try {
      if (_userFavoritesRef == null) {
        print('❌ No authenticated user found');
        return false;
      }

      await _userFavoritesRef!.doc(programId).delete();
      print('✅ Removed program $programId from favorites');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if a program is favorited
  static Future<bool> isFavorite(String programId) async {
    try {
      if (_userFavoritesRef == null) return false;
      
      final doc = await _userFavoritesRef!.doc(programId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking if favorite: $e');
      return false;
    }
  }

  /// Get favorites status with subscription info
  static Future<Map<String, dynamic>> getFavoritesStatus() async {
    try {
      final subscriptionService = FirebaseSubscriptionService();
      final favorites = await getFavoritePrograms();
      final isPremium = await subscriptionService.hasPremiumSubscription();
      
      return {
        'favorites': favorites,
        'count': favorites.length,
        'isPremium': isPremium,
        'limit': isPremium ? null : _normalUserLimit,
        'canAddMore': isPremium || favorites.length < _normalUserLimit,
      };
    } catch (e) {
      print('❌ Error getting favorites status: $e');
      return {
        'favorites': <String>{},
        'count': 0,
        'isPremium': false,
        'limit': _normalUserLimit,
        'canAddMore': true,
      };
    }
  }

  /// Get favorites with real-time updates (Stream)
  static Stream<Set<String>> getFavoritesStream() {
    if (_userFavoritesRef == null) {
      return Stream.value({});
    }

    return _userFavoritesRef!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  /// Migrate existing local favorites to Firebase (one-time migration)
  static Future<bool> migrateLocalFavoritesToFirebase() async {
    try {
      if (_userFavoritesRef == null) {
        print('❌ No authenticated user for migration');
        return false;
      }

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      const String localFavoritesKey = 'favorite_programs';
      final localFavorites = prefs.getStringList(localFavoritesKey) ?? [];
      
      if (localFavorites.isEmpty) {
        print('✅ No local favorites to migrate');
        return true;
      }

      print('🔄 Migrating ${localFavorites.length} local favorites to Firebase...');
      
      // Batch write for efficiency
      final batch = _firestore.batch();
      
      for (final programId in localFavorites) {
        final docRef = _userFavoritesRef!.doc(programId);
        batch.set(docRef, {
          'programId': programId,
          'addedAt': FieldValue.serverTimestamp(),
          'userId': _currentUserId,
          'migratedFromLocal': true,
        });
      }
      
      await batch.commit();
      
      // Clear local favorites after successful migration
      await prefs.remove(localFavoritesKey);
      
      print('✅ Successfully migrated ${localFavorites.length} favorites to Firebase');
      return true;
    } catch (e) {
      print('❌ Error migrating local favorites: $e');
      return false;
    }
  }

  /// Clear all favorites for the current user
  static Future<bool> clearAllFavorites() async {
    try {
      if (_userFavoritesRef == null) return false;
      
      final snapshot = await _userFavoritesRef!.get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Cleared all favorites');
      return true;
    } catch (e) {
      print('❌ Error clearing favorites: $e');
      return false;
    }
  }
}
