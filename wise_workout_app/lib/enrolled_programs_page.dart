import 'package:flutter/material.dart';
import 'models/program.dart';
import 'services/firebase_programs_service.dart';
import 'services/favorites_service.dart';
import 'program_details_page.dart';
import 'subscription_page.dart';

class EnrolledProgramsPage extends StatefulWidget {
  const EnrolledProgramsPage({super.key});

  @override
  State<EnrolledProgramsPage> createState() => _EnrolledProgramsPageState();
}

class _EnrolledProgramsPageState extends State<EnrolledProgramsPage> with SingleTickerProviderStateMixin {
  final FirebaseProgramsService _programsService = FirebaseProgramsService();
  late TabController _tabController;
  List<Program> _enrolledPrograms = [];
  List<Program> _allPrograms = []; // Store all programs for favorites functionality
  Set<String> _favoritePrograms = {}; // Store favorite program IDs
  bool _isLoading = true;
  Map<String, dynamic>? _favoritesStatus; // Store favorites status info

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrolledPrograms();
    _loadFavoritePrograms();
    _loadFavoritesStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledPrograms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading enrolled programs...');
      
      // First, ensure all programs are loaded
      print('📚 Loading all programs first...');
      await _programsService.loadPrograms();
      print('✅ All programs loaded: ${_programsService.allPrograms.length}');
      
      // Store all programs for favorites functionality
      _allPrograms = _programsService.allPrograms;
      
      // Then get enrolled programs
      final enrolledPrograms = await _programsService.getEnrolledPrograms();
      print('✅ Loaded ${enrolledPrograms.length} enrolled programs');
      
      // Debug: Print enrolled program names
      for (var program in enrolledPrograms) {
        print('   📚 Enrolled: ${program.name}');
      }
      
      if (mounted) {
        setState(() {
          _enrolledPrograms = enrolledPrograms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading enrolled programs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading programs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFavoritePrograms() async {
    try {
      final favorites = await FavoritesService.getFavoritePrograms();
      setState(() {
        _favoritePrograms = favorites;
      });
    } catch (e) {
      print('Error loading favorite programs: $e');
    }
  }

  Future<void> _loadFavoritesStatus() async {
    try {
      final status = await FavoritesService.getFavoritesStatus();
      setState(() {
        _favoritesStatus = status;
      });
    } catch (e) {
      print('Error loading favorites status: $e');
    }
  }

  void _toggleFavorite(String programId) async {
    // If it's currently a favorite, allow removal without limit check
    if (_favoritePrograms.contains(programId)) {
      setState(() {
        _favoritePrograms.remove(programId);
      });
      
      try {
        await FavoritesService.removeFromFavorites(programId);
        
        // Refresh favorites status
        _loadFavoritesStatus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error removing from favorites: $e');
        // Revert on error
        setState(() {
          _favoritePrograms.add(programId);
        });
      }
    } else {
      // Adding to favorites - check limits
      final result = await FavoritesService.addToFavorites(programId);
      
      if (result['success']) {
        setState(() {
          _favoritePrograms.add(programId);
        });
        
        // Refresh favorites status
        _loadFavoritesStatus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show limit reached dialog for normal users
        if (result['isLimitReached'] == true && mounted) {
          _showFavoriteLimitDialog(result);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showFavoriteLimitDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Favorites Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ve reached your favorites limit (${result['currentCount']}/${result['limit']}).',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Get unlimited favorites and more features!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Training Programs',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadEnrolledPrograms,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Favorites'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _enrolledPrograms.isEmpty
                  ? _buildEmptyState()
                  : _buildProgramsList(_enrolledPrograms),
          // Favorites tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFavoritesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Enrolled Programs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t enrolled in any training programs yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to profile
                // You can navigate to programs page here if needed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Browse Programs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsList([List<Program>? programs]) {
    final programsToShow = programs ?? _enrolledPrograms;
    final isShowingFavorites = programs != null && programs != _enrolledPrograms;
    
    return RefreshIndicator(
      onRefresh: _loadEnrolledPrograms,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isShowingFavorites 
                ? 'Favorite Programs (${programsToShow.length})'
                : 'Enrolled Programs (${programsToShow.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: programsToShow.length,
                itemBuilder: (context, index) {
                  final program = programsToShow[index];
                  return _buildProgramCard(program);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    // Get all favorite programs from all programs (not just enrolled ones)
    final favoritePrograms = _allPrograms
        .where((program) => _favoritePrograms.contains(program.id))
        .toList();
    
    if (favoritePrograms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Favorite Programs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mark programs as favorites by tapping the heart icon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _buildFavoritesStatusCard(),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Favorites status card
        _buildFavoritesStatusCard(),
        const SizedBox(height: 8),
        // Programs list
        Expanded(child: _buildProgramsList(favoritePrograms)),
      ],
    );
  }

  Widget _buildFavoritesStatusCard() {
    if (_favoritesStatus == null) return const SizedBox.shrink();
    
    final isPremium = _favoritesStatus!['isPremium'] ?? false;
    final count = _favoritesStatus!['count'] ?? 0;
    final limit = _favoritesStatus!['limit'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
            ? [Colors.purple.withOpacity(0.1), Colors.deepPurple.withOpacity(0.1)]
            : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium ? Colors.purple.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.star : Icons.favorite,
            color: isPremium ? Colors.purple : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium User' : 'Free User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.purple : Colors.orange,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPremium 
                    ? 'Unlimited favorites ($count saved)'
                    : 'Favorites: $count/${limit ?? 3}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium && limit != null && count >= limit) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgramCard(Program program) {
    final isEnrolled = _enrolledPrograms.any((p) => p.id == program.id);
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramDetailsPage(
              program: program,
              initialIsFavorite: _favoritePrograms.contains(program.id),
            ),
          ),
        );
        
        // Handle the returned result
        if (result != null) {
          if (result is Map<String, dynamic>) {
            final enrollmentChanged = result['enrollmentChanged'] ?? false;
            final favoriteChanged = result['favoriteChanged'] ?? false;
            final isFavorite = result['isFavorite'] ?? false;
            final programId = result['programId'] ?? '';
            
            // Update favorite status if it changed
            if (favoriteChanged && programId.isNotEmpty) {
              setState(() {
                if (isFavorite) {
                  _favoritePrograms.add(programId);
                } else {
                  _favoritePrograms.remove(programId);
                }
              });
            }
            
            // Refresh the list if enrollment status changed
            if (enrollmentChanged) {
              print('Enrollment status changed, refreshing enrolled programs list...');
              _loadEnrolledPrograms();
            }
          } else if (result == true) {
            // Handle old format for backward compatibility
            print('Enrollment status changed, refreshing enrolled programs list...');
            _loadEnrolledPrograms();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program image/icon with favorite button
              Stack(
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: program.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              program.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.fitness_center,
                                  size: 40,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.fitness_center,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(program.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favoritePrograms.contains(program.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: _favoritePrograms.contains(program.id)
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Program name
              Text(
                program.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Category badge
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        program.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (isEnrolled) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Enrolled',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              
              // Duration
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      program.duration,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
