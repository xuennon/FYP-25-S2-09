import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_subscription_service.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_programs';
  static const int _normalUserLimit = 3; // Normal users can only save 3 favorites
  
  static Future<Set<String>> getFavoritePrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
      return favoritesList.toSet();
    } catch (e) {
      print('Error loading favorites: $e');
      return {};
    }
  }
  
  static Future<bool> saveFavoritePrograms(Set<String> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, favorites.toList());
      return true;
    } catch (e) {
      print('Error saving favorites: $e');
      return false;
    }
  }
  
  // Check if user can add more favorites based on subscription
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
      print('Error checking favorites limit: $e');
      return {
        'canAdd': false,
        'reason': 'Error checking subscription status',
        'currentCount': 0,
        'limit': _normalUserLimit,
      };
    }
  }
  
  static Future<Map<String, dynamic>> addToFavorites(String programId) async {
    try {
      // Check if already favorited
      final favorites = await getFavoritePrograms();
      if (favorites.contains(programId)) {
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
      
      // Add to favorites
      favorites.add(programId);
      final saved = await saveFavoritePrograms(favorites);
      
      return {
        'success': saved,
        'message': saved ? 'Added to favorites!' : 'Failed to save favorites',
        'currentCount': favorites.length,
        'limit': canAddResult['limit'],
      };
    } catch (e) {
      print('Error adding to favorites: $e');
      return {
        'success': false,
        'message': 'Error adding to favorites: $e',
      };
    }
  }
  
  static Future<bool> removeFromFavorites(String programId) async {
    try {
      final favorites = await getFavoritePrograms();
      favorites.remove(programId);
      return await saveFavoritePrograms(favorites);
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }
  
  static Future<bool> isFavorite(String programId) async {
    try {
      final favorites = await getFavoritePrograms();
      return favorites.contains(programId);
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }
  
  // Get favorites status with subscription info
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
      print('Error getting favorites status: $e');
      return {
        'favorites': <String>{},
        'count': 0,
        'isPremium': false,
        'limit': _normalUserLimit,
        'canAddMore': true,
      };
    }
  }
}
