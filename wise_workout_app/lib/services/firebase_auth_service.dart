import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword(String email, String password) async {
    try {
      print('Attempting Firebase login for: $email');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase auth successful, user: ${result.user?.uid}');
      
      if (result.user != null) {
        try {
          // Get user role from Firestore
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .get();
          
          print('Firestore document exists: ${userDoc.exists}');
          
          if (userDoc.exists) {
            Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
            if (userData != null) {
              return {
                'success': true,
                'user': result.user,
                'role': userData['role'] ?? 'user',
                'message': 'Login successful'
              };
            }
          }
          
          // Create user document if it doesn't exist (for first time login)
          print('Creating new user document...');
          await _createUserDocument(result.user!, 'user');
          return {
            'success': true,
            'user': result.user,
            'role': 'user',
            'message': 'Login successful'
          };
        } catch (firestoreError) {
          print('Firestore error: $firestoreError');
          // Even if Firestore fails, we can still log in
          return {
            'success': true,
            'user': result.user,
            'role': 'user',
            'message': 'Login successful (role defaulted)'
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Login failed - no user returned'
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message
      };
    } catch (e) {
      print('Unexpected error during login: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e'
      };
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'role': role,
      'displayName': user.displayName ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Register new user
  Future<Map<String, dynamic>> registerWithEmailPassword(
    String email, 
    String password, 
    String displayName,
    {String role = 'user'}
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(displayName);
        
        // Create user document
        await _createUserDocument(result.user!, role);
        
        return {
          'success': true,
          'user': result.user,
          'message': 'Registration successful'
        };
      }
      
      return {
        'success': false,
        'message': 'Registration failed'
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e'
      };
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get user role
  Future<String> getUserRole() async {
    if (_auth.currentUser == null) return 'guest';
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] ?? 'user';
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    
    return 'user';
  }
}
