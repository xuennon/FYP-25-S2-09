import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import 'firebase_subscription_service.dart';

class FirebaseTeamsService extends ChangeNotifier {
  static final FirebaseTeamsService _instance = FirebaseTeamsService._internal();
  factory FirebaseTeamsService() => _instance;
  FirebaseTeamsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();
  
  List<Team> _allTeams = [];
  List<Team> _myTeams = [];
  List<Team> _joinedTeams = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _teamsSubscription;
  
  // Constants for member limits
  static const int FREE_USER_TEAM_MEMBER_LIMIT = 4;
  static const int PREMIUM_USER_TEAM_MEMBER_LIMIT = -1; // -1 means unlimited
  
  List<Team> get allTeams => _allTeams;
  List<Team> get myTeams => _myTeams;
  List<Team> get joinedTeams => _joinedTeams;
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;

  // Start real-time listening for teams
  void startListening() {
    _teamsSubscription?.cancel();
    
    _teamsSubscription = _firestore
        .collection('teams')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _updateTeamsFromSnapshot(snapshot);
          },
          onError: (error) {
            print('❌ Error in teams stream: $error');
            loadTeams();
          },
        );
  }

  // Stop real-time listening
  void stopListening() {
    _teamsSubscription?.cancel();
    _teamsSubscription = null;
  }

  // Update teams from Firestore snapshot
  void _updateTeamsFromSnapshot(QuerySnapshot snapshot) {
    try {
      print('🔄 Real-time update: Processing ${snapshot.docs.length} team documents...');
      
      _allTeams = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Team.fromMap(data, doc.id);
      }).toList();
      
      // Sort by created date (newest first)
      _allTeams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _categorizeTeams();
      
      print('🏆 Real-time update: Loaded ${_allTeams.length} teams');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error updating teams from snapshot: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Categorize teams into my teams and joined teams
  void _categorizeTeams() {
    if (currentUserId == null) {
      _myTeams = [];
      _joinedTeams = [];
      return;
    }

    _myTeams = _allTeams.where((team) => team.isCreator(currentUserId!)).toList();
    _joinedTeams = _allTeams.where((team) => 
      team.isMember(currentUserId!) && !team.isCreator(currentUserId!)
    ).toList();
  }

  // Manual loading as fallback
  Future<void> loadTeams() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('🔄 Manual loading teams from Firebase...');
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('teams')
          .where('isActive', isEqualTo: true)
          .get();
      
      _updateTeamsFromSnapshot(querySnapshot);
    } catch (e) {
      print('❌ Error in manual loading teams: $e');
      _isLoading = false;
      _allTeams = [];
      notifyListeners();
    }
  }

  // Create a new team
  Future<String?> createTeam({
    required String name,
    required String description,
    String? imageUrl,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user - currentUserId is null');
        print('❌ FirebaseAuth.instance.currentUser: ${_auth.currentUser}');
        return null;
      }

      print('🔄 Creating team: $name');
      print('🔄 User ID: $currentUserId');
      print('🔄 Description: $description');

      final teamData = {
        'name': name,
        'description': description,
        'createdBy': currentUserId,
        'members': [currentUserId], // Creator is automatically a member
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      print('🔄 Team data to be saved: $teamData');

      DocumentReference docRef = await _firestore
          .collection('teams')
          .add(teamData);

      print('✅ Successfully created team: $name with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Error creating team: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // Join a team with detailed result information
  Future<Map<String, dynamic>> joinTeamWithResult(String teamId) async {
    try {
      if (currentUserId == null) {
        return {
          'success': false,
          'message': 'Please log in to join a team.',
        };
      }

      // First check if team exists
      final team = getTeamById(teamId);
      if (team == null) {
        return {
          'success': false,
          'message': 'Team not found.',
        };
      }

      // Check if user is already a member
      if (team.isMember(currentUserId!)) {
        return {
          'success': false,
          'message': 'You are already a member of this team.',
        };
      }

      // Check if team can accept new members based on creator's subscription
      final canAcceptMembers = await canTeamAcceptNewMembers(teamId);
      if (!canAcceptMembers) {
        final memberLimit = await getTeamMemberLimitForTeam(teamId);
        return {
          'success': false,
          'message': 'This team has reached its member limit of $memberLimit members. The team creator needs to upgrade to Premium for unlimited members.',
        };
      }

      // Add user to team members array
      await _firestore.collection('teams').doc(teamId).update({
        'members': FieldValue.arrayUnion([currentUserId]),
      });

      // Force reload to ensure UI updates immediately
      await loadTeams();
      
      return {
        'success': true,
        'message': 'Successfully joined ${team.name}!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error joining team: $e',
      };
    }
  }

  // Join a team
  Future<bool> joinTeam(String teamId) async {
    final result = await joinTeamWithResult(teamId);
    return result['success'] as bool;
  }

  // Leave a team
  Future<bool> leaveTeam(String teamId) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('🔄 Leaving team: $teamId');
      print('🔄 Current user ID: $currentUserId');

      // First check if user is actually a member
      final team = getTeamById(teamId);
      if (team == null) {
        print('❌ Team not found: $teamId');
        return false;
      }

      if (!team.isMember(currentUserId!)) {
        print('❌ User is not a member of team: $teamId');
        return false;
      }

      // Remove user from team members array
      await _firestore.collection('teams').doc(teamId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      print('✅ Successfully left team: $teamId');
      
      // Force reload to ensure UI updates immediately
      await loadTeams();
      
      return true;
    } catch (e) {
      print('❌ Error leaving team: $e');
      return false;
    }
  }

  // Search teams by name or description
  List<Team> searchTeams(String query) {
    if (query.isEmpty) return _allTeams;
    
    final lowercaseQuery = query.toLowerCase();
    return _allTeams.where((team) =>
      team.name.toLowerCase().contains(lowercaseQuery) ||
      team.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Get team by ID
  Team? getTeamById(String teamId) {
    try {
      return _allTeams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is member of a team
  bool isTeamMember(String teamId) {
    if (currentUserId == null) return false;
    final team = getTeamById(teamId);
    return team?.isMember(currentUserId!) ?? false;
  }

  // Check if user is creator of a team
  bool isTeamCreator(String teamId) {
    if (currentUserId == null) return false;
    final team = getTeamById(teamId);
    return team?.isCreator(currentUserId!) ?? false;
  }

  // Get maximum team member limit for current user based on subscription
  Future<int> getTeamMemberLimit() async {
    try {
      bool isPremium = await _subscriptionService.hasPremiumSubscription();
      return isPremium ? PREMIUM_USER_TEAM_MEMBER_LIMIT : FREE_USER_TEAM_MEMBER_LIMIT;
    } catch (e) {
      print('❌ Error checking subscription: $e');
      return FREE_USER_TEAM_MEMBER_LIMIT; // Default to free limit on error
    }
  }

  // Check if team can accept new members based on creator's subscription
  Future<bool> canTeamAcceptNewMembers(String teamId) async {
    try {
      final team = getTeamById(teamId);
      if (team == null) return false;

      // Get the creator's subscription type
      final creatorDoc = await _firestore.collection('users').doc(team.createdBy).get();
      if (!creatorDoc.exists) {
        return team.memberCount < FREE_USER_TEAM_MEMBER_LIMIT;
      }

      final creatorData = creatorDoc.data() as Map<String, dynamic>;
      final creatorUserType = creatorData['userType'] ?? 'normal';
      
      if (creatorUserType == 'premium') {
        return true; // Premium users have unlimited members
      } else {
        return team.memberCount < FREE_USER_TEAM_MEMBER_LIMIT;
      }
    } catch (e) {
      print('❌ Error checking team member capacity: $e');
      return false;
    }
  }

  // Get team member limit for a specific team based on creator's subscription
  Future<int> getTeamMemberLimitForTeam(String teamId) async {
    try {
      final team = getTeamById(teamId);
      if (team == null) return FREE_USER_TEAM_MEMBER_LIMIT;

      // Get the creator's subscription type
      final creatorDoc = await _firestore.collection('users').doc(team.createdBy).get();
      if (!creatorDoc.exists) {
        return FREE_USER_TEAM_MEMBER_LIMIT;
      }

      final creatorData = creatorDoc.data() as Map<String, dynamic>;
      final creatorUserType = creatorData['userType'] ?? 'normal';
      
      return creatorUserType == 'premium' ? PREMIUM_USER_TEAM_MEMBER_LIMIT : FREE_USER_TEAM_MEMBER_LIMIT;
    } catch (e) {
      print('❌ Error getting team member limit: $e');
      return FREE_USER_TEAM_MEMBER_LIMIT;
    }
  }

  // Update team information (only creator can do this)
  Future<bool> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Check if user is the creator
      if (!isTeamCreator(teamId)) {
        print('❌ User is not the creator of this team');
        return false;
      }

      print('🔄 Updating team: $teamId');

      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      if (updateData.isNotEmpty) {
        await _firestore.collection('teams').doc(teamId).update(updateData);
        print('✅ Successfully updated team: $teamId');
      }

      return true;
    } catch (e) {
      print('❌ Error updating team: $e');
      return false;
    }
  }

  // Delete team (only creator can do this)
  Future<bool> deleteTeam(String teamId) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Check if user is the creator
      if (!isTeamCreator(teamId)) {
        print('❌ User is not the creator of this team');
        return false;
      }

      print('🔄 Permanently deleting team: $teamId');

      // Permanent delete - completely remove the document from Firebase
      await _firestore.collection('teams').doc(teamId).delete();

      print('✅ Successfully permanently deleted team: $teamId');
      return true;
    } catch (e) {
      print('❌ Error deleting team: $e');
      return false;
    }
  }

  // Get teams stream for real-time updates
  Stream<List<Team>> getTeamsStream() {
    return _firestore
        .collection('teams')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Team.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Clean up when service is disposed
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
