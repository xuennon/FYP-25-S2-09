import 'firebase_favorites_service.dart';

class FavoritesService {
  // Delegate all calls to Firebase service for better architecture
  
  static Future<Set<String>> getFavoritePrograms() async {
    return FirebaseFavoritesService.getFavoritePrograms();
  }
  
  static Future<Map<String, dynamic>> canAddToFavorites() async {
    return FirebaseFavoritesService.canAddToFavorites();
  }
  
  static Future<Map<String, dynamic>> addToFavorites(String programId) async {
    return FirebaseFavoritesService.addToFavorites(programId);
  }
  
  static Future<bool> removeFromFavorites(String programId) async {
    return FirebaseFavoritesService.removeFromFavorites(programId);
  }
  
  static Future<bool> isFavorite(String programId) async {
    return FirebaseFavoritesService.isFavorite(programId);
  }
  
  static Future<Map<String, dynamic>> getFavoritesStatus() async {
    return FirebaseFavoritesService.getFavoritesStatus();
  }
  
  // Additional Firebase-specific methods
  static Stream<Set<String>> getFavoritesStream() {
    return FirebaseFavoritesService.getFavoritesStream();
  }
  
  static Future<bool> migrateLocalFavoritesToFirebase() async {
    return FirebaseFavoritesService.migrateLocalFavoritesToFirebase();
  }
}
