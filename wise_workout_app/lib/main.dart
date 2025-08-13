import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'user_home_page.dart';
import 'services/firebase_auth_service.dart';
import 'services/user_profile_service.dart';
import 'services/firebase_user_profile_service.dart';
import 'services/firebase_teams_service.dart';
import 'team_details_page.dart';
import 'models/team.dart';
import 'reset_password_page.dart';

// Global navigation key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _pendingTeamLink;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinking();
  }

  void _initializeDeepLinking() {
    // Listen for Firebase Auth state changes to handle pending team links
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && _pendingTeamLink != null) {
        // User is authenticated, handle the pending team link
        _handleTeamLink(_pendingTeamLink!);
        _pendingTeamLink = null;
      }
    });
  }

  Future<void> _handleTeamLink(String linkToken) async {
    try {
      final teamsService = FirebaseTeamsService();
      final linkInfo = await teamsService.getTeamFromLink(linkToken);
      
      if (linkInfo != null) {
        // Create Team object from the team data
        final teamData = Team.fromMap(linkInfo['teamData'], linkInfo['teamId']);
        
        // Navigate to team details page
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TeamDetailsPage(teamData: teamData),
          ),
          (route) => false,
        );
        
        // If user is not already a member, show join dialog
        if (!linkInfo['isAlreadyMember']) {
          await Future.delayed(const Duration(milliseconds: 500));
          final context = navigatorKey.currentContext;
          if (context != null) {
            _showJoinTeamDialog(context, teamData, linkToken);
          }
        }
      } else {
        // Show error for invalid link
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired team invite link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error handling team link: $e');
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening team link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showJoinTeamDialog(BuildContext context, Team teamData, String linkToken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join ${teamData.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You\'ve been invited to join this team:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamData.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (teamData.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        teamData.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text('Members: ${teamData.members.length}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  final teamsService = FirebaseTeamsService();
                  final result = await teamsService.joinTeamThroughLink(linkToken);
                  
                  Navigator.of(context).pop(); // Close loading dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Close loading dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error joining team: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Join Team', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Method to handle incoming deep links from external sources
  void handleIncomingLink(String link) {
    // Extract team link token from URL
    final uri = Uri.parse(link);
    String? linkToken;
    
    // Handle different URL formats
    if (uri.scheme == 'wiseworkout' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'team') {
      // Custom scheme: wiseworkout://team/TOKEN
      linkToken = uri.pathSegments[1];
    } else if (uri.scheme == 'https') {
      if (uri.host == 'wiseworkout.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
        // New HTTPS format: https://wiseworkout.app/join/TOKEN
        linkToken = uri.pathSegments[1];
      } else if (uri.host == 'wise-workout.web.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
        // Firebase hosting format: https://wise-workout.web.app/join/TOKEN
        linkToken = uri.pathSegments[1];
      } else if (uri.host == 'wiseworkout.app' && uri.path.startsWith('/join-team')) {
        // Legacy HTTPS format: https://wiseworkout.app/join-team?token=TOKEN
        linkToken = uri.queryParameters['token'];
      } else if (uri.host == 'wiseworkout.com' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'team') {
        // Legacy format: https://wiseworkout.com/team/TOKEN
        linkToken = uri.pathSegments[1];
      }
    }
    
    if (linkToken != null) {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _handleTeamLink(linkToken);
      } else {
        // Store the link to handle after authentication
        _pendingTeamLink = linkToken;
        // Navigate to login page
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseUserProfileService _profileService = FirebaseUserProfileService();
  bool _isLoading = false;

  void _handleLogin() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Firebase authentication...');
      Map<String, dynamic> result = await _authService.signInWithEmailPassword(email, password);

      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && !firebaseUser.emailVerified) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before logging in.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });

      print('Firebase auth result: $result');

      if (result['success']) {
        // Check suspension status after successful authentication
        bool isSuspended = await _profileService.isUserSuspended();
        
        if (isSuspended) {
          // Sign out the user immediately if suspended
          await FirebaseAuth.instance.signOut();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been suspended. Please contact support for assistance.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }

        // Load user profile after successful login and suspension check
        UserProfileService().loadProfile();

        // All authenticated users go to UserHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserHomePage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your credential to login',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () async {
                          const String url = 'https://fyp-25-s2-09-wisefitness.onrender.com/index.html';
                          try {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              // Fallback: show dialog with URL if can't launch
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Visit Sign Up Page'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Please copy the URL below and open it in your browser:',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            url,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Clipboard.setData(const ClipboardData(text: url));
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('URL copied to clipboard!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                        ),
                                        child: const Text('Copy URL'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          } catch (e) {
                            // Show error snackbar if something goes wrong
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening sign up page: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
