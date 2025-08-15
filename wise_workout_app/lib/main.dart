import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'user_home_page.dart';
import 'services/firebase_auth_service.dart';
import 'services/user_profile_service.dart';
import 'services/firebase_user_profile_service.dart';
import 'services/firebase_teams_service.dart';
import 'team_details_page.dart';
import 'discovered_team_details_page.dart';
import 'models/team.dart';
import 'reset_password_page.dart';

// Global navigation key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global function to handle deep links from anywhere in the app
void handleGlobalDeepLink(String link) {
  print('🌐 Global deep link handler called with: $link');
  
  // Extract team link token from URL
  final uri = Uri.parse(link);
  String? linkToken;
  
  // Debug: Print URI components
  print('🔍 Global URI Debug:');
  print('   Scheme: ${uri.scheme}');
  print('   Host: ${uri.host}');
  print('   Path: ${uri.path}');
  print('   PathSegments: ${uri.pathSegments}');
  print('   PathSegments length: ${uri.pathSegments.length}');
  if (uri.pathSegments.isNotEmpty) {
    print('   First path segment: "${uri.pathSegments[0]}"');
    if (uri.pathSegments.length > 1) {
      print('   Second path segment: "${uri.pathSegments[1]}"');
    }
  }
  
  // Handle different URL formats
  if (uri.scheme == 'wiseworkout' && uri.host == 'team' && uri.pathSegments.isNotEmpty) {
    // Custom scheme: wiseworkout://team/TOKEN (host is 'team', path is '/TOKEN')
    linkToken = uri.pathSegments[0];
    print('🔗 Found custom scheme token: $linkToken');
  } else if (uri.scheme == 'https') {
    if (uri.host == 'wiseworkout.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      // New HTTPS format: https://wiseworkout.app/join/TOKEN
      linkToken = uri.pathSegments[1];
      print('🔗 Found wiseworkout.app token: $linkToken');
    } else if (uri.host == 'fyp-25-s2-09.web.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      // Firebase hosting format: https://fyp-25-s2-09.web.app/join/TOKEN
      linkToken = uri.pathSegments[1];
      print('🔗 Found Firebase hosting token: $linkToken');
    } else if (uri.host == 'wiseworkout.app' && uri.path.startsWith('/join-team')) {
      // Legacy HTTPS format: https://wiseworkout.app/join-team?token=TOKEN
      linkToken = uri.queryParameters['token'];
      print('🔗 Found legacy query token: $linkToken');
    } else if (uri.host == 'wiseworkout.com' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'team') {
      // Legacy format: https://wiseworkout.com/team/TOKEN
      linkToken = uri.pathSegments[1];
      print('🔗 Found wiseworkout.com token: $linkToken');
    }
  }
  
  if (linkToken != null) {
    print('✅ Extracted link token: $linkToken');
    _handleGlobalTeamLink(linkToken);
  } else {
    print('❌ No valid link token found in: $link');
  }
}

// Global function to handle team links
Future<void> _handleGlobalTeamLink(String linkToken) async {
  print('🔗 Processing team link globally with token: $linkToken');
  
  try {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ User not authenticated, redirecting to login');
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    final teamsService = FirebaseTeamsService();
    print('🔍 Fetching team info from token...');
    final linkInfo = await teamsService.getTeamFromLink(linkToken);
    
    if (linkInfo != null) {
      print('✅ Team info retrieved successfully');
      final teamData = linkInfo['teamData'] as Map<String, dynamic>;
      final teamId = linkInfo['teamId'] as String;
      final isAlreadyMember = linkInfo['isAlreadyMember'] as bool;
      
      print('📋 Team Details:');
      print('   - Team ID: $teamId');
      print('   - Team Name: ${teamData['name']}');
      print('   - Is Already Member: $isAlreadyMember');
      
      if (isAlreadyMember) {
        print('👤 User is already a member - navigating to TeamDetailsPage');
        // User is already a member - navigate to TeamDetailsPage
        final teamObject = Team.fromMap(teamData, teamId);
        // First navigate to UserHomePage as base, then push TeamDetailsPage
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserHomePage()),
          (route) => false,
        );
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => TeamDetailsPage(teamData: teamObject),
          ),
        );
      } else {
        print('🆕 User is not a member - navigating to DiscoveredTeamDetailsPage');
        // User is not a member - navigate to DiscoveredTeamDetailsPage
        final teamDataMap = <String, String>{
          'id': teamId,
          'name': teamData['name']?.toString() ?? 'Unknown Team',
          'description': teamData['description']?.toString() ?? '',
          'members': (teamData['members'] as List<dynamic>?)?.length.toString() ?? '0',
        };
        
        print('📝 Team Data Map: $teamDataMap');
        
        // First navigate to UserHomePage as base, then push DiscoveredTeamDetailsPage
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserHomePage()),
          (route) => false,
        );
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DiscoveredTeamDetailsPage(
              teamData: teamDataMap,
              initialJoinedState: false,
            ),
          ),
        );
      }
      print('✅ Navigation completed successfully');
    } else {
      print('❌ No team info returned - invalid or expired link');
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
    print('❌ Error handling global team link: $e');
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
  StreamSubscription<Uri>? _linkStreamSubscription;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initializeDeepLinking();
    _setupAppLinksListening();
  }

  void _initializeDeepLinking() {
    // Listen for Firebase Auth state changes to handle pending team links
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && _pendingTeamLink != null) {
        // User is authenticated, handle the pending team link
        print('🔗 User authenticated, processing pending link: $_pendingTeamLink');
        _handleTeamLink(_pendingTeamLink!);
        _pendingTeamLink = null;
      }
    });
  }

  void _setupAppLinksListening() async {
    try {
      // Listen for deep links when app is running
      _linkStreamSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        print('📱 Received deep link while app is running: $uri');
        handleIncomingLink(uri.toString());
      }, onError: (err) {
        print('❌ Deep link stream error: $err');
      });

      // Get initial link when app is opened from a link
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('📱 App opened with initial link: $initialUri');
        handleIncomingLink(initialUri.toString());
      }
    } on PlatformException catch (e) {
      print('❌ Error setting up deep link listening: $e');
    } catch (e) {
      print('❌ Unexpected error in deep link setup: $e');
    }
  }

  @override
  void dispose() {
    _linkStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleTeamLink(String linkToken) async {
    print('🔗 Handling team link with token: $linkToken');
    try {
      final teamsService = FirebaseTeamsService();
      print('🔍 Fetching team info from token...');
      final linkInfo = await teamsService.getTeamFromLink(linkToken);
      
      if (linkInfo != null) {
        print('✅ Team info retrieved successfully');
        final teamData = linkInfo['teamData'] as Map<String, dynamic>;
        final teamId = linkInfo['teamId'] as String;
        final isAlreadyMember = linkInfo['isAlreadyMember'] as bool;
        
        print('📋 Team Details:');
        print('   - Team ID: $teamId');
        print('   - Team Name: ${teamData['name']}');
        print('   - Is Already Member: $isAlreadyMember');
        
        if (isAlreadyMember) {
          print('👤 User is already a member - navigating to TeamDetailsPage');
          // User is already a member - navigate to TeamDetailsPage
          final teamObject = Team.fromMap(teamData, teamId);
          // First navigate to UserHomePage as base, then push TeamDetailsPage
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UserHomePage()),
            (route) => false,
          );
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TeamDetailsPage(teamData: teamObject),
            ),
          );
        } else {
          print('🆕 User is not a member - navigating to DiscoveredTeamDetailsPage');
          // User is not a member - navigate to DiscoveredTeamDetailsPage
          final teamDataMap = <String, String>{
            'id': teamId,
            'name': teamData['name']?.toString() ?? 'Unknown Team',
            'description': teamData['description']?.toString() ?? '',
            'members': (teamData['members'] as List<dynamic>?)?.length.toString() ?? '0',
          };
          
          print('📝 Team Data Map: $teamDataMap');
          
          // First navigate to UserHomePage as base, then push DiscoveredTeamDetailsPage
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UserHomePage()),
            (route) => false,
          );
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => DiscoveredTeamDetailsPage(
                teamData: teamDataMap,
                initialJoinedState: false,
              ),
            ),
          );
        }
        print('✅ Navigation completed successfully');
      } else {
        print('❌ No team info returned - invalid or expired link');
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

  // Method to handle incoming deep links from external sources
  void handleIncomingLink(String link) {
    print('🔗 Processing incoming link: $link');
    
    // Extract team link token from URL
    final uri = Uri.parse(link);
    String? linkToken;
    
    // Debug: Print URI components
    print('🔍 URI Debug:');
    print('   Scheme: ${uri.scheme}');
    print('   Host: ${uri.host}');
    print('   Path: ${uri.path}');
    print('   PathSegments: ${uri.pathSegments}');
    print('   PathSegments length: ${uri.pathSegments.length}');
    if (uri.pathSegments.isNotEmpty) {
      print('   First path segment: "${uri.pathSegments[0]}"');
      if (uri.pathSegments.length > 1) {
        print('   Second path segment: "${uri.pathSegments[1]}"');
      }
    }
    
    // Handle different URL formats
    if (uri.scheme == 'wiseworkout' && uri.host == 'team' && uri.pathSegments.isNotEmpty) {
      // Custom scheme: wiseworkout://team/TOKEN (host is 'team', path is '/TOKEN')
      linkToken = uri.pathSegments[0];
      print('🔗 Found custom scheme token: $linkToken');
    } else if (uri.scheme == 'https') {
      if (uri.host == 'wiseworkout.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
        // New HTTPS format: https://wiseworkout.app/join/TOKEN
        linkToken = uri.pathSegments[1];
        print('🔗 Found wiseworkout.app token: $linkToken');
      } else if (uri.host == 'fyp-25-s2-09.web.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
        // Firebase hosting format: https://fyp-25-s2-09.web.app/join/TOKEN
        linkToken = uri.pathSegments[1];
        print('🔗 Found Firebase hosting token: $linkToken');
      } else if (uri.host == 'wiseworkout.app' && uri.path.startsWith('/join-team')) {
        // Legacy HTTPS format: https://wiseworkout.app/join-team?token=TOKEN
        linkToken = uri.queryParameters['token'];
        print('🔗 Found legacy query token: $linkToken');
      } else if (uri.host == 'wiseworkout.com' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'team') {
        // Legacy format: https://wiseworkout.com/team/TOKEN
        linkToken = uri.pathSegments[1];
        print('🔗 Found wiseworkout.com token: $linkToken');
      }
    }
    
    if (linkToken != null) {
      print('✅ Extracted link token: $linkToken');
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('✅ User is authenticated, handling team link immediately');
        _handleTeamLink(linkToken);
      } else {
        print('⚠️ User not authenticated, storing link for later');
        // Store the link to handle after authentication
        _pendingTeamLink = linkToken;
        // Navigate to login page
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      print('❌ No valid link token found in: $link');
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
