import 'package:flutter/material.dart';
import 'models/program.dart';
import 'services/firebase_programs_service.dart';
import 'services/favorites_service.dart';
import 'subscription_page.dart';

class ProgramDetailsPage extends StatefulWidget {
  final Program program;
  final bool? initialIsFavorite; // Optional parameter for initial favorite status

  const ProgramDetailsPage({
    super.key, 
    required this.program,
    this.initialIsFavorite,
  });

  @override
  State<ProgramDetailsPage> createState() => _ProgramDetailsPageState();
}

class _ProgramDetailsPageState extends State<ProgramDetailsPage> {
  final FirebaseProgramsService _programsService = FirebaseProgramsService();
  bool _isEnrolled = false;
  bool _isLoading = false;
  bool _enrollmentChanged = false; // Track if enrollment status changed
  bool _isFavorite = false; // Track if this program is favorited
  bool _favoriteChanged = false; // Track if favorite status changed

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite ?? false;
    _checkEnrollmentStatus();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await FavoritesService.isFavorite(widget.program.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    final enrolled = await _programsService.isEnrolledInProgram(widget.program.id);
    if (mounted) {
      setState(() {
        _isEnrolled = enrolled;
      });
    }
  }

  Future<void> _toggleEnrollment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isEnrolled) {
        success = await _programsService.unenrollFromProgram(widget.program.id);
        if (success) {
          setState(() {
            _isEnrolled = false;
            _enrollmentChanged = true; // Mark that enrollment changed
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unenrolled from ${widget.program.name}')),
            );
          }
        }
      } else {
        success = await _programsService.enrollInProgram(widget.program.id);
        if (success) {
          setState(() {
            _isEnrolled = true;
            _enrollmentChanged = true; // Mark that enrollment changed
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Enrolled in ${widget.program.name}!')),
            );
          }
        }
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() async {
    // If it's currently a favorite, allow removal without limit check
    if (_isFavorite) {
      setState(() {
        _isFavorite = false;
        _favoriteChanged = true;
      });
      
      try {
        await FavoritesService.removeFromFavorites(widget.program.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.program.name} removed from favorites!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error removing from favorites: $e');
        // Revert on error
        setState(() {
          _isFavorite = true;
        });
      }
    } else {
      // Adding to favorites - check limits
      final result = await FavoritesService.addToFavorites(widget.program.id);
      
      if (result['success']) {
        setState(() {
          _isFavorite = true;
          _favoriteChanged = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.program.name} added to favorites!'),
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
          onPressed: () => Navigator.pop(context, {
            'enrollmentChanged': _enrollmentChanged,
            'favoriteChanged': _favoriteChanged,
            'isFavorite': _isFavorite,
            'programId': widget.program.id,
          }),
        ),
        title: const Text(
          'Program Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.program.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.program.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultIcon();
                          },
                        ),
                      )
                    : _buildDefaultIcon(),
              ),
              const SizedBox(height: 20),

              // Program name and category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.program.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Program ID: ${widget.program.createdBy}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.program.category,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration
              Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    widget.program.duration,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.program.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Features
              if (widget.program.features.isNotEmpty) ...[
                const Text(
                  'What\'s Included',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.program.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 30),
              ],

              // Enroll button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleEnrollment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEnrolled ? Colors.red : Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEnrolled ? 'Unenroll from Program' : 'Enroll Now',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.fitness_center,
      size: 80,
      color: Colors.grey[400],
    );
  }
}
