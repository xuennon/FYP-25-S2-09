import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/program.dart';

class FirebaseProgramsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Program> _allPrograms = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _programsSubscription;
  
  List<Program> get allPrograms => _allPrograms;
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;

  // Start real-time listening for programs
  void startListening() {
    _programsSubscription?.cancel(); // Cancel any existing subscription
    
    _programsSubscription = _firestore
        .collection('services')
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _updateProgramsFromSnapshot(snapshot);
          },
          onError: (error) {
            print('❌ Error in programs stream: $error');
            // Fallback to manual loading
            loadPrograms();
          },
        );
  }

  // Stop real-time listening
  void stopListening() {
    _programsSubscription?.cancel();
    _programsSubscription = null;
  }

  // Update programs from Firestore snapshot
  void _updateProgramsFromSnapshot(QuerySnapshot snapshot) {
    try {
      print('🔄 Real-time update: Processing ${snapshot.docs.length} program documents...');
      
      // Filter and sort in memory
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Only include programs that have required fields and valid data
        return data.containsKey('name') && 
               data.containsKey('category') &&
               data.containsKey('createdBy') &&
               data['name']?.toString().isNotEmpty == true &&
               data['category']?.toString().isNotEmpty == true &&
               data['createdBy']?.toString().isNotEmpty == true &&
               (data['isActive'] == true || data['isActive'] == null);
      }).toList();
      
      // Sort by createdAt if available
      filteredDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aCreatedAt = aData['createdAt'] as Timestamp?;
        final bCreatedAt = bData['createdAt'] as Timestamp?;
        
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        
        return bCreatedAt.compareTo(aCreatedAt); // Descending order
      });
      
      _allPrograms = filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Program.fromMap(data, doc.id);
      }).toList();
      
      print('📚 Real-time update: Loaded ${_allPrograms.length} programs');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error updating programs from snapshot: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manual loading as fallback
  Future<void> loadPrograms() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('🔄 Manual loading programs from services collection...');
      
      QuerySnapshot querySnapshot;
      
      try {
        // First, try to get all documents from services collection
        querySnapshot = await _firestore
            .collection('services')
            .get();
      } catch (permissionError) {
        print('❌ Permission error, trying alternative approach...');
        
        // If that fails, try without any conditions
        try {
          querySnapshot = await _firestore
              .collection('services')
              .limit(50) // Limit to avoid too much data
              .get();
        } catch (e) {
          print('❌ Alternative approach also failed: $e');
          // Return empty list but don't throw error
          _allPrograms = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      _updateProgramsFromSnapshot(querySnapshot);
    } catch (e) {
      print('❌ Error in manual loading programs: $e');
      _isLoading = false;
      _allPrograms = []; // Ensure we have an empty list on error
      notifyListeners();
    }
  }

  // Clean up when service is disposed
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  List<Program> getProgramsByCategory(String category) {
    if (category == 'All') {
      return _allPrograms;
    }
    return _allPrograms.where((program) => 
      program.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  List<String> getAvailableCategories() {
    final categories = _allPrograms.map((program) => program.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  Program? getProgramById(String programId) {
    try {
      return _allPrograms.firstWhere((program) => program.id == programId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> enrollInProgram(String programId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Add user to program enrollments
      await _firestore
          .collection('program_enrollments')
          .doc('${currentUser.uid}_$programId')
          .set({
        'userId': currentUser.uid,
        'programId': programId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      print('✅ Successfully enrolled in program: $programId');
      return true;
    } catch (e) {
      print('❌ Error enrolling in program: $e');
      return false;
    }
  }

  Future<bool> unenrollFromProgram(String programId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Remove user from program enrollments
      await _firestore
          .collection('program_enrollments')
          .doc('${currentUser.uid}_$programId')
          .delete();

      print('✅ Successfully unenrolled from program: $programId');
      return true;
    } catch (e) {
      print('❌ Error unenrolling from program: $e');
      return false;
    }
  }

  Future<bool> isEnrolledInProgram(String programId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection('program_enrollments')
          .doc('${currentUser.uid}_$programId')
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking enrollment status: $e');
      return false;
    }
  }

  Future<List<Program>> getEnrolledPrograms() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final enrollmentsSnapshot = await _firestore
          .collection('program_enrollments')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      final programIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['programId'] as String)
          .toList();

      return _allPrograms.where((program) => 
        programIds.contains(program.id)
      ).toList();
    } catch (e) {
      print('❌ Error getting enrolled programs: $e');
      return [];
    }
  }
}
