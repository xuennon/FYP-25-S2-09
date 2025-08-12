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
    
    print('🎧 Starting real-time listening for programs...');
    
    _programsSubscription = _firestore
        .collection('services')
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            print('🔔 Real-time update received: ${snapshot.docs.length} documents');
            _updateProgramsFromSnapshot(snapshot);
          },
          onError: (error) {
            print('❌ Error in programs stream: $error');
            print('❌ Stream error type: ${error.runtimeType}');
            // Fallback to manual loading
            print('🔄 Falling back to manual loading...');
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
      
      // Debug: Print all document data
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('📄 Document ${doc.id}: $data');
      }
      
      // More lenient filtering - only require essential fields
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check basic requirements
        bool hasName = data.containsKey('name') && data['name'] != null && data['name'].toString().trim().isNotEmpty;
        bool hasCategory = data.containsKey('category') && data['category'] != null && data['category'].toString().trim().isNotEmpty;
        bool hasCreatedBy = data.containsKey('createdBy') && data['createdBy'] != null && data['createdBy'].toString().trim().isNotEmpty;
        
        // Duration is optional but if present should not be empty
        bool durationOk = !data.containsKey('duration') || data['duration'] == null || data['duration'].toString().trim().isNotEmpty;
        
        // isActive check - default to true if not specified
        bool isActiveOk = data['isActive'] != false; // Allow null or true
        
        bool passesFilter = hasName && hasCategory && hasCreatedBy && durationOk && isActiveOk;
        
        print('🔍 Doc ${doc.id}: name=$hasName, category=$hasCategory, createdBy=$hasCreatedBy, duration=$durationOk, isActive=$isActiveOk => ${passesFilter ? "PASS" : "FAIL"}');
        
        return passesFilter;
      }).toList();
      
      print('✅ Filtered documents: ${filteredDocs.length}/${snapshot.docs.length} passed filter');
      
      // Sort by createdAt if available
      filteredDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        // Handle different timestamp formats
        DateTime? aCreatedAt;
        DateTime? bCreatedAt;
        
        try {
          if (aData['createdAt'] != null) {
            if (aData['createdAt'] is String) {
              aCreatedAt = DateTime.parse(aData['createdAt']);
            } else {
              aCreatedAt = (aData['createdAt'] as Timestamp).toDate();
            }
          }
        } catch (e) {
          print('⚠️ Could not parse createdAt for doc ${a.id}: ${aData['createdAt']}');
        }
        
        try {
          if (bData['createdAt'] != null) {
            if (bData['createdAt'] is String) {
              bCreatedAt = DateTime.parse(bData['createdAt']);
            } else {
              bCreatedAt = (bData['createdAt'] as Timestamp).toDate();
            }
          }
        } catch (e) {
          print('⚠️ Could not parse createdAt for doc ${b.id}: ${bData['createdAt']}');
        }
        
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        
        return bCreatedAt.compareTo(aCreatedAt); // Descending order (newest first)
      });
      
      // Convert to Program objects
      final programs = <Program>[];
      for (var doc in filteredDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final program = Program.fromMap(data, doc.id);
          programs.add(program);
        } catch (e) {
          print('❌ Error creating Program from doc ${doc.id}: $e');
          // Continue with other documents
        }
      }
      
      _allPrograms = programs;
      
      print('📚 Real-time update: Successfully loaded ${_allPrograms.length} programs');
      
      // Debug: Print program names
      for (var program in _allPrograms) {
        print('   ✅ ${program.name} (${program.category}) - ${program.duration}');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error updating programs from snapshot: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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
      
      // Since Firebase rules allow public read access to services collection,
      // we don't need to check authentication for reading
      final currentUser = _auth.currentUser;
      print('🔍 Current user: ${currentUser?.uid ?? 'null'} (anonymous: ${currentUser?.isAnonymous ?? 'N/A'})');
      
      QuerySnapshot querySnapshot;
      
      try {
        // Try to get all documents from services collection
        print('🔄 Attempting to fetch from services collection...');
        querySnapshot = await _firestore
            .collection('services')
            .get();
            
        print('✅ Successfully fetched ${querySnapshot.docs.length} documents from services collection');
        
        // Debug: Print first few document IDs
        for (int i = 0; i < querySnapshot.docs.length && i < 3; i++) {
          print('📄 Document ${i+1}: ${querySnapshot.docs[i].id}');
        }
        
      } catch (error) {
        print('❌ Error fetching from services collection: $error');
        print('❌ Error type: ${error.runtimeType}');
        
        // Try alternative approach with limit
        try {
          print('🔄 Trying with limit...');
          querySnapshot = await _firestore
              .collection('services')
              .limit(50)
              .get();
          print('✅ Alternative approach successful: ${querySnapshot.docs.length} documents');
        } catch (e) {
          print('❌ Alternative approach also failed: $e');
          _allPrograms = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      _updateProgramsFromSnapshot(querySnapshot);
    } catch (e) {
      print('❌ Error in manual loading programs: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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
        print('❌ No user logged in for enrollment');
        return false;
      }

      print('🔄 Enrolling user ${currentUser.uid} in program $programId');

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
        print('❌ No user logged in for unenrollment');
        return false;
      }

      print('🔄 Unenrolling user ${currentUser.uid} from program $programId');

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
      if (currentUser == null) {
        print('❌ No user logged in for getEnrolledPrograms');
        return [];
      }

      print('🔍 Getting enrolled programs for user: ${currentUser.uid}');

      final enrollmentsSnapshot = await _firestore
          .collection('program_enrollments')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      print('📄 Found ${enrollmentsSnapshot.docs.length} enrollment documents');

      final programIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['programId'] as String)
          .toList();

      print('🔍 Program IDs from enrollments: $programIds');

      final enrolledPrograms = _allPrograms.where((program) => 
        programIds.contains(program.id)
      ).toList();

      print('✅ Matched ${enrolledPrograms.length} programs from ${_allPrograms.length} total programs');
      
      // Debug: Print enrolled program details
      for (var program in enrolledPrograms) {
        print('   📚 Enrolled Program: ${program.name} (ID: ${program.id})');
      }

      return enrolledPrograms;
    } catch (e) {
      print('❌ Error getting enrolled programs: $e');
      return [];
    }
  }
}
